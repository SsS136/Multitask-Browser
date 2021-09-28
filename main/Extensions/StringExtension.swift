//
//  String.swift
//  main
//
//  Created by Ryu on 2021/05/28.
//

import Foundation
import UIKit

extension String {
    func hiraganaToKatakana() -> String {
        return self.transform(transform: .hiraganaToKatakana, reverse: false)
    }
    func katakanaTohiragana() -> String {
        return self.transform(transform: .hiraganaToKatakana, reverse: true)
    }
    private func transform(transform: StringTransform, reverse: Bool) -> String {
        if let string = self.applyingTransform(transform, reverse: reverse) {
            return string
        } else {
            return ""
        }
    }
    var isHiragana: Bool {
        let range = "^[ぁ-ゞ 　]+$"
        return NSPredicate(format: "SELF MATCHES %@", range).evaluate(with: self)
    }

    var isKatakana: Bool {
        let range = "^[ァ-ヾ]+$"
        return NSPredicate(format: "SELF MATCHES %@", range).evaluate(with: self)
    }

    var isAlphanumeric:Bool {
        let range = "[a-zA-Z0-9]+"
        return NSPredicate(format: "SELF MATCHES %@", range).evaluate(with: self)
    }
}
