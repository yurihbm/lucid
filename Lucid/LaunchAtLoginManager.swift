//
//  LaunchAtLoginManager.swift
//  Lucid
//

import Observation

@Observable
final class LaunchAtLoginManager {
    private(set) var isEnabled: Bool

    private let service: LaunchAtLoginService

    init(service: LaunchAtLoginService = SMAppServiceLaunchAtLoginService()) {
        self.service = service
        self.isEnabled = service.isEnabled
    }

    func toggle() {
        do {
            if isEnabled {
                try service.unregister()
            } else {
                try service.register()
            }
            isEnabled = service.isEnabled
        } catch {
            isEnabled = service.isEnabled
        }
    }
}
