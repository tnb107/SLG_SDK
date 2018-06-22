//
//  SlgSDK.swift
//  sdk
//
//  Created by Apple on 9/14/17.
//  Copyright © 2017 slg. All rights reserved.
//

import Foundation
import UIKit
import FBSDKCoreKit
import FirebaseCore
import FirebaseMessaging 
import UserNotifications
import StoreKit
import SVProgressHUD
import FBSDKLoginKit
import Alamofire
import SwiftyJSON
import ObjectMapper
import GoogleSignIn


public typealias InitIAPCompletionHandler = (_ success: Bool, _ products: [Product]?) -> ()
public typealias ProductsRequestCompletionHandler = (_ success: Bool, _ products: [SKProduct]?) -> ()
public typealias ProductPurchaseCompletionHandler = (_ success: Bool, _ transaction: SKPaymentTransaction) -> ()
public typealias UserLoginCompletionHandler = (_ issuccess: Bool,_ response: Any?,_ message: String?,_ errorCode: Int?,_ user: User?) -> ()
public typealias DashboardCompletionHandler = (_ isLogout: Bool) -> ()

public class SlgSDK :NSObject {
    var productsRequest: SKProductsRequest?
    var productsRequestCompletionHandler: ProductsRequestCompletionHandler?
    var productIdentifiers: Set<String> = []
    var temporaryUIViewController: UIViewController?
    var temporarydashboardCompletionHandler: DashboardCompletionHandler?
    var temporaryDashboardUIViewController: UIViewController?
    
    var productPurchaseCompletionHandler: ProductPurchaseCompletionHandler?
    
    
    public static let SlgSDKPurchaseNotification = "SlgSDKPurchaseNotification"
    
    public static let shared: SlgSDK = {
        Messaging.messaging().subscribe(toTopic: "/topics/slg")
        return SlgSDK()
    }()
    
    public var clientId: String?
    public var clientsecret: String?
    public var cpid: String?
    
    private var _products = [Product]()
    
    private var _debugMode: Bool = false
    
    private override init(){
        super.init()
        //start init payment
        SKPaymentQueue.default().add(self)
    }
    
    public func initIAP(clientId: String,initIAPCompletionHandler: InitIAPCompletionHandler?){
        Alamofire.request(Define.productApple, method: .post, parameters: ["client_id" : clientId], encoding: JSONEncoding.default, headers: nil).responseJSON { (response) in
            
            
            switch(response.result){
            case .success(let value):
                let json = JSON(value)
                //let message:String = json["message"].string ?? ""
                let errorCode:Int = json["error_code"].int ?? 0
                
                DLog.log(message: Define.productApple)
                DLog.log(message: json)
                
                let data = json["data"]
                
                if(errorCode == 200){
                    let ps = Mapper<Product>().mapArray(JSONString: data.rawString() ?? "")
                    
                    guard let productApples = ps else {
                        initIAPCompletionHandler?(false, nil)
                        return
                    }

                    //add product id
                    for item in data.arrayValue {
                        DLog.log(message: "productApple: \(item)")
                        self.addProductId(productId: item["product_id"].string ?? "")
                    }
                    
                    //request product
                    self.requestProducts { (success, products) in
                        //
                        DLog.log(message: "request product: \(success)")
                        if success, let products = products {
                            for product in products {
                                for productApple in productApples {
                                    if product.productIdentifier == productApple.productId {
                                        productApple.skProduct = product
                                        break
                                    }
                                }
                            }
                            DLog.log(message: "request product success: \(productApples)")
                            self._products = productApples
                        }
                        
                        initIAPCompletionHandler?(success, productApples)
                    }
                }else{
                    initIAPCompletionHandler?(false, nil)
                }
            case .failure(let error):
                initIAPCompletionHandler?(false, nil)
                DLog.log(message: "failure: \(error.localizedDescription)")
            }
        }
        //end init payment
    }
    
    public func initIAP(clientId: String){
        self.initIAP(clientId: clientId, initIAPCompletionHandler: nil)
    }
    
    public var debugMode: Bool {
        set {
            self._debugMode = newValue
            DLog.isDebug = newValue
        }
        
        get {
            return self._debugMode
        }
    }
    
    public var products: [Product] {
        return self._products
    }
      
    public func login(_ uiViewController: UIViewController, delegate: LoginDelegate?){
        let bundle = Util.getSDKBundle()
        
        let homeViewController: HomeViewController = HomeViewController(nibName: "HomeViewController", bundle: bundle)
        homeViewController.delegate = delegate
        uiViewController.present(homeViewController, animated: true, completion: nil)
    }
    
