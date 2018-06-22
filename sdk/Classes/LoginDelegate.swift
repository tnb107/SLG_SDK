//
//  LoginDelegate.swift
//  sdk
//
//  Created by Apple on 9/19/17.
//  Copyright © 2017 slg. All rights reserved.
//

import Foundation

public protocol LoginDelegate {
    func responseLogin(issuccess: Bool,response: Any?, message: String?,errorCode: Int?, user: User?)
}
