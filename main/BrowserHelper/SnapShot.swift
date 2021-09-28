//
//  SnapShot.swift
//  main
//
//  Created by Ryu on 2021/05/06.
//

import Foundation
import UIKit

protocol BrowserImage : PrivateDataCore {
    var target:CGRect { get set }
    func take(view:inout UIView,mainViewController:BrowserViewController) throws -> UIImage
}

extension BrowserImage {
    func take(view:inout UIView,mainViewController:BrowserViewController) throws -> UIImage {
        
        defer{
            changeAllAlpha(alpha: 1, mainViewController: mainViewController)
            mainViewController.view.backgroundColor = isPrivate ? .privateColor : .background
        }
        
        changeAllAlpha(alpha: 0, mainViewController: mainViewController)
        mainViewController.view.backgroundColor = .whiteBlack
        UIGraphicsBeginImageContextWithOptions(target.size, false, 0.0)
        
        guard let context = UIGraphicsGetCurrentContext() else {
            throw SnapShot.SnapShotError.cannotGetContext
        }
        
        context.translateBy(x: -target.minX, y: -target.minY)
        view.layer.render(in: context)
        
        guard let image = UIGraphicsGetImageFromCurrentImageContext() else {
            throw SnapShot.SnapShotError.cannotConvert
        }
        
        UIGraphicsEndImageContext()
        return image
        
    }
    func changeAllAlpha(alpha:CGFloat,mainViewController:BrowserViewController) {
        mainViewController.contentViewController.view.alpha = alpha
        mainViewController.searchView.alpha = alpha
        mainViewController.browserTabBarController.view.alpha = alpha
        mainViewController.bottomToolBar.alpha = alpha
        mainViewController.webWindows.forEach {$0.alpha = alpha}
        mainViewController.windowButton.forEach { $0.alpha = alpha }
    }
}

struct SnapShot: BrowserImage {
    
    var target:CGRect
    
    init(target:CGRect) {
        self.target = target
    }
    enum SnapShotError : Error {
        case cannotGetContext
        case cannotConvert
    }
}

