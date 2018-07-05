//
//  Define.swift
//  sdk
//
//  Created by Apple on 9/18/17.
//  Copyright © 2017 slg. All rights reserved.
//

import Foundation 
class Define {
    static let root = "https://api.slg.vn/"
    static let register = root + "v3/user/register"
    static let login = root + "v3/user/login"
    static let refreshToken = root + "v3/user/refresh-token"
    static let getUserInfo = root + "v3/user"//thông tin người dùng
    static let changePass = root + "v3/user/change-password"
    static let updateAccount = root + "v3/user/set-email-password-device"
    static let deviceLogin = root + "v3/user/login-device"
    static let productApple = root + "v3/mobile-items"
    static let saveFirebaseToken = root + "v3/user/save-firebase-token"
    static let facebookLogin = root + "v3/user/login-facebook"
    static let googleLogin = root + "v3/user/login-google"
    static let changeInformation = root + "v3/user/change-information"
    
    static let validateAccessToken  = root + "apiv1/oauth/validate-access-token"
    static let userInformation = root + "apiv2/user/information"
    static let verifyiap = root + "apiv1/verify-iap/ios"
    static let rootCdn = "https://store-slg.cdn.vccloud.vn/portal/"

    //env (optional) 1 = product, 0 = sandbox
    static let envProduct = 1
    static let envSandbox = 0
    
    static let osId = 1
}
