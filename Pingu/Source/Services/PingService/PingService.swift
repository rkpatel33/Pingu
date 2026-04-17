//
//  PingService.swift
//  Pingu
//
//  Created by Thanos Theodoridis on 2/4/20.
//  Copyright © 2020 Thanos Theodoridis. All rights reserved.
//

import Foundation
import Darwin

public enum PingResult {
    case timeout
    case responseInMilliseconds(Int)
    case unknownResult
    case unknownHost
    case paused
}

public class PingService {

    // MARK: - Public Properties

    public private(set) var isPinging: Bool = false

    // MARK: - Private Properties

    private let pingPath = "/sbin/ping"
    private var task: Process?
    private var pipe: Pipe?
    private var outputHandle: FileHandle?

    // MARK: - Public Methods

    public func startPinging(host: String, interval: TimeInterval, observer: @escaping (PingResult) -> Void) {
        stopPinging()
        isPinging = true

        NSLog("Starting pings - Host: \(host) - Interval: \(interval)")

        let task = Process()
        task.launchPath = pingPath
        task.arguments = ["-i", "\(interval)", host]

        let pipe = Pipe()
        task.standardOutput = pipe

        let outputHandle = pipe.fileHandleForReading
        outputHandle.readabilityHandler = { [weak self] handle in
            guard let self = self else { return }
            if let line = String(data: handle.availableData, encoding: .utf8) {
                observer(self.parse(line: line))
            }
        }

        self.task = task
        self.pipe = pipe
        self.outputHandle = outputHandle

        DispatchQueue.global(qos: .userInteractive).async {
            do {
                try task.run()
                task.waitUntilExit()
            } catch {
                NSLog("Failed to launch ping: \(error)")
            }
        }
    }

    public func stopPinging() {
        NSLog("Stopping pings")
        isPinging = false
        outputHandle?.readabilityHandler = nil
        if task?.isRunning == true {
            task?.terminate()
        }

        task = nil
        pipe = nil
        outputHandle = nil
    }

    public func getAddress(forHost host: String) -> (data: Data?, error: NSError?) {
        var streamError = CFStreamError()
        let cfhost = CFHostCreateWithName(nil, host as CFString).takeRetainedValue()
        let status = CFHostStartInfoResolution(cfhost, .addresses, &streamError)

        if !status {
            return (nil, NSError(domain: kCFErrorDomainCFNetwork as String,
                                 code: Int(CFNetworkErrors.cfHostErrorUnknown.rawValue),
                                 userInfo: nil))
        }

        var success: DarwinBoolean = false

        guard let addresses = CFHostGetAddressing(cfhost, &success)?.takeUnretainedValue() as? [Data] else {
            return (nil, NSError(domain: kCFErrorDomainCFNetwork as String,
                                 code: Int(CFNetworkErrors.cfHostErrorHostNotFound.rawValue),
                                 userInfo: nil))
        }

        for address in addresses {
            let addrin = address.socketAddress
            if address.count >= MemoryLayout<sockaddr>.size && addrin.sa_family == UInt8(AF_INET) {
                return (address, nil)
            }
        }

        return (nil, NSError(domain: kCFErrorDomainCFNetwork as String,
                             code: Int(CFNetworkErrors.cfHostErrorHostNotFound.rawValue),
                             userInfo: nil))
    }

    // MARK: - Internal Methods

    func parse(line: String) -> PingResult {
        if line.hasSuffix("Unknown host") {
            return .unknownHost
        } else if line.hasPrefix("Request timeout") {
            return .timeout
        }

        let components = line.components(separatedBy: "time=")

        guard components.count == 2, let timeComponent = components.last else {
            return .unknownResult
        }

        if let milliseconds = Double(timeComponent.filter("0123456789.".contains)) {
            return .responseInMilliseconds(Int(milliseconds))
        }

        return .unknownResult
    }
}
