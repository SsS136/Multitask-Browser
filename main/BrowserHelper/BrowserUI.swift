//
//  BrowserUI.swift
//  main
//
//  Created by Ryu on 2021/05/15.
//

import Foundation
import UIKit
extension UIColor {

    static func colorLerp(from: UIColor, to: UIColor, progress: CGFloat) -> UIColor {
        
        let t = max(0, min(1, progress))
        
        var redA: CGFloat = 0
        var greenA: CGFloat = 0
        var blueA: CGFloat = 0
        var alphaA: CGFloat = 0
        from.getRed(&redA, green: &greenA, blue: &blueA, alpha: &alphaA)
        
        var redB: CGFloat = 0
        var greenB: CGFloat = 0
        var blueB: CGFloat = 0
        var alphaB: CGFloat = 0
        to.getRed(&redB, green: &greenB, blue: &blueB, alpha: &alphaB)
        
        let lerp = { (a: CGFloat, b: CGFloat, t: CGFloat) -> CGFloat in
            return a + (b - a) * t
        }
        
        let r = lerp(redA, redB, t)
        let g = lerp(greenA, greenB, t)
        let b = lerp(blueA, blueB, t)
        let a = lerp(alphaA, alphaB, t)
        
        return UIColor(red: r, green: g, blue: b, alpha: a)
    }
}
struct BrowserUI {
    static let ink70 = UIColor(hex: "363959")
    static let ink80 = UIColor(hex: "202340")
    static let ink90 = UIColor(hex: "0f1126")
}
