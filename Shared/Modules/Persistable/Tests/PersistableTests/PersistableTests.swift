import XCTest
@testable import Persistable

final class PersistenceStateMachineTests: XCTestCase {
    static var stateMachine = PersistenceStateMachine()

    func test_initial_state() {
        XCTAssertEqual(PersistenceStateMachineTests.stateMachine.currentState, .created)
    }

    func test_synced_state() {
        PersistenceStateMachineTests.stateMachine.process(event: .onLoad)
        XCTAssertEqual(PersistenceStateMachineTests.stateMachine.currentState, .synced)
    }

    func test_modified_state() {
        PersistenceStateMachineTests.stateMachine.process(event: .onLoad)
        PersistenceStateMachineTests.stateMachine.process(event: .onModify)
        XCTAssertEqual(PersistenceStateMachineTests.stateMachine.currentState, .modified)
    }

    func test_saves_state() {
        PersistenceStateMachineTests.stateMachine.process(event: .onLoad)
        PersistenceStateMachineTests.stateMachine.process(event: .onModify)
        PersistenceStateMachineTests.stateMachine.process(event: .onSave)
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
        PersistableTests.persistable.persistenceSM.process(event: .onLoad)
        XCTAssertEqual(PersistableTests.persistable.persistenceState, .synced)
    }

    func test_initial_modified() {
        PersistableTests.persistable.persistenceSM.process(event: .onLoad)
        PersistableTests.persistable.persistenceSM.process(event: .onModify)
        XCTAssertTrue(PersistableTests.persistable.isModified)
    }

}
