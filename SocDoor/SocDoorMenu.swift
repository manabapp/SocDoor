//
//  SocDoorMenu.swift
//  SocDoor
//
//  Created by Hirose Manabu on 2021/02/12.
//

import SwiftUI

let MAIL_ADDRESS = "manabapp@gmail.com"
let COPYRIGHT = "Copyright © 2021 manabapp. All rights reserved."
let URL_BASE = "https://manabapp.github.io/"
let URL_WEBPAGE = URL_BASE + "Apps/index.html"
let URL_WEBPAGE_JA = URL_BASE + "Apps/index_ja.html"
let URL_POLICY = URL_BASE + "SocDoor/PrivacyPolicy.html"
let URL_POLICY_JA = URL_BASE + "SocDoor/PrivacyPolicy_ja.html"
let URL_TERMS = URL_BASE + "SocDoor/TermsOfService.html"
let URL_TERMS_JA = URL_BASE + "SocDoor/TermsOfService_ja.html"

struct SocDoorMenu: View {
    @EnvironmentObject var object: SocDoorSharedObject
    @State private var logText: String = ""
    
    var body: some View {
        List {
            Section(header: Text("Header_PREFERENCES")) {
                NavigationLink(destination: AppSetting()) {
                    CommonRaw(name:"App Settings", image:"wrench", detail:"Description_App_Settings")
                }
            }
            Section(header: Text("Header_LOG")) {
                ZStack {
                    NavigationLink(destination: SocDoorTraceLogViewer(text: $logText)) {
                        EmptyView()
                    }
                    Button(action: {
                        SocLogger.debug("SocDoorMenu: Button: Trace Log")
                        self.logText = SocLogger.getLog()
                    }) {
                        CommonRaw(name:"Trace Log", image:"note.text", detail:"Description_Trace_Log")
                    }
                }
                NavigationLink(destination: SocDoorAccessLogViewer()) {
                    CommonRaw(name:"Access Log", image:"note.text", detail:"Description_Access_Log")
                }
            }
            Section(header: Text("Header_INFORMATION")) {
                NavigationLink(destination: AboutApp()) {
                    CommonRaw(name:"About App", image:"info.circle", detail:"Description_About_App")
                }
                Button(action: {
                    SocLogger.debug("SocDoorMenu: Button: Policy")
                    self.openURL(urlString: SocDoorSharedObject.isJa ? URL_POLICY_JA : URL_POLICY)
                }) {
                    CommonRaw(name:"Privacy Policy", image:"hand.raised.fill", detail:"Description_Privacy_Policy")
                }
                Button(action: {
                    SocLogger.debug("SocDoorMenu: Button: Terms")
                    self.openURL(urlString: SocDoorSharedObject.isJa ? URL_TERMS_JA : URL_TERMS)
                }) {
                    CommonRaw(name:"Terms of Service", image:"doc.plaintext", detail:"Description_Terms_of_Service")
                }
            }
        }
        .listStyle(PlainListStyle())
        .navigationBarTitle("Menu", displayMode: .inline)
    }
    
    func openURL(urlString: String) {
        do {
            guard let url = URL(string: urlString) else {
                throw SocDoorError.CantOpenURL
            }
            guard UIApplication.shared.canOpenURL(url) else {
                throw SocDoorError.CantOpenURL
            }
            UIApplication.shared.open(url)
        }
        catch let error as SocDoorError {
            self.object.alertMessage = error.message
            self.object.alertDetail = error.detail
            self.object.isPopAlert = true
        }
        catch {
            fatalError("SocDoorMenu.openURL(\(urlString)): \(error)")
        }
    }
}

fileprivate struct CommonRaw: View {
    @EnvironmentObject var object: SocDoorSharedObject
    let name: String
    let image: String
    let detail: LocalizedStringKey
    
    var body: some View {
        HStack {
            Image(systemName: self.image)
                .resizable()
                .scaledToFit()
                .frame(width: 22, height: 22, alignment: .center)
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(self.name)
                        .font(.system(size: 20))
                    Spacer()
                }
                if object.appSettingDescription {
                    HStack {
                        Text(self.detail)
                            .font(.system(size: 12))
                            .foregroundColor(Color.init(UIColor.systemGray))
                        Spacer()
                    }
                }
            }
            .padding(.leading)
        }
    }
}

