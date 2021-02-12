//
//  SocDoorError.swift
//  SocDoor
//
//  Created by Hirose Manabu on 2021/02/12.
//

import Foundation

enum SocDoorError: Error {
    case NotSupport
    case NoValue
    case NoFilter
    case InvalidIpAddr
    case InvalidCidr
    case InvalidSuffix
    case InvalidPort
    case CantUseIpAddr
    case AlreadyAddressExist(cidr: String)
    case AddressExceeded
    case FailedHealthCheck(detail: String)
    case CantOpenURL
    case InternalError
}

extension SocDoorError: LocalizedError {
    var message: String {
        switch self {
        case .NotSupport: return NSLocalizedString("Message_NotSupport", comment: "")
        case .NoValue: return NSLocalizedString("Message_NoValue", comment: "")
        case .NoFilter: return NSLocalizedString("Message_NoFilter", comment: "")
        case .InvalidIpAddr: return NSLocalizedString("Message_InvalidIpAddr", comment: "")
        case .InvalidCidr: return NSLocalizedString("Message_InvalidCidr", comment: "")
        case .InvalidSuffix: return NSLocalizedString("Message_InvalidSuffix", comment: "")
        case .InvalidPort: return NSLocalizedString("Message_InvalidPort", comment: "")
        case .CantUseIpAddr: return NSLocalizedString("Message_CantUseIpAddr", comment: "")
        case .AlreadyAddressExist: return NSLocalizedString("Message_AlreadyAddressExist", comment: "")
        case .AddressExceeded: return NSLocalizedString("Message_AddressExceeded", comment: "")
        case .FailedHealthCheck: return NSLocalizedString("Message_FailedHealthCheck", comment: "")
        case .CantOpenURL: return NSLocalizedString("Message_CantOpenURL", comment: "")
        default: return NSLocalizedString("Message_default", comment: "")
        }
    }
}

extension SocDoorError {
    var detail: String {
        switch self {
        case .AlreadyAddressExist(let cidr): return cidr
        case .FailedHealthCheck(let detail): return detail
        default: return ""
        }
    }
}
