//
//  BrowserDataSaver.swift
//  main
//
//  Created by Ryu on 2021/05/06.
//

import Foundation
import UIKit

public typealias CellData = [[String:Any]]
public typealias BFList = [[String:String]]

final class BrowserDataManager : NSObject, PrivateDataCore {
    
    private var base:CGFloat {
        get{
            guard let view = view else { return 0 }
            return view.bounds.size.width > view.bounds.size.height ? view.bounds.size.height : view.bounds.size.width
        }
    }
    
    private var view:UIView!

    weak var data:DataReloaderDataSource!
    var webView: BrowserWKWebView!
    private var newpageExist:BrowserViewController.IsNewPageViewExist!
    var array:CellData!
    private var allowDelegateHandle = true

    struct PrivateData {
        static var privateArray : CellData = {
            return [["url" : "New Page","forwardlist" : [],"backlist" : [],"favicon" : UIImage.convenienceInit(named: "rocket.png", size: CGSize(width: 23.5, height: 23.5))!,"snapshot" : UIImage(named: "white.png")!,"title" : "New Page","token" : token]]
        }()
        static var token = createToken().0
        static var index = 0
    }

    private static func createToken() -> (String, String, String) {
        let token = BrowserFileOperations.randomString(length: 30)
        let faviconToken = BrowserFileOperations.randomString(length: 40)
        let snapshotToken = BrowserFileOperations.randomString(length: 40)
        return (token,faviconToken,snapshotToken)
    }
    private func storingBFListFromWebView() -> (BFList,BFList) {//0 forward 1 backward
        var webviewlist:BFList = [[:]]
        var backforwardlist:BFList = [[:]]
        webView.backForwardList.forwardList.forEach{
            var webdic:[String:String] = [:]
            webdic.updateValue($0.url.absoluteString, forKey: "url")
            webdic.updateValue($0.title ?? "about:blank", forKey: "title")
            webviewlist.append(webdic)
            if webviewlist[0] == [:] {
                webviewlist.remove(at: 0)
            }
        }
        webView.backForwardList.backList.forEach{
            var webdic:[String:String] = [:]
            webdic.updateValue($0.url.absoluteString, forKey: "url")
            webdic.updateValue($0.title ?? "about:blank", forKey: "title")
            backforwardlist.append(webdic)
            if backforwardlist[0] == [:] {
                backforwardlist.remove(at: 0)
            }
        }
        return (webviewlist,backforwardlist)
    }
    private func storingBFListFromWebView(webView:BrowserWKWebView) -> (BFList,BFList) {//0 forward 1 backward
        var webviewlist:BFList = [[:]]
        var backforwardlist:BFList = [[:]]
        webView.backForwardList.forwardList.forEach{
            var webdic:[String:String] = [:]
            webdic.updateValue($0.url.absoluteString, forKey: "url")
            webdic.updateValue($0.title ?? "about:blank", forKey: "title")
            webviewlist.append(webdic)
            if webviewlist[0] == [:] {
                webviewlist.remove(at: 0)
            }
        }
        webView.backForwardList.backList.forEach{
            var webdic:[String:String] = [:]
            webdic.updateValue($0.url.absoluteString, forKey: "url")
            webdic.updateValue($0.title ?? "about:blank", forKey: "title")
            backforwardlist.append(webdic)
            if backforwardlist[0] == [:] {
                backforwardlist.remove(at: 0)
            }
        }
        return (webviewlist,backforwardlist)
    }
    public func savePrivateData(identifier:inout Bool,view:inout UIView,favicon:UIImage,webInstances:inout [String:BrowserWKWebView],mainViewController:BrowserViewController) {
        
        guard allowDelegateHandle else { return }
        let image = takeSnapShot(view: &view,mainViewController: mainViewController)
        let index = PrivateData.index
        guard index >= 0 && index < privateArray.count else { return }
        var dic = PrivateData.privateArray[index]
        var reload = DataReloader()
        reload.data = self
        webInstances.updateValue(webView, forKey: dic["token"] as! String)
        dic["url"] = webView.url?.absoluteString ?? "New Page"
        if let t = webView.title {
            if t != "" {
                dic["title"] = t
            }
        }else{
            dic["title"] = "New Page"
        }
        dic["snapshot"] = image
        if !identifier {
            dic["favicon"] = newpageExist == .exist ? UIImage(named: "rocket.png") : favicon
        }else{
            identifier = false
        }
        dic["forwardlist"] = storingBFListFromWebView().0
        dic["backlist"] = storingBFListFromWebView().1
        PrivateData.privateArray[index] = dic
        reload.reloadAll()
        
    }
    public func saveData(identifier:inout Bool,view:inout UIView,favicon:UIImage,webInstances:inout [String:BrowserWKWebView],mainViewController:BrowserViewController) {
        
        guard allowDelegateHandle else { return }
        
        let tokens = Self.createToken()//token,favicontoken,snapshotToken
        let image = takeSnapShot(view: &view, mainViewController: mainViewController)
        
        if BrowserFileOperations.getArrayFromJsonData(jsonData: BrowserFileOperations.readFromFile(dir: "CellData.json").data(using: .utf8)!)?.count == 0 {
            print("no items")
            BrowserFileOperations.writingToFile(text: BrowserFileOperations.convertDictionaryToJson(dictionary: [["token" : tokens.0,"url" : "New Page","forwardlist" : [],"backlist" : [],"favicon" : tokens.1,"snapshot" : tokens.2,"title" : "New Page"]])!, dir: "CellData.json")
            webInstances.updateValue(webView, forKey: tokens.0)
            UserDefaults.standard.setValue(tokens.0, forKey: "currentToken")
            UserDefaults.standard.setValue(0, forKey: "currentIndex")
            if let fav = favicon.pngData() {
                BrowserFileOperations.saveImage(dir: "favicon",name:"\(tokens.1).png", data: fav)
            }else{
                BrowserFileOperations.saveImage(dir: "favicon", name: "\(tokens.1).png", data: (UIImage.convenienceInit(named: "rocket.png", size: CGSize(width: 23.5, height: 23.5))?.pngData())!)
            }
            BrowserFileOperations.saveImage(dir: "snapshot", name: "\(tokens.2).png", data:image.pngData()!)
        }else{
            let res = BrowserFileOperations.readFromFile(dir: "CellData.json")
            let a = BrowserFileOperations.getDictionaryFromJsonData(jsonData: res.data(using: .utf8)!, token: UserDefaults.standard.string(forKey: "currentToken")!)
            var b = BrowserFileOperations.getArrayFromJsonData(jsonData: res.data(using: .utf8)!)

            let ftoken = a?["favicon"]
            let stoken = a?["snapshot"]
            if let webtoken = a?["token"] as? String {
                webInstances.updateValue(webView, forKey:webtoken)
            }
            if !identifier {
                if let fav = favicon.pngData() {
                    newpageExist == .exist ? BrowserFileOperations.replaceData(dir: "favicon", name: "\(ftoken ?? "").png", replaceData: (UIImage.convenienceInit(named: "rocket.png", size: CGSize(width: 23.5, height: 23.5))?.pngData())!) : BrowserFileOperations.replaceData(dir: "favicon", name: "\(ftoken ?? "").png", replaceData: fav)
                }else{
                    BrowserFileOperations.replaceData(dir: "favicon", name: "\(ftoken ?? "").png", replaceData: (UIImage.convenienceInit(named: "rocket.png", size: CGSize(width: 23.5, height: 23.5))?.pngData())!)
                }
            }else{
                identifier = false
            }
            BrowserFileOperations.replaceData(dir: "snapshot", name: "\(stoken ?? "").png", replaceData: image.pngData()!)
            
            let index = BrowserFileOperations.searchArray(fromToken: a?["token"] as? String ?? "", array: b ?? [])
            if let intIndex = index {
                var dic = b?[intIndex]
                if newpageExist == .exist {
                    
                    dic?["url"] = "New Page"
                }else{
                    dic?["url"] = webView.url?.absoluteString ?? "about:blank"
                }
                dic?["forwardlist"] = storingBFListFromWebView().0
                dic?["backlist"] = storingBFListFromWebView().1
                if let t = webView.title {
                    if t != "" {
                        dic?["title"] = t
                    }
                }else{
                    dic?["title"] = "New Page"
                }
                b![intIndex] = dic!
            }
            BrowserFileOperations.writingToFile(text: BrowserFileOperations.convertDictionaryToJson(dictionary: b ?? []) ?? "", dir: "CellData.json")
        }
    }
    
