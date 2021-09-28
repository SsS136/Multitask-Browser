//
//  AdBlockerHelper.swift
//  main
//
//  Created by Ryu on 2021/05/18.
//

import Foundation
import UIKit
import WebKit

final class AdBlockHelper {
    static let adblockProcessName = "ContentBlockingRule"
    static var isRunning:Bool = false
    static func jsonName() -> String {
        let level = UserDefaults.standard.integer(forKey: "blockLevel")
        switch level {
        case 0:
            return "lowAdBlock"
        case 1:
            return "middleAdBlock"
        default:
            return "highAdBlock"
        }
    }
    static func startAdBlocking(viewController:BrowserViewController) {
        isRunning = true
        let path =  Bundle.main.path(forResource: jsonName(), ofType: "json")!
        let data = try! String(contentsOfFile:path, encoding: String.Encoding.utf8)
        if UserDefaults.standard.bool(forKey: "adblock") {
            print("通過")
            WKContentRuleListStore.default().compileContentRuleList(
                forIdentifier: adblockProcessName,
                encodedContentRuleList:data) { (contentRuleList, error) in
                if let error = error {
                    print("ここ\(error)")
                    return
                }
                print("\(String(describing: contentRuleList))")
                viewController.webView.configuration.userContentController.add(contentRuleList!)
            }
        }
    }
    
    static func startAdBlocking(configuration:WKWebViewConfiguration) -> WKWebViewConfiguration {
        isRunning = true
        let path =  Bundle.main.path(forResource: jsonName(), ofType: "json")!
        let data = try! String(contentsOfFile:path, encoding: String.Encoding.utf8)
        if UserDefaults.standard.bool(forKey: "adblock") {
            DispatchQueue.main.async {
                WKContentRuleListStore.default().compileContentRuleList(
                    forIdentifier: adblockProcessName,
                    encodedContentRuleList:data) { (contentRuleList, error) in
                    if let error = error {
                        print("ここ\(error)")
                        return
                    }
                    print("\(String(describing: contentRuleList))")
                    configuration.userContentController.add(contentRuleList!)
                }
            }
        }
        return configuration
    }
    static func continueAdBlocking(viewController:BrowserViewController,elseHundler:(() -> Void)?) {
        if UserDefaults.standard.bool(forKey: "adblock") {
            if isRunning {
                WKContentRuleListStore.default().lookUpContentRuleList(forIdentifier: adblockProcessName, completionHandler: {(contentRuleList,error) in
                    if let error = error {
                        print("ここ\(error)")
                      return
                    }
                    print(contentRuleList)
                    viewController.webView.configuration.userContentController.add(contentRuleList!)
                })
            }else{
                if let hundle = elseHundler {
                    hundle()
                }
            }
        }
    }
    static func unableAdBlocking() {
        WKContentRuleListStore.default().removeContentRuleList(forIdentifier: adblockProcessName, completionHandler: {
            isRunning = false
            print("ここ\($0 as Any)")
        })
    }
}
