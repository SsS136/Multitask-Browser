//
//  TranslationManager.swift
//  main
//
//  Created by Ryu on 2021/05/28.
//

import Foundation
import UIKit
import Kanna

protocol TranslationManagerDelegate : AnyObject {
    func openUrl(urlString:String)
    func descendTranslataionView()
}

final class TranslationManager : WebLanguage {
    
    //url to translate
    var url: URL
    
    //Notify if web should be translated.
    weak var delegate:TranslationManagerDelegate!
    
    private var searchURL:String = ""
    private var mustTranslate:Bool = false {
        didSet {
            if mustTranslate {
                self.delegate.descendTranslataionView()
            }
        }
    }
    
    init(url:URL) {
        self.url = url
        identifyWebLanguage { result in
            DispatchQueue.main.async {
                if case let .success(bool) = result {
                    if bool {
                        self.mustTranslate = true
                        let language = LanguageDetector.deviceLanguage
                        let baseURL = "https://translate.google.com/translate?hl=\(language)&sl=auto&tl=\(language)&u=\(url.absoluteString)&sandbox=1"
                        self.searchURL = baseURL
                    }else{
                        self.mustTranslate = false
                    }
                }else{
                    self.mustTranslate = false
                }
            }
        }
    }
    
    func mustTranslateThisPage() -> Bool {
        return mustTranslate
    }
    
    @discardableResult func translate() -> Bool {
        guard mustTranslate else {
            return false
        }
        self.delegate.openUrl(urlString: searchURL.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)!)
        return true
    }
    
    enum WebError : Error {
        case invalidUrl
    }
}
protocol WebLanguage {
    var url:URL{get set}
}
extension WebLanguage {
    func identifyWebLanguage(completionHandler:@escaping (Result<Bool,TranslationManager.WebError>) -> ()) {
        DispatchQueue.global().async {
            if let data = try? Data(contentsOf: url),let doc = try? HTML(html: data, encoding: .utf8) {
                var isDeviceLanguage:[Bool] = []
                doc.css("p,li,a").forEach {
                    isDeviceLanguage.append(LanguageDetector().findOutOtherLanguageOrNot($0.content ?? ""))//
                }
                let beforeCount = isDeviceLanguage.count
                let afterCount = isDeviceLanguage.filter {$0}.count
                completionHandler(.success(beforeCount/2 < afterCount ? true : false))
            }else{
                completionHandler(.failure(.invalidUrl))
            }
        }
    }
}

///code for https://qiita.com/_ha1f/items/3f45ed483e8366fbe81c
struct LanguageDetector {
    static var deviceLanguage:String {
        return Locale.preferredLanguages[0]
    }
    static let undetermined = "und"

    private let tagger = NSLinguisticTagger(tagSchemes: [.language], options: 0)
    private func detect(_ text: String) -> String {
        guard !text.isEmpty else {
            return LanguageDetector.undetermined
        }
        tagger.string = text
        return tagger.tag(at: 0, scheme: .language, tokenRange: nil, sentenceRange: nil)?.rawValue ?? LanguageDetector.undetermined
    }
    func findOutOtherLanguageOrNot(_ text:String) -> Bool {
        let languageCode = detect(text)
        return languageCode.contains("und") ? false : !Self.deviceLanguage.contains(languageCode)
    }
}