    init(web:BrowserWKWebView,newpageExist:BrowserViewController.IsNewPageViewExist) {
        self.allowDelegateHandle = true
        self.array = nil
        self.webView = web
        self.newpageExist = newpageExist
    }
    
    init(array:CellData) {
        self.allowDelegateHandle = false
        self.array = array
    }
    
    public func removeData(index:Int) {
        
        guard !allowDelegateHandle else { return }
        
        let fav = array[index]["favicon"] as! String
        let snap = array[index]["snapshot"] as! String
        array.remove(at: index)
        BrowserFileOperations.writingToFile(text: BrowserFileOperations.convertDictionaryToJson(dictionary: array)!, dir: "CellData.json")
        BrowserFileOperations.deleteData(dir:"snapshot",name:"\(snap).png")
        BrowserFileOperations.deleteData(dir: "favicon", name: "\(fav).png")
        
    }
    public static func removePrivateData(index:Int) {
        PrivateData.privateArray.remove(at: index)
    }
    
    private func takeSnapShot(view:inout UIView,mainViewController:BrowserViewController) -> UIImage {
        self.view = view
        let a = SnapShot(target: CGRect(center: CGPoint(x: view.bounds.size.width/2, y: view.bounds.size.height/2), size: CGSize(width: base, height: base)))
        do{
            let image = try a.take(view: &view,mainViewController:mainViewController)
            return image
        }catch{
            return UIImage(named: "white.png")!
        }
    }
    