    public func openDashBoard(_ uiViewController: UIViewController?,callBackDialogDissmiss dashboardCompletionHandler: DashboardCompletionHandler?){
        let bundle = Util.getSDKBundle()
        
        let userInfoViewController: UserInfoViewController = UserInfoViewController(nibName: "UserInfoViewController", bundle: bundle)
        userInfoViewController.dashboardCompletionHandler = dashboardCompletionHandler
        if let uiViewController = uiViewController {
            uiViewController.present(userInfoViewController, animated: true, completion: nil)
        }
    }
    
    public func validateCurrentAccessToken(uiViewController: UIViewController, userLoginCompletionHandler:  UserLoginCompletionHandler?){
        
        let user = Util.getCurrentUser()
        
        if let user = user {
            let parameters: [String:Any] = [
                "access_token" : user.accessToken ?? ""
            ]
            
            DLog.log(message: parameters)
            
            SVProgressHUD.show(withStatus: "đang kiểm tra...")
            UIApplication.shared.beginIgnoringInteractionEvents()
            
            Alamofire.request(Define.validateAccessToken, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: nil).responseJSON { (response) in
                SVProgressHUD.dismiss()
                UIApplication.shared.endIgnoringInteractionEvents()
                
                switch(response.result){
                case .success(let value):
                    let json = JSON(value)
                    let message:String = json["message"].string ?? ""
                    let errorCode:Int = json["error_code"].int ?? 0
                    
                    DLog.log(message: json)
                    
                    if(errorCode == 200){
                        Util.showNotification(message: "Xin chào \(user.username ?? "bạn")")
                        userLoginCompletionHandler?(true, value, message, errorCode, user)
                    }else{
                        Util.showNotification(message: message)
                        userLoginCompletionHandler?(false, value, message, errorCode, nil)
                    }
                case .failure(let error):
                    userLoginCompletionHandler?(false, nil, error.localizedDescription, nil, nil)
                    Util.showMessage(controller: uiViewController,message: error.localizedDescription)
                }
                
            }
        }else { 
            userLoginCompletionHandler?(false, nil, "Bạn chưa đăng nhập !", nil, nil)
        }
    }
    
    public func showAssistiveTouch(uiViewController: UIViewController,dashboardCompletionHandler:  DashboardCompletionHandler?){
        temporarydashboardCompletionHandler = dashboardCompletionHandler
        temporaryDashboardUIViewController = uiViewController
        
        let assistiveTouch = AssistiveTouch(frame: CGRect(x: 10, y: 100, width: 56, height: 56))
        assistiveTouch.addTarget(self, action: #selector(self.tapAssistiveTouch(sender:)), for: .touchUpInside)
        assistiveTouch.setImage(UIImage(named: "ic_assistive_touch", in: Util.getSDKBundle(), compatibleWith: nil), for: .normal)
        uiViewController.view.addSubview(assistiveTouch)
    }
    
    @objc public func tapAssistiveTouch(sender: UIButton) { 
        self.openDashBoard(temporaryDashboardUIViewController, callBackDialogDissmiss: temporarydashboardCompletionHandler)
    }
    
    public static func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Void { 
        FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
        
        FirebaseApp.configure()
    }
    
    public static func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        if let error = error {
            DLog.log(message: "\(error.localizedDescription)")
            NotificationCenter.default.post(
                name: Notification.Name(rawValue: "ToggleAuthUINotification"), object: nil, userInfo: nil)
        } else {
            // Perform any operations on signed in user here.
            let userId: String = user.userID                  // For client-side use only!
            let idToken: String = user.authentication.idToken // Safe to send to the server
            let fullName: String = user.profile.name
            let givenName: String = user.profile.givenName
            let familyName: String = user.profile.familyName
            let email: String = user.profile.email
            
            NotificationCenter.default.post(
                name: Notification.Name(rawValue: "ToggleAuthUINotification"),
                object: nil,
                userInfo: ["userID": userId,
                           "idToken": idToken,
                           "fullName": fullName,
                           "givenName": givenName,
                           "familyName": familyName,
                           "email": email,
                           "accessToken": signIn.currentUser.authentication.accessToken])
        }
    }
    
//
    @available(iOS 10.0, *)
    public static func registerNotification(application: UIApplication, messageDelegate: MessagingDelegate?,unUserNotificationCenterDelegate: UNUserNotificationCenterDelegate?){
        // [START set_messaging_delegate]
        Messaging.messaging().delegate = messageDelegate
        // [END set_messaging_delegate]
        // Register for remote notifications. This shows a permission dialog on first run, to
        // show the dialog at a more appropriate time move this registration accordingly.
        // [START register_for_notifications]
        
            // For iOS 10 display notification (sent via APNS)
            UNUserNotificationCenter.current().delegate = unUserNotificationCenterDelegate
            
            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
            UNUserNotificationCenter.current().requestAuthorization(
                options: authOptions,
                completionHandler: {_, _ in })
        
        
        application.registerForRemoteNotifications()
        
        // [END register_for_notifications]
    }
    
