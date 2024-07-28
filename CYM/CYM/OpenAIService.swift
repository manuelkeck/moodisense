//
//  OpenAIService.swift
//  CYM
//
//  Created by Manuel Keck on 23.05.24.
//

import Foundation

enum HTTPMethod: String {
    case post = "POST"
    case get = "GET"
}

class OpenAIService {
    static let shared = OpenAIService()
    
    private init () { }
    
    private func generateURLRequest(httpMethod: HTTPMethod, user_heartrate: String, user_heartratevariability: String, user_gender: String, user_age: String) throws -> URLRequest {
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            throw URLError(.badURL)
        }
        
        var urlRequest = URLRequest(url: url)
        
        // Method
        urlRequest.httpMethod = httpMethod.rawValue
        
        // Header
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.addValue("Bearer \(Secrets.apiKey)", forHTTPHeaderField: "Authorization")
        
        // Body
        
        // let systemMessage = GPTMessage(role: "system", content: "You are an expert for neuroscience and can transform vital data into mood or emotion verbs.")
        // let systemMessage = GPTMessage(role: "system", content: "You are an expert in automotive neuroscience. Transform the given heart rate data into an energy state that fits a parabolic mood curve. The curve represents energy states as follows: 'no energy' (left low), 'too little energy' (left middle), 'optimal energy' (peak), 'pent-up energy' (right middle), and 'blocked energy' (right low).")
        let systemMessage = GPTMessage(
            role: "system",
            content: """
            You are an expert in automotive neuroscience. Transform the given heart rate, and heart rate variability data, based on the given age and gender into an energy state that fits a parabolic mood curve, considering that the measurements are taken while driving. The curve represents energy states as follows: 'no energy' (left low), 'too little energy' (left middle), 'optimal energy' (peak), 'pent-up energy' (right middle), and 'blocked energy' (right low). Consider the following flexible guidelines:

            - Heart Rate: Generally, lower heart rates (below 50 bpm) can indicate 'no energy', while slightly higher rates (50-60 bpm) might suggest 'too little energy'. Moderate rates (60-70 bpm) are often associated with 'optimal energy'. Higher rates (70-100 bpm) might indicate 'pent-up energy', and very high rates (above 100 bpm) could be a sign of 'blocked energy'.
            - Heart Rate Variability (HRV): Higher HRV typically indicates better autonomic function, which can correspond to 'optimal energy' or 'pent-up energy'. Lower HRV might suggest stress or fatigue, potentially leading to 'blocked energy' or 'no energy', depending on the heart rate.

            Use these guidelines to classify the energy state of a driver. Consider the interaction between heart rate and HRV, as well as the context of driving, to determine the most appropriate energy state.
            """
        )

        // let userMessage = GPTMessage(role: "user", content: message)
        // let userMessage = GPTMessage(role: "user", content: "Derive the energy state based on the following heart rate data: \(message).")
        let userMessage = GPTMessage(
            role: "user",
            content: """
            Here are my latest health metrics:
            - Gender: \(user_gender)
            - Age: \(user_age)
            - Heart Rate: \(user_heartrate) bpm
            - HRV: \(user_heartratevariability) ms

            Determine my energy level based on the provided data. Keep in mind, that the vital data is measured in a driving situation.
            """
        )

        // let mood = GPTFunctionProp(type: "string", description: "The most likely mood or emotion derived for the given heart rate value.")
        let energyState = GPTFunctionProp(type: "string", description: "The derived energy state while driving based on the given vital data, following the parabolic curve of energy states.")

        let params: [String: GPTFunctionProp] = [
            // "mood": mood
            "energy_state": energyState
        ]
        let functionParams = GPTFunctionParam(type: "object", properties: params, required: ["energy_state"])
        
        // let function = GPTFunction(name: "get_energy_state", description: "Get the suspected emotion or mood for a given heart rate.", parameters: functionParams)
        let function = GPTFunction(name: "get_energy_state", description: "Get the derived energy state while driving for given vital data, based on a parabolic energy curve.", parameters: functionParams)
        
        let payload = GPTChatPayload(model: "gpt-3.5-turbo-0125", messages: [systemMessage, userMessage], functions: [function])
        //let payload = GPTChatPayload(model: "gpt-4o", messages: [systemMessage, userMessage], functions: [function])
        
        // Encode
        let jsonData = try JSONEncoder().encode(payload)
        
        urlRequest.httpBody = jsonData
                        
        return urlRequest
    }
    
    func sendPromptToChatGPT(user_heartrate: String, user_heartratevariability: String, user_gender: String, user_age: String, auth0Token: String) async throws -> String {
        let urlRequest = try generateURLRequest(
            httpMethod: .post,
            user_heartrate: user_heartrate,
            user_heartratevariability: user_heartratevariability,
            user_gender: user_gender,
            user_age: user_age
        )
        let (data, _) = try await URLSession.shared.data(for: urlRequest)
        
        // Decode
        let result = try JSONDecoder().decode(GPTResponse.self, from: data)
        let args = result.choices[0].message.functionCall.arguments
        guard let argData = args.data(using: .utf8) else {
            throw URLError(.badURL)
        }
                
        let mood = try JSONDecoder().decode(MoodResponse.self, from: argData)
        
        print("Mood: \(mood)")
                
        // Send mood to database
        sendMoodToMoodify(mood: mood.energy_state, auth0Token: auth0Token)
        
        return mood.energy_state
    }
    
    func sendMoodToMoodify(mood: String, auth0Token: String) {
        //guard let url = URL(string: "http://localhost:3000/api/mood-connector") else {
        guard let url = URL(string: "https://changeyourmood.vercel.app/api/mood-connector") else {
            print("Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                
        let body: [String: Any] = [
            // "auth0Sub": "auth0|664c6a628885a45ede5c7198",
            "auth0Sub": auth0Token,
            "prevMood": "",
            "currentMood": mood
        ]
        
        // Create JSON from body
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        } catch {
            print("Error serializing JSON: \(error)")
            return
        }
                
        // URLSession for data task
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error making POST request: \(error)")
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                print("Server error")
                return
            }
            
            if let data = data {
                do {
                    if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                        print("Response: \(jsonResponse)")
                    } else {
                        let responseString = String(data: data, encoding: .utf8)
                        print("Response String: \(responseString ?? "Unable to parse response as String")")
                    }
                } catch {
                    print("Data: \(data)")
                    print("Error processing response data: \(error)")
                }
            }
        }
        
        task.resume()
    }
}
