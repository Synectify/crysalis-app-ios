//
//  Task.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 02/10/2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation

public enum TaskError: Error {
    case unknownStatus(sw: UInt16)
    case cardReaderNotSet
}

@available(iOS 13.0, *)
public protocol Task: class {
    associatedtype TaskResult
    
    var cardReader: CardReader? {get set}
    var delegate: CardManagerDelegate? {get set}

    func run(with environment: CardEnvironment, completion: @escaping (CompletionResult<TaskResult>, CardEnvironment?) -> Void )
}

@available(iOS 13.0, *)
extension Task {
    func sendCommand<AnyCommandSerializer>(_ commandSerializer: AnyCommandSerializer, environment: CardEnvironment, completion: @escaping (CompletionResult<TaskResult>, CardEnvironment?) -> Void)
        where AnyCommandSerializer: CommandSerializer {
            guard let reader = cardReader else {
                completion(.failure(TaskError.cardReaderNotSet), nil)
                return
            }
               
            let commandApdu = commandSerializer.serialize(with: environment)
            reader.send(commandApdu: commandApdu) { commandResponse in
                switch commandResponse {
                case .success(let responseApdu):
                    guard let status = responseApdu.status else {
                        completion(.failure(TaskError.unknownStatus(sw: responseApdu.sw)), nil)
                        return
                    }
                    //TODO: parse error
                   /* switch status {
                        
                    case .processCompleted:
                        <#code#>
                    case .pinsNotChanged:
                        <#code#>
                    case .invalidParams:
                        <#code#>
                    case .errorProcessingCommand:
                        <#code#>
                    case .invalidState:
                        <#code#>
                    case .insNotSupported:
                        <#code#>
                    case .needEcryption:
                        <#code#>
                    case .needPause:
                        <#code#>
                    case .pin1Changed:
                        <#code#>
                    case .pin2Changed:
                        <#code#>
                    case .pin3Changed:
                        <#code#>
                    }
                    
                    completion(.success())
                     */
                    break
                case .failure(let error):
                    completion(.failure(error), nil)
                }
            }
    }
}
