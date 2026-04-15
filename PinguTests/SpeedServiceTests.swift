//
//  SpeedServiceTests.swift
//  PinguTests
//

import XCTest
@testable import Pingu

final class SpeedServiceTests: XCTestCase {

    var service: SpeedService!
    var results: [SpeedResult]!

    override func setUp() {
        super.setUp()
        service = SpeedService()
        service.interval = 1.0
        results = []
        service.observer = { [weak self] result in
            self?.results.append(result)
        }
    }

    override func tearDown() {
        service.stopSpeedTest()
        service = nil
        results = nil
        super.tearDown()
    }

    // MARK: - Rate Limit Backoff

    func testBackoffDoublesOnRateLimit() {
        XCTAssertEqual(service.backoffMultiplier, 1.0)

        simulate429()
        XCTAssertEqual(service.backoffMultiplier, 2.0)

        simulate429()
        XCTAssertEqual(service.backoffMultiplier, 4.0)

        simulate429()
        XCTAssertEqual(service.backoffMultiplier, 8.0)
    }

    func testBackoffCapsAtMaximum() {
        for _ in 0..<20 {
            simulate429()
        }
        XCTAssertEqual(service.backoffMultiplier, service.maxBackoffMultiplier)
    }

    func testBackoffResetsOnSuccess() {
        simulate429()
        simulate429()
        XCTAssertEqual(service.backoffMultiplier, 4.0)

        simulateSuccess()
        XCTAssertEqual(service.backoffMultiplier, 1.0)
    }

    func testBackoffResetsOnStop() {
        simulate429()
        simulate429()
        XCTAssertGreaterThan(service.backoffMultiplier, 1.0)

        service.stopSpeedTest()
        XCTAssertEqual(service.backoffMultiplier, 1.0)
    }

    // MARK: - Result Reporting

    func testRateLimitedResultReported() {
        simulate429()

        XCTAssertEqual(results.count, 1)
        guard case .rateLimited = results.first else {
            XCTFail("Expected .rateLimited, got \(String(describing: results.first))")
            return
        }
    }

    func testErrorResultOnNon200() {
        simulateHTTPStatus(500)

        XCTAssertEqual(results.count, 1)
        guard case .error = results.first else {
            XCTFail("Expected .error, got \(String(describing: results.first))")
            return
        }
    }

    func testErrorResetsBackoff() {
        simulate429()
        XCTAssertEqual(service.backoffMultiplier, 2.0)

        simulateHTTPStatus(500)
        XCTAssertEqual(service.backoffMultiplier, 1.0)
    }

    func testTimeoutOnZeroBytes() {
        service.startSpeedTest()

        let session = URLSession.shared
        let task = session.dataTask(with: URL(string: "https://example.com")!)
        service.urlSession(session, task: task, didCompleteWithError: URLError(.timedOut))

        XCTAssertEqual(results.count, 1)
        guard case .timeout = results.first else {
            XCTFail("Expected .timeout, got \(String(describing: results.first))")
            return
        }
    }

    func testSpeedCalculation() {
        service.startSpeedTest()

        let session = URLSession.shared
        let url = URL(string: "https://speed.cloudflare.com/__down?bytes=1000000")!
        let task = session.dataTask(with: url)

        // 200 response
        let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
        let exp1 = expectation(description: "response handler")
        service.urlSession(session, dataTask: task, didReceive: response) { _ in
            exp1.fulfill()
        }
        wait(for: [exp1], timeout: 1.0)

        // Send 1 MB of data
        let data = Data(count: 1_000_000)
        service.urlSession(session, dataTask: task, didReceive: data)

        // Fake the start time to be exactly 1 second ago
        service.downloadStartTime = CFAbsoluteTimeGetCurrent() - 1.0

        // Signal download complete
        service.urlSession(session, task: task, didCompleteWithError: nil)

        XCTAssertEqual(results.count, 1)
        guard case .speedInMbps(let mbps) = results.first else {
            XCTFail("Expected .speedInMbps, got \(String(describing: results.first))")
            return
        }
        // 1MB in 1s = 8 Mbps
        XCTAssertEqual(mbps, 8.0, accuracy: 0.5)
    }

    // MARK: - Start / Stop

    func testStartSetsRunning() {
        service.startSpeedTest()
        XCTAssertTrue(service.isRunning)
    }

    func testStopClearsRunning() {
        service.startSpeedTest()
        service.stopSpeedTest()
        XCTAssertFalse(service.isRunning)
    }

    func testDoubleStartIsNoOp() {
        service.startSpeedTest()
        XCTAssertTrue(service.isRunning)
        service.startSpeedTest() // should not crash or restart
        XCTAssertTrue(service.isRunning)
    }

    // MARK: - Helpers

    /// Simulate a 429 response without stopping the service (preserves backoff state).
    private func simulate429() {
        simulateHTTPStatus(429)
    }

    /// Simulate a successful download.
    private func simulateSuccess() {
        resetMeasurementState()

        let session = URLSession.shared
        let url = URL(string: "https://speed.cloudflare.com/__down?bytes=1000000")!
        let task = session.dataTask(with: url)

        let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
        let exp = expectation(description: "response handler")
        service.urlSession(session, dataTask: task, didReceive: response) { _ in
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)

        // Send data and complete
        service.urlSession(session, dataTask: task, didReceive: Data(count: 500_000))
        service.downloadStartTime = CFAbsoluteTimeGetCurrent() - 1.0
        service.urlSession(session, task: task, didCompleteWithError: nil)
    }

    /// Simulate an HTTP response with the given status code.
    private func simulateHTTPStatus(_ statusCode: Int) {
        resetMeasurementState()

        let session = URLSession.shared
        let url = URL(string: "https://speed.cloudflare.com/__down?bytes=1000000")!
        let response = HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
        let task = session.dataTask(with: url)

        let exp = expectation(description: "completion handler called")
        service.urlSession(session, dataTask: task, didReceive: response) { _ in
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
    }

    /// Reset per-measurement state so the next delegate call is accepted.
    /// Mirrors what `runSpeedTest()` does internally.
    private func resetMeasurementState() {
        if !service.isRunning {
            service.startSpeedTest()
        }
        service.bytesReceived = 0
        service.downloadStartTime = 0
        service.hasReceivedFirstByte = false
        service.hasReported = false
    }
}
