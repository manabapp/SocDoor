//
//  SocDoorFilter.swift
//  SocDoor
//
//  Created by Hirose Manabu on 2021/02/12.
//

import Foundation

struct SocDoorFilter {
    let cidr: String
    var netaddr: UInt32
    var netmask: UInt32
    var isCheck: Bool = false
    var isDeleted: Bool = false
    
    var isActive: Bool { self.isCheck && !self.isDeleted }
    var isAny: Bool { self.netmask == 0 }
    
    static func validCidr(cidr: String) -> SocDoorFilter? {
        guard cidr.isValidCidrFormat else {
            return nil
        }
        let array: [String] = cidr.components(separatedBy: "/")
        guard array.count == 2 else {
            return nil
        }
        let netaddr_org = UInt32(inet_addr(array[0])).bigEndian
        let netmask = UInt32(0xffffffff) << (32 - Int(array[1])!)
        let netaddr = netaddr_org & netmask
        var filter = SocDoorFilter(cidr: String.init(cString: inet_ntoa(in_addr(s_addr: netaddr.bigEndian))) + "/" + array[1])
        filter.netaddr = netaddr
        filter.netmask = netmask
        return filter
    }
    
    init(cidr: String, isCheck: Bool = false) {
        self.cidr = cidr
        let array: [String] = cidr.components(separatedBy: "/")
        self.netaddr = UInt32(inet_addr(array[0])).bigEndian
        self.netmask = UInt32(0xffffffff) << (32 - Int(array[1])!)
        self.isCheck = isCheck
    }
    
    func check(addr: String) -> Bool {
        return (UInt32(inet_addr(addr)).bigEndian & self.netmask) == self.netaddr
    }
}
