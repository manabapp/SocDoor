//
//  SocDoorTcpServer.swift
//  SocDoor
//
//  Created by Hirose Manabu on 2021/02/12.
//

import SwiftUI

struct SocDoorTcpServer: View {
    @EnvironmentObject var object: SocDoorSharedObject
    @Environment(\.presentationMode) var presentationMode
    @Binding var frontAddress: SocAddress  //backend host
    @Binding var backAddress: SocAddress  //backend host
    @State private var sockets: [SocSocket] = []
    @State private var stats = SocDoorStatistics()
    @State private var isInterrupted: Bool = false
    @State private var isInProgress: Bool = false
    
    private var serverName: String {
        return frontAddress.addr + ":" + String(frontAddress.port) + " - " + backAddress.addr + ":" + String(backAddress.port)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            List {
                Section(header: Text("Header_DOOR_SERVER")) {
                    TcpServerRow(name: self.serverName, stats: self.$stats, isActive: self.$isInProgress)
                }
                Section(header: Text("Header_SESSIONS")) {
                    ForEach(0 ..< self.sockets.count, id: \.self) { i in
                        if i > 0 && i % 2 == 0 && !self.sockets[i - 1].isClosed && !self.sockets[i].isClosed {
                            TcpSessionRow(frontSocket: self.$sockets[i - 1], backSocket: self.$sockets[i])
                        }
                    }
                }
            }
            
            Form {
                Button(action: {
                    if self.isInterrupted && !self.isInProgress {
                        SocLogger.debug("SocPingOnePinger: Button: Close")
                        self.presentationMode.wrappedValue.dismiss()
                        return
                    }
                    if self.isInProgress {
                        SocLogger.debug("SocPingOnePinger: Button: Stop")
                        self.isInterrupted = true
                        return
                    }
                    
                    do {
                        try self.healthCheck(address: backAddress)
                        var listening = try SocSocket(family: AF_INET, type: SOCK_STREAM, proto: 0)
                        try listening.setsockopt(level: SOL_SOCKET, option: SO_REUSEADDR, value: SocOptval(bool: true))
                        try listening.bind(address: frontAddress)
                        try listening.listen(backlog: 1024)
                        listening.localAddress = frontAddress
                        listening.isServer = true
                        listening.isListening = true
                        self.sockets.append(listening)
                    }
                    catch let error as SocError {
                        self.object.alertMessage = error.message
                        self.object.alertDetail = error.detail
                        self.object.isPopAlert = true
                        return
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
                    
                    SocLogger.debug("SocPingOnePinger: Button: Start")
                    self.isInterrupted = false
                    self.isInProgress = true
                    DispatchQueue.global().async {
                        while true {
                            self.pollSessions()
                            if self.isInterrupted {
                                break
                            }
                            if self.sockets[0].revents & POLLIN == POLLIN {
                                self.newSession(listener: 0)
                            }
                            for i in 1 ..< self.sockets.count {
                                if self.sockets[i].isClosed {
                                    continue
                                }
                                let j = i % 2 == 0 ? i - 1 : i + 1  // pair socket index
                                if self.sockets[i].revents & POLLIN == POLLIN {
                                    self.relaySession(receiver: i, sender: j)
                                }
                                self.postSession(index: i, pairIndex: j)
                            }
                        }
                        for i in 0 ..< self.sockets.count {
                            self.closeSession(i)
                        }
                        self.isInProgress = false
                    }
                }) {
                    HStack {
                        Spacer()
                        if !self.isInterrupted || self.isInProgress {
                            Image(systemName: self.isInProgress ? "stop.fill" : "play.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 19, height: 19, alignment: .center)
                            Text(self.isInProgress ?  "Button_Stop" : "Button_Start")
                                .padding(.leading, 10)
                                .padding(.trailing, 20)
                        }
                        else {
                            VStack {
                                Text("Close")
                                    .foregroundColor(Color.init(UIColor.label))
                                if object.appSettingDescription {
                                    Text("Description_Close")
                                        .font(.system(size: 12))
                                        .foregroundColor(Color.init(UIColor.systemGray))
                                }
                            }
                        }
                        Spacer()
                    }
                }
            }
            .frame(height: 110)
        }
        .navigationBarTitle("TCP-TCP", displayMode: .inline)
        .navigationBarBackButtonHidden(self.isInProgress)
    }
    
    private func healthCheck(address: SocAddress) throws {
        self.object.hotspot.ifconfig()
        guard self.object.hotspot.isActive else {
            throw SocDoorError.FailedHealthCheck(detail: "Backend host \(address.addr) not found")
        }
        
        let detail: String
        do {
            let socket = try! SocSocket(family: AF_INET, type: SOCK_STREAM, proto: 0)
            defer {
                try! socket.close()
            }
            try socket.setsockopt(level: IPPROTO_TCP, option: TCP_CONNECTIONTIMEOUT, value: SocOptval(double: 5.0))  //timeout 5sec
            try socket.setsockopt(level: IPPROTO_IP, option: IP_BOUND_IF, value: SocOptval(int: self.object.hotspot.index))
            try socket.connect(address: address)
            return
        }
        catch let error as SocError {
            switch error.code {
            case ETIMEDOUT, EHOSTDOWN, EHOSTUNREACH:
                detail = "Backend host \(address.addr) not found"
            case ECONNREFUSED:
                detail = "Backend service \(address.port)/tcp not available"
            default:
                detail = "Unexpected Error\nerrno=\(error.code)[\(ERRNO_NAMES[Int(error.code)])]"
            }
        }
        catch {
            fatalError("SocDoorServer: \(error)")
        }
        throw SocDoorError.FailedHealthCheck(detail: detail)
    }
    
    private func pollSessions() {
        while true {
            do {
                if self.isInterrupted {
                    return
                }
                let ret = try SocSocket.poll(sockets: &self.sockets, events: POLLIN, timeout: 5000)  //wait for 5sec
                if ret > 0 {
                    return
                }
            }
            catch let error as SocError {
                if error.code != EINTR {
                    self.stats.error += 1
                    return
                }
            }
            catch {
                fatalError("SocDoorServer: \(error)")
            }
        }
    }
    
    private func newSession(listener: Int) {
        var isFalied: Bool = true
        var from: SocAddress? = nil
        var frontSocket: SocSocket
        do {
            self.stats.requests += 1
            (frontSocket, from) = try self.sockets[listener].accept(needAddress: true)
            defer {
                if isFalied {
                    try! frontSocket.close()
                }
            }
            guard let fromAddress = from else {
                self.stats.failure += 1
                DispatchQueue.main.async {
                    object.denyAccessLog(source: nil)
                }
                return
            }
            var isAllow = false
            for filter in self.object.filters {
                if filter.isActive && filter.check(addr: fromAddress.addr) {
                    isAllow = true
                    break
                }
            }
            if !isAllow {
                self.stats.block += 1
                DispatchQueue.main.async {
                    object.denyAccessLog(source: from)
                }
                return
            }
            frontSocket.localAddress = self.sockets[listener].localAddress
            frontSocket.remoteAddress = fromAddress
            frontSocket.isConnected = true
            frontSocket.isServer = true
            
            var backSocket = try SocSocket(family: AF_INET, type: SOCK_STREAM, proto: 0)
            defer {
                if isFalied {
                    try! backSocket.close()
                }
            }
            try backSocket.setsockopt(level: IPPROTO_TCP, option: TCP_CONNECTIONTIMEOUT, value: SocOptval(double: 5.0))  //timeout 5sec
            try backSocket.setsockopt(level: IPPROTO_IP, option: IP_BOUND_IF, value: SocOptval(int: self.object.hotspot.index))
            try backSocket.connect(address: self.backAddress)
            backSocket.localAddress = try backSocket.getsockname()
            backSocket.remoteAddress = self.backAddress
            backSocket.isConnected = true
            
            isFalied = false
            self.stats.pass += 1
            DispatchQueue.main.async {
                object.allowAccessLog(source: from, local: backSocket.localAddress)
            }
            self.sockets.append(frontSocket)
            self.sockets.append(backSocket)
        }
        catch let error as SocError {
            self.stats.failure += 1
            self.stats.error += 1
            DispatchQueue.main.async {
                object.failedAccessLog(source: from, error: error)
            }
        }
        catch {
            fatalError("SocDoorServer: \(error)")
        }
    }
    
    private func relaySession(receiver: Int, sender: Int) {
        var buffer = Data([UInt8](repeating: 0, count: Int(BUFSIZ)))
        let received: Int
        do {
            received = try self.sockets[receiver].recv(data: &buffer, flags: 0)
            if received == 0 {
                self.sockets[receiver].isRdShutdown = true
                return
            }
            if receiver % 2 == 1 {
                self.stats.rxbytes += Int64(received)
            }
        }
        catch let error as SocError {
            switch error.code {
            case ECONNRESET, ENOTCONN:
                self.sockets[receiver].isRdShutdown = true
                self.sockets[receiver].isWrShutdown = true
            default:
                self.stats.error += 1
            }
            return
        }
        catch {
            fatalError("SocDoorServer: \(error)")
        }
        
        do {
            let data = Data(buffer[0 ..< received])
            let sent = try self.sockets[sender].send(data: data, flags: 0)
            if sender % 2 == 1 {
                self.stats.txbytes += Int64(sent)
            }
        }
        catch let error as SocError {
            switch error.code {
            case EPIPE:
                self.sockets[sender].isWrShutdown = true
            case ECONNRESET, ENOTCONN:
                self.sockets[sender].isRdShutdown = true
                self.sockets[sender].isWrShutdown = true
            default:
                self.stats.error += 1
            }
            return
        }
        catch {
            fatalError("SocDoorServer: \(error)")
        }
    }
    
    private func closeSession(_ index: Int) {
        if index == 0 {
            if !self.sockets[index].isClosed {
                try! self.sockets[index].close()
            }
            self.sockets[index].isClosed = true
            return
        }
        let i = index % 2 == 0 ? index - 1 : index
        let j = index % 2 == 0 ? index : index + 1
        if !self.sockets[i].isClosed {
            try! self.sockets[i].close()
            self.sockets[i].isClosed = true
        }
        if !self.sockets[j].isClosed {
            try! self.sockets[j].close()
            self.sockets[j].isClosed = true
        }
    }
    
    private func postSession(index: Int, pairIndex: Int) {
        if self.sockets[index].isRdShutdown && self.sockets[index].isWrShutdown {
            self.closeSession(index)
        }
        else if self.sockets[index].isRdShutdown && self.sockets[pairIndex].isRdShutdown {
            self.closeSession(index)
        }
        else if self.sockets[index].isWrShutdown && self.sockets[pairIndex].isWrShutdown {
            self.closeSession(index)
        }
        else if self.sockets[index].isRdShutdown && !self.sockets[pairIndex].isWrShutdown {
            do {
                try self.sockets[pairIndex].shutdown(how: SHUT_WR)
                self.sockets[pairIndex].isWrShutdown = true
            }
            catch _ as SocError {
                self.closeSession(index)
            }
            catch {
                fatalError("SocDoorServer: \(error)")
            }
        }
        else if self.sockets[index].isWrShutdown && !self.sockets[pairIndex].isRdShutdown {
            do {
                try self.sockets[pairIndex].shutdown(how: SHUT_RD)
                self.sockets[pairIndex].isRdShutdown = true
            }
            catch _ as SocError {
                self.closeSession(index)
            }
            catch {
                fatalError("SocDoorServer: \(error)")
            }
        }
        
        if !self.sockets[index].isClosed {
            do {
                let ret = try self.sockets[index].getsockopt(level: IPPROTO_TCP, option: TCP_CONNECTION_INFO)
                self.sockets[index].connInfo = ret.connInfo
            }
            catch _ as SocError {
                self.stats.error += 1
            }
            catch {
                fatalError("SocDoorServer: \(error)")
            }
        }
    }
}

fileprivate struct TcpServerRow: View {
    @EnvironmentObject var object: SocDoorSharedObject
    var name: String
    @Binding var stats: SocDoorStatistics
    @Binding var isActive: Bool

    var body: some View {
        HStack {
            Image(systemName: "rectangle.portrait.arrowtriangle.2.outward")
                .resizable()
                .scaledToFit()
                .frame(width: 22, height: 22, alignment: .center)
                .foregroundColor(Color.init(self.isActive ? UIColor.systemGreen : UIColor.systemGray))
            VStack(alignment: .leading, spacing: 2) {
                Text(self.name)
                    .font(.system(size: 16))
                self.countsText
                self.bytesText
                if object.appSettingDescription {
                    self.bytesText2
                }
                ProgressView(value: self.stats.progressValue, total: self.stats.progressTotal)
                    .accentColor(Color.init(self.isActive ? UIColor.systemBlue : UIColor.systemGray))
                HStack {
                    Text("0")
                        .font(.system(size: 10))
                        .foregroundColor(Color.init(UIColor.systemGray))
                    Spacer()
                    Text(self.stats.totalString)
                        .font(.system(size: 10))
                        .foregroundColor(Color.init(UIColor.systemGray))
                }
            }
            .padding(.leading)
        }
    }
    
    private var countsText: Text {
        let label = Text("Label_Connections")
            .font(.system(size: 12))
            .foregroundColor(Color.init(UIColor.systemGray))
        let count = Text("\(self.stats.requests)")
            .font(.system(size: 12))
            .foregroundColor(Color.init(self.isActive ? UIColor.label : UIColor.systemGray))
        let equal = Text(" = ")
            .font(.system(size: 12))
            .foregroundColor(Color.init(UIColor.systemGray))
        let label2 = Text("Label_Access_Allow")
            .font(.system(size: 12))
            .foregroundColor(Color.init(UIColor.systemGray))
        let count2 = Text("\(self.stats.pass)")
            .font(.system(size: 12))
            .foregroundColor(Color.init(self.isActive && self.stats.pass > 0 ? UIColor.systemGreen : UIColor.systemGray))
        let plus = Text(" + ")
            .font(.system(size: 12))
            .foregroundColor(Color.init(UIColor.systemGray))
        let label3 = Text("Label_Access_Deny")
            .font(.system(size: 12))
            .foregroundColor(Color.init(UIColor.systemGray))
        let count3 = Text("\(self.stats.block)")
            .font(.system(size: 12))
            .foregroundColor(Color.init(self.isActive && self.stats.block > 0 ? UIColor.systemYellow : UIColor.systemGray))
        let label4 = Text("Label_Access_Error")
            .font(.system(size: 12))
            .foregroundColor(Color.init(UIColor.systemGray))
        let count4 = Text("\(self.stats.failure)")
            .font(.system(size: 12))
            .foregroundColor(Color.init(self.isActive && self.stats.failure > 0 ? UIColor.systemRed : UIColor.systemGray))
        return label + count + equal + label2 + count2 + plus + label3 + count3 + plus + label4 + count4
    }
    
    private var bytesText: Text {
        let label = Text("Label_Cellurar_Data_Total")
            .font(.system(size: 12))
            .foregroundColor(Color.init(UIColor.systemGray))
        let count = Text("\(self.stats.sumbytes) ")
            .font(.system(size: 12))
            .foregroundColor(Color.init(self.isActive ? UIColor.label : UIColor.systemGray))
        let label2 = Text(self.stats.sumbytes == 1 ? "Label_byte" : "Label_bytes")
            .font(.system(size: 12))
            .foregroundColor(Color.init(UIColor.systemGray))
        return label + count + label2
    }
    
    private var bytesText2: Text {
        let bytes = Text("RX: \(self.stats.rxbytes) ")
            .font(.system(size: 12))
            .foregroundColor(Color.init(UIColor.systemGray))
        let label = Text(self.stats.rxbytes == 1 ? "Label_byte" : "Label_bytes")
            .font(.system(size: 12))
            .foregroundColor(Color.init(UIColor.systemGray))
        let bytes2 = Text(", TX: \(self.stats.txbytes) ")
            .font(.system(size: 12))
            .foregroundColor(Color.init(UIColor.systemGray))
        let label2 = Text(self.stats.txbytes == 1 ? "Label_byte" : "Label_bytes")
            .font(.system(size: 12))
            .foregroundColor(Color.init(UIColor.systemGray))
        return bytes + label + bytes2 + label2
    }
}

fileprivate struct TcpSessionRow: View {
    @EnvironmentObject var object: SocDoorSharedObject
    @Binding var frontSocket: SocSocket
    @Binding var backSocket: SocSocket
    private var sumbytes: Int64 {Int64(self.frontSocket.connInfo.tcpi_rxbytes + self.frontSocket.connInfo.tcpi_txbytes) }
    
    var body: some View {
        HStack {
            Image(systemName: "arrow.left.and.right")
                .resizable()
                .scaledToFit()
                .frame(width: 22, height: 22, alignment: .center)
            VStack(alignment: .leading, spacing: 2) {
                if object.appSettingDescription {
                    self.date
                }
                self.name
                HStack(spacing: 2) {
                    Text("Front:")
                        .font(.system(size: 12))
                        .foregroundColor(Color.init(UIColor.systemGray))
                    Image(systemName: self.isEstablished(self.frontSocket) ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                        .font(.system(size: 11))
                        .foregroundColor(Color.init(self.isEstablished(self.frontSocket) ? UIColor.systemGreen : UIColor.systemYellow))
                    Text(self.getTcpState(self.frontSocket))
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color.init(UIColor.systemGray))
                    Text(", Back:")
                        .font(.system(size: 12))
                        .foregroundColor(Color.init(UIColor.systemGray))
                    Image(systemName: self.isEstablished(self.backSocket) ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                        .font(.system(size: 11))
                        .foregroundColor(Color.init(self.isEstablished(self.backSocket) ? UIColor.systemGreen : UIColor.systemYellow))
                    Text(self.getTcpState(self.backSocket))
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color.init(UIColor.systemGray))
                }
                self.bytesText
                if object.appSettingDescription {
                    self.bytesText2
                }
                ProgressView(value: self.progressValue, total: self.progressTotal)
                HStack {
                    Text("0")
                        .font(.system(size: 10))
                        .foregroundColor(Color.init(UIColor.systemGray))
                    Spacer()
                    Text(self.totalString)
                        .font(.system(size: 10))
                        .foregroundColor(Color.init(UIColor.systemGray))
                }
            }
            .padding(.leading)
        }
    }
    
    private var date: Text {
        let label = Text("Label_Start_Date")
            .font(.system(size: 12))
            .foregroundColor(Color.init(UIColor.systemGray))
        let start = Text(object.dateFormatter.string(from: self.frontSocket.openDate))
            .font(.system(size: 12))
            .foregroundColor(Color.init(UIColor.systemGray))
        return label + start
    }
    
    private var name: Text {
        let label = Text("Client ")
            .font(.system(size: 18))
            .foregroundColor(Color.init(UIColor.systemGray))
        let client = Text(self.frontSocket.remoteAddress!.addr + ":" + String(self.frontSocket.remoteAddress!.port))
            .font(.system(size: 22))
        return label + client
    }
    
    private func isEstablished(_ socket: SocSocket) -> Bool {
        return socket.connInfo.tcpi_state == 4
    }
    
    private func getTcpState(_ socket: SocSocket) -> String {
        if socket.connInfo.tcpi_state >= SocLogger.tcpStateNames.count {
            return "Unknown"
        }
        else {
            return SocLogger.tcpStateNames[Int(socket.connInfo.tcpi_state)]
        }
    }
    
    private var bytesText: Text {
        let label = Text("Label_Cellurar_Data")
            .font(.system(size: 12))
            .foregroundColor(Color.init(UIColor.systemGray))
        let count = Text("\(sumbytes) ")
            .font(.system(size: 12))
        let label2 = Text(sumbytes == 1 ? "Label_byte" : "Label_bytes")
            .font(.system(size: 12))
            .foregroundColor(Color.init(UIColor.systemGray))
        return label + count + label2
    }
    
    private var bytesText2: Text {
        let bytes = Text("RX: \(self.frontSocket.connInfo.tcpi_rxbytes) ")
            .font(.system(size: 12))
            .foregroundColor(Color.init(UIColor.systemGray))
        let label = Text(self.frontSocket.connInfo.tcpi_rxbytes == 1 ? "Label_byte" : "Label_bytes")
            .font(.system(size: 12))
            .foregroundColor(Color.init(UIColor.systemGray))
        let bytes2 = Text(", TX: \(self.frontSocket.connInfo.tcpi_txbytes) ")
            .font(.system(size: 12))
            .foregroundColor(Color.init(UIColor.systemGray))
        let label2 = Text(self.frontSocket.connInfo.tcpi_txbytes == 1 ? "Label_byte" : "Label_bytes")
            .font(.system(size: 12))
            .foregroundColor(Color.init(UIColor.systemGray))
        return bytes + label + bytes2 + label2
    }
    
    private var progressValue: Double { Double(sumbytes) }
    private var progressTotal: Double {
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
