//
//  VitalDataCollector.swift
//  CYM Sensory Watch App
//
//  Created by Manuel Keck on 27.05.24.
//

import Foundation
import HealthKit

class VitalDataCollector {
    private var heartRate: Double = 0.0
    private var heartRateVariability: Double = 0.0
    private var bodyTemperature: Double = 0.0
    private var oxygenSaturation: Double = 0.0
    private var gender: String = "Undefined"
    private var age: Int = 0
    private var bloodPressure: String = "0.0"
    private var systolicPressure: Double?
    private var diastolicPressure: Double?
    private var electrodermalActivity: Double = 0.0
    
    let healthStore = HKHealthStore()
    
    let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
    let heartRateVariabilityType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
    let bodyTemperatureType = HKQuantityType.quantityType(forIdentifier: .bodyTemperature)!
    let oxygenSaturationType = HKQuantityType.quantityType(forIdentifier: .oxygenSaturation)!
    let systolicType = HKObjectType.quantityType(forIdentifier: .bloodPressureSystolic)!
    let diastolicType = HKObjectType.quantityType(forIdentifier: .bloodPressureDiastolic)!
    let electrodermalActivityType = HKObjectType.quantityType(forIdentifier: .electrodermalActivity)!
    
    let sendData = PhoneConnector()
    
    var heartRateAnchor: HKQueryAnchor?
    var heartRateVariabilityAnchor: HKQueryAnchor?
    var bodyTemperatureAnchor: HKQueryAnchor?
    var oxygenSaturationAnchor: HKQueryAnchor?
    var electrodermalActivityAnchor: HKQueryAnchor?
    
    var timer: Timer?
    
    init() {
        enableBackgroundDelivery()
        
        readUserCharacteristics()
        startHeartRateQuery()
        startHeartRateVariabilityQuery()
        startBodyTemperatureQuery()
        // startOxygenSaturationQuery()
        // setupObserverQuery()
        startBloodPressureQuery()
        
        startTimer()
    }
    
    func readUserCharacteristics() {
        // Gender
        do {
            let biologicalSex = try healthStore.biologicalSex()
            
            switch biologicalSex.biologicalSex {
            case .notSet:
                self.gender = "Not set"
            case .female:
                self.gender = "Female"
            case .male:
                self.gender = "Male"
            case .other:
                self.gender = "Other"
                
            @unknown default:
                fatalError()
            }
            
            // Age
            let dateOfBirthComponents = try healthStore.dateOfBirthComponents()
            if let dateOfBirth = Calendar.current.date(from: dateOfBirthComponents) {
                self.age = calculateAge(birthDate: dateOfBirth)
            }
        } catch {
            print("Error reading user characteristics: \(error.localizedDescription)")
        }
    }
    
