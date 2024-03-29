//
//  BinanceNetworkService.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 15.02.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class BinanceNetworkService {
    let binance: BinanceChain
    let testnet: Bool
    
    init(isTestNet:Bool) {
        self.testnet = isTestNet
        binance = isTestNet ? BinanceChain(endpoint: BinanceChain.Endpoint.testnet):
            BinanceChain(endpoint: BinanceChain.Endpoint.mainnet)
    }
    
    func getInfo(address: String) -> AnyPublisher<BinanceInfoResponse, Error> {
        let future = Future<BinanceInfoResponse,Error> {[unowned self] promise in
            self.binance.account(address: address) { response in
                if let error = response.getError() {
                    promise(.failure(error))
                    return
                }
               
                let balances = response.account.balances.reduce(into: [:]) { result, balance in
                    result[balance.symbol] = Decimal(balance.free)
                }
                
                let accountNumber = response.account.accountNumber
                let sequence = response.account.sequence
                let info = BinanceInfoResponse(balances: balances, accountNumber: accountNumber, sequence: sequence)
                promise(.success(info))
            }
        }
        return AnyPublisher(future)
    }
}


extension BinanceChain.Response {
    func getError() -> Error? {
        if self.error?.localizedDescription.lowercased().contains("account not found") ?? false {
            return WalletError.noAccount(message: "no_account_bnb".localized)
        } else {
            return error
        }
    }
}

struct BinanceInfoResponse {
    let balances: [String:Decimal]
    let accountNumber: Int
    let sequence: Int
}
