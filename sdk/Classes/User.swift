//
//  File.swift
//  sdk
//
//  Created by Apple on 9/19/17.
//  Copyright © 2017 slg. All rights reserved.
//

import Foundation
import ObjectMapper
public class User: Mappable {
//    "id" : 4395337,
//    "token_type" : "Bearer",
//    "expires_in" : 3600,
//    "phone" : "",
//    "sex" : "",
//    "identify" : "",
//    "refresh_token" : "jIBWP7tGH3dYvPUTa6uZKmVL2o9WQCtcNnrlbnZe",
//    "avatar" : "",
//    "address" : "",
//    "birthday" : "",
//    "username" : "test123",
//    "fullname" : "",
//    "email" : "default.test123@fpay.vn",
//    "access_token" : "tkDUU8ESDP85Jf7YDDOAiO8thTkuuRRyMxDyH9dV"
    
    public var accessToken: String?
    public var address: String?
    private var _avatar: String?
    public var birthday: String?
    private var _email: String?
    public var expiresIn: Int?
    public var fullname: String?
    public var id: Int?
    private var _identify: String?
    private var _phone: String?
    public var refreshToken: String?
    private var _sex: String?
    public var tokenType: String?
    public var username: String?
    private var _coverImage:String?
    public var provider: String?
    
    public var phone: String? {
        if let myPhone = _phone {
            let index = myPhone.count - 3
            if index > 0 {
                let asterisks: String = String(repeating: "*", count: index)
                let suffix:String = String(myPhone.suffix(3))
                return asterisks + suffix
            }
        }
        return _phone
    }
    
    public var identify: String? {
        if let myIdentify = _identify {
            let index = myIdentify.count - 3
            if index > 0 {
                let asterisks: String = String(repeating: "*", count: index)
                let suffix:String = String(myIdentify.suffix(3))
                return asterisks + suffix
            }
            
        }
        return _identify
    }
    
    public var email: String? {
        if let myEmail = _email {
            let mailPrefix:String = String(myEmail.prefix(upTo: myEmail.index(of: "@")!))
            
            let asterisks: String = String(repeating: "*", count: mailPrefix.count - 3)
            let endSuffix:String = String(mailPrefix.suffix(3))
            
            let newMailPrefix:String = asterisks + endSuffix
            
            let mailSuffix = myEmail[myEmail.index(of: "@")!...]
            
            return  newMailPrefix + mailSuffix;
        }
        return _email
    }
    
    public var sex: String?{
        if let mySex = _sex {
            return (mySex == "1") ? "Nam" : "Nữ"
        }
        return self._sex
    }
    
    public var avatar: String?{
        get {
            if let userAvatar = self._avatar {
                if userAvatar.starts(with: "http") {
                    return userAvatar
                }else{
                    return Define.rootCdn + userAvatar
                }
            }
            return nil
        }

        set {
            self._avatar = newValue
        }
    }
    public var coverImage: String?{
        get{
            if let coverImage = self._coverImage {
                return Define.rootCdn + coverImage
            }
            return nil
        }
        set{
            self._coverImage = newValue
        }
    }
    
    public var realname: String? {
        if let fullname = self.fullname {
            if fullname.count > 0 {
                return fullname
            }
        }
        return self.username
    }
    
    required public init?(map: Map) {
    }
    
    // Mappable
    public func mapping(map: Map) {
        accessToken    <- map["access_token"]
        address    <- map["address"]
        _avatar    <- map["avatar"]
        birthday    <- map["birthday"]
        _email    <- map["email"]
        expiresIn    <- map["expires_in"]
        fullname    <- map["fullname"]
        id    <- map["id"]
        _identify    <- map["identify"]
        _phone    <- map["phone"]
        refreshToken    <- map["refresh_token"]
        _sex    <- map["sex"]
        tokenType <- map["token_type"]
        username <- map["username"]
        _coverImage <- map["cover_image"]
        provider <- map["provider"]
    }
}
