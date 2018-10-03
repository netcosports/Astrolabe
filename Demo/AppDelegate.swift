//
//  AppDelegate.swift
//  Astrolabe
//
//  Created by Sergei Mikhan on 12/27/16.
//  Copyright © 2016 Netcosports. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

  var window: UIWindow?

  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    let window = UIWindow(frame: UIScreen.main.bounds)
    window.backgroundColor = .white
    let home = HomeViewController()
    let navigation = UINavigationController(rootViewController: home)
    window.rootViewController = navigation
    window.makeKeyAndVisible()
    self.window = window
    return true
  }
}
