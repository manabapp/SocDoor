//
//  SocDoorFilterManager.swift
//  SocDoor
//
//  Created by Hirose Manabu on 2021/02/12.
//

import SwiftUI

struct SocDoorFilterManager: View {
    @EnvironmentObject var object: SocDoorSharedObject
    
    static let maxRegistNumber: Int = 16
    
    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section(header: Text("Header_FILTER_LIST").font(.system(size: 16, weight: .semibold)),
                        footer: object.appSettingDescription ? Text("Footer_FILTER_LIST").font(.system(size: 12)) : nil) {
//                    FilterRaw(filter: self.object.filters[0])
//                        .contentShape(Rectangle())
//                        .onTapGesture { self.object.filters[0].isCheck.toggle() }
                    ForEach(0 ..< self.object.filters.count, id: \.self) { i in
                        if !self.object.filters[i].isDeleted {
                            FilterRaw(filter: self.object.filters[i])
                                .contentShape(Rectangle())
                                .onTapGesture { self.object.filters[i].isCheck.toggle() }
                        }
                    }
                    .onDelete { indexSet in
                        SocLogger.debug("SocTestAddressManager: onDelete: \(indexSet)")
                        indexSet.forEach { i in
                            if i != 0 {
                                self.object.filters[i].isDeleted = true
                            }
                        }
                        SocDoorSharedObject.saveFilters(doorFilters: self.object.filters)
                    }
                }
            }
            .listStyle(PlainListStyle())
            
            Form {
                NavigationLink(destination: FilterRegister()) {
                    HStack {
                        Spacer()
                        VStack {
                            Text("New Filter")
                            if object.appSettingDescription {
                                Text("Description_New_Filter")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color.init(UIColor.systemGray))
                            }
                        }
                        Spacer()
                    }
                }
            }
            .frame(height: 110)
        }
        .navigationBarTitle("Filter Manager", displayMode: .inline)
    }
}

fileprivate struct FilterRaw: View {
    @EnvironmentObject var object: SocDoorSharedObject
    let filter: SocDoorFilter
    
    var body: some View {
        HStack {
            Image(systemName: filter.isCheck ? "checkmark.circle.fill" : "globe")
                .resizable()
                .scaledToFit()
                .frame(width: 22, height: 22, alignment: .center)
                .foregroundColor(Color.init(filter.isCheck ? UIColor.systemBlue : UIColor.systemGray))
            VStack(alignment: .leading, spacing: 2) {
                Text(filter.cidr)
                    .font(.system(size: 19))
            }
            .padding(.leading)
            Spacer()
        }
    }
}

fileprivate struct FilterRegister: View {
    @EnvironmentObject var object: SocDoorSharedObject
    @Environment(\.presentationMode) var presentationMode
    @State private var ipAddrString: String = ""
    @State private var suffixString: String = ""

    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section(header: Text("Header_FILTER").font(.system(size: 16, weight: .semibold)),
                        footer: object.appSettingDescription ? Text("Footer_FILTER").font(.system(size: 12)) : nil) {
                    HStack {
                        TextField("192.168.10.0", text: $ipAddrString)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(maxWidth: .infinity)
                        Text("/")
                            .font(.system(size: 22))
                        TextField("24", text: $suffixString)
                            .keyboardType(.numberPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 50)
                    }
                }
            }
            .listStyle(PlainListStyle())
            
            Form {
                Section(footer:
                            HStack {
                                Spacer()
                                Text(self.errorMessage)
                                    .foregroundColor(Color.init(isParamsValid ? UIColor.systemGreen : UIColor.systemRed));
                                Spacer()
                            }
                ) {
                    Button(action: {
                        SocLogger.debug("SocPingOnePinger: Button: Stop")
                        do {
                            try self.register()
                            self.presentationMode.wrappedValue.dismiss()
                        }
                        catch let error as SocDoorError {
                            self.object.alertMessage = error.message
                            self.object.alertDetail = error.detail
                            self.object.isPopAlert = true
                            return
                        }
                        catch {
                            fatalError("SocDoorServer: \(error)")
                        }
                    }) {
                        HStack {
                            Spacer()
                            Image(systemName: "plus.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 19, height: 19, alignment: .center)
                            Text("Button_Register")
                                .padding(.leading, 10)
                                .padding(.trailing, 20)
                            Spacer()
                        }
                    }
                    .disabled(!self.isParamsValid)
                }
            }
            .frame(height: 120)
        }
        .navigationBarTitle("New Filter", displayMode: .inline)
    }
    
    private func register() throws {
        guard let newFilter = SocDoorFilter.validCidr(cidr: "\(ipAddrString)/\(suffixString)") else {
            throw SocDoorError.InvalidCidr
        }
        for filter in self.object.filters {
            if !filter.isDeleted && filter.cidr == newFilter.cidr {
                SocLogger.debug("AddressRegister.getInetAddress: \(filter.cidr) exists")
                throw SocDoorError.AlreadyAddressExist(cidr: filter.cidr)
            }
        }
        
        var count: Int = 0
        for filter in self.object.filters {
            if !filter.isDeleted {
                count += 1
            }
        }
        if count >= SocDoorFilterManager.maxRegistNumber {
            SocLogger.debug("AddressRegister.getInetAddress: Can't register anymore")
            throw SocDoorError.AddressExceeded
        }
        self.object.filters.append(newFilter)
        SocDoorSharedObject.saveFilters(doorFilters: self.object.filters)
    }
    
    private var errorMessage: String {
        guard !ipAddrString.isEmpty else {
            return NSLocalizedString("Message_NoValue", comment: "")
        }
        guard ipAddrString.isValidIPv4Format else {
            return NSLocalizedString("Message_InvalidIpAddr", comment: "")
        }
        guard !suffixString.isEmpty else {
            return NSLocalizedString("Message_NoValue", comment: "")
        }
        guard suffixString.isValidCidrSuffix else {
            return NSLocalizedString("Message_InvalidSuffix", comment: "")
        }
        return NSLocalizedString("Message_OK", comment: "")
    }
    
    private var isParamsValid: Bool {
        guard !ipAddrString.isEmpty else {
            return false
        }
        guard ipAddrString.isValidIPv4Format else {
            return false
        }
        guard !suffixString.isEmpty else {
            return false
        }
        guard suffixString.isValidCidrSuffix else {
            return false
        }
        return true
    }
}
