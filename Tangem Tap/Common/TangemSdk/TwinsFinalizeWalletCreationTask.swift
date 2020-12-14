//
//  TwinsFinalizeWalletCreationTask.swift
//  Tangem Tap
//
//  Created by Andrew Son on 25/11/20.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import TangemSdk

class TwinsFinalizeWalletCreationTask: CardSessionRunnable {
	
	private let fileToWrite: Data
	
	var requiresPin2: Bool { true }
	
	init(fileToWrite: Data) {
		self.fileToWrite = fileToWrite
	}
	
	func run(in session: CardSession, completion: @escaping CompletionResult<TapScanTaskResponse>) {
		let task = WriteFileCommand(dataToWrite: FileDataProtectedByPasscode(data: fileToWrite))
		task.run(in: session, completion: { (result) in
			switch result {
			case .success:
				self.readCard(in: session, completion: completion)
			case .failure(let error):
				completion(.failure(error))
			}
		})
	}
	
	func readCard(in session: CardSession, completion: @escaping CompletionResult<TapScanTaskResponse>) {
		let task = TapScanTask()
		task.run(in: session, completion: completion)
	}
	
}