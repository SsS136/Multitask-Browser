//
//  BrowserTabBarController.swift
//  main
//
//  Created by Ryu on 2021/04/19.
//

import Foundation
import UIKit

protocol BrowserTabBarControllerDelegate : AnyObject {
    func didDeleteCell(token:String,index:Int)//
    func isDisplayNewPage(display:Bool)//
    func cellTapped()//
    func cellTapped(cell:TabCollectionViewCell?,indexPath:IndexPath)//
    func changeTextFieldBlank()//
    func reloadTabBar()//
    func reloadTabCollection()//
    func touchedTabBar(bool:Bool)//
    func getRequiredInstance() -> (BrowserTabBarController, TabCollectionViewController)//
    func tabToWebWindow(_ sender: BrowserTabLongPressGesture)
    func getCellInstance(at:IndexPath) -> (BrowserTabBarCell?, TabCollectionViewCell?)
    func getMainInstance() -> BrowserViewController
}

protocol PastCellManagerDelegate {
    func getMainInstance() -> BrowserViewController
}

struct PastCellManager {
    static var pastCell:(BrowserTabBarCell?,TabCollectionViewCell?)
    static var delegate:PastCellManagerDelegate!
    static func batchSelected() {
        pastCell.0?.backgroundColor = .selected
        pastCell.1?.selected()
    }
    static func batchDeselected() {
        let browser = delegate.getMainInstance()
        let tabbar = browser.browserTabBarController
        let tabCollection = browser.contentViewController
        for i in 0..<tabbar.array().count {
            if let tabbarcell = tabbar.collectionView.cellForItem(at: IndexPath(row: i, section: 0)) as? BrowserTabBarCell,let tabcell = tabCollection.collectionView.cellForItem(at: IndexPath(row: i, section: 0)) as? TabCollectionViewCell {
                tabbarcell.deselected()
                tabcell.deselected()
            }
        }
    }
    static var cellCount = 0
}

class BrowserTabBarController : UIViewController,BrowserTabBarCellDelegate,UICollectionViewDataSource, UICollectionViewDelegate,UICollectionViewDelegateFlowLayout, DataReloaderDataSource, PrivateDataCore, PastCellManagerDelegate {
    func getMainInstance() -> BrowserViewController {
        return self.delegate.getMainInstance()
    }
    
    func getRequiredInstance() -> (BrowserTabBarController, TabCollectionViewController) {
        self.delegate.getRequiredInstance()
    }
    
    static var cellColor = UIColor.background
    weak var delegate:BrowserTabBarControllerDelegate!
    
    fileprivate lazy var reloader:DataReloader = {
        var a = DataReloader()
        a.data = self
        return a
    }()
    
    lazy var collectionView: UICollectionView = {
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .background
        collectionView.register(BrowserTabBarCell.self, forCellWithReuseIdentifier: "TabBarCell")
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.semanticContentAttribute = .forceRightToLeft
        return collectionView
    }()
    
    lazy var array = { () -> CellData in
        var cellData = CellData()
        defer{
            PastCellManager.cellCount = cellData.count
        }
        if !FileManager.default.fileExists(atPath: NSHomeDirectory() + "/Documents/CellData.json") {
            let jsonString = BrowserFileOperations.convertDictionaryToJson(dictionary: [])
            BrowserFileOperations.writingToFile(text: jsonString!, dir: "CellData.json")
        }
        let res = BrowserFileOperations.readFromFile(dir: "CellData.json")
        cellData = BrowserFileOperations.getArrayFromJsonData(jsonData: res.data(using: .utf8)!) ?? []
        return cellData
    }
    
    var isPrivate:Bool {
        get{
            return DataReloader.isPrivate
        }
        set{
            DataReloader.isPrivate = newValue
        }
    }
    
    var privateArray:CellData {
        get{
            return BrowserDataManager.PrivateData.privateArray
        }set{
            BrowserDataManager.PrivateData.privateArray = newValue
        }
    }
    
