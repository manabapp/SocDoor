//
//  SocDoorSharedObject.swift
//  SocDoor
//
//  Created by Hirose Manabu on 2021/02/12.
//

import SwiftUI

class SocDoorSharedObject: ObservableObject {
    static var isJa: Bool { return Locale.preferredLanguages.first!.hasPrefix("ja") }
    
    //==========================================
    // Access Log
    //==========================================
    @Published var logBuffer: String = ""
    var dateFormatter = DateFormatter()
    func resetAccessLog() {
        self.logBuffer = ""
    }
    func getAddress(_ address: SocAddress?) -> String {
        return address != nil ? address!.addr + ":" + String(address!.port) : "n/a"
    }
    func allowAccessLog(source: SocAddress?, local: SocAddress?) {
        self.logBuffer += dateFormatter.string(from: Date())
        self.logBuffer += " [A] \(self.getAddress(source)) (\(self.getAddress(local)))\n"
    }
    func denyAccessLog(source: SocAddress?) {
        self.logBuffer += dateFormatter.string(from: Date())
        self.logBuffer += " [D] \(self.getAddress(source))\n"
    }
    func failedAccessLog(source: SocAddress?, error: SocError?) {
        self.logBuffer += dateFormatter.string(from: Date())
        self.logBuffer += " [E] \(self.getAddress(source))"
        if let e = error {
            self.logBuffer += " errno=\(e.code)[\(ERRNO_NAMES[Int(e.code)])]"
        }
        self.logBuffer += "\n"
    }
    
    //==========================================
    // App's parameters
    //==========================================
    @Published var appVersion: String = ""
    @Published var orientation: UIInterfaceOrientation = .unknown
    @Published var cellurar = SocDoorInterface(deviceType: SocDoorInterface.deviceTypeCellurar)
    @Published var hotspot = SocDoorInterface(deviceType: SocDoorInterface.deviceTypeHotspot)
    @Published var deviceWidth: CGFloat = 0.0
    @Published var isAlerting: Bool = false
    @Published var alertMessage: String = ""
    @Published var alertDetail: String = ""
    @Published var isPopAlert: Bool = false
    @Published var isProcessing: Bool = false
    
    //==========================================
    // App's loading parameters are follows.
    //==========================================
    @Published var filters: [SocDoorFilter] = []
    @Published var isAgree: Bool = false
    @Published var agreementDate: Date? = nil
    @Published var appSettingDescription: Bool = true {
        didSet {
            UserDefaults.standard.set(appSettingDescription, forKey: "appSettingDescription")
            SocLogger.debug("SocDoorSharedObject: appSettingDescription = \(appSettingDescription)")
        }
    }
    @Published var appSettingIdleTimerDisabled: Bool = false {
        didSet {
            UserDefaults.standard.set(appSettingIdleTimerDisabled, forKey: "appSettingIdleTimerDisabled")
            UIApplication.shared.isIdleTimerDisabled = appSettingIdleTimerDisabled
            SocLogger.debug("SocDoorSharedObject: appSettingIdleTimerDisabled = \(appSettingIdleTimerDisabled)")
            SocLogger.debug("SocDoorSharedObject: UIApplication.shared.isIdleTimerDisabled = \(appSettingIdleTimerDisabled)")
        }
    }
    @Published var appSettingScreenColorInverted: Bool = false {
        didSet {
            UserDefaults.standard.set(appSettingScreenColorInverted, forKey: "appSettingScreenColorInverted")
            SocLogger.debug("SocDoorSharedObject: appSettingScreenColorInverted = \(appSettingScreenColorInverted)")
        }
    }
    @Published var appSettingTraceLevel: Int = SocLogger.traceLevelNoData {
        didSet {
            UserDefaults.standard.set(appSettingTraceLevel, forKey: "appSettingTraceLevel")
            SocLogger.debug("SocDoorSharedObject: appSettingTraceLevel = \(appSettingTraceLevel)")
            SocLogger.setTraceLevel(appSettingTraceLevel)
        }
    }
    @Published var appSettingDebugEnabled: Bool = false {
        didSet {
            UserDefaults.standard.set(appSettingDebugEnabled, forKey: "appSettingDebugEnabled")
            SocLogger.debug("SocDoorSharedObject: appSettingDebugEnabled = \(appSettingDebugEnabled)")
            if appSettingDebugEnabled {
                SocLogger.enableDebug()
            }
            else {
                SocLogger.disableDebug()
            }
        }
    }
    @Published var doorSettingFrontPort: Int = 80 {
        didSet {
            UserDefaults.standard.set(doorSettingFrontPort, forKey: "doorSettingFrontPort")
            SocLogger.debug("SocDoorSharedObject: doorSettingFrontPort = \(doorSettingFrontPort)")
        }
    }
    @Published var doorSettingBackPort: Int = 80 {
        didSet {
            UserDefaults.standard.set(doorSettingBackPort, forKey: "doorSettingBackPort")
            SocLogger.debug("SocDoorSharedObject: doorSettingBackPort = \(doorSettingBackPort)")
        }
    }
    
    func getAgreementDate() -> String {
        let value = UserDefaults.standard.object(forKey: "agreementDate")
        guard let date = value as? Date else {
            return "N/A"
        }
        let dateFormatter = DateFormatter()
        dateFormatter.calendar = Calendar(identifier: .gregorian)
        dateFormatter.locale = Locale(identifier: "C")
        dateFormatter.timeZone = .current
        dateFormatter.dateFormat = "YYYY/MM/dd HH:mm:ss"
        return dateFormatter.string(from: date)
    }
    
