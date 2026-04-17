import XCTest
@testable import Pingu

final class RescaleTests: XCTestCase {

    func testRescaleMiddleValue() {
        let result: Float = rescale(50, from: (0, 100), to: (0, 10))
        XCTAssertEqual(result, 5.0, accuracy: 0.001)
    }

    func testRescaleLowerBound() {
        let result: Float = rescale(0, from: (0, 100), to: (1, 12))
        XCTAssertEqual(result, 1.0, accuracy: 0.001)
    }

    func testRescaleUpperBound() {
        let result: Float = rescale(100, from: (0, 100), to: (1, 12))
        XCTAssertEqual(result, 12.0, accuracy: 0.001)
    }

    func testRescaleDoubleType() {
        let result: Double = rescale(25.0, from: (0, 50), to: (0, 1))
        XCTAssertEqual(result, 0.5, accuracy: 0.001)
    }

    func testRescaleBeyondUpperBound() {
        let result: Float = rescale(200, from: (0, 100), to: (0, 10))
        XCTAssertEqual(result, 20.0, accuracy: 0.001)
    }

    func testRescaleNegativeInput() {
        let result: Float = rescale(-50, from: (0, 100), to: (0, 10))
        XCTAssertEqual(result, -5.0, accuracy: 0.001)
    }

    func testRescaleZeroRange() {
        let result: Float = rescale(5, from: (5, 5), to: (0, 10))
        XCTAssertTrue(result.isFinite)
    }

    func testRescaleIdentityDomain() {
        let result: Float = rescale(7, from: (0, 10), to: (0, 10))
        XCTAssertEqual(result, 7.0, accuracy: 0.001)
    }
}
