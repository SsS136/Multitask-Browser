//
//  SecurityCheckContentView.swift
//  practice
//
//  Created by Ryu on 2021/03/05.
//

import Foundation
import UIKit
protocol SecurityCheckContentViewDelegate : AnyObject {
    func reloadWebView()
    func unableAdBlock()
}
class SecurityCheckContentView : UIView {
    weak var delegate:SecurityCheckContentViewDelegate!
    var stackView = UIStackView()
    var swch = UISwitch()

    override init(frame:CGRect) {
        super.init(frame: .zero)
        
        self.backgroundColor = UIColor(hex: "010E32", alpha: 1.0)
        self.translatesAutoresizingMaskIntoConstraints = false
        
        self.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        stackView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        stackView.widthAnchor.constraint(equalTo: self.widthAnchor).isActive = true
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.distribution = .fillProportionally
        
        //first cell
        let imageView = UIImageView(image: UIImage(systemName: "lock.shield")).then{
            $0.tintColor = secureChecker ? .gray : .red
        }
        
        let state = UILabel()
        state.text = secureChecker ? "This page is encrypted" : "This page is not encrypted"
        state.adjustsFontSizeToFitWidth = true
        state.translatesAutoresizingMaskIntoConstraints = false
        state.textColor = .white

        let cellView1 = SecurityCheckContentCell(object: [imageView,state])
        stackView.addArrangedSubview(cellView1)
        state.widthAnchor.constraint(equalTo: cellView1.stack.widthAnchor, multiplier: 0.8).isActive = true
        
        cellView1.widthAnchor.constraint(equalTo: self.widthAnchor).isActive = true
        //center line
        let line = LineView()
        stackView.addArrangedSubview(line)
        line.widthAnchor.constraint(equalTo: cellView1.widthAnchor, multiplier: 0.8).isActive = true
        
        //secondcell
        let cellView:SecurityCheckContentCell
        
        do {
            let state = UILabel()
            state.text = "Block not encrypted webpages"
            state.adjustsFontSizeToFitWidth = true
            state.translatesAutoresizingMaskIntoConstraints = false
            state.textColor = .white
            swch.isOn = UserDefaults.standard.bool(forKey: "blockhttp")
            swch.addTarget(self, action: #selector(changeSwitch(sender:)), for: UIControl.Event.valueChanged)
            cellView = SecurityCheckContentCell(object: [state,swch])
            stackView.addArrangedSubview(cellView)
            state.widthAnchor.constraint(equalTo: cellView.stack.widthAnchor, multiplier: 0.8).isActive = true
            cellView.widthAnchor.constraint(equalTo: self.widthAnchor).isActive = true
        }
        let line2 = LineView()
        stackView.addArrangedSubview(line2)
        line2.widthAnchor.constraint(equalTo: cellView1.widthAnchor, multiplier: 0.8).isActive = true
        stackView.addArrangedSubview(line2)
        let adblock = UILabel().then{
            $0.text = "Ad Block"
            $0.adjustsFontSizeToFitWidth = true
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.textColor = .white
        }
        var adblockSwitch = UISwitch().then {
            UserDefaults.standard.register(defaults: ["adblock" : true])
            $0.isOn = UserDefaults.standard.bool(forKey: "adblock")
            $0.frame = .zero
            $0.addTarget(self, action: #selector(adblockModeChange(sender:)), for: UIControl.Event.valueChanged)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        let adblockCell = SecurityCheckContentCell(object: [adblock,adblockSwitch])
        stackView.addArrangedSubview(adblockCell)
        adblock.widthAnchor.constraint(equalTo: adblockCell.stack.widthAnchor, multiplier: 0.8).isActive = true
        adblockCell.widthAnchor.constraint(equalTo: self.widthAnchor).isActive = true
        let line3 = LineView()
        stackView.addArrangedSubview(line3)
        line3.widthAnchor.constraint(equalTo: cellView1.widthAnchor, multiplier: 0.8).isActive = true
        stackView.addArrangedSubview(line3)
        let level = UILabel().then {
            $0.text = "Block Level"
            $0.adjustsFontSizeToFitWidth = true
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.textColor = .white
        }
        let adblockSegment = UISegmentedControl(items: ["low","middle","high"]).then {
            UserDefaults.standard.register(defaults: ["blockLevel" : 1])
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.addTarget(self, action: #selector(adblockLevelChanged(sender:)), for: .valueChanged)
            $0.backgroundColor = .gray
            $0.selectedSegmentTintColor = .lightGray
            $0.selectedSegmentIndex = UserDefaults.standard.integer(forKey: "blockLevel")
        }
        let blockLevel = SecurityCheckContentCell(object: [level,adblockSegment])
        stackView.addArrangedSubview(blockLevel)
        adblockSegment.widthAnchor.constraint(equalTo: blockLevel.stack.widthAnchor, multiplier: 0.65).isActive = true
        level.widthAnchor.constraint(equalTo: blockLevel.stack.widthAnchor, multiplier: 0.35).isActive = true
        blockLevel.widthAnchor.constraint(equalTo: self.widthAnchor).isActive = true
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    @objc func changeSwitch(sender:UISwitch) {
        if sender.isOn {
            NotificationCenter.default.post(name: Notification.Name(rawValue: "block.action"), object: nil, userInfo: ["state": "true"])
        }else{
            NotificationCenter.default.post(name: Notification.Name(rawValue: "block.action"), object: nil, userInfo: ["state": "false"])
        }
    }
    @objc func adblockModeChange(sender:UISwitch) {
        UserDefaults.standard.setValue(sender.isOn, forKey: "adblock")
        if sender.isOn {
            //self.delegate.reloadWebView()
            NotificationCenter.default.post(name: Notification.Name("reloadWebView"), object: nil)
        }else{
            //self.delegate.unableAdBlock()
            NotificationCenter.default.post(name: Notification.Name("unableAdBlock"), object: nil)
        }
    }
    @objc func adblockLevelChanged(sender:UISegmentedControl) {
        UserDefaults.standard.setValue(sender.selectedSegmentIndex, forKey: "blockLevel")
        //self.delegate.unableAdBlock()
        NotificationCenter.default.post(name: Notification.Name("unableAdBlock"), object: nil)
    }
}
