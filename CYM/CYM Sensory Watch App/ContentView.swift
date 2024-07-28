//
//  ContentView.swift
//  CYM Sensory Watch App
//
//  Created by Manuel Keck on 23.05.24.
//

import SwiftUI
import HealthKit

struct ContentView: View {
    let healthStore = HKHealthStore()
    let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
    let heartRateVariabilityType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
    let bodyTemperatureType = HKQuantityType.quantityType(forIdentifier: .bodyTemperature)!
    let oxygenSaturationType = HKQuantityType.quantityType(forIdentifier: .oxygenSaturation)!
    let dateOfBirthType = HKObjectType.characteristicType(forIdentifier: .dateOfBirth)!
    let biologicalSexType = HKObjectType.characteristicType(forIdentifier: .biologicalSex)!
    let bloodPressureSystolicType = HKObjectType.quantityType(forIdentifier: .bloodPressureSystolic)!
    let bloodPressureDiastolicType = HKObjectType.quantityType(forIdentifier: .bloodPressureDiastolic)!
    let electrodermalActivityType = HKObjectType.quantityType(forIdentifier: .electrodermalActivity)!

    func requestAuthorization() {
        let typesToRead: Set<HKObjectType> = [
            heartRateType,
            heartRateVariabilityType,
            bodyTemperatureType,
            oxygenSaturationType,
            dateOfBirthType,
            biologicalSexType,
            bloodPressureSystolicType,
            bloodPressureDiastolicType,
            electrodermalActivityType
        ]

        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { (success, error) in
            if success {
                _ = VitalDataCollector()
                //vitaldatacollector.startHeartRateQuery()
            } else {
                // Handle error
                print("Authorization failed")
            }
        }
    }
    
    var body: some View {
        HStack {
            Image(systemName: "applewatch")
                .resizable()
                .frame(width: 35, height: 50)
                .foregroundColor(.white)
            
            Spacer()
            
            if #available(iOS 17.0, *) {
                ZStack {
                    Image(systemName: "lock.doc")
                        .foregroundColor(Color.blue)
                        .frame(width: 10, height: 10)
                        .phaseAnimator([0, 1, 3]) { content, phase in content
                                .opacity(phase == 1 ? 1 : 0)
                                .offset(x: phase == 3 ? 10 : -70)
                        } animation: { phase in
                                .easeIn(duration: 1)
                        }
                }
            } else {
                // Error handling for older iOS
            }
            
            Image(systemName: "iphone")
                .resizable()
                .frame(width: 35, height: 60)
                .foregroundColor(.white)
            
        }
        .padding()
        .onAppear {
            requestAuthorization()
        }
        VStack {
            Spacer()
            Text("Sending vital data to MoodiSense iOS App")
                .padding()
                .font(.footnote)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
    }
}

#Preview {
    ContentView()
}
