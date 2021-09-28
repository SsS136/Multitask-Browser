//
//  UIImage.Orientation.swift
//  main
//
//  Created by Ryu on 2021/04/09.
//

import Foundation
import UIKit
extension UIImage.Orientation {
    
    var isLandscape: Bool {
        switch self {
        case .up, .down, .upMirrored, .downMirrored:
            return false
        case .left, .right, .leftMirrored, .rightMirrored:
            return true
        @unknown default:
            fatalError()
        }
    }
    
}