    public static func registerNotification2(application: UIApplication, messageDelegate: MessagingDelegate?){
        // [START set_messaging_delegate]
        Messaging.messaging().delegate = messageDelegate
        // [END set_messaging_delegate]
        // Register for remote notifications. This shows a permission dialog on first run, to
        // show the dialog at a more appropriate time move this registration accordingly.
        // [START register_for_notifications]
        
            let settings: UIUserNotificationSettings =
                UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            application.registerUserNotificationSettings(settings)
        
        
        application.registerForRemoteNotifications()
        
        // [END register_for_notifications]
    }
    
    
    public static func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool { 
        if GIDSignIn.sharedInstance().handle(url, sourceApplication: sourceApplication, annotation: annotation) {
            return true
        } else if FBSDKApplicationDelegate.sharedInstance().application(application, open: url, sourceApplication: sourceApplication, annotation: application) {
            return true
        }
        return false
    }
    
    
    public static func activateApp(){
        FBSDKAppEvents.activateApp()
    }
    
    
    public static func configureFCM(messagingDelegate: MessagingDelegate){
        // [START set_messaging_delegate]
        Messaging.messaging().delegate = messagingDelegate
        // [END set_messaging_delegate]
    }
    
    public static func logout(){
        Util.saveString(key: "user", value: "")
        FBSDKLoginManager().logOut()
        GIDSignIn.sharedInstance().signOut()
    }
    
    public func checkRefreshToken() -> Bool{
        let date = Date()
        let day = Calendar.current.component(.day, from: date)
        let month = Calendar.current.component(.month, from: date)
        let year = Calendar.current.component(.year, from: date)
        let dateNew = String(day)+"-"+String(month)+"-"+String(year)
        let dateOld = Util.getString(key: "dateRefreshToken")
        if(dateOld == dateNew){
            return false;
        }else{
            Util.saveString(key: "dateRefreshToken", value: dateNew)
            return true;
        }
    }
}

extension SlgSDK {
    
    
    private func getReceipt() -> String?{
        do{
            let appStoreReceiptURL = Bundle.main.appStoreReceiptURL
            DLog.log(message: "appStoreReceiptURL: \(appStoreReceiptURL!)")
            
            if let url = appStoreReceiptURL {
                let receipt: Data = try Data(contentsOf: url)
                let receiptData = receipt.base64EncodedString(options: Data.Base64EncodingOptions(rawValue: 0))
                DLog.log(message: "receiptData: " + receiptData)
                return receiptData
            }
        }catch {
            DLog.log(message: "ERROR: " +  error.localizedDescription)
        }
        
        return nil
    }
    
    public func requestProducts(completionHandler: @escaping ProductsRequestCompletionHandler) {
        productsRequest?.cancel()
        productsRequestCompletionHandler = completionHandler
        
        productsRequest = SKProductsRequest(productIdentifiers: productIdentifiers)
        productsRequest!.delegate = self
        productsRequest!.start()
    }
    
    public func addProductId(productId: String) {
        let result = productIdentifiers.insert(productId)
        DLog.log(message: "addProductId: \(result)")
    }
    
    public func buyProduct(_ product : SKProduct, uiViewController: UIViewController, productPurchaseCompletionHandler: @escaping ProductPurchaseCompletionHandler){
        DLog.log(message: "Buying \(product.productIdentifier)...")
        
        guard let _ = Util.getCurrentUser() else {
            //
            Util.showMessage(controller: uiViewController, message: "Bạn chưa đăng nhập\n\nVui lòng đăng nhập để thực hiện hành động này")
            return
        }
        
        self.temporaryUIViewController = uiViewController
        self.productPurchaseCompletionHandler = productPurchaseCompletionHandler
        
        
        
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment)
    }
    
    public class func canMakePayments() -> Bool {
        return SKPaymentQueue.canMakePayments()
    }
    
    public func restorePurchases() {
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
}

extension SlgSDK : SKProductsRequestDelegate {
    public func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        let products = response.products
        DLog.log(message: "Loaded list of products...")
        productsRequestCompletionHandler?(true, products)
        clearRequestAndHandler()
        
