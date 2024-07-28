//
//  ContentView.swift
//  CYM
//
//  Created by Manuel Keck on 23.05.24.
//

import SwiftUI
import AVFoundation

struct ContentView: View {
    @State private var heartrate: String = ""
    @State private var heartratevariability: String = ""
    @State private var bloodpressure: String = ""
    @State private var submitText: String = ""
    @State private var token: String = UserDefaults.standard.string(forKey: "token") ?? ""
    @State private var previousRange: Double? = nil
    @State private var animate = false
    @State private var mood = ""
    @State private var pulsate = false
    @State private var gender: String = ""
    @State private var age: String = ""

    @StateObject private var watchConnector = WatchConnector()
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black
                    .edgesIgnoringSafeArea(.all)
                
                VStack {
                    Spacer()
                    
                    if !watchConnector.isReachable {
                        Image(systemName: "applewatch")
                            .resizable()
                            .frame(width: 35, height: 50)
                            .foregroundColor(.white)
                            .padding()
                            .scaleEffect(pulsate ? 1.3 : 1.0) 
                            .animation(Animation.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: pulsate)
                            .onAppear {
                                pulsate = true
                            }
                        
                        Text("Please open the corresponding app on your Apple Watch.")
                            .padding()
                            .foregroundColor(.gray)
                            .font(.headline)
                            .multilineTextAlignment(.center)
                    } else {
                        VStack {
                            if token != "" {
                                Image(systemName: "network")
                                    .resizable()
                                    .frame(width: 30, height: 30)
                                    .foregroundColor(.white)
                                Text("Moodify")
                                    .foregroundColor(.white)
                            } else {
                                Image(systemName: "network")
                                    .resizable()
                                    .frame(width: 30, height: 30)
                                    .foregroundColor(.red)
                                Text("Please go to Settings and provide a valid Auth0 key.")
                                    .foregroundColor(.red)
                                    .multilineTextAlignment(.center)
                            }
                            
                            Spacer()
                            
                            let tmp_mood = mood
                                                        
                            if #available(iOS 17.0, *) {
                                Text(tmp_mood)
                                    .padding()
                                    .foregroundColor(.blue)
                                    .phaseAnimator([0, 1, 3]) { content, phase in content
                                            .scaleEffect(phase)
                                            .opacity(phase == 1 ? 1 : 0)
                                            .offset(y: phase == 3 ? -200 : 0)
                                    } animation: { phase in
                                            .easeIn(duration: 2)
                                    }
                            } else {
                                // Fallback on earlier versions
                            }
                                                                    
                            Image(systemName: "iphone")
                                .resizable()
                                .frame(width: 40, height: 70)
                                .foregroundColor(.white)
                                .padding()
                                
                            Text("Age: \(watchConnector.age)")
                                .foregroundStyle(.white)
                                .font(.footnote)
                            Text("Gender: \(watchConnector.gender)")
                                .foregroundStyle(.white)
                                .font(.footnote)
                            Text("Heart Rate: ~\(watchConnector.heartRate) bpm")
                                .foregroundStyle(.white)
                                .font(.footnote)
                            Text("Heart Rate Variability: ~\(watchConnector.heartRateVariability) ms")
                                .foregroundStyle(.white)
                                .font(.footnote)
                            
                            Spacer()
                        }
                        .onAppear {
                            self.animate = true
                        }
                    }
                    
                    Spacer()
                                        
