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
    static let getUserInfo = root + "apiv1/user/get-user-info"
    static let changePass = root + "apiv1/user/change-pass"
    static let login = root + "apiv1/user/login"
    static let facebookLogin = root + "apiv1/user/facebook/login"
    static let googleLogin = root + "apiv1/user/google/login"
    static let deviceLogin = root + "apiv1/user/device/login"
    static let register = root + "apiv1/user/register"
    static let validateAccessToken  = root + "apiv1/oauth/validate-access-token"
    static let userInformation = root + "apiv2/user/information"
    static let changeInformation = root + "apiv2/user/change-information"
    static let verifyiap = root + "apiv1/verify-iap/ios"
    static let productApple = root + "apiv2/product/apple_product_list" 
    static let rootCdn = "https://store-slg.cdn.vccloud.vn/portal/"

    //env (optional) 1 = product, 0 = sandbox
    static let envProduct = 1
    static let envSandbox = 0
    
    static let osId = 2
}
