//
//  AppDelegate.swift
//  main
//
//  Created by のあっと on 2021/02/04.
//

import UIKit
import GCDWebServer

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        setUpWebServer()
        NSSetUncaughtExceptionHandler({exception in
            let name = exception.name
            print("\(name)")
            
            print("\(exception.reason ?? "")")
            print("\(exception.callStackSymbols )")

            var log: String? = nil
            do{
                let name = exception.name
                log = "\(name), \(exception.reason ?? ""), \(exception.callStackSymbols )"
            }
            UserDefaults.standard.setValue(log, forKey: "failLog")
            UserDefaults.standard.setValue(true, forKey: "clashLog")
        })
        return true
    }
    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    fileprivate func setUpWebServer() {
        let server = WebServer.instance
        if server.server.isRunning { return }
        SessionRestoreHandler.register(server)
        do {
            try server.start()
        } catch let err as NSError {
            print("Error: Unable to start WebServer \(err)")
        }
    }
}

