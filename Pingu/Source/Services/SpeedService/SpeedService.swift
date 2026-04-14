//
//  SpeedService.swift
//  Pingu
//

import Foundation

public class SpeedService: NSObject, URLSessionDataDelegate {

    // MARK: - Configuration

    private let speedTestURL = "https://speed.cloudflare.com/__down"
    private let downloadSize: Int = 1_000_000 // 1 MB
    private let measurementWindow: TimeInterval = 4.0
    private let connectTimeout: TimeInterval = 10.0

    // MARK: - Properties

    private var timer: Timer?
    private var urlSession: URLSession?
    private var currentTask: URLSessionDataTask?
    public var interval: TimeInterval = 5.0
    public var observer: ((SpeedResult) -> Void)?

    private(set) var isRunning: Bool = false

    // Backoff state
    private var backoffMultiplier: Double = 1.0
    private let maxBackoffMultiplier: Double = 12.0 // caps at ~60s with 5s base

    // Per-measurement state
    private var bytesReceived: Int = 0
    private var downloadStartTime: CFAbsoluteTime = 0
    private var hasReceivedFirstByte: Bool = false
    private var measureTimer: Timer?
    private var hasReported: Bool = false

    // MARK: - Init

    public override init() {
        super.init()
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = connectTimeout
        config.timeoutIntervalForResource = 30
        config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        urlSession = URLSession(configuration: config, delegate: self, delegateQueue: .main)
    }

    // MARK: - Public Methods

    public func startSpeedTest() {
        guard !isRunning else { return }
        isRunning = true
        runSpeedTest()
    }

    public func stopSpeedTest() {
        isRunning = false
        timer?.invalidate()
        timer = nil
        cancelMeasurement()
    }

    // MARK: - Private Methods

    private func runSpeedTest() {
        cancelMeasurement()

        guard let url = URL(string: "\(speedTestURL)?bytes=\(downloadSize)&t=\(Date().timeIntervalSince1970)") else {
            report(.error)
            return
        }

        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData

        bytesReceived = 0
        downloadStartTime = 0
        hasReceivedFirstByte = false
        hasReported = false

        currentTask = urlSession?.dataTask(with: request)
        currentTask?.resume()
    }

    private func cancelMeasurement() {
        measureTimer?.invalidate()
        measureTimer = nil
        currentTask?.cancel()
        currentTask = nil
    }

    private func report(_ result: SpeedResult) {
        guard !hasReported else { return }
        hasReported = true
        cancelMeasurement()

        if case .rateLimited = result {
            backoffMultiplier = min(backoffMultiplier * 2, maxBackoffMultiplier)
        } else {
            backoffMultiplier = 1.0
        }

        observer?(result)
        scheduleNextTest()
    }

    private func reportMeasuredSpeed() {
        let elapsed = CFAbsoluteTimeGetCurrent() - downloadStartTime
        guard elapsed > 0, bytesReceived > 0 else {
            report(.timeout)
            return
        }
        let mbps = (Double(bytesReceived) * 8.0) / (elapsed * 1_000_000.0)
        report(.speedInMbps(mbps))
    }

    private func scheduleNextTest() {
        guard isRunning else { return }
        let delay = interval * backoffMultiplier
        timer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            self?.runSpeedTest()
        }
    }

    // MARK: - URLSessionDataDelegate

    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask,
                           didReceive response: URLResponse,
                           completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        guard let httpResponse = response as? HTTPURLResponse else {
            completionHandler(.allow)
            return
        }

        if httpResponse.statusCode == 429 {
            report(.rateLimited)
            completionHandler(.cancel)
            return
        }

        if httpResponse.statusCode != 200 {
            report(.error)
            completionHandler(.cancel)
            return
        }

        completionHandler(.allow)
    }

    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        bytesReceived += data.count

        if !hasReceivedFirstByte {
            hasReceivedFirstByte = true
            downloadStartTime = CFAbsoluteTimeGetCurrent()

            measureTimer = Timer.scheduledTimer(withTimeInterval: measurementWindow, repeats: false) { [weak self] _ in
                self?.reportMeasuredSpeed()
            }
        }
    }

    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if hasReported { return }

        if let urlError = error as? URLError, urlError.code == .cancelled {
            return
        }

        if error != nil {
            if bytesReceived > 0 {
                reportMeasuredSpeed()
            } else {
                report(.timeout)
            }
            return
        }

        // Download completed before measurement window elapsed
        reportMeasuredSpeed()
    }

    deinit {
        stopSpeedTest()
        urlSession?.invalidateAndCancel()
    }
}
