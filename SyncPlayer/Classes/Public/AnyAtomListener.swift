//
//  AnyAtomListener.swift
//  SyncPlayer
//
//  Created by xuyunshi on 2022/6/2.
//

import Foundation

/// A cancelable listener class.
@objc
public class AnyAtomListener: NSObject, AtomListener {
    public init(cancelCallBack: @escaping (() -> Void)) {
        self.cancelCallBack = cancelCallBack
    }
    
    public let cancelCallBack: (()->Void)
    
    @objc
    public func cancel() {
        cancelCallBack()
    }
}
