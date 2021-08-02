import XCTest
@testable import Persistable

final class PersistenceStateMachineTests: XCTestCase {
    static var stateMachine = PersistenceStateMachine()

    func test_initial_state() {
        XCTAssertEqual(PersistenceStateMachineTests.stateMachine.currentState, .created)
    }

    func test_synced_state() {
        PersistenceStateMachineTests.stateMachine.process(event: .load)
        XCTAssertEqual(PersistenceStateMachineTests.stateMachine.currentState, .synced)
    }

    func test_modified_state() {
        PersistenceStateMachineTests.stateMachine.process(event: .load)
        PersistenceStateMachineTests.stateMachine.process(event: .modify)
        XCTAssertEqual(PersistenceStateMachineTests.stateMachine.currentState, .modified)
    }

    func test_saves_state() {
        PersistenceStateMachineTests.stateMachine.process(event: .load)
        PersistenceStateMachineTests.stateMachine.process(event: .modify)
        PersistenceStateMachineTests.stateMachine.process(event: .save)
        XCTAssertEqual(PersistenceStateMachineTests.stateMachine.currentState, .synced)
    }
}

final class PersistableTests: XCTestCase {
    struct Persistable: PersistableP {
        var persistenceSM: PersistenceStateMachine
    }

    static var persistable: PersistableP!

    override func setUp() {
        super.setUp()
        PersistableTests.persistable = PersistableTests.Persistable(persistenceSM: PersistenceStateMachine())
    }

    func test_initial_state() {
        XCTAssertEqual(PersistableTests.persistable.persistenceState, .created)
    }

    func test_initial_synced() {
        PersistableTests.persistable.persistenceSM.process(event: .load)
        XCTAssertEqual(PersistableTests.persistable.persistenceState, .synced)
    }

    func test_initial_modified() {
        PersistableTests.persistable.persistenceSM.process(event: .load)
        PersistableTests.persistable.persistenceSM.process(event: .modify)
        XCTAssertTrue(PersistableTests.persistable.isModified)
    }

}
