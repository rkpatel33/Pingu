//
//  SpeedService.swift
//  Pingu
//

import Foundation

public class SpeedService {

    // MARK: - Configuration

    private let speedTestURL = "https://speed.cloudflare.com/__down"
    private let fileSize: Int = 2_000_000 // 2 MB
    private let timeout: TimeInterval = 15.0

    // MARK: - Properties

    private var timer: Timer?
    private var urlSession: URLSession?
    private var currentTask: URLSessionDataTask?
    public var interval: TimeInterval = 5.0
    public var observer: ((SpeedResult) -> Void)?

    private(set) var isRunning: Bool = false

    // MARK: - Init

    public init() {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = timeout
        config.timeoutIntervalForResource = timeout
        config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        self.urlSession = URLSession(configuration: config)
    }

    // MARK: - Public Methods

    public func startSpeedTest() {
        guard !isRunning else { return }
        isRunning = true

        // Run first test immediately
        runSpeedTest()

        // Schedule recurring tests
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.runSpeedTest()
        }
    }

    public func stopSpeedTest() {
        isRunning = false
        timer?.invalidate()
        timer = nil
        currentTask?.cancel()
        currentTask = nil
    }

    // MARK: - Private Methods

    private func runSpeedTest() {
        guard let url = URL(string: "\(speedTestURL)?bytes=\(fileSize)&t=\(Date().timeIntervalSince1970)") else {
            observer?(.error)
            return
        }

        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData

        let startTime = CFAbsoluteTimeGetCurrent()

        currentTask = urlSession?.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }

            // Check for cancellation
            if let urlError = error as? URLError, urlError.code == .cancelled {
                return
            }

            // Check for timeout
            if let urlError = error as? URLError, urlError.code == .timedOut {
                DispatchQueue.main.async {
                    self.observer?(.timeout)
                }
                return
            }

            // Check for other errors
            if error != nil {
                DispatchQueue.main.async {
                    self.observer?(.error)
                }
                return
            }

            // Check HTTP status
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 429 {
                    DispatchQueue.main.async {
                        self.observer?(.rateLimited)
                    }
                    return
                }

                if httpResponse.statusCode != 200 {
                    DispatchQueue.main.async {
                        self.observer?(.error)
                    }
                    return
                }
            }

            // Calculate speed
            let endTime = CFAbsoluteTimeGetCurrent()
            let durationSeconds = endTime - startTime

            guard durationSeconds > 0, let data = data, data.count > 0 else {
                DispatchQueue.main.async {
                    self.observer?(.error)
                }
                return
            }

            // Calculate Mbps: (bytes * 8) / (seconds * 1_000_000)
            let mbps = (Double(data.count) * 8.0) / (durationSeconds * 1_000_000.0)

            DispatchQueue.main.async {
                self.observer?(.speedInMbps(mbps))
            }
        }

        currentTask?.resume()
    }

    deinit {
        stopSpeedTest()
        urlSession?.invalidateAndCancel()
    }
}
