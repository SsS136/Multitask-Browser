//
//  UIColorExtension.swift
//  main
//
//  Created by Ryu on 2021/03/11.
//

import Foundation
import UIKit

extension UIColor {
    convenience init(hex: String, alpha: CGFloat = 1.0) {
        let v = Int("000000" + hex, radix: 16) ?? 0
        let r = CGFloat(v / Int(powf(256, 2)) % 256) / 255
        let g = CGFloat(v / Int(powf(256, 1)) % 256) / 255
        let b = CGFloat(v / Int(powf(256, 0)) % 256) / 255
        self.init(red: r, green: g, blue: b, alpha: min(max(alpha, 0), 1))
    }
    class func rgba(red: Int, green: Int, blue: Int, alpha: CGFloat) -> UIColor{
        return UIColor(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: alpha)
    }
    public class func dynamicColor(light: UIColor, dark: UIColor) -> UIColor {
        if #available(iOS 13, *) {
            return UIColor { (traitCollection:UITraitCollection) -> UIColor in
                if traitCollection.userInterfaceStyle == .dark {
                    return dark
                } else {
                    return light
                }
            }
        }
        return light
    }
    public static var borderColor:UIColor {
        return dynamicColor(light: UIColor(hex: "CFCFCF"), dark: UIColor(hex: "313F52"))
    }
    public static var background: UIColor {
        return dynamicColor(
            light: UIColor(hex: "F1F1F1"),//UIColor(hex: "F0FEFB"),
            dark: UIColor(hex: "191E25")//UIColor(hex: "080037")
        )
    }
    public static var selected:UIColor {
        return dynamicColor(light:UIColor(hex: "E7E6E1"),dark:UIColor(hex: "343F56"))
    }
    public static var collectionSelected = UIColor.orange
    public static var text: UIColor {
        return dynamicColor(
            light: UIColor(hex: "191E25"),
            dark: UIColor(hex: "F1F1F1")
        )
    }
    public static var newPageColor:UIColor {
        return dynamicColor(light: UIColor(hex: "F0F2F3"), dark: .rgba(red: 41, green: 40, blue: 45, alpha: 1))
    }
    public static var privateSelectedColor:UIColor {
        return dynamicColor(light: .white, dark: UIColor(hex: "5F9FF4"))
    }
    public static var privateColor:UIColor {
        return dynamicColor(light: UIColor(hex: "D7D7FF"), dark: UIColor(hex: "2E0170"))
    }
    public static var blackWhite : UIColor {
        return dynamicColor(light: .black, dark: .white)
    }
    public static var whiteBlack : UIColor {
        return dynamicColor(light: .white, dark: .black)
    }
}
