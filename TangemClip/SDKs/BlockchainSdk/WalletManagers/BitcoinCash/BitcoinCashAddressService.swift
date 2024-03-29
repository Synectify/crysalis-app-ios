//
//  BitcoinCashAddressService.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 14.02.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

public class BitcoinCashAddressService: AddressService {
    public func makeAddress(from walletPublicKey: Data) -> String {
        let compressedKey = Secp256k1Utils.convertKeyToCompressed(walletPublicKey)!
        let prefix = Data([UInt8(0x00)]) //public key hash
        let payload = RIPEMD160.hash(message: compressedKey.sha256())
        let walletAddress = Bech32.encode(prefix + payload, prefix: "bitcoincash")
        return walletAddress
    }
    
    public func validate(_ address: String) -> Bool {
        return (try? BitcoinCashAddress(address)) != nil
    }
}
