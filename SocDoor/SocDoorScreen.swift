//
//  SocDoorScreen.swift
//  SocDoor
//
//  Created by Hirose Manabu on 2021/02/12.
//

import SwiftUI

struct SocDoorScreen: UIViewRepresentable {
    @EnvironmentObject var object: SocDoorSharedObject
    @Binding var text: String
    static var fontSize: CGFloat = 9.5

    static func initSize(width: CGFloat) {
        if width <= 0.0 {
            SocLogger.error("SocDoorScreen.initSize: width = \(width)")
            assertionFailure("SocDoorScreen.initSize: width = \(width)")
            return
        }
        //Devices supported iOS 14 or newer
        if width >= 428 {  //Device width 428pt : iPhone 12 Pro Max
            SocDoorScreen.fontSize = 10.7
        }
        else if width >= 414 {  //Device width 414pt : iPhone 6s Plus, 7 Plus, 8 Plus, XR, 11, XS Max, 11 Pro Max
            SocDoorScreen.fontSize = 10.4
        }
        else if width >= 390 {  //Device width 390pt : iPhone 12, 12 Pro
            SocDoorScreen.fontSize = 9.8
        }
        else if width >= 375 {  //Device width 375pt : iPhone 6s, 7, 8, SE(2nd Gen), X, XS, 11 Pro, 12 mini
            SocDoorScreen.fontSize = 9.5
        }
        else {  //Device width 320pt : iPhone SE(1st Gen), iPod touch(7th Gen)
            SocDoorScreen.fontSize = 8.0
        }
    }
    
    func makeUIView(context: Context) -> UITextView {
        let myTextArea = UITextView()
        myTextArea.keyboardType = .asciiCapable
        myTextArea.isEditable = false
        myTextArea.delegate = context.coordinator
        myTextArea.font = UIFont(name: "Courier", size: SocDoorScreen.fontSize)
        myTextArea.textAlignment = .left
        if self.object.appSettingScreenColorInverted {
            if UITraitCollection.current.userInterfaceStyle == .dark {
                //secondarySystemBackground in Dark #F2F2F7
                myTextArea.backgroundColor = UIColor(red: 0.949, green: 0.949, blue: 0.969, alpha: 1.0)
                myTextArea.textColor = UIColor.black
            }
            else {
                //secondarySystemBackground in Dark #1C1C1E
                myTextArea.backgroundColor = UIColor(red: 0.110, green: 0.110, blue: 0.118, alpha: 1.0)
                myTextArea.textColor = UIColor.white
            }
        }
        else {
            myTextArea.backgroundColor = UIColor.secondarySystemBackground
            myTextArea.textColor = UIColor.label
        }
        return myTextArea
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        uiView.text = text
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator : NSObject, UITextViewDelegate {
        var parent: SocDoorScreen
        
        init(_ uiTextView: SocDoorScreen) {
            self.parent = uiTextView
        }
        
        func textViewDidChange(_ textView: UITextView) {
            self.parent.text = textView.text
        }
    }
}
