//
//  SocDoorStatistics.swift
//  SocDoor
//
//  Created by Hirose Manabu on 2021/02/12.
//

import Foundation

struct SocDoorStatistics {
    var requests: Int = 0  //Pass + Block + Error = Request
    var pass: Int = 0
    var block: Int = 0
    var failure: Int = 0
    var error: Int = 0
    var rxbytes: Int64 = 0
    var txbytes: Int64 = 0
    
    var sumbytes: Int64 { rxbytes + txbytes }
    var progressValue: Double { Double(sumbytes) }
    var progressTotal: Double {
        switch sumbytes {
        case 0 ..< 10240:
            return Double(10240)
        case 10240 ..< 102400:
            return Double(102400)
        case 102400 ..< 1048576:
            return Double(1048576)
        case 1048576 ..< 10485760:
            return Double(10485760)
        case 10485760 ..< 104857600:
            return Double(104857600)
        case 104857600 ..< 1073741824:
            return Double(1073741824)
        case 1073741824 ..< 10737418240:
            return Double(10737418240)
        case 10737418240 ..< 107374182400:
            return Double(107374182400)
        case 107374182400 ..< 1099511627776:
            return Double(1099511627776)
        case 1099511627776 ..< 10995116277760:
            return Double(10995116277760)
        default:
            return Double(109951162777600)
        }
    }
    var totalString: String {
        switch sumbytes {
        case 0 ..< 10240:
            return "10 KB"
        case 10240 ..< 102400:
            return "100 KB"
        case 102400 ..< 1048576:
            return "1 MB"
        case 1048576 ..< 10485760:
            return "10 MB"
        case 10485760 ..< 104857600:
            return "100 MB"
        case 104857600 ..< 1073741824:
            return "1 GB"
        case 1073741824 ..< 10737418240:
            return "10 GB"
        case 10737418240 ..< 107374182400:
            return "100 GB"
        case 107374182400 ..< 1099511627776:
            return "1 TB"
        case 1099511627776 ..< 10995116277760:
            return "10 TB"
        default:
            return "100 TB"
        }
    }
}

