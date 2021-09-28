//
//  UIViewExtension.swift
//  main
//
//  Created by Ryu on 2021/04/10.
//

import Foundation
import UIKit

extension UIView {
    func parentViewController() -> String? {
        var parentResponder: UIResponder? = self
        while true {
            guard let nextResponder = parentResponder?.next else { return nil }
            if let viewController = nextResponder as? UIViewController {
                return String(describing: type(of: viewController))
            }
            parentResponder = nextResponder
        }
    }

    func parentView<T: UIView>(type: T.Type) -> T? {
        var parentResponder: UIResponder? = self
        while true {
            guard let nextResponder = parentResponder?.next else { return nil }
            if let view = nextResponder as? T {
                return view
            }
            parentResponder = nextResponder
        }
    }
    func circle() {
        self.clipsToBounds = true
        self.layer.cornerRadius = self.bounds.size.width/2
    }
}
