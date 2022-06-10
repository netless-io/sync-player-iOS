//
//  Log.swift
//  SyncPlayer
//
//  Created by xuyunshi on 2022/5/31.
//

import Foundation

/// Indicate if open console log or not
public var showLog = false

/// Use this to trigger log open or not When using OC.
@objc
public class Log: NSObject {
    @objc
    public func set(log: Bool) {
        showLog = log
    }
}
