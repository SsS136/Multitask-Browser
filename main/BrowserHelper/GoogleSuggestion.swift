//
//  GoogleSuggestion.swift
//  main
//
//  Created by Ryu on 2021/05/29.
//

import Foundation
import UIKit
import Kanna

class GoogleSuggestion {
    enum SuggestionError : Error {
        case failedTofetchData
        case detectNULLData
    }
    static func searchSuggestion(searchText:String,count:Int,completionHandler:@escaping (Result<[String],SuggestionError>) -> ()) {
        if UserDefaults.standard.bool(forKey: "suggestion") {
            let url = "https://www.google.com/complete/search?hl=en&q=" + searchText.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)! + "&output=toolbar"
            var array = [String]()
            DispatchQueue.global().async {
                if let doc = try? XML(url: URL(string: url)!, encoding: .utf8) {
                    var counter = 0
                    doc.xpath("//suggestion").forEach {
                        if let element = $0["data"] {
                            guard counter < count else { return }
                            array.append(element)
                            counter+=1
                        }
                    }
                    completionHandler(.success(array))
                }else{
                    completionHandler(.failure(.detectNULLData))
                }
            }
        }
    }
}


