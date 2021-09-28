//
//  AutoCompleteManager.swift
//  main
//
//  Created by Ryu on 2021/05/28.
//

import Foundation
import UIKit

protocol AutoCompleteManagerDelegate : AnyObject {
    func fetchTopSearchbarViewDelegate() -> TopSearchbarView
}
final class AutoCompleteManager {
    static weak var delegate:AutoCompleteManagerDelegate!
    static let path = Bundle.main.path(forResource: "domains", ofType: "txt")
    static private(set) internal var currentList:[String] {
        get{
            //[String]
            UserDefaults.standard.register(defaults: ["currentList":famousDomains()])
            return UserDefaults.standard.array(forKey: "currentList") as! [String]
        }
        set{
            UserDefaults.standard.setValue(newValue, forKey: "currentList")
            var list = UserDefaults.standard.array(forKey: "currentList")
            if list!.count > 200 {
                list?.removeLast()
            }
        }
    }
    static private func famousDomains() -> [String] {
        var arrayOfStrings: [String]?
        do {
            if let path = path {
                let data = try String(contentsOfFile:path, encoding: String.Encoding.utf8)
                arrayOfStrings = data.components(separatedBy: "\n")
            }
        }catch let err as NSError{
            print(err)
        }
        return arrayOfStrings!
    }
    static func addAutoCompleteDomain(url:String) {
        let instance = delegate.fetchTopSearchbarViewDelegate()
        currentList.append(url)
        instance.textField.filterStrings(currentList)
    }
    static func addAutoCompleteDomains(urls:[String]) {
        urls.forEach { addAutoCompleteDomain(url: $0) }
    }
}
