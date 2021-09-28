//
//  TabCollectionViewController.swift
//  main
//
//  Created by Ryu on 2021/03/17.
//

import Foundation
import UIKit

protocol TabCollectionViewControllerDelegate : AnyObject {
    func cellTapped(cell:TabCollectionViewCell?,indexPath:IndexPath)
    func cellTapped()
    func didDeleteCell(token:String,index:Int)
    func isDisplayNewPage(display:Bool)
    func scrollTabBar()
    func isTouchedTabBar() -> Bool
    func touchedTabBar(bool:Bool)
    func getContentMode() -> displayMode
    func getRequiredInstance() -> (BrowserTabBarController, TabCollectionViewController)
    func getContentExistMode() -> contentExist
    func changeEntireColor(color:UIColor)
    func getMainInstance() -> BrowserViewController
}
protocol TabCollectionViewControllerDataSource : AnyObject {
    func getSnapshotToken() -> String
}

class TabCollectionViewController : UIViewController, UICollectionViewDelegate,UICollectionViewDelegateFlowLayout,TabCollectionNavigationBarUIDelegate,TabCollectionViewCellDelegate,UICollectionViewDataSource,PrivateDataCore, PastCellManagerDelegate {
    
    func getMainInstance() -> BrowserViewController {
        return self.delegate.getMainInstance()
    }

    weak var delegate:TabCollectionViewControllerDelegate!
    
    let collectionView: UICollectionView = {
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .whiteBlack
        collectionView.register(TabCollectionViewCell.self, forCellWithReuseIdentifier: "CollectionViewCell")
        return collectionView
    }()
    
    private let urls: [String] = ["https://google.co.jp"]
    var isTapDetect:Bool = true
    var topBar = TabCollectionNavigationBar()
    
    lazy var array = { () -> CellData in
        if !FileManager.default.fileExists(atPath: NSHomeDirectory() + "/Documents/CellData.json") {
            let jsonString = BrowserFileOperations.convertDictionaryToJson(dictionary: [])
            BrowserFileOperations.writingToFile(text: jsonString!, dir: "CellData.json")
        }
        let res = BrowserFileOperations.readFromFile(dir: "CellData.json")
        return BrowserFileOperations.getArrayFromJsonData(jsonData: res.data(using: .utf8)!) ?? []
    }
    
