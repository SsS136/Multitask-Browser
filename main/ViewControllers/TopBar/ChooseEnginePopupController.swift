//
//  ChooseEnginePopupController.swift
//  practice
//
//  Created by Ryu on 2021/03/03.
//
import Foundation
import UIKit

class ChooseEnginePopupController : UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor(hex: "010E32", alpha: 1.0)
        popoverPresentationController?.backgroundColor = .systemGray3

        //initialize
        let engineList = SearchEngineList(searchEngineCellArray: [SearchEngineCellView(image: UIImage.convenienceInit(named: "google.png", size: CGSize(width: 30, height: 30)), title: "Google", tag: 100),SearchEngineCellView(image: UIImage.convenienceInit(named: "youtube.png", size: CGSize(width: 30, height: 30)), title: "YouTube", tag: 101),SearchEngineCellView(image: UIImage.convenienceInit(named: "duckduckgo.png", size: CGSize(width: 30, height: 30)), title: "DuckDuckGo", tag: 102),SearchEngineCellView(image: UIImage.convenienceInit(named: "twitter.png", size: CGSize(width: 30, height: 30)), title: "Twitter", tag: 103),SearchEngineCellView(image: UIImage.convenienceInit(named: "Amazon_icon.png", size: CGSize(width: 30, height: 30)), title: "Amazon", tag: 104),SearchEngineCellView(image: UIImage.convenienceInit(named: "wiki.png", size: CGSize(width: 30, height: 30)), title: "Wikipedia", tag: 105)])

        //autolayout
        view.addSubview(engineList)
        engineList.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 13).isActive = true
        engineList.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        engineList.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        engineList.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
        
        NotificationCenter.default.addObserver(self, selector: #selector(dismissPresentController), name: Notification.Name(rawValue: "dismiss.action"), object: nil)
        
    }
    @objc func dismissPresentController() {
        self.dismiss(animated: true, completion: nil)
    }
}
