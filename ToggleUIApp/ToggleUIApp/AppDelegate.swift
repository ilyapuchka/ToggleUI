//
//  AppDelegate.swift
//  ToggleUIApp
//
//  Created by Ilya Puchka on 13/05/2020.
//  Copyright © 2020 Ilya Puchka. All rights reserved.
//

import UIKit
import Combine
import ToggleUI

let toggles = Toggles().withDefaults { (toggles) in
    toggles.$value3Decodable.defaultValue.$feature3 = "initial"
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var bag = Set<AnyCancellable>()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.

//        print(toggles.toggleConfig?.f)
//        print(toggles.toggleConfig?.g)
//        toggles.toggleD.sink(receiveValue: {
//            print($0)
//        }).store(in: &bag)
//
//        toggles.value3Decodable.sink {
//            print($0?.feature3)
//        }.store(in: &bag)
//
//        toggles.remoteConfig.sink {
//            print($0?.module?.feature3)
//        }.store(in: &bag)

        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}
