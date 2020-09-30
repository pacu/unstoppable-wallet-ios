//
//  ZcashAdapter.swift
//  UnstoppableWallet
//
//  Created by Francisco Gindre on 9/30/20.
//  Copyright © 2020 Grouvi. All rights reserved.
//

import Foundation

import ZcashLightClientKit
import RxSwift
import HdWalletKit
class ZcashAdapter: IAdapter {
    func start() {
        try? synchronizer.start(retry: false)
    }
    
    func stop() {
        synchronizer.stop()
    }
    
    func refresh() {
        try? synchronizer.start(retry: false)
    }
    
    var debugInfo: String {
        """
        ZcashAdapter address: \(synchronizer.getAddress(accountIndex: 0))
        spendingKeys: \(keys.description)
        balance: \(synchronizer.initializer.getBalance())
        verified balance: \(synchronizer.initializer.getVerifiedBalance())
        """
    }
    
    var synchronizer: SDKSynchronizer
    
    var keys: [String]
    init(wallet: Wallet, syncMode: SyncMode?, derivation: MnemonicDerivation?, testMode: Bool) throws {
        guard case let .mnemonic(words, _) = wallet.account.type else {
            throw AdapterError.unsupportedAccount
        }
        
        
        let initializer = Initializer(cacheDbURL:try! __cacheDbURL(),
                                  dataDbURL: try! __dataDbURL(),
                                  pendingDbURL: try! __pendingDbURL(),
                                  endpoint: LightWalletEndpoint(address: "lightwalletd.electriccoin.co", port: 9067),
                                  spendParamsURL: try! __spendParamsURL(),
                                  outputParamsURL: try! __outputParamsURL(),
                                  loggerProxy: loggingProxy)
        
        guard let spendingKeys = try initializer.initialize(seedProvider: DefaultProvider(words: words), walletBirthdayHeight: BlockHeight.max) else  {
            throw InitializerError.accountInitFailed
        }
        self.keys = spendingKeys
        
        self.synchronizer = try SDKSynchronizer(initializer: initializer)
    }

}


fileprivate struct DefaultProvider: SeedProvider {
    func seed() -> [UInt8] {
        Mnemonic.seed(mnemonic: words).bytes
    }
    
    var words: [String]
    
    init(words: [String]) {
        self.words = words
    }
    
    
}
var loggingProxy = SampleLogger(logLevel: .debug)

func __documentsDirectory() throws -> URL {
    try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
}

func __cacheDbURL() throws -> URL {
    try __documentsDirectory().appendingPathComponent(ZcashSDK.DEFAULT_DB_NAME_PREFIX+ZcashSDK.DEFAULT_CACHES_DB_NAME, isDirectory: false)
}

func __dataDbURL() throws -> URL {
    try __documentsDirectory().appendingPathComponent(ZcashSDK.DEFAULT_DB_NAME_PREFIX+ZcashSDK.DEFAULT_DATA_DB_NAME, isDirectory: false)
}

func __pendingDbURL() throws -> URL {
    try __documentsDirectory().appendingPathComponent(ZcashSDK.DEFAULT_DB_NAME_PREFIX+ZcashSDK.DEFAULT_PENDING_DB_NAME)
}

func __spendParamsURL() throws -> URL {
    Bundle.main.url(forResource: "sapling-spend", withExtension: ".params")!
}

func __outputParamsURL() throws -> URL {
    Bundle.main.url(forResource: "sapling-output", withExtension: ".params")!
}

import os
class SampleLogger: ZcashLightClientKit.Logger {
    enum LogLevel: Int {
        case debug
        case error
        case warning
        case event
        case info
    }
    
    var level: LogLevel
    init(logLevel: LogLevel) {
        self.level = logLevel
    }
    
    private static let subsystem = Bundle.main.bundleIdentifier!
    static let oslog = OSLog(subsystem: subsystem, category: "sample-logs")
    
    func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        guard level.rawValue == LogLevel.debug.rawValue else { return }
        log(level: "DEBUG 🐞", message: message, file: file, function: function, line: line)
    }
    
    func error(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        guard level.rawValue <= LogLevel.error.rawValue else { return }
        log(level: "ERROR 💥", message: message, file: file, function: function, line: line)
    }
    
    func warn(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
           guard level.rawValue <= LogLevel.warning.rawValue else { return }
           log(level: "WARNING ⚠️", message: message, file: file, function: function, line: line)
    }

    func event(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        guard level.rawValue <= LogLevel.event.rawValue else { return }
        log(level: "EVENT ⏱", message: message, file: file, function: function, line: line)
    }
    
    func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        guard level.rawValue <= LogLevel.info.rawValue else { return }
        log(level: "INFO ℹ️", message: message, file: file, function: function, line: line)
    }
    
    private func log(level: String, message: String, file: String, function: String, line: Int) {
        let fileName = file as NSString
        
        os_log("[%@] %@ - %@ - Line: %d -> %@", log: Self.oslog, type: .default, level, fileName.lastPathComponent, function, line, message)
    }
    
    
}
