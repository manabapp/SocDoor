//
//  SocDoorConfiguration.swift
//  SocDoor
//
//  Created by Hirose Manabu on 2021/02/12.
//

import SwiftUI

struct SocDoorConfiguration: View {
    @EnvironmentObject var object: SocDoorSharedObject
    @State var frontAddress = SocAddress(family: AF_INET, addr: "")
    @State var backAddress = SocAddress(family: AF_INET, addr: "")
    @State private var protocolIndex: Int = 0
    @State private var stringFrontAddr: String = ""
    @State private var stringFrontPort: String = ""
    @State private var stringBackAddr: String = ""
    @State private var stringBackPort: String = ""
    
    static let protocolTCP: Int = 0
    static let protocolHTTP: Int = 1
    static let protocolHTTPS: Int = 2
    
    init(frontAddr: String, frontPort: Int, backPort: Int) {
        _stringFrontAddr = State(initialValue: frontAddr)
        _stringFrontPort = State(initialValue: String(frontPort))
        _stringBackPort = State(initialValue: String(backPort))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            List {
                Section(header: Text("Header_PROTOCOL").font(.system(size: 16, weight: .semibold)),
                        footer: object.appSettingDescription ? Text("Footer_PROTOCOL").font(.system(size: 12)) : nil) {
                    Picker("", selection: self.$protocolIndex) {
                        Text("TCP-TCP").tag(Self.protocolTCP)
                        Text("HTTP-HTTP").tag(Self.protocolHTTP)
                        Text("HTTPS-HTTPS").tag(Self.protocolHTTPS)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                Section(header:
                            HStack(alignment: .bottom) {
                                Image(systemName: "signpost.left.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 22, height: 22)
                                Text("Header_FRONT-END")
                                    .font(.system(size: 16, weight: .semibold))
                                    .frame(alignment: .bottom)
                            },
                        footer: object.appSettingDescription ? Text("Footer_FRONT-END").font(.system(size: 12)) : nil) {
                    HStack {
                        Text("Label_IP_address")
                            .frame(width: 110, alignment: .leading)
                        Text(stringFrontAddr.isEmpty ? "N/A" : stringFrontAddr)
                            .foregroundColor(Color.init(stringFrontAddr.isEmpty ? UIColor.systemGray: UIColor.label))
                        Spacer()
                        Button(action: {
                            stringFrontAddr = ""
                            self.object.cellurar.ifconfig()
                            if self.object.cellurar.isActive {
                                stringFrontAddr = self.object.cellurar.inet.addr
                            }
                            else {
                                self.object.alertMessage = NSLocalizedString("Message_Cellurar_is_disabled", comment: "")
                                self.object.alertDetail = ""
                                self.object.isPopAlert = true
                            }
                        }) {
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(Color.init(UIColor.systemBlue))
                        }
                    }
                    HStack {
                        Text("Label_Port_number")
                            .frame(width: 110, alignment: .leading)
                        switch protocolIndex {
                        case Self.protocolTCP:
                            TextField("80", text: $stringFrontPort)
                                .keyboardType(.numberPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .frame(maxWidth: .infinity)
                        case Self.protocolHTTP:
                            Text("80")
                        default:
                            Text("443")
                        }
                    }
                    .gesture (
                        TapGesture().onEnded { _ in
                            UIApplication.shared.closeKeyboard()
                        }
                    )
                    NavigationLink(destination: SocDoorFilterManager()) {
                        HStack {
                            Text("Label_Allow_address")
                                .frame(width: 110, alignment: .leading)
                            VStack(alignment: .leading, spacing: 1) {
                                if object.hasActiveFilter {
                                    ForEach(0 ..< object.filters.count, id: \.self) { i in
                                        if !object.filters[i].isDeleted && object.filters[i].isCheck {
                                            Text(object.filters[i].cidr)
                                        }
                                    }
                                }
                                else {
                                    Text("N/A")
                                        .foregroundColor(Color.init(UIColor.systemGray))
                                }
                            }
                            .frame(alignment: .leading)
                            Spacer()
                        }
                    }
                    if protocolIndex == Self.protocolHTTPS {
                        NavigationLink(destination: EmptyView()) {
                            HStack {
                                Text("Label_Certificate")
                                    .frame(width: 110, alignment: .leading)
                                VStack(alignment: .leading, spacing: 1) {
                                    Text("N/A")
                                }
                                .frame(alignment: .leading)
                                Spacer()
                            }
                        }
                        .disabled(true)
                    }
                }
                Section(header:
                            HStack(alignment: .bottom) {
                                Text("Header_BACK-END")
                                    .font(.system(size: 16, weight: .semibold))
                                    .frame(alignment: .bottom)
                                Image(systemName: "signpost.right.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 22, height: 22)
                            },
                        footer: object.appSettingDescription ? Text("Footer_BACK-END").font(.system(size: 12)) : nil) {
                    HStack {
                        Text("Label_IP_address")
                            .frame(width: 110, alignment: .leading)
                        TextField("", text: $stringBackAddr)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(maxWidth: .infinity)
                        Button(action: {
                            stringBackAddr = ""
                            self.object.hotspot.ifconfig()
                            guard self.object.hotspot.isActive, self.object.hotspot.hasBroadcast else {
                                self.object.alertMessage = NSLocalizedString("Message_No_backend_hosts_found", comment: "")
                                self.object.alertDetail = ""
                                self.object.isPopAlert = true
                                return
                            }
                            self.object.isProcessing = true
                            DispatchQueue.global().async {
                                do {
                                    if let address = try self.lookup() {
                                        stringBackAddr = address.addr
                                    }
                                    DispatchQueue.main.async {
                                        self.object.isProcessing = false
                                    }
                                }
                                catch let error as SocError {
                                    DispatchQueue.main.async {
                                        self.object.isProcessing = false
                                        self.object.alertMessage = error.message
                                        self.object.alertDetail = error.detail
                                        self.object.isPopAlert = true
                                    }
                                }
                                catch {
                                    fatalError("SocDoorServer: \(error)")
                                }
                            }
                        }) {
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(Color.init(UIColor.systemBlue))
                        }
                    }
                    HStack {
                        Text("Label_Port_number")
                            .frame(width: 110, alignment: .leading)
                        switch protocolIndex {
                        case Self.protocolTCP:
                            TextField("80", text: $stringBackPort)
                                .keyboardType(.numberPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .frame(maxWidth: .infinity)
                        case Self.protocolHTTP:
                            Text("80")
                        default:
                            Text("443")
                        }
                    }
                    .gesture (
                        TapGesture().onEnded { _ in
                            UIApplication.shared.closeKeyboard()
                        }
                    )
                }
            }
            .listStyle(GroupedListStyle())
            
            Form {
                Section(footer:
                            HStack {
                                Spacer();
                                Text(self.errorMessage)
                                    .foregroundColor(Color.init(isParamsValid ? UIColor.systemGreen : UIColor.systemRed));
                                Spacer()
                            }
                ) {
                    ZStack {
                        NavigationLink(destination: SocDoorTcpServer(frontAddress: self.$frontAddress, backAddress: self.$backAddress)) {
                            EmptyView()
                        }
                        Button(action: {
                            frontAddress.addr = self.stringFrontAddr
                            frontAddress.port = UInt16(self.stringFrontPort)!
                            object.doorSettingFrontPort = Int(frontAddress.port)
                            
                            backAddress.addr = self.stringBackAddr
                            backAddress.port = UInt16(self.stringBackPort)!
                            object.doorSettingBackPort = Int(backAddress.port)
                        }) {
                            HStack {
                                Spacer()
                                VStack {
                                    Text("Open")
                                        .foregroundColor(Color.init(self.isParamsValid ? UIColor.label : UIColor.systemGray))
                                    if object.appSettingDescription {
                                        Text("Description_Open")
                                            .font(.system(size: 12))
                                            .foregroundColor(Color.init(UIColor.systemGray))
                                    }
                                }
                                Spacer()
                            }
                        }
                    }
                    .disabled(!self.isParamsValid)
                }
            }
            .frame(height: 120)
        }
        .navigationBarTitle("Door", displayMode: .inline)
    }
    
    private func lookup() throws -> SocAddress? {
        let socket = try SocSocket(family: AF_INET, type: SOCK_DGRAM, proto: IPPROTO_ICMP)
        try socket.setsockopt(level: SOL_SOCKET, option: SO_BROADCAST, value: SocOptval(bool: true))
        try socket.setsockopt(level: IPPROTO_IP, option: IP_BOUND_IF, value: SocOptval(int: self.object.hotspot.index))
        
        var echo = icmp(type: UInt8(ICMP_ECHO), code: 0)
        echo.icmp_id = UInt16(getpid() & 0xFFFF)
        echo.icmp_seq = UInt16(0)
        var sum = UInt64(UInt16(echo.icmp_type) + UInt16(echo.icmp_code) >> 1) + UInt64(echo.icmp_id) + UInt64(echo.icmp_seq)
        while sum >> 16 != 0 {
            sum = (sum & 0xffff) + (sum >> 16)
        }
        echo.icmp_cksum = ~UInt16(sum)
        let data = Data(bytes: &echo, count: ICMP_HDRLEN)
        _ = try socket.sendto(data: data, flags: 0, address: self.object.hotspot.broadcast)
        
        var buffer = Data([UInt8](repeating: 0, count: Int(BUFSIZ)))
        let lastDate = Date()
        while true {
            let elapsedMsec = Int32(Date().timeIntervalSince(lastDate) * 1000.0)
            if elapsedMsec > 2000 {
                break
            }
            let revents = try socket.poll(events: POLLIN, timeout: 2000 - elapsedMsec)
            if revents == 0 {  // Poll: Timeout
                break
            }
            if revents & POLLIN == 0 { // should be POLLERR, POLLHUP, POLLNVAL. we unexpect POLLPRI or POLLOUT
                break
            }
            let (received, from) = try socket.recvfrom(data: &buffer, flags: 0, needAddress: true)
            if received == 0 {
                continue
            }
            let ipVhl = Data(buffer[0 ..< 1]).withUnsafeBytes { $0.load(as: UInt8.self) }
            let ipHdrLen = Int((ipVhl & 0xF) << 2)
            if received < ipHdrLen + ICMP_HDRLEN {
                continue
            }
            let icmpHdr = Data(buffer[ipHdrLen ..< ipHdrLen + ICMP_HDRLEN]).withUnsafeBytes { $0.load(as: icmp.self) }
            if icmpHdr.icmp_type != ICMP_ECHOREPLY || icmpHdr.icmp_id != echo.icmp_id {
                continue
            }
            if let address = from {
                if address.addr != self.object.hotspot.inet.addr {
                    return address
                }
            }
        }
        return nil
    }
    
    private var errorMessage: String {
        guard protocolIndex == Self.protocolTCP else {
            return NSLocalizedString("Message_NotSupport", comment: "")
        }
        //Front
        guard !stringFrontAddr.isEmpty else {
            return NSLocalizedString("Message_NoValue", comment: "")
        }
        guard stringFrontAddr.isValidIPv4Format else {
            return NSLocalizedString("Message_InvalidIpAddr", comment: "")
        }
        guard stringFrontAddr != "0.0.0.0" else {
            return NSLocalizedString("Message_CantUseIpAddr", comment: "")
        }
        guard !stringFrontPort.isEmpty else {
            return NSLocalizedString("Message_NoValue", comment: "")
        }
        guard (UInt16(stringFrontPort) != nil) else {
            return NSLocalizedString("Message_InvalidPort", comment: "")
        }
        guard object.hasActiveFilter else {
            return NSLocalizedString("Message_NoFilter", comment: "")
        }
        //Back
        guard !stringBackAddr.isEmpty else {
            return NSLocalizedString("Message_NoValue", comment: "")
        }
        guard stringBackAddr.isValidIPv4Format else {
            return NSLocalizedString("Message_InvalidIpAddr", comment: "")
        }
        guard stringBackAddr != "172.20.10.0" && stringBackAddr != "172.20.10.1" && stringBackAddr != "172.20.10.15" else {
            return NSLocalizedString("Message_CantUseIpAddr", comment: "")
        }
        guard !stringBackPort.isEmpty else {
            return NSLocalizedString("Message_NoValue", comment: "")
        }
        guard (UInt16(stringBackPort) != nil) else {
            return NSLocalizedString("Message_InvalidPort", comment: "")
        }
        return NSLocalizedString("Message_OK", comment: "")
    }
    
    private var isParamsValid: Bool {
        guard protocolIndex == Self.protocolTCP else {
            return false
        }
        //Front
        guard !stringFrontAddr.isEmpty else {
            return false
        }
        guard stringFrontAddr.isValidIPv4Format else {
            return false
        }
        guard stringFrontAddr != "0.0.0.0" else {
            return false
        }
        guard !stringFrontPort.isEmpty else {
            return false
        }
        guard (UInt16(stringFrontPort) != nil) else {
            return false
        }
        guard object.hasActiveFilter else {
            return false
        }
        //Back
        guard !stringBackAddr.isEmpty else {
            return false
        }
        guard stringBackAddr.isValidIPv4Format else {
            return false
        }
        guard stringBackAddr != "172.20.10.0" && stringBackAddr != "172.20.10.1" && stringBackAddr != "172.20.10.15" else {
            return false
        }
        guard !stringBackPort.isEmpty else {
            return false
        }
        guard (UInt16(stringBackPort) != nil) else {
            return false
        }
        return true
    }
}
