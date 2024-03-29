//
//  TokenItems+Array.swift
//  Tangem Tap
//
//  Created by Alexander Osokin on 28.02.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

extension Array where Element == TokenItem {
    mutating func remove(token: Token) {
        if let index = firstIndex(where: { $0.token == token }) {
            remove(at: index)
        }
    }
    
    mutating func remove(blockchain: Blockchain) {
        if let index = firstIndex(where: { $0.blockchain == blockchain }) {
            remove(at: index)
        }
    }
    
    mutating func remove(_ tokenItem: TokenItem) {
        if let index = firstIndex(where: { $0 == tokenItem }) {
            remove(at: index)
        }
    }
}
