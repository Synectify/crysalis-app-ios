//
//  Logger.swift
//  Tangem Tap
//
//  Created by Andrew Son on 18/02/21.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

class Logger: TangemSdkLogger {
    
    private let fileManager = FileManager.default
    
    var scanLogFileData: Data? {
        try? Data(contentsOf: scanLogsFileUrl)
    }
    
    private var scanLogsFileUrl: URL {
        fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0].appendingPathComponent("scanLogs.txt")
    }
    
    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss:SSS"
        return formatter
    }()
    
    private var isRecordingLogs: Bool = false
    
    init() {
        try? fileManager.removeItem(at: scanLogsFileUrl)
    }
    
    func log(_ message: String, level: Log.Level) {
        let formattedMessage = "\(self.dateFormatter.string(from: Date())): \(message)\n"
        let messageData = formattedMessage.data(using: .utf8)!
        if let handler = try? FileHandle(forWritingTo: scanLogsFileUrl) {
            handler.seekToEndOfFile()
            handler.write(messageData)
            handler.closeFile()
        } else {
            try? messageData.write(to: scanLogsFileUrl)
        }
    }
}