    public func createNewPageData(at:Int) {
        
        guard !allowDelegateHandle else { return }
        
        let tokens = Self.createToken()//0 token 1 favicon 2 snapshot
        let dic = ["token" : tokens.0 ,"url" : "New Page","favicon" : tokens.1,"snapshot" : tokens.2,"forwardlist" : [],"backlist" : [],"title" : "New Page"] as [String : Any]
        BrowserFileOperations.saveImage(dir: "favicon", name: "\(tokens.1).png", data: (UIImage.convenienceInit(named: "rocket.png", size: CGSize(width: 23.5, height: 23.5))?.pngData())!)
        BrowserFileOperations.saveImage(dir: "snapshot", name: "\(tokens.2).png", data: (UIImage.convenienceInit(named: "white.png", size: CGSize(width: 23.5, height: 23.5))?.pngData())!)
        array.insert(dic, at: at)
        UserDefaults.standard.setValue(tokens.0, forKey: "currentToken")
        UserDefaults.standard.setValue(at, forKey: "currentIndex")
        BrowserFileOperations.writingToFile(text: BrowserFileOperations.convertDictionaryToJson(dictionary: array!)!, dir: "CellData.json")
        
    }
    
    @discardableResult func fetchWebWindowDataToTab(at:Int,favicon:UIImage,webView:BrowserWKWebView) -> String {
        
        guard !allowDelegateHandle else { return "" }
        
        let tokens = Self.createToken()//0 token 1 favicon 2 snapshot
        let bflist = storingBFListFromWebView(webView: webView)
        if !isPrivate {
            let dic = ["token" : tokens.0 ,"url" : webView.url?.absoluteString ?? "New Page","favicon" : tokens.1,"snapshot" : tokens.2,"forwardlist" : bflist.0,"backlist" : bflist.1,"title" : webView.title ?? "New Page"] as [String : Any]
            BrowserFileOperations.saveImage(dir: "favicon", name: "\(tokens.1).png", data: favicon.pngData()!)
            BrowserFileOperations.saveImage(dir: "snapshot", name: "\(tokens.2).png", data: (UIImage.convenienceInit(named: "white.png", size: CGSize(width: 23.5, height: 23.5))?.pngData())!)
            array.insert(dic, at: at)
            UserDefaults.standard.setValue(tokens.0, forKey: "currentToken")
            UserDefaults.standard.setValue(at, forKey: "currentIndex")
            BrowserFileOperations.writingToFile(text: BrowserFileOperations.convertDictionaryToJson(dictionary: array!)!, dir: "CellData.json")
        }else{
            let dic = [["url" : webView.url?.absoluteString ?? "New Page","forwardlist" : bflist.0,"backlist" : bflist.1,"favicon" : favicon,"snapshot" : UIImage.convenienceInit(named: "rocket.png", size: CGSize(width: 23.5, height: 23.5))!,"title" : webView.title ?? "New Page","token" : tokens.0]]
            PrivateData.privateArray.insert(contentsOf: dic, at: at)
            PrivateData.token = tokens.0
            PrivateData.index = at
        }
        return tokens.0
    }
    
    public func createPrivatePage(at:Int) {
        
        guard !allowDelegateHandle else { return }
        
        let token = Self.createToken().0
        let new = [["url" : "New Page","forwardlist" : [],"backlist" : [],"favicon" : UIImage.convenienceInit(named: "rocket.png", size: CGSize(width: 23.5, height: 23.5))!,"snapshot" : UIImage(named: "white.png")!,"title" : "New Page","token" : token]]
        PrivateData.privateArray.insert(contentsOf: new, at: at)

    }
}
extension BrowserDataManager : DataReloaderDataSource {
    func getRequiredInstance() -> (BrowserTabBarController, TabCollectionViewController) {
        return self.data.getRequiredInstance()
    }
}
protocol PrivateDataCore {
    var isPrivate:Bool { get set }
    var privateArray:CellData { get set }
    var privateToken:String { get set }
    var privateIndex:Int { get set }
}
extension PrivateDataCore {
    var isPrivate:Bool {
        get{
            return DataReloader.isPrivate
        }
        set{
            DataReloader.isPrivate = newValue
        }
    }
    var privateArray:CellData {
        get{
            return BrowserDataManager.PrivateData.privateArray
        }
        set{
            BrowserDataManager.PrivateData.privateArray = newValue
        }
    }
    var privateToken:String {
        get{
            return BrowserDataManager.PrivateData.token
        }
        set{
            BrowserDataManager.PrivateData.token = newValue
        }
    }
    var privateIndex:Int {
        get{
            return BrowserDataManager.PrivateData.index
        }
        set{
            BrowserDataManager.PrivateData.index = newValue
        }
    }
}
