//
//  BinanceError.swift
//  TangemClip
//
//  Created by Andrew Son on 20/04/21.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

public class BinanceError: Error, LocalizedError {
    
    public enum Reason: Int {
        case unknown = 0
        init(_ code: Int) {
            self = .unknown
        }
    }

    public var code: Int = 0
    public var reason: Reason = .unknown
    private var message: String = ""

    required init(_ reason: Reason, message: String) {
        self.reason = reason
        self.message = message
    }

    convenience init(code: Int, message: String) {
        self.init(Reason(code), message: message)
        self.code = code
    }

    convenience init(message: String) {
        self.init(.unknown, message: message)
    }
    
    // MARK: - Error

    public var errorDescription: String? {
        return self.message
    }
    
}
