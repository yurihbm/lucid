//
//  StateManagerTests.swift
//  LucidTests
//

import IOKit.pwr_mgt
import Testing
@testable import Lucid

private final class MockPowerAssertionService: PowerAssertionService {
    var createCallCount = 0
    var releaseCallCount = 0
    var lastReason: String?
    var lastReleasedID: IOPMAssertionID?
    var idToReturn: IOPMAssertionID? = 42

    func createAssertion(reason: String) -> IOPMAssertionID? {
        createCallCount += 1
        lastReason = reason
        return idToReturn
    }

    func releaseAssertion(_ id: IOPMAssertionID) {
        releaseCallCount += 1
        lastReleasedID = id
    }
}

struct StateManagerTests {
    @Test func startsInactive() {
        let sut = StateManager(assertionService: MockPowerAssertionService())
        #expect(sut.isActive == false)
    }

    @Test func activateCreatesAssertionAndSetsActive() {
        let mock = MockPowerAssertionService()
        let sut = StateManager(assertionService: mock)

        sut.activate()

        #expect(sut.isActive == true)
        #expect(mock.createCallCount == 1)
    }

    @Test func activateWhenAlreadyActiveDoesNotCreateAnotherAssertion() {
        let mock = MockPowerAssertionService()
        let sut = StateManager(assertionService: mock)

        sut.activate()
        sut.activate()

        #expect(mock.createCallCount == 1)
    }

    @Test func deactivateReleasesAssertionAndSetsInactive() {
        let mock = MockPowerAssertionService()
        mock.idToReturn = 7
        let sut = StateManager(assertionService: mock)
        sut.activate()

        sut.deactivate()

        #expect(sut.isActive == false)
        #expect(mock.releaseCallCount == 1)
        #expect(mock.lastReleasedID == 7)
    }

    @Test func deactivateWhenInactiveDoesNothing() {
        let mock = MockPowerAssertionService()
        let sut = StateManager(assertionService: mock)

        sut.deactivate()

        #expect(mock.releaseCallCount == 0)
    }

    @Test func toggleFlipsState() {
        let mock = MockPowerAssertionService()
        let sut = StateManager(assertionService: mock)

        sut.toggle()
        #expect(sut.isActive == true)

        sut.toggle()
        #expect(sut.isActive == false)
    }

    @Test func activateFailureKeepsStateInactive() {
        let mock = MockPowerAssertionService()
        mock.idToReturn = nil
        let sut = StateManager(assertionService: mock)

        sut.activate()

        #expect(sut.isActive == false)
    }
}