        for p in products {
            DLog.log(message: "Found product: \(p.productIdentifier) \(p.localizedTitle) \(p.price.floatValue)")
        }
    }
    
    private func clearRequestAndHandler() {
        productsRequest = nil
        productsRequestCompletionHandler = nil
    }
    
}

extension SlgSDK : SKPaymentTransactionObserver {
    public func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
         
        
        for transaction in transactions {
            switch (transaction.transactionState) {
            case .purchased:
                SVProgressHUD.dismiss()
                UIApplication.shared.endIgnoringInteractionEvents()
                complete(transaction: transaction)
                break
            case .failed:
                SVProgressHUD.dismiss()
                UIApplication.shared.endIgnoringInteractionEvents()
                fail(transaction: transaction)
                break
            case .restored:
                restore(transaction: transaction)
                break
            case .deferred:
                DLog.log(message: "paymentQueue .deferred")
                break
            case .purchasing:
                DLog.log(message: "paymentQueue .purchasing")
                SVProgressHUD.show()
                UIApplication.shared.beginIgnoringInteractionEvents()
                break
            }
        }
        
        
        
        //self.productPurchaseCompletionHandler = nil
    }
    
    public func complete(transaction: SKPaymentTransaction) {
        
        DLog.log(message: "complete... \(transaction.payment.productIdentifier)")
        deliverPurchaseNotificationFor(identifier: transaction.payment.productIdentifier)
        SKPaymentQueue.default().finishTransaction(transaction)
        
        let parameters: [String:Any] = [
            "receipt" : self.getReceipt() ?? "",
            "product_id" : transaction.payment.productIdentifier,
            "client_id" : self.clientId ?? "",
            "uid" : Util.getCurrentUser()?.id ?? "",
            "env" : ((self._debugMode) ? Define.envSandbox: Define.envProduct),
            "access_token" : Util.getCurrentUser()?.accessToken ?? ""
        ]
        
        DLog.log(message: parameters)
        
        SVProgressHUD.show(withStatus: "Xác nhận...")
        UIApplication.shared.beginIgnoringInteractionEvents()
        
        Alamofire.request(Define.verifyiap, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: nil).responseJSON { (response) in
            SVProgressHUD.dismiss()
            UIApplication.shared.endIgnoringInteractionEvents()
            
            switch(response.result){
            case .success(let value):
                let json = JSON(value)
                let message:String = json["message"].string ?? ""
                let errorCode:Int = json["error_code"].int ?? 0
                
                DLog.log(message: "transaction complete: \(json)")
                
                if (errorCode == 200){
                    self.productPurchaseCompletionHandler?(true, transaction)
                }else{
                    self.productPurchaseCompletionHandler?(false, transaction)
                    if let uiViewController = self.temporaryUIViewController {
                        Util.showMessage(controller: uiViewController, message: message)
                    }
                }
            case .failure(let error):
                self.productPurchaseCompletionHandler?(false, transaction)
                if let uiViewController = self.temporaryUIViewController {
                    Util.showMessage(controller: uiViewController, message: error.localizedDescription)
                }
            }
            self.productPurchaseCompletionHandler = nil
        }
        
        self.productPurchaseCompletionHandler = nil
    }
    
//    private func verifyiap(){
//        
//    }
    
    public func restore(transaction: SKPaymentTransaction) {
        guard let productIdentifier = transaction.original?.payment.productIdentifier else { return }
        
        DLog.log(message: "restore... \(productIdentifier)")
        deliverPurchaseNotificationFor(identifier: productIdentifier)
        SKPaymentQueue.default().finishTransaction(transaction)
    }
    
    public func fail(transaction: SKPaymentTransaction) {
        DLog.log(message: "fail...")
        if let transactionError = transaction.error as NSError? {
            let message:String = "Transaction Error (code \(transactionError.code)): \(transaction.error?.localizedDescription ?? "unknown error")";
            DLog.log(message: message)
            if let uiViewController = self.temporaryUIViewController {
                Util.showMessage(controller: uiViewController, message: message)
            } 
        }
        
        SKPaymentQueue.default().finishTransaction(transaction)
        self.productPurchaseCompletionHandler?(false, transaction)
        self.productPurchaseCompletionHandler = nil
    }
    
    public func deliverPurchaseNotificationFor(identifier: String?) {
        guard let identifier = identifier else { return }
         
        //UserDefaults.standard.set(true, forKey: identifier)
        //UserDefaults.standard.synchronize()
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: SlgSDK.SlgSDKPurchaseNotification), object: identifier)
    }
}
