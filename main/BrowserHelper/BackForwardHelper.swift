//
//  BackForwardHelper.swift
//  main
//
//  Created by Ryu on 2021/04/24.
//

import Foundation
import UIKit
import WebKit

protocol BackForward {
    @discardableResult func goBack() -> (String,BrowserBackForwardList)
    @discardableResult func goForward() -> (String,BrowserBackForwardList)
    var canGoBack:Bool! { get set }
    var canGoForward:Bool! { get set }
    var dic:[String : Any]? { get }
}

protocol URLProfile {
    var backUrls:[String] { get set }
    var forwardUrls:[String] { get set }
}

struct BrowserBackForwardList : URLProfile {
    
    var backUrls: [String]
    var forwardUrls: [String]
    
    init(back:[String],forward:[String]) {
        self.backUrls = back
        self.forwardUrls = forward
    }
    mutating func removeBackItem() {
        let m = backUrls.last!
        backUrls.removeLast()
        forwardUrls.append(m)
    }
    mutating func removeForwardItem() {
        let m = forwardUrls.last!
        forwardUrls.removeLast()
        backUrls.append(m)
    }
    
}

class BackForwardHelper : NSObject, BackForward, URLProfile {

    var forwardUrls: [String]
    
    var backUrls: [String]
    
    func goBack() -> (String,BrowserBackForwardList) {
        let list = fetchBackForwardList()
        let url = backUrls.last!
        webView.loadURL(url: url)
        return (url,list)
    }
    func fetchBackForwardList() -> BrowserBackForwardList {
        scrutinyForwardList()
        scrutinyBackList()
        return BrowserBackForwardList(back: backUrls, forward: forwardUrls)
    }
    func scrutinyForwardList() {
        if let d = dic, let lists = d["forwardlist"] as? BFList, lists.count != 0 {
            canGoForward = true
            forwardUrls = lists.map{ $0["url"]! }
        }else{
            canGoForward = false
        }
    }
    func scrutinyBackList() {
        if let d = dic, let lists = d["backlist"] as? BFList, lists.count != 0 {
            canGoBack = true
            backUrls = lists.map{ $0["url"]! }
        }else{
            canGoBack = false
        }
    }
    func goForward() -> (String,BrowserBackForwardList) {
        let list = fetchBackForwardList()
        let url = backUrls.last!
        webView.loadURL(url: url)
        return (url,list)
    }
    
   var array = { () -> CellData in
        if !FileManager.default.fileExists(atPath: NSHomeDirectory() + "/Documents/CellData.json") {
            let jsonString = BrowserFileOperations.convertDictionaryToJson(dictionary: [])
            BrowserFileOperations.writingToFile(text: jsonString!, dir: "CellData.json")
        }
        let res = BrowserFileOperations.readFromFile(dir: "CellData.json")
        return BrowserFileOperations.getArrayFromJsonData(jsonData: res.data(using: .utf8)!)!
    }
    
    var token:String
    var dic:[String : Any]? {
        get{
            let arr = array()
            if let int = BrowserFileOperations.searchArray(fromToken: token, array: arr) {
                return arr[int]
            }else{
                return nil
            }
        }
    }
    
    var canGoBack: Bool!
    
    var canGoForward: Bool!
    var webView:BrowserWKWebView
    
    init(token:String,web:BrowserWKWebView) {
        self.token = token
        self.backUrls = []
        self.forwardUrls = []
        self.webView = web
    }
}
