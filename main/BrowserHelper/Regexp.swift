//
//  Regexp.swift
//  main
//
//  Created by Ryu on 2021/03/08.
//

import Foundation

final class Regexp {
    
    let internalRegexp: NSRegularExpression
    let pattern: String

    init(_ pattern: String) {
        self.pattern = pattern
        self.internalRegexp = try! NSRegularExpression( pattern: pattern, options: NSRegularExpression.Options.caseInsensitive)
    }

    func isMatch(input: String) -> Bool {
        let matches = self.internalRegexp.matches( in: input, options: [], range:NSMakeRange(0, input.count) )
        return matches.count > 0
    }

    func matches(input: String) -> [String]? {
        if self.isMatch(input: input) {
            let matches = self.internalRegexp.matches( in: input, options: [], range:NSMakeRange(0, input.count) )
            var results: [String] = []
            for i in 0 ..< matches.count {
                results.append( (input as NSString).substring(with: matches[i].range) )
            }
            return results
        }
        return nil
    }
    static func checkZenkaku(fieldText:String) -> Bool {
        return fieldText.contains("「") == true || fieldText.contains("」") == true || fieldText.contains("ー") == true || fieldText.contains("＾") == true || fieldText.contains("〜") == true || fieldText.contains("￥") == true || fieldText.contains("・") == true || fieldText.contains("？") == true || fieldText.contains("；") == true || fieldText.contains("＊") == true || fieldText.contains("｜") == true || fieldText.contains("。") == true || fieldText.contains("＞") == true || fieldText.contains("、") == true || fieldText.contains("＜") == true || fieldText.contains("＋") == true || fieldText.contains("』") == true || fieldText.contains("『") == true || fieldText.contains("あ") == true || fieldText.contains("い") == true || fieldText.contains("う") == true || fieldText.contains("え") == true || fieldText.contains("お") == true || fieldText.contains("か") == true || fieldText.contains("き") == true || fieldText.contains("く") == true || fieldText.contains("け") == true || fieldText.contains("こ") == true || fieldText.contains("た") == true || fieldText.contains("ち") == true || fieldText.contains("つ") == true || fieldText.contains("て") == true || fieldText.contains("と") == true || fieldText.contains("な") == true || fieldText.contains("に") == true || fieldText.contains("ぬ") == true || fieldText.contains("ね") == true || fieldText.contains("の") == true || fieldText.contains("は") == true || fieldText.contains("ひ") == true || fieldText.contains("ふ") == true || fieldText.contains("へ") == true || fieldText.contains("ほ") == true || fieldText.contains("ま") == true || fieldText.contains("み") == true || fieldText.contains("む") == true || fieldText.contains("め") == true || fieldText.contains("も") == true || fieldText.contains("や") == true || fieldText.contains("ゆ") == true || fieldText.contains("よ") == true || fieldText.contains("ら") == true || fieldText.contains("り") == true || fieldText.contains("る") == true || fieldText.contains("れ") == true || fieldText.contains("ろ") == true || fieldText.contains("わ") == true || fieldText.contains("お") == true || fieldText.contains("ん") == true
    }
}
