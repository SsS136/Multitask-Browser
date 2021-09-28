//
//  BrowserDownloadSheet.swift
//  main
//
//  Created by Ryu on 2021/04/17.
//

import Foundation
import UIKit
protocol BrowserDownloadSheetDelegate : AnyObject {
    func downloadStart()
}
class BrowserDownloadSheet : UIViewController {
    var itemTitle:String = ""
    weak var delegate:BrowserDownloadSheetDelegate!
    
    lazy var downloadButton:UIButton = {() -> UIButton in
        let button = UIButton()
        button.setTitle("Download", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.titleLabel?.adjustsFontSizeToFitWidth = true
        button.setTitleColor(.whiteBlack, for: .normal)
        button.backgroundColor = .text
        button.clipsToBounds = true
        button.layer.cornerRadius = 5
        button.addTarget(self, action: #selector(self.addButtonTapped), for: .touchUpInside)
        return button
    }()
    lazy var titleLabel:UILabel = { () -> UILabel in
        let label = UILabel()
        label.text = itemTitle
        label.textColor = .blackWhite
        label.adjustsFontSizeToFitWidth = true
        label.translatesAutoresizingMaskIntoConstraints = false
        label.lineBreakMode = .byTruncatingMiddle
        return label
    }()
    let stack = UIStackView()
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .background
        stack.alignment = .center
        stack.distribution = .equalSpacing
        stack.axis = .vertical
        view.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.addArrangedSubViews([titleLabel,downloadButton])
        NSLayoutConstraint.activate([
            downloadButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.5),
           // downloadButton.heightAnchor.constraint(equalToConstant: 35),
            stack.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.7),
            stack.leftAnchor.constraint(equalTo: view.leftAnchor),
            stack.rightAnchor.constraint(equalTo: view.rightAnchor),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            titleLabel.widthAnchor.constraint(lessThanOrEqualTo: stack.widthAnchor),
            //titleLabel.heightAnchor.constraint(equalToConstant: 23)
        ])
    }
    @objc func addButtonTapped() {
        self.delegate.downloadStart()
    }
}
