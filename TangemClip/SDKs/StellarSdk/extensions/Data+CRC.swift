//
//  Data+CRC.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 29/01/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/**
 CRC-CCITT (XModem)
 [http://www.lammertbies.nl/comm/info/crc-calculation.html]()
 
 [http://web.mit.edu/6.115/www/amulet/xmodem.htm]()
 */
private func CRCCCITTXModem(_ bytes: Data) -> UInt16 {
    var crc: UInt16 = 0
    
    for byte in bytes {
        crc ^= UInt16(byte) << 8
        
        for _ in 0..<8 {
            if crc & 0x8000 != 0 {
                crc = crc << 1 ^ 0x1021
            } else {
                crc = crc << 1
            }
        }
    }
    
    return crc
}


extension UInt8 {
    func crc16() -> UInt16 {
        return CRCCCITTXModem(Data([self]))
    }
}


extension Data {
    func stellarCrc16() -> UInt16 {
        return CRCCCITTXModem(self)
    }
    
    func crcValid() -> Bool {
        return CRCCCITTXModem(subdata(in: 0..<count-2)) == self.subdata(in: count-2..<count).withUnsafeBytes { $0.pointee }
    }
    
    func crc16Data() -> Data {
        var crc = stellarCrc16()
        let crcData = Data(bytes: &crc, count: MemoryLayout.size(ofValue: crc))
        
        let checksumedData = NSMutableData(data: self)
        checksumedData.append(crcData)
        
        return checksumedData as Data
    }
    
}
