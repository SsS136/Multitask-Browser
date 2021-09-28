//
//  CustomWebView.swift
//  main
//
//  Created by Ryu on 2021/03/20.
//

import UIKit
import WebKit
import Foundation

protocol CustomWKWebDelegate : AnyObject {
    func urlDidGet(customWebView: BrowserWKWebView, arrURL: [URL])
}

class BrowserWKWebView: WKWebView {

    
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    var arrDownloadRequest = [URL]()

    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    var backList:[String] = []
    var forwardList:[String] = []
//    override var backForwardList: WKBackForwardList {
//        get{
//
//        }
//    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override init(frame: CGRect, configuration: WKWebViewConfiguration) {
        super.init(frame: frame, configuration: configuration)
    }
    
    init(frame: CGRect){
        // Default WKWebConfiguration is applyed.
        let configuration = WKWebViewConfiguration()
        super.init(frame: frame, configuration: configuration)
        self.allowsBackForwardNavigationGestures = true
    }
    
    override func layerWillDraw(_ layer: CALayer) {
    }
    
    public func getIconImage(){
        let scriptPath = Bundle.main.path(forResource: "script", ofType: "js")
        let script: String?
        arrDownloadRequest.removeAll()
        
        do{
            script = try String(contentsOfFile: scriptPath!, encoding: String.Encoding.utf8)
        }catch let error as NSError{
            print("Script file does not exist. \(error)")
            return
        }
        self.evaluateJavaScript(script!, completionHandler: {(result, error) -> Void in
            guard let result = result, error == nil else{
                print(error ?? "Error: Point 1")
                return
            }
            self.getIconImage_func1(result: result)
        })
    }
    
    func loadURL(url: String){
        let request = URLRequest(url: URL(string: url)!)
        self.load(request)
    }
    
    
    private func getIconImage_func1(result: Any){
        let iconURL = String(describing: result)
        let tempMyURL = (self.url?.absoluteString)!
        
        if iconURL.isEmpty == false && tempMyURL.isEmpty == false{
            let myURL = String(tempMyURL)
            
            //------------------------------------------------------
            //  myURL might contain this 3 patterns
            //  https://www.test.com/
            //  https://www.test.com/testDirectry/
            //  https://www.test.com/testDirectry/testFile.html
            //
            //  iconURL might contain this 5 patterns
            //  https://www.test.com/testDirectry/image.png
            //  //www.test.com/testDirectry/image.png
            //  /testDirectry/image.png
            //  testDirectry/image.png
            //  ./testDirectry/image.png
            //------------------------------------------------------
            
            if iconURL.hasPrefix("http"){
                //  Absolute Path.; https://www.test.com/images/image.png
                let strURL = iconURL
                let url = URL(string: strURL)
                if let a = url {
                    arrDownloadRequest.append(a)
                }
            }else if iconURL.hasPrefix("//"){
                //  Absolute Path.; //www.test.com/images/image.png
                let httpsURL = "https:" + iconURL
                let url = URL(string: httpsURL)
                if let a = url {
                    arrDownloadRequest.append(a)
                }
            }else if (iconURL[iconURL.startIndex] == "/" && iconURL.hasPrefix("//") == false){
                //  Absolute Path.; /images/image.png
                let mainPage = suggestMainPage(url: myURL)
                let strURL = mainPage + iconURL
                let url = URL(string: strURL)
                if let a = url {
                    arrDownloadRequest.append(a)
                }
            }else if (iconURL[iconURL.startIndex] != "/" && iconURL[iconURL.startIndex] != "."){
                //  Relative Path.; images/image.png
                let strURL = myURL + iconURL
                let url = URL(string: strURL)
                if let a = url {
                    arrDownloadRequest.append(a)
                }
            }else if iconURL.hasPrefix("../"){
                //  Relative Path.; ./images/image.png
                let directryCount = stringCount(counted: iconURL, counting: "../")
                let strURL = moveDirectry(url: myURL, back: directryCount)
                let url = URL(string: strURL)
                if let a = url {
                    arrDownloadRequest.append(a)
                }
            }else if iconURL.hasPrefix("./"){
                //  Relative Path.; ../images/image.png
                let directryCount = stringCount(counted: iconURL, counting: "./")
                let strURL = moveDirectry(url: myURL, back: directryCount)
                let url = URL(string: strURL)
                if let a = url {
                    arrDownloadRequest.append(a)
                }
            }
        }
        urlDidGet(url: arrDownloadRequest)
    }
    
    private func stringCount(counted: String, counting: String) -> Int{
        let length = counting.count
        var num = 0
        var counter = 0
        for char in counted {
            let index = counting.index(counting.startIndex, offsetBy: num)
            if char == counting[index]{
                num += 1
                if num == length{
                    num = 0
                    counter += 1
                }
            }else{
                num = 0
            }
        }
        
        return counter
    }
    
    private func moveDirectry(url: String, back: Int) -> String{
        var tempURL = url
        var count = 0
        for num in 1...tempURL.count{
            let index = tempURL.index(tempURL.endIndex, offsetBy: -1)
            print(tempURL[index])
            if tempURL[index] == "/" && num != 1{
                count += 1
                guard count + 1 == back else{
                    tempURL.remove(at: index)
                    return tempURL
                }
            }
            tempURL.remove(at: index)
        }
        return ""
    }
    

    private func suggestMainPage(url: String)-> String{
        var num = 0
        var tempURL = ""
        for chara in url {
            if String(chara) == "/"{
                if num > 1{
                    return tempURL
                }else{
                    tempURL += String(chara)
                }
                num += 1
            }else{
                tempURL += String(chara)
            }
        }
        return ""
    }
    
    
    // Delegate
    weak var delegate: CustomWKWebDelegate!
    func urlDidGet(url: [URL]){
        self.delegate.urlDidGet(customWebView: self, arrURL: url)
    }
}

