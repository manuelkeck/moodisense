//
//  WatchConnector.swift
//  CYM
//
//  Created by Manuel Keck on 23.05.24.
//

import Foundation
import WatchConnectivity

class WatchConnector: NSObject, WCSessionDelegate, ObservableObject {
    @Published var heartRate: String = ""
    @Published var heartRateVariability: String = ""
    @Published var isReachable: Bool = false
    @Published var age: String = ""
    @Published var gender: String = ""
    
    var session: WCSession?
    
    override init() {
        super.init()
        if WCSession.isSupported() {
            self.session = WCSession.default
            self.session?.delegate = self
            self.session?.activate()
        }
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if activationState == .activated {
            print("WCSession on iPhone activated: \(session.isReachable)")
            DispatchQueue.main.async {
                self.isReachable = session.isReachable
            }
        } else if let error = error {
            print("WCSession activation failed on iPhone with error: \(error.localizedDescription)")
        }
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("WCSession on iPhone became inactive")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        print("WCSession on iPhone deactivated")
        session.activate() // Re-activate the session if needed
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        if let heartRate = message["heartRate"] as? String {
            DispatchQueue.main.async {
                self.heartRate = heartRate
            }
        }
        if let heartRateVariability = message["heartRateVariability"] as? String {
            DispatchQueue.main.async {
                self.heartRateVariability = heartRateVariability
            }
        }
        if let age = message["age"] as? String {
            DispatchQueue.main.async {
                self.age = age
            }
        }
        if let gender = message["gender"] as? String {
            DispatchQueue.main.sync {
                self.gender = gender
            }
        }
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        print("iPhone session reachability changed: \(session.isReachable)")
        DispatchQueue.main.async {
            self.isReachable = session.isReachable
        }
    }
}
