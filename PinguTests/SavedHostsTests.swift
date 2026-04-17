import XCTest
@testable import Pingu

final class SavedHostsTests: XCTestCase {

    var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: "com.pingu.tests.savedHosts")!
        defaults.removePersistentDomain(forName: "com.pingu.tests.savedHosts")
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: "com.pingu.tests.savedHosts")
        defaults = nil
        super.tearDown()
    }

    // MARK: - Add

    func testAddHostSelectsIt() {
        let saved = SavedHosts()
        let host = Host(host: "example.com", interval: .seconds(1))
        saved.add(host)

        XCTAssertEqual(saved.selectedHost, host)
    }

    func testAddMultipleHostsSelectsLatest() {
        let saved = SavedHosts()
        let first = Host(host: "first.com", interval: .seconds(1))
        let second = Host(host: "second.com", interval: .seconds(5))

        saved.add(first)
        saved.add(second)

        XCTAssertEqual(saved.selectedHost, second)
        XCTAssertEqual(saved.hosts.count, 2)
    }

    func testAddCapsAtFiveHosts() {
        let saved = SavedHosts()
        for i in 0..<6 {
            saved.add(Host(host: "host\(i).com", interval: .seconds(1)))
        }

        XCTAssertEqual(saved.hosts.count, 5)
    }

    func testAddInsertsAtFront() {
        let saved = SavedHosts()
        let first = Host(host: "first.com", interval: .seconds(1))
        let second = Host(host: "second.com", interval: .seconds(1))

        saved.add(first)
        saved.add(second)

        XCTAssertEqual(saved.hosts.first, second)
    }

    // MARK: - Selection

    func testSetSelected() {
        let saved = SavedHosts()
        let host1 = Host(host: "one.com", interval: .seconds(1))
        let host2 = Host(host: "two.com", interval: .seconds(1))

        saved.add(host1)
        saved.add(host2)

        saved.setSelected(host1)
        XCTAssertEqual(saved.selectedHost, host1)
    }

    func testSetSelectedDeselectsOthers() {
        let saved = SavedHosts()
        let host1 = Host(host: "one.com", interval: .seconds(1))
        let host2 = Host(host: "two.com", interval: .seconds(1))

        saved.add(host1)
        saved.add(host2)
        saved.setSelected(host1)

        let selectedCount = saved.hosts.filter { $0.selected }.count
        XCTAssertEqual(selectedCount, 1)
    }

    func testSelectedHostReturnsNilWhenEmpty() {
        let saved = SavedHosts()
        XCTAssertNil(saved.selectedHost)
    }

    // MARK: - Persistence

    func testSaveAndLoad() {
        let saved = SavedHosts()
        let host = Host(host: "persist.com", interval: .seconds(5))
        saved.add(host)
        saved.save(toStore: defaults)

        let loaded = SavedHosts.load(fromStore: defaults)
        XCTAssertEqual(loaded.hosts.count, 1)
        XCTAssertEqual(loaded.hosts.first?.host, "persist.com")
        XCTAssertEqual(loaded.hosts.first?.interval, .seconds(5))
    }

    func testLoadFromEmptyStoreReturnsEmpty() {
        let loaded = SavedHosts.load(fromStore: defaults)
        XCTAssertTrue(loaded.hosts.isEmpty)
        XCTAssertNil(loaded.selectedHost)
    }

    func testLoadPreservesSelection() {
        let saved = SavedHosts()
        let host1 = Host(host: "one.com", interval: .seconds(1))
        let host2 = Host(host: "two.com", interval: .seconds(1))
        saved.add(host1)
        saved.add(host2)
        saved.setSelected(host1)
        saved.save(toStore: defaults)

        let loaded = SavedHosts.load(fromStore: defaults)
        XCTAssertEqual(loaded.selectedHost?.host, "one.com")
    }
}