    var scrollFlag:Bool! {
        didSet {
            if !scrollFlag {
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: {[weak self] in
                    guard let self = self else { return }
                    if self.delegate.getContentExistMode() == .exist {
                        self.delegate.cellTapped()
                    }
                    self.topBar.addButton.isEnabled = true
                    self.topBar.cancelButton.isEnabled = true
                    self.isTapDetect = true
                })
            }
        }
    }
    
    internal var isPrivate:Bool {
        get{
            return DataReloader.isPrivate
        }
        set{
            DataReloader.isPrivate = newValue
        }
    }
    
    internal var privateArray:CellData {
        get{
            return BrowserDataManager.PrivateData.privateArray
        }set{
            BrowserDataManager.PrivateData.privateArray = newValue
        }
    }
    
    private var base:CGFloat {
        get{
            guard let view = view else { return 0 }
            return view.bounds.size.width > view.bounds.size.height ? view.bounds.size.height : view.bounds.size.width
        }
    }
    private var ReBase:CGFloat {
        get{
            guard let view = view else { return 0 }
            return view.bounds.size.width < view.bounds.size.height ? view.bounds.size.height : view.bounds.size.width
        }
    }
    func reloadArray() {
        DispatchQueue.main.async {[self] in
            collectionView.performBatchUpdates({
                collectionView.reloadSections(IndexSet(integer: 0))
            }, completion: nil)
            collectionView.collectionViewLayout.invalidateLayout()
        }
        //collectionView.reloadData()
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.dataSource = self
        collectionView.delegate = self
        topBar.uiDelegate = self
        _ = isPrivate ? privateArray : array()
        UserDefaults.standard.register(defaults: ["currentIndex" : 0])
        collectionView.backgroundColor = .systemGray3
        
        view.addSubview(collectionView)
        view.addSubview(topBar)
        topBar.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        topBar.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor).isActive = true
        topBar.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.topAnchor.constraint(equalTo: topBar.bottomAnchor).isActive = true
        collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        collectionView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor).isActive = true
        collectionView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        let panGesture = CellPanGesture(target: self, action: #selector(self.panGesture(gesture:)))
        panGesture.delegate = self
        collectionView.addGestureRecognizer(panGesture)
        
        NotificationCenter.default.addObserver(
                    self,
                    selector: #selector(orientationChanged),
                    name: UIDevice.orientationDidChangeNotification,
                    object: nil)
        
    }
    @objc func orientationChanged() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05, execute: {
            self.reloadAll()
        })
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return isPrivate ? privateArray.count : array().count
    }
    private func getIndexFromCell(cell:TabCollectionViewCell) -> (Int?,String) {
        let cellToken = cell.token
        let token = isPrivate ? cellToken : String(cellToken[cellToken.index(cellToken.startIndex, offsetBy: 9)...cellToken.index(cellToken.endIndex,offsetBy: -2)])
        guard token != "" else { return (nil,"") }
        guard let index = searchArray(fromToken: token) else { return (nil,token) }
        return (index,token)
    }
    private func reloadAll() {
        var reload = DataReloader()
        reload.data = self
        reload.reloadAll()
    }
    //delegate method
    func cancelButtonTapped(cell: TabCollectionViewCell) {

        guard (isPrivate ? privateArray.count : array().count) != 1 || cell.urlLabel.text != "New Page" else { return }
        cell.delegate = self
        let i = getIndexFromCell(cell: cell); let token = i.1
        
        guard token != "" else { return }; guard let index = i.0 else { return }
        var data = DataReloader()
        data.data = self
        data.delete(at: [IndexPath(row: index, section: 0)],completionHandler: nil)
        remove(at: index)
        self.delegate.didDeleteCell(token: token,index: index)
        
        if self.isPrivate ? self.privateArray.count == 0 : self.array().count == 0 {
            self.delegate.isDisplayNewPage(display: true)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {[weak self] in
                self?.addButtonTapped()
            }
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
    //delegate method
    func privateButtonTapped() {
        isPrivate = isPrivate ? false : true
        if isPrivate {
            self.delegate.changeEntireColor(color: .privateColor)
        }else{
            self.delegate.changeEntireColor(color: .background)
        }
        reloadAll()
        self.delegate.cellTapped(cell: nil, indexPath: IndexPath(row: isPrivate ? BrowserDataManager.PrivateData.index : UserDefaults.standard.integer(forKey: "currentIndex"), section: 0))
    }
    func searchArray(fromToken:String) -> Int? {
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
    func cellAllDeselected() {
        for i in 0..<array().count - 1{
            guard let cell:TabCollectionViewCell = collectionView.cellForItem(at: IndexPath(row: i, section: 0)) as? TabCollectionViewCell else { return }
            cell.deselected()
        }
    }
    func urlToHostName(urlString:String) -> String {
        if urlString == "New Page" {
            return urlString
        }else{
            let component: NSURLComponents = NSURLComponents(string: urlString)!
            return component.host ?? "about:blank"
        }
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CollectionViewCell", for: indexPath) as! TabCollectionViewCell
        cell.delegate = self
        guard indexPath.item >= 0 && indexPath.item < (isPrivate ? privateArray.count : array().count) else { return cell }
        if indexPath.row == UserDefaults.standard.integer(forKey: "currentIndex") {
            cell.selected()
        }else{
            cell.deselected()
        }
        if !isPrivate {
            let dic = array()[indexPath.item]
            cell.token = dic["token"] as! String
            let icon = BrowserFileOperations.readImage(dir:"favicon/\(dic["favicon"] ?? "").png") ?? UIImage.convenienceInit(named: "rocket.png", size: CGSize(width: 23.5, height: 23.5))
            let snapshot = BrowserFileOperations.readImage(dir:"snapshot/\(dic["snapshot"] ?? "").png") ?? UIImage.convenienceInit(named: "rocket.png", size: CGSize(width: 23.5, height: 23.5))
            if let url = dic["url"] as? String {
                cell.setIconAndSnapshot(favicon: icon!, snapshot: snapshot!,url:urlToHostName(urlString: url),token:String(describing:dic["token"]))
            }
            return cell
        }else{
            let dic = privateArray[indexPath.item]
            let icon = dic["favicon"] as! UIImage
            let snapshot = dic["snapshot"] as! UIImage
            let url = dic["url"] as! String
            let token = dic["token"] as! String
            cell.token = token
            cell.setIconAndSnapshot(favicon: icon, snapshot: snapshot, url: urlToHostName(urlString: url), token: token)
            return cell
        }
    }
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        if !self.delegate.isTouchedTabBar() {
            scrollFlag = false
        }
    }
    
    func onLongPress() {
        let alert: UIAlertController = UIAlertController(title: "削除", message: "\(array().count)個のタブを全て削除しますか？", preferredStyle:  UIAlertController.Style.actionSheet)
        let delete: UIAlertAction = UIAlertAction(title: "Delete", style: UIAlertAction.Style.default, handler:{
            (action: UIAlertAction!) -> Void in
            BrowserFileOperations.removeSomeFile(files: ["CellData.json","favicon","snapshot"])
            self.addButtonTapped()
        })
        let cancelAction: UIAlertAction = UIAlertAction(title: "cancel", style: UIAlertAction.Style.cancel, handler:{
            (action: UIAlertAction!) -> Void in
            print("cancelAction")
        })
        alert.addAction(delete)
        alert.addAction(cancelAction)
        self.present(alert, animated: true, completion: nil)
        
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
    
    private func save() {
        let data = BrowserDataManager(array: array())
        data.createNewPageData(at: 0)
    }

    public func addButtonTapped() {
        guard deleteAll(at: 500) else { return }

        var reloader = DataReloader()
        reloader.data = self
        reloader.insert(at: [IndexPath(row: 0, section: 0)]) { _ in
            if self.array().count <= 1 {
                self.reloadAll()
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now()) {
            PastCellManager.delegate = self
            PastCellManager.batchDeselected()
        }

        
        if isPrivate {
            let data = BrowserDataManager(array: privateArray)
            data.data = self
            data.createPrivatePage(at: 0)
        }else{
            save()
        }
        
        collectionView.scrollToItem(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            self.scrollFlag = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.delegate.scrollTabBar()
        }
    }
    struct TabCollectionStore {
        static var cell:TabCollectionViewCell!
    }
    @objc func panGesture(gesture:CellPanGesture) {
        if let index = collectionView.indexPathForItem(at: gesture.location(in: collectionView)),let cell = collectionView.cellForItem(at: index) as? TabCollectionViewCell {
            
            guard (isPrivate ? privateArray.count : array().count) != 1 || cell.urlLabel.text != "New Page" else { return }
            
            let translation = gesture.translation(in: cell)
            print("Gesture:",gesture.state.rawValue)
            
            switch gesture.state {
            case .began:
                TabCollectionStore.cell = cell
            case .changed,.possible:
                handlePanChange(translation: translation, cell:  TabCollectionStore.cell)
            default:
                if let _ = getIndexFromCell(cell: cell).0 {
                    handlePanEnded(cell: cell)
                }
            }
        }
    }
    private func removeCellBasedOnAlpha(_ cellAlpha: CGFloat, _ cell: TabCollectionViewCell) {
        let gi = getIndexFromCell(cell: cell)
        print("cellAlpha:",cellAlpha)
        if cellAlpha <= 0, let _ = gi.0 {
            print("cellToken:",cell.token)
            cancelButtonTapped(cell: cell)
        }else{
            cell.alpha = cellAlpha
        }
    }
    
    private func handlePanChange(translation:CGPoint,cell:TabCollectionViewCell) {
        let degree:CGFloat = translation.x / 20
        let angle = degree * .pi / 70
        let ratio:CGFloat = 1/40
        let ratioValue = ratio * translation.x
        let rotateTranslation = CGAffineTransform(rotationAngle: angle)
        if ratioValue > 0 {
            let cellAlpha = 1 - ratioValue
            removeCellBasedOnAlpha(cellAlpha, cell)
        } else if ratioValue < 0 {
            let cellAlpha = 1 + ratioValue
            removeCellBasedOnAlpha(cellAlpha, cell)
        }
        cell.transform = rotateTranslation.translatedBy(x: translation.x, y: translation.y)
    }
    private func handlePanEnded(cell:TabCollectionViewCell) {
        UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.7, options: []) {
            cell.transform = .identity
            cell.alpha = 1
            cell.layoutIfNeeded()
        }
    }
    func collectionView(_ collectionView: UICollectionView,
                   canMoveItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        reloadArray()
    }
}
extension TabCollectionViewController {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if self.delegate.getContentMode() == .part {
            ///cell size is constant  in the case of part mode
            return CGSize(width: BrowserUX.normalCellSize, height: BrowserUX.normalCellSize)
        }else{
            ///adjust cell size based on portrait and landscape
            BrowserUX.tabCollectionView = self.view
            return BrowserUX.PhoneType().tabCellSize
        }
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 3
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 3
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
           return UIEdgeInsets(top: 3, left: 3, bottom: 3, right: 3)
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let cell:TabCollectionViewCell = collectionView.cellForItem(at: indexPath) as? TabCollectionViewCell else { return }
        if isTapDetect {
            let cellToken = cell.token
            if isPrivate {
                BrowserDataManager.PrivateData.token = cellToken
                BrowserDataManager.PrivateData.index = indexPath.item
            }else{
                UserDefaults.standard.setValue(cellToken[cellToken.index(cellToken.startIndex, offsetBy: 9)...cellToken.index(cellToken.endIndex,offsetBy: -2)], forKey: "currentToken")
                UserDefaults.standard.setValue(indexPath.item, forKey: "currentIndex")
            }
            collectionView.scrollToItem(at: indexPath, at: .centeredVertically, animated: true)
            self.delegate.cellTapped(cell: cell,indexPath: indexPath)
        }
    }
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
//
//        guard let cell:TabCollectionViewCell = collectionView.cellForItem(at: indexPath) as? TabCollectionViewCell else { return }
//        cell.deselected()
//        cellAllDeselected()
    }
    func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath,to destinationIndexPath: IndexPath) {
    }
}

extension TabCollectionViewController : UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
         let pan = gestureRecognizer as! UIPanGestureRecognizer
         let trans = pan.translation(in: gestureRecognizer.view)
        return abs(trans.x) > abs(trans.y)
    }
}

extension TabCollectionViewController : DataReloaderDataSource {
    func getRequiredInstance() -> (BrowserTabBarController, TabCollectionViewController) {
        return self.delegate.getRequiredInstance()
    }
}

class CellPanGesture : UIPanGestureRecognizer, UIGestureRecognizerDelegate {
    
    var cell:TabCollectionViewCell!
    
    override init(target: Any?, action: Selector?) {
        super.init(target: target, action: action)
        delegate = self
    }
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        let pan = gestureRecognizer as! UIPanGestureRecognizer
        let trans = pan.translation(in: gestureRecognizer.view)
        return abs(trans.x) > abs(trans.y)
    }
    
}
