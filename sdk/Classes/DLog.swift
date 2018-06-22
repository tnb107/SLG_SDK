//
//  Log.swift
//  sdk
//
//  Created by Apple on 9/18/17.
//  Copyright © 2017 slg. All rights reserved.
//

import Foundation

public class DLog {
    //
    static var isDebug: Bool = true
    
    public static func log(message: Any) -> Void {
        if isDebug {
            print(message)
        }
    }
}
