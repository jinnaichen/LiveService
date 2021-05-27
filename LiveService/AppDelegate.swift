//
//  AppDelegate.swift
//  LiveService
//
//  Created by jinnaichen on 2021/5/27.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        let liveVC = LiveViewController()
        window?.rootViewController = liveVC
        window?.makeKeyAndVisible()
        return true
    }
}

