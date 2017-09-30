//
//  PREDLogger.swift
//  AFNetworking
//
//  Created by 王思宇 on 30/09/2017.
//

import Foundation
import CocoaLumberjack

public func PREDLogError(_ message: @autoclosure () -> String) {
    DDLogError(message)
}

public func PREDLogWarn(_ message: @autoclosure () -> String) {
    DDLogWarn(message)
}

public func PREDLogInfo(_ message: @autoclosure () -> String) {
    DDLogInfo(message)
}

public func PREDLogDebug(_ message: @autoclosure () -> String) {
    DDLogDebug(message)
}

public func PREDLogVerbose(_ message: @autoclosure () -> String) {
    DDLogVerbose(message)
}

public func PREDTagLogError(tag: Any, message: @autoclosure () -> String) {
    DDLogVerbose(message, tag:tag)
}

public func PREDTagLogWarn(tag: Any, message: @autoclosure () -> String) {
    DDLogWarn(message, tag:tag)
}

public func PREDTagLogInfo(tag: Any, message: @autoclosure () -> String) {
    DDLogInfo(message, tag:tag)
}

public func PREDTagLogDebug(tag: Any, message: @autoclosure () -> String) {
    DDLogDebug(message, tag:tag)
}

public func PREDTagLogVerbose(tag: Any, message: @autoclosure () -> String) {
    DDLogVerbose(message, tag:tag)
}
