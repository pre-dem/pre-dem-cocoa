//
//  PREDLogger.swift
//  AFNetworking
//
//  Created by 王思宇 on 30/09/2017.
//

import Foundation
import CocoaLumberjack

public func PREDLogError(_ message: @autoclosure () -> String, tag: Any? = nil, file: StaticString = #file, function: StaticString = #function, line: UInt = #line) {
    DDLogError(message, file: file, function: function, line: line, tag: tag, ddlog: PREDLog.sharedInstance)
}

public func PREDLogWarn(_ message: @autoclosure () -> String, tag: Any? = nil, file: StaticString = #file, function: StaticString = #function, line: UInt = #line) {
    DDLogWarn(message, file: file, function: function, line: line, tag: tag, ddlog: PREDLog.sharedInstance)
}

public func PREDLogInfo(_ message: @autoclosure () -> String, tag: Any? = nil, file: StaticString = #file, function: StaticString = #function, line: UInt = #line) {
    DDLogInfo(message, file: file, function: function, line: line, tag: tag, ddlog: PREDLog.sharedInstance)
}

public func PREDLogDebug(_ message: @autoclosure () -> String, tag: Any? = nil, file: StaticString = #file, function: StaticString = #function, line: UInt = #line) {
    DDLogDebug(message, file: file, function: function, line: line, tag: tag, ddlog: PREDLog.sharedInstance)
}

public func PREDLogVerbose(_ message: @autoclosure () -> String, tag: Any? = nil, file: StaticString = #file, function: StaticString = #function, line: UInt = #line) {
    DDLogVerbose(message, file: file, function: function, line: line, tag: tag, ddlog: PREDLog.sharedInstance)
}