fileprivate struct AppSetting: View {
    @EnvironmentObject var object: SocDoorSharedObject

    var body: some View {
        List {
            Section(header: Text("DESCRIPTION").font(.system(size: 16, weight: .semibold)),
                    footer: object.appSettingDescription ? Text("Footer_DESCRIPTION").font(.system(size: 12)) : nil) {
                Toggle(isOn: self.$object.appSettingDescription) {
                    Text("Label_Enabled")
                }
            }
            Section(header: Text("IDLE TIMER").font(.system(size: 16, weight: .semibold)),
                    footer: object.appSettingDescription ? Text("Footer_IDLE_TIMER").font(.system(size: 12)) : nil) {
                Toggle(isOn: self.$object.appSettingIdleTimerDisabled) {
                    Text("Label_Disabled")
                }
            }
            Section(header: Text("SCREEN COLOR").font(.system(size: 16, weight: .semibold)),
                    footer: object.appSettingDescription ? Text("Footer_SCREEN_COLOR").font(.system(size: 12)) : nil) {
                Toggle(isOn: self.$object.appSettingScreenColorInverted) {
                    Text("Label_Inverted")
                }
            }
            Section(header: Text("SYSTEM CALL TRACE").font(.system(size: 16, weight: .semibold)),
                    footer: object.appSettingDescription ? Text("Footer_SYSTEM_CALL_TRACE").font(.system(size: 12)) : nil) {
                Picker("", selection: self.$object.appSettingTraceLevel) {
                    Text("Label_TRACE_Level1").tag(SocLogger.traceLevelNoData)
                    Text("Label_TRACE_Level2").tag(SocLogger.traceLevelInLine)
                    Text("Label_TRACE_Level3").tag(SocLogger.traceLevelHexDump)
                }
                .pickerStyle(SegmentedPickerStyle())
            }
#if DEBUG
            Section(header: Text("DEBUG").font(.system(size: 16, weight: .semibold)),
                    footer: object.appSettingDescription ? Text("Footer_DEBUG").font(.system(size: 12)) : nil) {
                Toggle(isOn: self.$object.appSettingDebugEnabled) {
                    Text("Label_Enabled")
                }
            }
#endif
        }
        .listStyle(GroupedListStyle())
        .navigationBarTitle("App Setting", displayMode: .inline)
    }
}

fileprivate struct SocDoorTraceLogViewer: View {
    @EnvironmentObject var object: SocDoorSharedObject
    @Binding var text: String
    @State private var isEditable: Bool = false
    @State private var isDecodable: Bool = true
    
    var body: some View {
        VStack(spacing: 0) {
            SocDoorScreen(text: self.$text)
            if object.orientation.isPortrait {
                HStack(spacing: 0) {
                    Form {
                        Button(action: {
                            SocLogger.debug("SocDoorTraceLogViewer: Button: Reload")
                            self.text = SocLogger.getLog()
                        }) {
                            HStack {
                                Spacer()
                                Image(systemName: "arrow.clockwise")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 19, height: 19, alignment: .center)
                                Text("Button_Reload2")
                                    .padding(.leading, 5)
                                Spacer()
                            }
                        }
                    }
                    Form {
                        Button(action: {
                            SocLogger.debug("SocDoorTraceLogViewer: Button: Copy")
                            self.text = SocLogger.getLog()
                            UIPasteboard.general.string = self.text
                            object.alertMessage = NSLocalizedString("Message_Copied_to_clipboard", comment: "")
                            object.isAlerting = true
                            DispatchQueue.global().async {
                                sleep(1)
                                DispatchQueue.main.async {
                                    object.isAlerting = false
                                }
                            }
                        }) {
                            HStack {
                                Spacer()
                                Image(systemName: "doc.on.doc")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 19, height: 19, alignment: .center)
                                Text("Button_Copy2")
                                    .padding(.leading, 5)
                                Spacer()
                            }
                        }
                    }
                    Form {
                        Button(action: {
                            SocLogger.debug("SocDoorTraceLogViewer: Button: Clear")
                            SocLogger.clearLog()
                            self.text = SocLogger.getLog()
                        }) {
                            HStack {
                                Spacer()
                                Image(systemName: "trash")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 19, height: 19, alignment: .center)
                                Text("Button_Clear2")
                                    .padding(.leading, 5)
                                Spacer()
                            }
                        }
                    }
                }
                .frame(height: 110)
            }
        }
        .navigationBarTitle(Text("Trace Log"), displayMode: .inline)
    }
}

