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
//    "product_id" : "com.slg.Demo.item1",
//    "money_in_game" : 44444,
//    "id" : 16,
//    "image" : "4444",
//    "client_id" : "3898128143",
//    "description" : "4444",
//    "title" : "44444",
//    "amount" : 44444,
//    "merchant_app_id" : 18903337
    
    public var productId: String?
    public var moneyInGame: String?
    public var id: Int?
    public var image: String?
    public var clientId: String?
    public var description: String?
    public var title: String?
    public var amount: Int?
    public var merchantAppId: Int?
    public var skProduct: SKProduct?
    
    public required init?(map: Map) {
        
    }
    
    public func mapping(map: Map) {
        productId <- map["product_id"]
        moneyInGame <- map["money_in_game"]
        id <- map["id"]
        image <- map["image"]
        clientId <- map["client_id"]
        description <- map["description"]
        title <- map["title"]
        amount <- map["amount"]
        merchantAppId <- map["merchant_app_id"]
    }
}
