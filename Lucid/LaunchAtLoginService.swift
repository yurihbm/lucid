//
//  LaunchAtLoginService.swift
//  Lucid
//

import ServiceManagement

protocol LaunchAtLoginService {
    var isEnabled: Bool { get }
    func register() throws
    func unregister() throws
}

struct SMAppServiceLaunchAtLoginService: LaunchAtLoginService {
    var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    func register() throws {
        try SMAppService.mainApp.register()
    }

    func unregister() throws {
        try SMAppService.mainApp.unregister()
    }
}
