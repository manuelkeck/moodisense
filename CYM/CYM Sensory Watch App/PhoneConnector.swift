//
//  PhoneConnector.swift
//  CYM Sensory Watch App
//
//  Created by Manuel Keck on 23.05.24.
//

import Foundation
import WatchConnectivity

class PhoneConnector: NSObject, WCSessionDelegate, ObservableObject {
    var session: WCSession?
    
    override init() {
        super.init()
        if WCSession.isSupported() {
            self.session = WCSession.default
            self.session?.delegate = self
            self.session?.activate()
        }
    }
    
    func sendHealthDataToPhone(heartRate: String, heartRateVariability: String, age: String, gender: String) {
        guard let session = session else {
            print("WCSession is not supported")
            return
        }
        
        if session.isReachable {
          let data = [
            "heartRate": heartRate,
            "heartRateVariability": heartRateVariability,
            "age": age,
            "gender": gender
          ]
          session.sendMessage(data, replyHandler: nil) { error in
            print("Error sending message to iPhone: \(error.localizedDescription)")
          }
        } else {
          print("iPhone is not reachable")
        }
    }
    
    // WCSessionDelegate method for activation
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if activationState == .activated {
            print("WCSession on Watch activated")
        } else if let error = error {
            print("WCSession activation failed on Watch with error: \(error.localizedDescription)")
        }
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        print("Watch session reachability changed: \(session.isReachable)")
    }
}
