//
//  TerminalKeysManager.swift
//  TangemKit
//
//  Created by Alexander Osokin on 23/09/2019.
//  Copyright © 2019 Smart Cash AG. All rights reserved.
//

import Foundation

struct TerminalKeysManager {
    public static let enabled = false
    private let secureStorage = SecureStorageManager()
    
    func getKeys() -> CryptoKeyPair? {
        guard TerminalKeysManager.enabled else {
            return nil
        }
        
        if let privateKey = secureStorage.get(key: StorageKey.terminalPrivateKey.rawValue) as? Data,
            let publicKey = secureStorage.get(key: StorageKey.terminalPublicKey.rawValue) as? Data {
            return CryptoKeyPair(privateKey: privateKey, publicKey: publicKey)
        }
        
        if let newKeys = CryptoUtils.getCryproKeyPair() {
            secureStorage.store(object: newKeys.privateKey, key: StorageKey.terminalPrivateKey.rawValue)
            secureStorage.store(object: newKeys.publicKey, key: StorageKey.terminalPublicKey.rawValue)
            return newKeys
        }
        
        return nil
    }
}