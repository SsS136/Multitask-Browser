//
//  UIStackViewExtension.swift
//  main
//
//  Created by Ryu on 2021/03/18.
//

import Foundation
import UIKit

extension UIStackView {
    func addArrangedSubViews(_ views:[UIView]) {
        for view in views {
            self.addArrangedSubview(view)
        }
    }
}
