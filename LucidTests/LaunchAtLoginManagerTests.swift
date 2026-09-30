//
//  LaunchAtLoginManagerTests.swift
//  LucidTests
//

import Testing
@testable import Lucid

private final class MockLaunchAtLoginService: LaunchAtLoginService {
    var isEnabled = false
    var registerCallCount = 0
    var unregisterCallCount = 0
    var shouldThrowOnRegister = false
    var shouldThrowOnUnregister = false

    func register() throws {
        registerCallCount += 1
        if shouldThrowOnRegister { throw TestError.failed }
        isEnabled = true
    }

    func unregister() throws {
        unregisterCallCount += 1
        if shouldThrowOnUnregister { throw TestError.failed }
        isEnabled = false
    }
}

private enum TestError: Error {
    case failed
}

struct LaunchAtLoginManagerTests {
    @Test func startsWithServiceCurrentState() {
        let mock = MockLaunchAtLoginService()
        mock.isEnabled = true
        let sut = LaunchAtLoginManager(service: mock)

        #expect(sut.isEnabled == true)
    }

    @Test func toggleFromDisabledRegisters() {
        let mock = MockLaunchAtLoginService()
        let sut = LaunchAtLoginManager(service: mock)

        sut.toggle()

        #expect(sut.isEnabled == true)
        #expect(mock.registerCallCount == 1)
    }

    @Test func toggleFromEnabledUnregisters() {
        let mock = MockLaunchAtLoginService()
        mock.isEnabled = true
        let sut = LaunchAtLoginManager(service: mock)

        sut.toggle()

        #expect(sut.isEnabled == false)
        #expect(mock.unregisterCallCount == 1)
    }

    @Test func toggleFailureKeepsPreviousState() {
        let mock = MockLaunchAtLoginService()
        mock.shouldThrowOnRegister = true
        let sut = LaunchAtLoginManager(service: mock)

        sut.toggle()

        #expect(sut.isEnabled == false)
    }
}
