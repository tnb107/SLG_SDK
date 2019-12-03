//
//  Utils.swift
//  sdk
//
//  Created by Apple on 9/18/17.
//  Copyright © 2017 slg. All rights reserved.
//

import Foundation
import UIKit
import SwiftyJSON
import ObjectMapper 
import CRToast

public class Util {
    public static func showMessage(controller: UIViewController,message: String){
        let alert = UIAlertController(title: nil, message: message, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Đóng", style: UIAlertAction.Style.default, handler: nil))
        controller.present(alert, animated: true, completion: nil)
    }
    
    public static func saveString(key: String, value: String){
        UserDefaults.standard.setValue(value, forKey: key)
    }
    
    public static func getString(key: String) -> String {
        let value = UserDefaults.standard.string(forKey: key) ?? ""
        return value
    }
    
    public static func getUUID() -> String {
        let uuid = UIDevice.current.identifierForVendor!.uuidString
        return uuid
    }
    
    public static func getData(json: JSON) -> JSON {
        return json["data"]
    }
    
    public static func getCurrentUser() -> User? {
        let userString = Util.getString(key: "user")
        if userString.count > 0 {
            // Convert JSON String to Model
            let user = Mapper<User>().map(JSONString: userString)
            return user
        }
        return nil
    }
    
    public static func showNotification(message: String,backgroundColor: UIColor = UIColor.darkGray,height: Int = 50 ,fontSize: CGFloat = 20, maxLine :Int = 3){
        let options: [AnyHashable : Any] = [
            kCRToastNotificationTypeKey:CRToastType.custom.rawValue,
            kCRToastTextKey: message ,
            kCRToastNotificationPreferredHeightKey: height,
            kCRToastBackgroundColorKey: backgroundColor,
            kCRToastAnimationInDirectionKey: CRToastAnimationDirection.right.rawValue,
            kCRToastAnimationOutDirectionKey: CRToastAnimationDirection.top.rawValue,
            kCRToastFontKey: UIFont.systemFont(ofSize: fontSize),
            kCRToastTextMaxNumberOfLinesKey: maxLine
        ]
        
        CRToastManager.showNotification(options: options, completionBlock: {
            //
        })
    }
    
    public static func getSDKBundle() -> Bundle? { 
        let bundle = Bundle(for: Util.self)
        let url =  bundle.url(forResource: "sdk", withExtension: "bundle")
        let resourceBundle = Bundle(url: url!)
        return resourceBundle
    }
    
    public static func getAccessToken() -> String {
        return getString(key: "accessToken")
    }
    
    public static func getProvider() -> String {
        return getString(key: "provider")
    }
    
}
