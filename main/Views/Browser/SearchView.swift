//
//  SearchView.swift
//  main
//
//  Created by Ryu on 2021/03/08.
//

import Foundation
import UIKit
extension UIStackView {
    
func removeAllArrangedSubviews() {
    let removedSubviews = arrangedSubviews.reduce([]) { (allSubviews, subview) -> [UIView] in
        self.removeArrangedSubview(subview)
        return allSubviews + [subview]
    }
    NSLayoutConstraint.deactivate(removedSubviews.flatMap({$0.constraints }))
    removedSubviews.forEach({ $0.removeFromSuperview() })
    }
}
protocol SearchViewDelegate : AnyObject {
    func linkLoad(url:String)
}
class SearchView : UIView, SearchViewCellDelgate {
    var stack = UIStackView()
    weak var delegate:SearchViewDelegate!
    init() {
        super.init(frame: .zero)
        let blurEffect = UIBlurEffect(style: .dark)
        let visualEffectView = UIVisualEffectView(effect: blurEffect)
        visualEffectView.frame = self.frame
        self.addSubview(visualEffectView)
        visualEffectView.translatesAutoresizingMaskIntoConstraints = false
        visualEffectView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        visualEffectView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        visualEffectView.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
        visualEffectView.leftAnchor.constraint(equalTo: self.leftAnchor).isActive = true
        
        self.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        stack.leftAnchor.constraint(equalTo: self.leftAnchor).isActive = true
        stack.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
        stack.axis = .vertical
        stack.distribution = .fillProportionally
        stack.alignment = .center
        
    }
    func stackCount() -> Int {
        var counter:Int = 0
        for _ in stack.subviews {
            counter+=1
        }
        return counter
    }

    func addCellToStack(cellArray:[SearchViewCell]) {
        stack.removeAllArrangedSubviews()
        for cell in cellArray {
            stack.addArrangedSubview(cell)
            cell.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
            cell.leftAnchor.constraint(equalTo: self.leftAnchor).isActive = true
            cell.delegate = self
        }
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.heightAnchor.constraint(lessThanOrEqualTo: self.heightAnchor).isActive = true
    }
    func removeCellFromStack(index:Int) {
        
    }
    func linkLoad(url: String) {
        self.delegate.linkLoad(url: url)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