    static func saveFilters(doorFilters: [SocDoorFilter]) {
        var stringsArray: [String] = []
        
        for i in 1 ..< doorFilters.count {  //skip defaultFilter (0.0.0.0/0)
            if !doorFilters[i].isDeleted {
                stringsArray.append(doorFilters[i].cidr)
            }
        }
        if stringsArray.count > 0 {
            SocLogger.debug("SocDoorSharedObject.saveFilters: \(stringsArray.count) filters")
            UserDefaults.standard.set(stringsArray, forKey: "filters")
            SocLogger.debug("SocDoorSharedObject.saveFilters: done")
        }
        else {
            SocLogger.debug("SocDoorSharedObject.saveFilters: removeObject")
            UserDefaults.standard.removeObject(forKey: "filters")
        }
    }
    
    init() {
        isAgree = UserDefaults.standard.bool(forKey: "isAgree")
        if UserDefaults.standard.object(forKey: "appSettingDescription") != nil {  //Default is true
            appSettingDescription = UserDefaults.standard.bool(forKey: "appSettingDescription")
        }
        appSettingIdleTimerDisabled = UserDefaults.standard.bool(forKey: "appSettingIdleTimerDisabled")
        appSettingScreenColorInverted = UserDefaults.standard.bool(forKey: "appSettingScreenColorInverted")
        appSettingTraceLevel = UserDefaults.standard.integer(forKey: "appSettingTraceLevel")
        appSettingDebugEnabled = UserDefaults.standard.bool(forKey: "appSettingDebugEnabled")
        if UserDefaults.standard.object(forKey: "doorSettingFrontPort") != nil {  //Default is not 0
            doorSettingFrontPort = UserDefaults.standard.integer(forKey: "doorSettingFrontPort")
        }
        if UserDefaults.standard.object(forKey: "doorSettingBackPort") != nil {  //Default is not 0
            doorSettingBackPort = UserDefaults.standard.integer(forKey: "doorSettingBackPort")
        }

        SocSocket.initSoc()
        SocLogger.setTraceLevel(appSettingTraceLevel)
        if appSettingDebugEnabled {
            SocLogger.enableDebug()
        }
        if let string = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as? String {
            appVersion = string
        }
        SocLogger.debug("App Version = \(appVersion)")
        SocLogger.debug("Agreed the Terms of Service: \(self.getAgreementDate())")
        
        dateFormatter.calendar = Calendar(identifier: .gregorian)
        dateFormatter.locale = Locale(identifier: "C")
        dateFormatter.timeZone = .current
        dateFormatter.dateFormat = "MMM dd HH:mm:ss"
        self.cellurar.ifconfig()
        self.hotspot.ifconfig()
        let width = CGFloat(UIScreen.main.bounds.width)
        let height = CGFloat(UIScreen.main.bounds.height)
        deviceWidth = width < height ? width : height
        SocDoorScreen.initSize(width: deviceWidth)
        
        SocLogger.debug("Load App Setting:")
        SocLogger.debug("appSettingDescription = \(appSettingDescription)")
        SocLogger.debug("appSettingIdleTimerDisabled = \(appSettingIdleTimerDisabled)")
        SocLogger.debug("appSettingScreenColorInverted = \(appSettingScreenColorInverted)")
        SocLogger.debug("appSettingTraceLevel = \(appSettingTraceLevel)")
        SocLogger.debug("appSettingDebugEnabled = \(appSettingDebugEnabled)")
        SocLogger.debug("doorSettingFrontPort = \(doorSettingFrontPort)")
        SocLogger.debug("doorSettingBackPort = \(doorSettingBackPort)")
        SocLogger.debug("Load Filter:")
        var defaultFilter = SocDoorFilter(cidr: "0.0.0.0/0")
        defaultFilter.isCheck = true
        filters.append(defaultFilter)
        SocLogger.debug("filter - 0.0.0.0/0")
        if UserDefaults.standard.object(forKey: "filters") != nil {
            if let stringsArray: [String] = UserDefaults.standard.stringArray(forKey: "filters") {
                for stringsElement in stringsArray {
                    if stringsElement.isValidCidrFormat {
                        filters.append(SocDoorFilter(cidr: stringsElement))
                        SocLogger.debug("filter - \(stringsElement)")
                    }
                    else {
                        SocLogger.error("Invalid filter - \(stringsElement)")
                        assertionFailure("Invalid filter - \(stringsElement)")
                    }
                }
            }
        }
        SocLogger.debug("Check Device Configuration:")
        SocLogger.debug("Cellurar Address = \(cellurar.inet.addr)")
        SocLogger.debug("Hotspot Address = \(hotspot.inet.addr)")
        SocLogger.debug("Appearance = \(UITraitCollection.current.userInterfaceStyle == .dark ? "Dark mode" : "Light mode")")
        SocLogger.debug("TimeZone = \(TimeZone.current)")
        SocLogger.debug("Languages = \(Locale.preferredLanguages)")
        SocLogger.debug("Screen Size = \(width) * \(height)")
        SocLogger.debug("SocDoorSharedObject.init: all done")
    }
}
