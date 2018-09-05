//
//  Product.swift
//  sdk
//
//  Created by Apple on 10/6/17.
//  Copyright © 2017 slg. All rights reserved.
//

import Foundation
import ObjectMapper
import StoreKit
public class Product : Mappable {
    
    public var productId: String?
    public var bonusCoin : Int?
    public var appId : Int?
    public var title: String?
    public var price : String?
    public var bonusGold : Int?
    public var clientId: String?
    public var id: Int?
    public var osId: Int?
    public var coin: Int?
    public var gold: Int?
    public var skProduct: SKProduct?
    
    public required init?(map: Map) {
        
    }
    
    public func mapping(map: Map) {
        productId <- map["item_id"]
        bonusCoin <- map["bonus_coin"]
        appId <- map["app_id"]
        title <- map["title"]
        price <- map["price"]
        bonusGold <- map["bonus_gold"]
        clientId <- map["client_id"]
        id <- map["id"]
        osId <- map["os_id"]
        coin <- map["coin"]
        gold <- map["gold"]
    }
}
