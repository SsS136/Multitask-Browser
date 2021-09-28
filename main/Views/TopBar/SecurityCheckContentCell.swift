//
//  SecurityCheckContentCell.swift
//  practice
//
//  Created by Ryu on 2021/03/05.
//

import Foundation
import UIKit

class SecurityCheckContentCell : UIView {
    var stack = UIStackView()
    
    init(object:[Any]) {
        
        super.init(frame: .zero)
        self.backgroundColor = UIColor(hex: "010E32", alpha: 1.0)
        self.translatesAutoresizingMaskIntoConstraints = false
        self.heightAnchor.constraint(equalToConstant: 55).isActive = true
        
        self.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.widthAnchor.constraint(equalTo: self.widthAnchor, multiplier: 0.90).isActive = true
        stack.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        stack.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        stack.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        stack.axis = .horizontal
        stack.alignment = .center
        stack.distribution = .equalSpacing

        for i in 0..<object.count {
            if let obj = object[i] as? UIView {
                stack.addArrangedSubview(obj)
            }
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
