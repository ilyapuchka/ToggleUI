import XCTest
import ToggleUI
import Combine

final class ToggleUILibTests: XCTestCase {

    let toggles = Toggles()

    var bag = Set<AnyCancellable>()

    func testInMemoryToggleProvider() {
        currentProvider = inMemoryProvider

        XCTAssertEqual(toggles.toggleA, true)
        XCTAssertEqual(toggles.toggleB, "B")
        XCTAssertEqual(toggles.toggleC, .c)
        XCTAssertEqual(toggles.toggleF, "F")
        XCTAssertEqual(toggles.toggleG, true)

        XCTAssertEqual(toggles.$toggleD.toggle.wrappedValue, true)
        XCTAssertEqual(toggles.$toggleE.toggle.wrappedValue, .b)

        XCTAssertEqual(toggles.value1sync, "value1")

        XCTAssertEqual(toggles.toggleConfig.f, "F")
        XCTAssertEqual(toggles.toggleConfig.g, true)
    }

    func testUserDefaultsToggleProvider() {
        UserDefaults.standard.set(values, forKey: UserDefaultsToggleProvider.key)
        currentProvider = UserDefaultsToggleProvider(
            userDefaults: UserDefaults.standard
        )

        XCTAssertEqual(toggles.toggleA, true)
        XCTAssertEqual(toggles.toggleB, "B")
        XCTAssertEqual(toggles.toggleC, .c)
        XCTAssertEqual(toggles.toggleF, "F")
        XCTAssertEqual(toggles.toggleG, true)

        XCTAssertEqual(toggles.$toggleD.toggle.wrappedValue, true)
        XCTAssertEqual(toggles.$toggleE.toggle.wrappedValue, .b)

        XCTAssertEqual(toggles.toggleConfig.f, "F")
        XCTAssertEqual(toggles.toggleConfig.g, true)

        UserDefaults.standard.setValue(nil, forKey: UserDefaultsToggleProvider.key)
    }

    func testObservers() {
        currentProvider = inMemoryProvider

        XCTAssertEqual(toggles.$value2.toggle.wrappedValue, true)
        XCTAssertEqual(toggles.$value3.toggle.wrappedValue, "value3")

        XCTAssertEqual(toggles.$value4.toggle.wrappedValue, "value4")
        XCTAssertEqual(toggles.$value1.toggle.wrappedValue, "value1")

        XCTAssertEqual(toggles.$value3Decodable.group.toggle.wrappedValue.feature3, "value3")

        let expValue2 = expectation(description: "")
        toggles.value2.sink { value in
            XCTAssertEqual(value, true)
            expValue2.fulfill()
        }.store(in: &bag)

        let expValue3 = expectation(description: "")
        toggles.value3.sink { value in
            XCTAssertEqual(value, "value3")
            expValue3.fulfill()
        }.store(in: &bag)

        let expValue4 = expectation(description: "")
        toggles.value4.sink { value in
            XCTAssertEqual(value, "value4")
            expValue4.fulfill()
        }.store(in: &bag)

        let expValue1 = expectation(description: "")
        toggles.value1.sink { value in
            XCTAssertEqual(value, "value1")
            expValue1.fulfill()
        }.store(in: &bag)

        let expValue3Decodable = expectation(description: "")
        toggles.value3Decodable.sink { value in
            XCTAssertEqual(value.feature3, "value3")
            expValue3Decodable.fulfill()
        }.store(in: &bag)

        waitForExpectations(timeout: 10, handler: nil)
    }
}
