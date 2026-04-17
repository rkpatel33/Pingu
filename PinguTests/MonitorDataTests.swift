import XCTest
@testable import Pingu

final class MonitorDataTests: XCTestCase {

    var data: MonitorData!

    override func setUp() {
        super.setUp()
        data = MonitorData()
    }

    override func tearDown() {
        data = nil
        super.tearDown()
    }

    // MARK: - Ping History

    func testAddPingResponse() {
        data.addPing(.responseInMilliseconds(42))
        XCTAssertEqual(data.pingHistory.count, 1)
        XCTAssertEqual(data.pingHistory.first?.value, 42)
    }

    func testAddPingTimeout() {
        data.addPing(.timeout)
        XCTAssertEqual(data.pingHistory.count, 1)
        XCTAssertEqual(data.pingHistory.first?.value, -1)
    }

    func testAddPingIgnoresUnknownResult() {
        data.addPing(.unknownResult)
        XCTAssertTrue(data.pingHistory.isEmpty)
    }

    func testAddPingIgnoresPaused() {
        data.addPing(.paused)
        XCTAssertTrue(data.pingHistory.isEmpty)
    }

    func testLatestPing() {
        data.addPing(.responseInMilliseconds(10))
        data.addPing(.responseInMilliseconds(20))
        XCTAssertEqual(data.latestPing?.value, 20)
    }

    func testLatestPingNilWhenEmpty() {
        XCTAssertNil(data.latestPing)
    }

    // MARK: - Speed History

    func testAddSpeedResult() {
        data.addSpeed(.speedInMbps(50.5))
        XCTAssertEqual(data.speedHistory.count, 1)
        XCTAssertEqual(data.speedHistory.first?.value, 50.5)
    }

    func testAddSpeedTimeout() {
        data.addSpeed(.timeout)
        XCTAssertEqual(data.speedHistory.count, 1)
        XCTAssertEqual(data.speedHistory.first?.value, -1)
    }

    func testAddSpeedError() {
        data.addSpeed(.error)
        XCTAssertEqual(data.speedHistory.count, 1)
        XCTAssertEqual(data.speedHistory.first?.value, -1)
    }

    func testAddSpeedRateLimited() {
        data.addSpeed(.rateLimited)
        XCTAssertEqual(data.speedHistory.count, 1)
        XCTAssertEqual(data.speedHistory.first?.value, -2)
    }

    func testLatestSpeed() {
        data.addSpeed(.speedInMbps(10.0))
        data.addSpeed(.speedInMbps(20.0))
        XCTAssertEqual(data.latestSpeed?.value, 20.0)
    }

    func testLatestSpeedNilWhenEmpty() {
        XCTAssertNil(data.latestSpeed)
    }

    // MARK: - Trim Independence

    func testAddPingDoesNotTrimSpeedHistory() {
        data.addSpeed(.speedInMbps(50.0))
        let speedCount = data.speedHistory.count

        data.addPing(.responseInMilliseconds(10))

        XCTAssertEqual(data.speedHistory.count, speedCount)
    }

    func testAddSpeedDoesNotTrimPingHistory() {
        data.addPing(.responseInMilliseconds(10))
        let pingCount = data.pingHistory.count

        data.addSpeed(.speedInMbps(50.0))

        XCTAssertEqual(data.pingHistory.count, pingCount)
    }
}
