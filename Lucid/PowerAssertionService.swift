//
//  PowerAssertionService.swift
//  Lucid
//

import IOKit.pwr_mgt

protocol PowerAssertionService {
    func createAssertion(reason: String) -> IOPMAssertionID?
    func releaseAssertion(_ id: IOPMAssertionID)
}

struct IOKitPowerAssertionService: PowerAssertionService {
    func createAssertion(reason: String) -> IOPMAssertionID? {
        var assertionID: IOPMAssertionID = 0
        let result = IOPMAssertionCreateWithName(
            kIOPMAssertionTypeNoIdleSleep as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            reason as CFString,
            &assertionID
        )
        return result == kIOReturnSuccess ? assertionID : nil
    }

    func releaseAssertion(_ id: IOPMAssertionID) {
        IOPMAssertionRelease(id)
    }
}
