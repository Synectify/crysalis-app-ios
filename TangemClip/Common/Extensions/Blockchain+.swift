//
//  Blockchain+.swift
//  TangemClip
//
//  Created by Andrew Son on 24/03/21.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

extension Blockchain: Identifiable {
    public var id: Int { return hashValue }
    
    var imageName: String? {
        switch self {
        case .binance:
            return "binance"
        case .bitcoin:
            return "btc"
        case .bitcoinCash:
            return "btc_cash"
        case .cardano:
            return "cardano"
        case .ethereum:
            return "eth"
        case .litecoin:
            return "litecoin"
        case .rsk:
            return "rsk"
        case .tezos:
            return "tezos"
        case .xrp:
            return "xrp"
        case .stellar:
            return "stellar"
        default:
            return nil
        }
    }
}
