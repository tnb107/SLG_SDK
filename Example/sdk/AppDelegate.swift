 //
//  AppDelegate.swift
//  sdk
//
//  Created by dieppn on 11/10/2017.
//  Copyright (c) 2017 dieppn. All rights reserved.
//

import UIKit
import sdk
import GoogleSignIn
import UserNotifications
import FirebaseMessaging
import FirebaseCore
import Fabric
import Crashlytics
import AppsFlyerLib
@UIApplicationMain
 class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate, AppsFlyerTrackerDelegate{
    func onConversionDataSuccess(_ conversionInfo: [AnyHashable : Any]!) {
        
    }
    
    func onConversionDataFail(_ error: Error!) {
        
    }
    

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        if #available(iOS 10.0, *) {
            SlgSDK.registerNotification(application: application, messageDelegate: self, unUserNotificationCenterDelegate: self)
        } else {
            SlgSDK.registerNotification2(application: application, messageDelegate: self)
        }
        SlgSDK.application(application, didFinishLaunchingWithOptions: launchOptions)
        
        // Initialize sign-in
        GIDSignIn.sharedInstance().clientID = "470969518590-ro7q4nqn6r7atgqcoknd9m17p4vi9lok.apps.googleusercontent.com"
        GIDSignIn.sharedInstance().delegate = self
        
        Fabric.with([Crashlytics.self, Answers.self])
        
        AppsFlyerTracker.shared().appsFlyerDevKey = "eUkopjzzvHxCQFDWBbtNMk"
        AppsFlyerTracker.shared().appleAppID = "1107919627"
        AppsFlyerTracker.shared().delegate = self
        AppsFlyerTracker.shared().isDebug = true
        
        return true
    }
    
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        return SlgSDK.application(application, open: url, sourceApplication: sourceApplication, annotation: annotation)
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        //
        return SlgSDK.application(app, open: url, sourceApplication: options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String, annotation: options[UIApplication.OpenURLOptionsKey.annotation])
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        SlgSDK.activateApp()
        AppsFlyerTracker.shared().trackAppLaunch()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


    func messaging(_ messaging: Messaging, didRefreshRegistrationToken fcmToken: String) {
        print("===token===\(fcmToken)")
    }
}

extension AppDelegate: GIDSignInDelegate{
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
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
    
    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
        //
    }
}
