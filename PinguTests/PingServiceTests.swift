import XCTest
@testable import Pingu

final class PingServiceTests: XCTestCase {

    var service: PingService!

    override func setUp() {
        super.setUp()
        service = PingService()
    }

    override func tearDown() {
        service.stopPinging()
        service = nil
        super.tearDown()
    }

    // MARK: - Parse

    func testParseResponseTime() {
        let result = service.parse(line: "64 bytes from 142.250.80.4: icmp_seq=0 ttl=117 time=12.345 ms")
        guard case .responseInMilliseconds(let ms) = result else {
            XCTFail("Expected .responseInMilliseconds, got \(result)")
            return
        }
        XCTAssertEqual(ms, 12)
    }

    func testParseSubMillisecondResponse() {
        let result = service.parse(line: "64 bytes from 192.168.1.1: icmp_seq=0 ttl=64 time=0.456 ms")
        guard case .responseInMilliseconds(let ms) = result else {
            XCTFail("Expected .responseInMilliseconds, got \(result)")
            return
        }
        XCTAssertEqual(ms, 0)
    }

    func testParseLargeResponseTime() {
        let result = service.parse(line: "64 bytes from 8.8.8.8: icmp_seq=5 ttl=117 time=999.123 ms")
        guard case .responseInMilliseconds(let ms) = result else {
            XCTFail("Expected .responseInMilliseconds, got \(result)")
            return
        }
        XCTAssertEqual(ms, 999)
    }

    func testParseTimeout() {
        let result = service.parse(line: "Request timeout for icmp_seq 0")
        guard case .timeout = result else {
            XCTFail("Expected .timeout, got \(result)")
            return
        }
    }

    func testParseUnknownHost() {
        let result = service.parse(line: "ping: cannot resolve nonexistent.host: Unknown host")
        guard case .unknownHost = result else {
            XCTFail("Expected .unknownHost, got \(result)")
            return
        }
    }

    func testParseUnknownResult() {
        let result = service.parse(line: "PING google.com (142.250.80.4): 56 data bytes")
        guard case .unknownResult = result else {
            XCTFail("Expected .unknownResult, got \(result)")
            return
        }
    }

    func testParseEmptyLine() {
        let result = service.parse(line: "")
        guard case .unknownResult = result else {
            XCTFail("Expected .unknownResult, got \(result)")
            return
        }
    }

    func testParseLineWithMultipleTimeEquals() {
        let result = service.parse(line: "time=fake time=42.0 ms")
        guard case .unknownResult = result else {
            XCTFail("Expected .unknownResult for malformed line, got \(result)")
            return
        }
    }

    // MARK: - Start / Stop

    func testStartSetsIsPinging() {
        service.startPinging(host: "localhost", interval: 1.0) { _ in }
        XCTAssertTrue(service.isPinging)
    }

    func testStopClearsIsPinging() {
        service.startPinging(host: "localhost", interval: 1.0) { _ in }
        service.stopPinging()
        XCTAssertFalse(service.isPinging)
    }

    func testStopWithoutStartDoesNotCrash() {
        service.stopPinging()
        XCTAssertFalse(service.isPinging)
    }

    func testDoubleStopDoesNotCrash() {
        service.startPinging(host: "localhost", interval: 1.0) { _ in }
        service.stopPinging()
        service.stopPinging()
        XCTAssertFalse(service.isPinging)
    }

    // MARK: - Address Resolution

    func testGetAddressForValidHost() {
        let (data, error) = service.getAddress(forHost: "localhost")
        XCTAssertNotNil(data)
        XCTAssertNil(error)
    }

    func testGetAddressForInvalidHost() {
        let (data, error) = service.getAddress(forHost: "this.host.definitely.does.not.exist.invalid")
        XCTAssertNil(data)
        XCTAssertNotNil(error)
    }
}