    func calculateAge(birthDate: Date) -> Int {
        let now = Date()
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: birthDate, to: now)
        return ageComponents.year ?? 0
    }
    
    func startHeartRateQuery() {
        let predicate = HKQuery.predicateForSamples(withStart: Date(), end: nil, options: .strictEndDate)
        let hrQuery = HKAnchoredObjectQuery(
            type: heartRateType,
            predicate: predicate,
            anchor: heartRateAnchor,
            limit: HKObjectQueryNoLimit
        ) { query, samples, deletedObjects, newAnchor, error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                return
            }
            self.heartRateAnchor = newAnchor
            if let heartRateSamples = samples as? [HKQuantitySample] {
                self.processHeartRateSamples(samples: heartRateSamples)
            }
        }
        
        hrQuery.updateHandler = { query, samples, deletedObjects, newAnchor, error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                return
            }
            self.heartRateAnchor = newAnchor
            if let heartRateSamples = samples as? [HKQuantitySample] {
                self.processHeartRateSamples(samples: heartRateSamples)
            }
        }
        healthStore.execute(hrQuery)
    }
    
    func startHeartRateVariabilityQuery() {
        let startDate = Calendar.current.date(byAdding: .day, value: -7, to: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: nil, options: .strictEndDate)
        let hrvQuery = HKAnchoredObjectQuery(
            type: heartRateVariabilityType,
            predicate: predicate,
            anchor: heartRateVariabilityAnchor,
            limit: HKObjectQueryNoLimit
        ) { query, samples, deletedObjects, newAnchor, error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                return
            }
            self.heartRateVariabilityAnchor = newAnchor
            if let heartRateVariabilitySamples = samples as? [HKQuantitySample] {
                self.processHeartRateVariabilitySamples(samples: heartRateVariabilitySamples)
            }
        }
        
        hrvQuery.updateHandler = { query, samples, deletedObjects, newAnchor, error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                return
            }
            self.heartRateVariabilityAnchor = newAnchor
            if let heartRateVariabilitySamples = samples as? [HKQuantitySample] {
                self.processHeartRateVariabilitySamples(samples: heartRateVariabilitySamples)
            }
        }
        healthStore.execute(hrvQuery)
    }
    
    func startBodyTemperatureQuery() {
        let startDate = Calendar.current.date(byAdding: .day, value: -7, to: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: nil, options: .strictEndDate)
        let btQuery = HKAnchoredObjectQuery(
            type: bodyTemperatureType,
            predicate: predicate,
            anchor: nil,
            limit: HKObjectQueryNoLimit
        ) { query, samples, deletedObjects, newAnchor, error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                return
            }
            self.bodyTemperatureAnchor = newAnchor
            if let bodyTemperatureSamples = samples as? [HKQuantitySample] {
                self.processBodyTemperatureSamples(samples: bodyTemperatureSamples)
            }
        }
        
        btQuery.updateHandler = { query, samples, deletedObjects, newAnchor, error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                return
            }
            self.bodyTemperatureAnchor = newAnchor
            if let bodyTemperatureSamples = samples as? [HKQuantitySample] {
                self.processBodyTemperatureSamples(samples: bodyTemperatureSamples)
            }
        }
        healthStore.execute(btQuery)
    }
    
    func startOxygenSaturationQuery() {
        //let startDate = Calendar.current.date(byAdding: .hour, value: -3, to: Date())
        let predicate = HKQuery.predicateForSamples(withStart: Date.distantPast, end: Date(), options: .strictEndDate)
        let osQuery = HKAnchoredObjectQuery(
            type: oxygenSaturationType,
            predicate: predicate,
            anchor: nil,
            limit: HKObjectQueryNoLimit
        ) { query, samples, deletedObjects, newAnchor, error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                return
            }
            self.oxygenSaturationAnchor = newAnchor
            if let oxygenSaturationSamples = samples as? [HKQuantitySample] {
                self.processOxygenSaturationSamples(samples: oxygenSaturationSamples)
            }
        }
        
        osQuery.updateHandler = { query, samples, deletedObjects, newAnchor, error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                return
            }
            self.oxygenSaturationAnchor = newAnchor
            if let oxygenSaturationSamples = samples as? [HKQuantitySample] {
                self.processOxygenSaturationSamples(samples: oxygenSaturationSamples)
            }
        }
        healthStore.execute(osQuery)
    }
    
    func setupObserverQuery() {
            guard let oxygenSaturationType = HKObjectType.quantityType(forIdentifier: .oxygenSaturation) else {
                return
            }

            let observerQuery = HKObserverQuery(sampleType: oxygenSaturationType, predicate: nil) { [weak self] _, _, error in
                if let error = error {
                    print("Observer query failed: \(error.localizedDescription)")
                    return
                }

                self?.fetchLatestOxygenSaturation()
            }

            healthStore.execute(observerQuery)
            healthStore.enableBackgroundDelivery(for: oxygenSaturationType, frequency: .immediate) { success, error in
                if success {
                    print("Enabled background delivery for oxygen saturation.")
                } else {
                    print("Failed to enable background delivery: \(String(describing: error?.localizedDescription))")
                }
            }
        }
    
    func fetchLatestOxygenSaturation() {
            guard let oxygenSaturationType = HKQuantityType.quantityType(forIdentifier: .oxygenSaturation) else {
                return
            }

            let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
            let sampleQuery = HKSampleQuery(sampleType: oxygenSaturationType, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { [weak self] _, results, error in
                guard error == nil, let results = results, let latestSample = results.first as? HKQuantitySample else {
                    print("Error fetching latest oxygen saturation sample: \(String(describing: error?.localizedDescription))")
                    return
                }

                let osUnit = HKUnit.percent()
                let osValue = latestSample.quantity.doubleValue(for: osUnit) * 100.0 // In percentage
                self?.oxygenSaturation = osValue

                // Aktualisieren Sie hier die Variable und senden Sie sie an Ihre iOS-App
                DispatchQueue.main.async {
                    self?.oxygenSaturation = osValue
                }
            }

            healthStore.execute(sampleQuery)
        }
    
    func startBloodPressureQuery() {
                
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let predicate = HKQuery.predicateForSamples(withStart: Date.distantPast, end: Date(), options: .strictEndDate)
        
        let systolicQuery = HKSampleQuery(sampleType: systolicType, predicate: predicate, limit: 1, sortDescriptors: [sortDescriptor]) { [weak self] query, results, error in
            guard let self = self, error == nil, let results = results, let latestSample = results.first as? HKQuantitySample else {
                print("Error fetching latest systolic pressure sample: \(String(describing: error?.localizedDescription))")
                return
            }
            systolicPressure = latestSample.quantity.doubleValue(for: HKUnit.millimeterOfMercury())
            self.processBloodPressureSamples()
        }

        let diastolicQuery = HKSampleQuery(sampleType: diastolicType, predicate: predicate, limit: 1, sortDescriptors: [sortDescriptor]) { [weak self] query, results, error in
            guard let self = self, error == nil, let results = results, let latestSample = results.first as? HKQuantitySample else {
                print("Error fetching latest diastolic pressure sample: \(String(describing: error?.localizedDescription))")
                return
            }
            diastolicPressure = latestSample.quantity.doubleValue(for: HKUnit.millimeterOfMercury())
            self.processBloodPressureSamples()
        }

        healthStore.execute(systolicQuery)
        healthStore.execute(diastolicQuery)
        
    }
    
    func startElectrodermalActivityQuery() {
        let predicate = HKQuery.predicateForSamples(withStart: Date.distantPast, end: nil, options: .strictEndDate)
        let eaQuery = HKAnchoredObjectQuery(
            type: electrodermalActivityType,
            predicate: predicate,
            anchor: electrodermalActivityAnchor,
            limit: HKObjectQueryNoLimit
        ) { query, samples, deletedObjects, newAnchor, error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                return
            }
            self.electrodermalActivityAnchor = newAnchor
            if let electrodermalActivitySamples = samples as? [HKQuantitySample] {
                self.processElectrodermalActivitySamples(samples: electrodermalActivitySamples)
            }
        }
        
        eaQuery.updateHandler = { query, samples, deletedObjects, newAnchor, error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                return
            }
            self.electrodermalActivityAnchor = newAnchor
            if let electrodermalActivitySamples = samples as? [HKQuantitySample] {
                self.processElectrodermalActivitySamples(samples: electrodermalActivitySamples)
            }
        }
        healthStore.execute(eaQuery)
    }
    
    func processHeartRateSamples(samples: [HKQuantitySample]) {
        guard let sample = samples.last else { print("no hr sample"); return }
        let heartRateUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
        let heartRate = sample.quantity.doubleValue(for: heartRateUnit)
        DispatchQueue.main.async {
            self.heartRate = heartRate
            self.sendHealthData()
        }
    }
    
    func processHeartRateVariabilitySamples(samples: [HKQuantitySample]) {
        guard let sample = samples.last else { print("no hrv sample"); return }
        let heartRateVariabilityUnit = HKUnit.secondUnit(with: .milli)
        let heartRateVariability = sample.quantity.doubleValue(for: heartRateVariabilityUnit)
        DispatchQueue.main.async {
            self.heartRateVariability = heartRateVariability
            print("Herzratenvariabilität Rückgabewert:", heartRateVariability)
            self.sendHealthData()
        }
    }
    
    func processBodyTemperatureSamples(samples: [HKQuantitySample]) {
        guard let sample = samples.last else { print("no bt sample"); return }
        let bodyTemperatureUnit = HKUnit.degreeCelsius()
        let bodyTemperature = sample.quantity.doubleValue(for: bodyTemperatureUnit)
        DispatchQueue.main.async {
            self.bodyTemperature = bodyTemperature
            self.sendHealthData()
        }
    }
    
    func processOxygenSaturationSamples(samples: [HKQuantitySample]) {
        guard let sample = samples.last else { print("no os sample"); return }
        let oxygenSaturationUnit = HKUnit.percent()
        let oxygenSaturation = sample.quantity.doubleValue(for: oxygenSaturationUnit)
        DispatchQueue.main.async {
            self.oxygenSaturation = oxygenSaturation
            self.sendHealthData()
        }
    }
    
    func processBloodPressureSamples() {
        guard let systolic = systolicPressure, let diastolic = diastolicPressure else {
            return
        }
        
        // Hier können Sie den tatsächlichen Blutdruck berechnen oder verarbeiten
        let bloodPressureString = "\(systolic)/\(diastolic) mmHg"
        
        // Aktualisieren Sie die UI oder senden Sie die Daten an Ihre iOS-App
        DispatchQueue.main.async {
            self.bloodPressure = bloodPressureString
        }
    }
    
    func processElectrodermalActivitySamples(samples: [HKQuantitySample]) {
        guard let sample = samples.last else { print("no ea sample"); return }
        let electrodermalAvtivityUnit = HKUnit.siemen()
        let electrodermalActivity = sample.quantity.doubleValue(for: electrodermalAvtivityUnit)
        DispatchQueue.main.async {
            self.electrodermalActivity = electrodermalActivity
            self.sendHealthData()
        }
    }
    
    func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(
            timeInterval: 10.0,
            target: self,
            selector: #selector(sendHealthData),
            userInfo: nil,
            repeats: true
        )
    }
    
    @objc func sendHealthData() {
        let heartRateString = String(format: "%.1f", self.heartRate)
        let heartRateVariabilityString = String(format: "%.1f", self.heartRateVariability)
        let bodyTemperatureString = String(format: "%.1f", self.bodyTemperature)
        let oxygenSaturationString = String(format: "%.1f", self.bodyTemperature)
        let ageString = String(self.age)
        let electrodermalActivityString = String(self.electrodermalActivity)
        
        print("----------------------------------------------------")
        print("Data package for iOS App:")
        print("Gender:                  \(self.gender)")
        print("Age:                     \(ageString)")
        print("Heart Rate:              \(heartRateString) bpm")
        print("Heart Rate Variability:  \(heartRateVariabilityString) ms")
        print("Body Temperature:        \(bodyTemperatureString) °C")
        print("Oxygen Saturation:       \(oxygenSaturationString) %")
        print("Blood Pressure:          \(self.bloodPressure) mmHg")
        print("Electrodermal Activity:  \(electrodermalActivityString) Siemens")
        
        self.sendData.sendHealthDataToPhone(
            heartRate: heartRateString,
            heartRateVariability: heartRateVariabilityString,
            age: ageString,
            gender: self.gender
        )
    }
    
    deinit {
        timer?.invalidate()
    }
    
    func enableBackgroundDelivery() {
        healthStore.enableBackgroundDelivery(for: heartRateType, frequency: .immediate) { (success, error) in
            if success {
                print("Enabled background delivery for heart rate")
            } else {
                print("Failed to enable background delivery: \(String(describing: error?.localizedDescription))")
            }
        }
        healthStore.enableBackgroundDelivery(for: heartRateVariabilityType, frequency: .immediate) { (success, error) in
            if success {
                print("Enabled background delivery for heart rate variability")
            } else {
                print("Failed to enable background delivery: \(String(describing: error?.localizedDescription))")
            }
        }
        healthStore.enableBackgroundDelivery(for: bodyTemperatureType, frequency: .immediate) { (success, error) in
            if success {
                print("Enabled background delivery for body temperature")
            } else {
                print("Failed to enable background delivery: \(String(describing: error?.localizedDescription))")
            }
        }
        healthStore.enableBackgroundDelivery(for: oxygenSaturationType, frequency: .hourly) { (success, error) in
            if success {
                print("Enabled background delivery for oxygen saturation")
            } else {
                print("Failed to enable background delivery: \(String(describing: error?.localizedDescription))")
            }
        }
        healthStore.enableBackgroundDelivery(for: electrodermalActivityType, frequency: .immediate) { (success, error) in
            if success {
                print("Enabled background delivery for electrodermal activity")
            } else {
                print("Failed to enable background delivery: \(String(describing: error?.localizedDescription))")
            }
        }
    }
}
