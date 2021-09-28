//
//  TabDataRestore.swift
//  Browser
//
//  Created by Ryu on 2021/06/11.
//

import UIKit
import SwiftyJSON

class TabDataRestore : NSObject {
    
    let backList:BFList
    let forwardList:BFList
    weak var webView:BrowserWKWebView?
    let currentURL:String
    private var count = 0
    private var mergeURLs = [String]()
    private var compactForwardURLs = [String]()
    
    init(Back:BFList,forward:BFList,currentURL:String,webView:BrowserWKWebView) {
        self.backList = Back
        self.forwardList = forward
        self.webView = webView
        self.currentURL = currentURL
    }
    func restoreTabData() {
        var backURLs = backList.compactMap { $0["url"] }
        backURLs.append(currentURL)
        //openUrl(urlString: backURLs.first ?? "https://google.com")
        compactForwardURLs = forwardList.compactMap { $0["url"] }
        mergeURLs = backURLs + compactForwardURLs
        let currentIndex = mergeURLs.count  - forwardList.count
        //openUrl(urlString: currentURL)
        DispatchQueue.global().async {
            for merge in self.mergeURLs {
                let url = merge.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)!
                let js = """
history.replaceState({},'',"\(url)")
"""
                DispatchQueue.main.async {
                    self.webView?.evaluateJavaScript(js, completionHandler: {(object,error) in
                        if let error = error {
                            print("エラーだよ:",url)
                            print("エラーだよ:",error)
                        }
                    })
                }
            }
        }
        webView?.evaluateJavaScript("""

""", completionHandler:nil)
//        webView?.evaluateJavaScript("""
//            var msg = "あなたは黒柴が好きですか？" ;
//            // 「はい」を選択した場合
//            if( window.confirm( msg ) ) {
//                console.log( "「はい」を選択しました。" );
//            // 「いいえ」を選択した場合
//            } else {
//                console.log( "「いいえ」を選択しました。" );
//            }
//            window.open('http://www.sejuku.net', '_blank');
//            history.replaceState({}, "", \(mergeURLs.first!);
//            """, completionHandler: nil)
//        for merge in mergeURLs {
//            webView?.evaluateJavaScript( """
//            var msg = "あなたは黒柴が好きですか？" ;
//            // 「はい」を選択した場合
//            if( window.confirm( msg ) ) {
//                console.log( "「はい」を選択しました。" );
//            // 「いいえ」を選択した場合
//            } else {
//                console.log( "「いいえ」を選択しました。" );
//            }
//            history.pushState({},"",\(merge);
//            alert("あ");
//            """, completionHandler: nil)
//        }
//        webView?.evaluateJavaScript("""
//        history.go(\(-currentIndex));
//""", completionHandler: nil)
//        let currentIndex = mergeURLs.count  - forwardList.count
//        print(backList,forwardList)
//
//        let jsonDict: [String: AnyObject] = [
//            "history": mergeURLs as AnyObject,
//            "currentPage": currentIndex as AnyObject
//        ]
//        if let json = JSON(jsonDict).rawString(.utf8, options: [])?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
//            if let restoreUrl = URL(string: "\(WebServer.instance.base)/errors/restore?history=\(json)") {
//                print(jsonDict)
//                self.webView?.load(URLRequest(url: restoreUrl))
//            }
//        }
//        _ = Timer(timeInterval: 0.1, target: self, selector: #selector(repeatTimer(_:)), userInfo: nil, repeats: true)
    }
//    @objc private func repeatTimer(_ sender:Timer) {
//        if count == mergeURLs.count - 1 {
//            sender.invalidate()
//            _ = Timer(timeInterval: 0.1, target: self, selector: #selector(backURL(_:)), userInfo: nil, repeats: true)
//            count = 0
//            return
//        }
//        self.openUrl(urlString: mergeURLs[count])
//        count+=1
//        print("timer1")
//    }
//    @objc private func backURL(_ sender:Timer) {
//        if count == compactForwardURLs.count - 1{
//            sender.invalidate()
//            count = 0
//            return
//        }
//        self.webView?.goBack()
//        count+=1
//        print("timer2")
//    }
    private func openUrl(urlString: String) {
        if let url = URL(string: urlString) {
            print("loadrequest")
            let request = NSURLRequest(url: url)
            webView?.load(request as URLRequest)
        }
    }
}