fileprivate struct SocDoorAccessLogViewer: View {
    @EnvironmentObject var object: SocDoorSharedObject
    @State private var isEditable: Bool = false
    @State private var isDecodable: Bool = true
    
    var body: some View {
        VStack(spacing: 0) {
            SocDoorScreen(text: self.$object.logBuffer)
            if object.orientation.isPortrait {
                HStack(spacing: 0) {
                    Form {
                        Button(action: {
                            SocLogger.debug("SocDoorAccessLogViewer: Button: Copy")
                            UIPasteboard.general.string = self.object.logBuffer
                            object.alertMessage = NSLocalizedString("Message_Copied_to_clipboard", comment: "")
                            object.isAlerting = true
                            DispatchQueue.global().async {
                                sleep(1)
                                DispatchQueue.main.async {
                                    object.isAlerting = false
                                }
                            }
                        }) {
                            HStack {
                                Spacer()
                                Image(systemName: "doc.on.doc")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 19, height: 19, alignment: .center)
                                Text("Button_Copy2")
                                    .padding(.leading, 5)
                                Spacer()
                            }
                        }
                    }
                    Form {
                        Button(action: {
                            SocLogger.debug("SocDoorAccessLogViewer: Button: Clear")
                            self.object.resetAccessLog()
                        }) {
                            HStack {
                                Spacer()
                                Image(systemName: "trash")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 19, height: 19, alignment: .center)
                                Text("Button_Clear2")
                                    .padding(.leading, 5)
                                Spacer()
                            }
                        }
                    }
                }
                .frame(height: 110)
            }
        }
        .navigationBarTitle(Text("Access Log"), displayMode: .inline)
    }
}


fileprivate struct AboutApp: View {
    @EnvironmentObject var object: SocDoorSharedObject
    
    var body: some View {
        VStack {
            Group {
                Image("SplashImage")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, alignment: .center)
                Text("SocDoor")
                    .font(.system(size: 26, weight: .bold))
                Text("BETA")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color.init(UIColor.systemGray))
                Text("version " + object.appVersion)
                    .font(.system(size: 16))
                    .padding(.bottom, 5)
                Text("This app is personal back door into your Local Network.")
                    .font(.system(size: 11))
            }
            Button(action: {
                SocLogger.debug("AboutApp: Button: webpage")
                self.openURL(urlString: SocDoorSharedObject.isJa ? URL_WEBPAGE_JA : URL_WEBPAGE)
            }) {
                HStack {
                    Spacer()
                    Image(systemName: "safari")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 14, height: 14)
                    Text("Developer Website")
                        .font(.system(size: 11))
                    Spacer()
                }
                .padding(.bottom, 5)
            }
            
            Text("Support OS: iOS 14.1 or newer")
                .font(.system(size: 11))
            Text("Localization: en, ja")
                .font(.system(size: 11))
                .padding(.bottom, 20)
            
            Text("Please feel free to contact me if you have any feedback.")
                .font(.system(size: 11))
            Button(action: {
                SocLogger.debug("AboutApp: Button: mailto")
                let url = URL(string: "mailto:" + MAIL_ADDRESS)!
                UIApplication.shared.open(url)
            }) {
                Text(MAIL_ADDRESS)
                    .font(.system(size: 12))
                    .padding(5)
            }
            
            Text(COPYRIGHT)
                .font(.system(size: 11))
                .foregroundColor(Color.init(UIColor.systemGray))
        }
        .navigationBarTitle("About App", displayMode: .inline)
    }
    
    private func openURL(urlString: String) {
        do {
            guard let url = URL(string: urlString) else {
                throw SocDoorError.CantOpenURL
            }
            guard UIApplication.shared.canOpenURL(url) else {
                throw SocDoorError.CantOpenURL
            }
            UIApplication.shared.open(url)
        }
        catch let error as SocDoorError {
            self.object.alertMessage = error.message
            self.object.alertDetail = error.detail
            self.object.isPopAlert = true
        }
        catch {
            fatalError("AboutApp.openURL(\(urlString)): \(error)")
        }
    }
}
