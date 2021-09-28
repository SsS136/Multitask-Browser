//
//  SearchEngineList.swift
//  practice
//
//  Created by Ryu on 2021/03/04.
//

import Foundation
import UIKit

class SearchEngineList : UIView {
    
    init(searchEngineCellArray:[SearchEngineCellView]) {
        super.init(frame:.zero)
        self.backgroundColor = UIColor(hex: "010E32", alpha: 1.0)
        self.translatesAutoresizingMaskIntoConstraints = false
        
        let arrayCount = searchEngineCellArray.count
        
        let stack = UIStackView()
        self.addSubview(stack)
    
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.widthAnchor.constraint(equalTo: self.widthAnchor).isActive = true
        stack.heightAnchor.constraint(equalTo: self.heightAnchor).isActive = true
        stack.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        stack.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        stack.axis = .vertical
        stack.distribution = .fillProportionally
        stack.alignment = .center
        
        for i in 0..<arrayCount {
            stack.addArrangedSubview(searchEngineCellArray[i])
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
