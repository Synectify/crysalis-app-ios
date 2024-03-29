//
//  SignerUtils.swift
//  Tangem Tap
//
//  Created by Andrew Son on 18/12/20.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

struct SignerUtils {
    private static var issuers: [KeyPair] = {
        let path = Bundle.main.url(forResource: "issuers", withExtension: "json")!
        let fileData = try! Data(contentsOf: path)
        return try! JSONDecoder.tangemSdkDecoder.decode([KeyPair].self, from: fileData)
    }()
    
    /// PROD
    static var signerKeys: KeyPair = {
        return issuers.first(where: {$0.id == "TANGEM"})!
    }()
    
    
    /// DEV
//    static var signerKeys: KeyPair = {
//        return issuers.first(where: {$0.id == "TANGEM SDK"})!
//    }()
}

struct KeyPair: Equatable, Codable {
    let id: String
    let privateKey: Data
    let publicKey: Data
}
