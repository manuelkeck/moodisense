//
//  RequestModels.swift
//  CYM
//
//  Created by Manuel Keck on 24.05.24.
//

import Foundation

struct GPTChatPayload: Encodable {
    let model: String
    let messages: [GPTMessage]
    let functions: [GPTFunction]
}

struct GPTMessage: Encodable {
    let role: String
    let content: String
}

struct GPTFunction: Encodable {
    let name: String
    let description: String
    let parameters: GPTFunctionParam
}

struct GPTFunctionParam: Encodable {
    let type: String
    let properties: [String: GPTFunctionProp]?
    let required: [String]?
}

struct GPTFunctionProp: Encodable {
    let type: String
    let description: String
}
