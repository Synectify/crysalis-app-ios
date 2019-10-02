//
//  Tlv.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 27/09/2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation

public struct Tlv {
    public let tag: TlvTag
    public let tagRaw: Byte
    public let value: Data
    
    public init (_ tag: TlvTag, value: Data) {
        self.tag = tag
        self.tagRaw = tag.rawValue
        self.value = value
    }
    
    public init (tagRaw: Byte, value: Data) {
        self.tag = TlvTag(rawValue: tagRaw) ?? .unknown
        self.tagRaw = tagRaw
        self.value = value
    }
    
    /// Serialize TLV to Data
    public func serialize() -> Data {
        var bytes = Data()
        let length = value.count
        bytes.reserveCapacity(1 + length)
        bytes.append(tagRaw)
        
        //serialize length
        if length > 0xFE { //long format
            bytes.append(0xFF)
            bytes.append(contentsOf: length.bytes2bigEndian)
        } else if length > 0 { //short format
            let lengthAsByte = length.byte
            bytes.append(lengthAsByte)
        } else {
            bytes.append(0x00)
        }
        
        //serialize data
        bytes.append(contentsOf: value)
        return bytes
    }
    
    /// Try to deserialize raw data to array of tlv items
    /// - Parameter data: raw TLV-array
    fileprivate static func deserialize(_ data: Data) -> [Tlv]? {
        let dataStream = InputStream(data: data)
        dataStream.open()
        
        var tags = [Tlv]()
        while dataStream.hasBytesAvailable {
            guard let tagCode = dataStream.readByte() else {
                print("Failed to read tag code")
                return nil
            }
            
            guard let dataLength = readTagLength(dataStream) else {
                return nil
            }
            
            guard let data = dataLength > 0 ? dataStream.readBytes(count: dataLength) : Data() else {
                print("Failed to read tag data")
                return nil
            }
            
            let tlvItem = Tlv(tagRaw: tagCode, value: data)
            tags.append(tlvItem)
        }
        
        dataStream.close()
        return tags
    }
    
    /// Helper method. Try to read length from dataStream
    /// - Parameter dataStream: dataStream initialized with raw tlv
    private static func readTagLength(_ dataStream: InputStream) -> Int? {
        guard let shortLengthBytes = dataStream.readByte() else {
            print("Failed to read tag lenght")
            return nil
        }
        
        if (shortLengthBytes == 0xFF) {
            guard let longLengthBytes = dataStream.readBytes(count: 2) else {
                print("Failed to read tag long lenght")
                return nil
            }
            
            return Int(lengthValue: longLengthBytes)
        } else {
            return Int(lengthValue: Data([shortLengthBytes]))
        }
    }
}

extension Array where Element == Tlv {    
    /// Serialize array of tlv items to Data
    /// - Parameter array: tlv array
    public func serialize() -> Data {
        return Data(self.reduce([], { $0 + $1.serialize() }))
    }
    
    /// Deserialize raw tlv data to array of tlv items
    /// - Parameter data: Raw TLV data
    public init?(_ data: Data) {
        guard let tlvArray = Tlv.deserialize(data) else {
            return nil
        }
        
        self = tlvArray
    }
}