    func reloadArray() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            self.collectionView.reloadData()
        }
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return isPrivate ? privateArray.count : array().count
    }
    static var count:Bool = false
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell:BrowserTabBarCell = collectionView.dequeueReusableCell(withReuseIdentifier: "TabBarCell", for: indexPath) as! BrowserTabBarCell
        cell.delegate = self
        cell.backgroundColor = Self.cellColor
        
        let longPress = BrowserTabLongPressGesture(target: self, action: #selector(tabToWebWindow(_:)))
        longPress.minimumPressDuration = 0.27
        longPress.cell = cell
        cell.addGestureRecognizer(longPress)
        
        let dic = isPrivate ? privateArray[indexPath.item] : array()[indexPath.item]
        
        if indexPath.row == UserDefaults.standard.integer(forKey: "currentIndex") {
            cell.selected()
        }
        
        if !isPrivate {
            let t = dic["token"] as! String
            cell.token = t
            if let title = dic["title"] as? String {
                if title != "" {
                    cell.setTitle(title:title, token: t)
                }else{
                    cell.setTitle(title: "about:blank", token: t)
                }
            }
            return cell
        }else{
            let token = dic["token"] as! String
            var title = ""
            if let t = dic["title"] as? String {
                if t != "" {
                    title = t
                }else{
                    title = "New Page"
                }
            }else{
                title = "about:blank"
            }
            cell.token = token
            cell.setTitle(title:title, token: token)
            return cell
        }
    }
    @objc func tabToWebWindow(_ sender: BrowserTabLongPressGesture) {
        self.delegate.tabToWebWindow(sender)
    }
    func didDeleteTab(cell:BrowserTabBarCell) {
        
        guard (isPrivate ? privateArray.count : array().count) != 1  || cell.titleLabel.text != "New Page" else { return }
        cell.delegate = self
        
        let token = String(cell.token)
        guard let index = searchArray(fromToken: token) else { return }

        reloader.delete(at: [IndexPath(row: index, section: 0)], completionHandler: nil)
        
        self.remove(at: index)
        
        self.delegate.didDeleteCell(token: token, index: index)
        if self.isPrivate ? self.privateArray.count == 0 : self.array().count == 0 {
            self.delegate.isDisplayNewPage(display: true)
            self.addButtonTapped()
            self.delegate.changeTextFieldBlank()
            //self.delegate.reloadTabCollection()
        }
    }
    private func deleteAll(at:Int) -> Bool {
        guard isPrivate ? privateArray.count < at : array().count < at else {
            let alert: UIAlertController = UIAlertController(title: "これ以上表示できません", message: "全て削除しますか？", preferredStyle:  UIAlertController.Style.alert)
            let defaultAction: UIAlertAction = UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler:{
                (action: UIAlertAction!) -> Void in
                BrowserFileOperations.removeSomeFile(files: ["CellData.json","favicon","snapshot"])
                self.addButtonTapped()
                print("OK")
            })
            let cancelAction: UIAlertAction = UIAlertAction(title: "キャンセル", style: UIAlertAction.Style.cancel, handler:{
                (action: UIAlertAction!) -> Void in
                print("Cancel")
            })
            alert.addAction(defaultAction);alert.addAction(cancelAction)
            present(alert, animated: true, completion:nil)
            return false
        }
        return true
    }
    private func reloadAll() {
        reloader.reloadAll()
    }
    private func save(at:Int) {
        let data = BrowserDataManager(array: isPrivate ? privateArray : array())
        data.createNewPageData(at: at)
    }
    private func scroll(at:Int,animated:Bool,point:UICollectionView.ScrollPosition) {
        collectionView.scrollToItem(at: IndexPath(row:at, section: 0), at: point, animated: animated)
    }
    public func addButtonTapped(at:Int = 0) {
        guard deleteAll(at: 500) else { return }

        reloader.insert(at: [IndexPath(row: at, section: 0)], completionHandler: nil)
        
        DispatchQueue.main.asyncAfter(deadline: .now()) {
            PastCellManager.delegate = self
            PastCellManager.batchDeselected()
        }

        if isPrivate {
            let data = BrowserDataManager(array: privateArray)
            data.data = self
            data.createPrivatePage(at: at)
        }else{
            save(at: at)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.scroll(at: 1, animated: false, point: .centeredHorizontally)
            self.scroll(at: 0, animated: true, point: .right)
        }
    }
    func remove(at:Int) {
        if isPrivate {
            BrowserDataManager.removePrivateData(index: at)
        }else{
            let data = BrowserDataManager(array: array())
            data.removeData(index: at)
        }
    }
    public func addWebViewForTargetBlank() {
        let at:Int
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            PastCellManager.delegate = self
            PastCellManager.batchDeselected()
        }
        if isPrivate {
            at = BrowserDataManager.PrivateData.index
            reloader.insert(at: [IndexPath(row: at, section: 0)], completionHandler: nil)
            let data = BrowserDataManager(array: privateArray)
            data.data = self
            data.createPrivatePage(at: at)
        }else{
            at = UserDefaults.standard.integer(forKey: "currentIndex")
            reloader.insert(at: [IndexPath(row: at, section: 0)], completionHandler: nil)
            save(at: at)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.scroll(at:at,animated: true,point: .centeredHorizontally)
            if let newCell:BrowserTabBarCell = self.collectionView.cellForItem(at: IndexPath(row: at, section: 0)) as? BrowserTabBarCell {
                newCell.cancelButton.isEnabled = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    newCell.cancelButton.isEnabled = true
                }
            }
        }
    }
    private func searchArray(fromToken:String) -> Int? {
        var count = 0
        for arr in isPrivate ? privateArray : array() {
            let dic = arr as [String : Any]
            if dic["token"] as! String == fromToken {
                return count
            }
            count+=1
        }
        return nil
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        _ = isPrivate ? privateArray : array()
        view.addSubview(collectionView)
        view.backgroundColor = .systemGray3
        view.layer.borderWidth = 0.3
        view.layer.borderColor = UIColor.borderColor.cgColor
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.dataSource = self
        collectionView.delegate = self

        NSLayoutConstraint.activate([
            collectionView.leftAnchor.constraint(equalTo: view.leftAnchor),
            collectionView.rightAnchor.constraint(equalTo: view.rightAnchor),
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        view.layer.borderColor = UIColor.borderColor.cgColor
    }
}

extension BrowserTabBarController {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return BrowserUX(tabBar: view, cellData: array()).tabBarCellSize
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
           return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let cell:BrowserTabBarCell = collectionView.cellForItem(at: indexPath) as? BrowserTabBarCell, cell != collectionView.cellForItem(at: IndexPath(row: isPrivate ? BrowserDataManager.PrivateData.index : UserDefaults.standard.integer(forKey: "currentIndex"), section: 0)) as? BrowserTabBarCell else { return }
        guard isPrivate ? privateArray.count != 1 : array().count != 1 else { return }
        
        let cellToken = cell.token
        
        if isPrivate {
            BrowserDataManager.PrivateData.token = cellToken
            BrowserDataManager.PrivateData.index = indexPath.item
        }else{
            UserDefaults.standard.setValue(cellToken, forKey: "currentToken")
            UserDefaults.standard.setValue(indexPath.item, forKey: "currentIndex")
        }
        
        //collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true
        
        self.delegate.touchedTabBar(bool:true)
        self.delegate.cellTapped(cell: nil,indexPath: indexPath)
    }
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
//        guard let cell:BrowserTabBarCell = collectionView.cellForItem(at: indexPath) as? BrowserTabBarCell else { return }
//        cell.deselected()
    }
    func collectionView(_ collectionView: UICollectionView,
                     willDisplay cell: UICollectionViewCell,
                     forItemAt indexPath: IndexPath) {
//        cell.alpha = 0
//        UIView.animate(withDuration: 0.5, delay: 0.0, options: .allowUserInteraction, animations: {
//            cell.alpha = 1
//        }, completion: nil)
    }
}

extension BrowserFileOperations {
    class func removeSomeFile(files:[String]) {
        files.forEach{Self.remove($0)}
    }
}
class BrowserTabLongPressGesture : UILongPressGestureRecognizer {
    var cell:BrowserTabBarCell!
    override init(target: Any?, action: Selector?) {
        super.init(target: target, action: action)
    }
}