                    Text("Open https://changeyourmood.vercel.app to get music recommendations based on your determined energy level.")
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white)
                        .padding(.bottom, 20)
                }
                .onChange(of: watchConnector.heartRate) { newHeartRate in
                    heartrate = newHeartRate
                    if let newHeartRateDouble = Double(newHeartRate) {
                        let newRange = heartRateRange(for: newHeartRateDouble)
                        if newRange != previousRange {
                            previousRange = newRange
                            Task {
                                do {
                                    print("Execute task with HR: \(newHeartRate) bpm and HRV: \(heartratevariability) ms")
                                    mood = try await OpenAIService.shared.sendPromptToChatGPT(
                                        user_heartrate: newHeartRate,
                                        user_heartratevariability: heartratevariability,
                                        user_gender: gender,
                                        user_age: age,
                                        auth0Token: token
                                    )
                                    
                                } catch {
                                    print("Error: \(error.localizedDescription)")
                                }
                            }
                        }
                    }
                }
                .onChange(of: watchConnector.heartRateVariability) { newHeartRateVariability in
                    heartratevariability = newHeartRateVariability
                }
                .onChange(of: heartrate) { newHeartRate in
                    
                }
                .padding()
            }
            .navigationBarItems(trailing: NavigationLink(destination: SettingsView(token: $token)) {
                Image(systemName: "gear")
                    .imageScale(.large)
                    .foregroundColor(.blue)
            })
            .onAppear {
                if let initialHeartRateDouble = Double(watchConnector.heartRate) {
                    let initialRange = heartRateRange(for: initialHeartRateDouble)
                    previousRange = initialRange
                    Task {
                        do {
                            print("Execute initial task with heart rate: \(watchConnector.heartRate)")
                            var tmp_heartrate = watchConnector.heartRate
                            
                            //tmp_heartrate = "80"
                            
                            mood = try await OpenAIService.shared.sendPromptToChatGPT(
                                user_heartrate: tmp_heartrate,
                                user_heartratevariability: heartratevariability,
                                user_gender: gender,
                                user_age: age,
                                auth0Token: token
                            )
                        } catch {
                            print("Error: \(error.localizedDescription)")
                        }
                    }
                }
            }
        }
    }
    
    func startAnimationLoop() {
            // Start the animation loop with initial delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                animate = true
                
                Timer.scheduledTimer(withTimeInterval: 3.5, repeats: true) { _ in
                    // Animate the text upwards and fade it out
                    withAnimation(.easeInOut(duration: 2)) {
                        self.animate = true
                    }
                    
                    // Reset the position after the fade-out
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        self.animate = false
                    }
                }
            }
        }
    
    func heartRateRange(for heartRate: Double) -> Double {
        switch heartRate {
        case ..<50:
            return 0
        case 50..<60:
            return 1
        case 60..<70:
            return 2
        case 70..<100:
            return 3
        default:
            return 4
        }
    }
}

struct SettingsView: View {
    @Binding var token: String
    @State private var isShowingScanner = false
    @State private var showConfirmation = false
    @State private var confirmationMessage = ""

    var body: some View {
        ZStack {
            Color.black
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                Spacer()
                HStack {
                    TextField("Enter your Auth0 key", text: $token)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .background(Color.black)
                        .cornerRadius(8)
                        .padding(.horizontal, 10)
                    
                    Button(action: {
                        isShowingScanner = true
                    }) {
                        Image(systemName: "qrcode.viewfinder")
                            .imageScale(.large)
                            .foregroundColor(.blue)
                    }
                    .sheet(isPresented: $isShowingScanner) {
                        QRCodeScannerView { result in
                            switch result {
                            case .success(let code):
                                self.token = code
                            case .failure(let error):
                                print("Scanning failed: \(error.localizedDescription)")
                            }
                            isShowingScanner = false
                        }
                    }
                }
                
                Button(action: {
                    if token.hasPrefix("auth") {
                        UserDefaults.standard.set(token, forKey: "token")
                        confirmationMessage = "✅ Auth0 key saved"
                    } else {
                        confirmationMessage = "❌ Please provide a valid Auth0 key"
                    }
                    withAnimation {
                        showConfirmation = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                        withAnimation {
                            showConfirmation = false
                        }
                    }
                }) {
                    Text("Save Token")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding(.top, 20)
                
                Spacer()
            }
            .padding()

            if showConfirmation {
                VStack {
                    Spacer()
                    Text(confirmationMessage)
                        .padding()
                        .foregroundColor(.white)
                        .transition(AnyTransition.opacity.animation(.easeInOut(duration:0.4)))
                        .padding(.bottom, 50)
                        
                }
            }
        }
        .navigationTitle("Settings")
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(token: .constant(""))
    }
}

struct QRCodeScannerView: UIViewControllerRepresentable {
    class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
        var parent: QRCodeScannerView
        var completion: (Result<String, Error>) -> Void

        init(parent: QRCodeScannerView, completion: @escaping (Result<String, Error>) -> Void) {
            self.parent = parent
            self.completion = completion
        }

        func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
            if let metadataObject = metadataObjects.first {
                guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
                guard let stringValue = readableObject.stringValue else { return }
                AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
                completion(.success(stringValue))
            }
        }
    }

    var completion: (Result<String, Error>) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self, completion: completion)
    }

    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()
        let captureSession = AVCaptureSession()

        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return viewController }
        let videoInput: AVCaptureDeviceInput

        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return viewController
        }

        if (captureSession.canAddInput(videoInput)) {
            captureSession.addInput(videoInput)
        } else {
            return viewController
        }

        let metadataOutput = AVCaptureMetadataOutput()

        if (captureSession.canAddOutput(metadataOutput)) {
            captureSession.addOutput(metadataOutput)

            metadataOutput.setMetadataObjectsDelegate(context.coordinator, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        } else {
            return viewController
        }

        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = viewController.view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        viewController.view.layer.addSublayer(previewLayer)

        captureSession.startRunning()

        return viewController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}
