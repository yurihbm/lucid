//
//  StateManager.swift
//  Lucid
//

import IOKit.pwr_mgt
import Observation

@Observable
final class StateManager {
    private(set) var isActive = false

    private let assertionService: PowerAssertionService
    private var assertionID: IOPMAssertionID?
    private let assertionReason: String

    init(
        assertionService: PowerAssertionService = IOKitPowerAssertionService(),
        assertionReason: String = "Lucid is preventing idle sleep"
    ) {
        self.assertionService = assertionService
        self.assertionReason = assertionReason
    }

    func activate() {
        guard !isActive else { return }
        guard let id = assertionService.createAssertion(reason: assertionReason) else { return }
        assertionID = id
        isActive = true
    }

    func deactivate() {
        guard isActive, let id = assertionID else { return }
        assertionService.releaseAssertion(id)
        assertionID = nil
        isActive = false
    }

    func toggle() {
        isActive ? deactivate() : activate()
    }
}
