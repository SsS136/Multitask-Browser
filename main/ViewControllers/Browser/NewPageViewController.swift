//
//  NewPageViewController.swift
//  main
//
//  Created by Ryu on 2021/03/24.
//

import Foundation
import UIKit

protocol NewPageViewControllerDelegate : AnyObject {
    func cellTapped()
    func loadURLAndDomain(url:String)
}

class NewPageViewController : UIViewController, Crop, UIPopoverPresentationControllerDelegate {
    
    weak var delegate:NewPageViewControllerDelegate!
    var collectionView:UICollectionView!
    
    private var displayTapGesture:UITapGestureRecognizer!
    private var cellLongPressGesture:UILongPressGestureRecognizer!
    
    private var add = UIButton()
    
    var isEditingCell = false {
        willSet{
            if isEditingCell != newValue {
                if !isEditingCell {
                    reload()
                    displayTapGesture = UITapGestureRecognizer(target: self, action: #selector(screenTapped))
                    collectionView.addGestureRecognizer(displayTapGesture)
                }else{
                    collectionView.removeGestureRecognizer(displayTapGesture)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        self.reload()
                    }
                }
            }
        }
    }
    var iconCell:[[String]] {
        get{
            UserDefaults.standard.register(defaults: ["iconCell" : [["https://www.google.co.jp","https://m.youtube.com","https://duckduckgo.com","https://mobile.twitter.com","https://www.amazon.co.jp","https://ja.m.wikipedia.org"],[]]])
            return UserDefaults.standard.array(forKey: "iconCell")! as! [[String]]
        }
        set{
            UserDefaults.standard.setValue(newValue, forKey: "iconCell")
        }
    }
    var titleCell:[[String]] {
        get{
            UserDefaults.standard.register(defaults: ["titleCell" : [["Google","YouTube","DuckDuckGo","Twitter","Amazon","Wikipedia"],[]]])
            return UserDefaults.standard.array(forKey: "titleCell") as! [[String]]
        }
        set{
            UserDefaults.standard.setValue(newValue, forKey: "titleCell")
        }
    }
    
    private lazy var _iconCell = iconCell
    private lazy var _titleCell = titleCell
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .newPageColor
        setCollectionView()
    }
    func animationAllEnd() {
        for i in 0..<iconCell[0].count {
            let cell:NewPageIconCell! = collectionView.cellForItem(at: IndexPath(row: i, section: 0)) as? NewPageIconCell
            cell.stopVibrateAnimation()
        }
    }
    private func setCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width:76, height:85)
        layout.sectionInset = UIEdgeInsets(top: 13, left: 13, bottom: 13, right: 13)
        layout.headerReferenceSize = CGSize(width:view.bounds.size.width,height:48)
        layout.estimatedItemSize = .zero
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.register(NewPageIconCell.self, forCellWithReuseIdentifier: "MyCell")
        collectionView.register(UICollectionReusableView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "Section")
        collectionView.backgroundColor = .clear
        collectionView.delegate = self
        collectionView.dataSource = self
        if isEditingCell {
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(screenTapped))
            collectionView.addGestureRecognizer(tapGesture)
        }
        self.view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            collectionView.leftAnchor.constraint(equalTo: view.leftAnchor),
            collectionView.rightAnchor.constraint(equalTo: view.rightAnchor)
        ])
    }
    @objc func screenTapped() {
        isEditingCell = false
    }
}
extension NewPageViewController : UICollectionViewDataSource, UICollectionViewDelegate {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return _iconCell.count
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print(indexPath)
        let cell:NewPageIconCell = collectionView.cellForItem(at: indexPath)! as! NewPageIconCell
        self.delegate.loadURLAndDomain(url: cell.url)
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return _iconCell[section].count
    }
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let sectionTitle = ["Favorite","Frequently Visited"]
        let icons = ["flame.fill","clock"]
        let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "Section", for: indexPath)
        let stack = UIStackView().then {
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.axis = .horizontal
            $0.distribution = .equalSpacing
            $0.alignment = .center
            $0.spacing = 10
        }
        let headerLabel = UILabel().then {
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.text = sectionTitle[indexPath.section]
            $0.textColor = .blackWhite
            $0.textAlignment = .left
            $0.font = UIFont.boldSystemFont(ofSize: 20)
        }
        let icon = UIImageView(image: UIImage(systemName: icons[indexPath.section],withConfiguration: UIImage.SymbolConfiguration(pointSize: 20))).then {
            $0.tintColor = .blackWhite
        }
        if indexPath.section == 1 {
            let clearButton = UIButton().then {
                $0.setTitle("All Clear", for: .normal)
                $0.frame = .zero
                $0.titleLabel?.textAlignment = .center
                $0.titleLabel?.font = UIFont.systemFont(ofSize: 12)
                $0.backgroundColor = .darkGray
                $0.titleLabel?.adjustsFontSizeToFitWidth = true
                $0.titleLabel?.textColor = .blackWhite
                $0.clipsToBounds = true
                $0.layer.cornerRadius = 12
                $0.addTarget(self, action: #selector(allClear), for: .touchUpInside)
                $0.translatesAutoresizingMaskIntoConstraints = false
            }
            headerView.addSubview(clearButton)
            NSLayoutConstraint.activate([
                clearButton.widthAnchor.constraint(equalToConstant: 60),
                clearButton.topAnchor.constraint(equalTo: headerView.topAnchor,constant: 8),
                clearButton.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -8),
                clearButton.rightAnchor.constraint(equalTo: headerView.rightAnchor, constant: -8)
            ])
        }else if indexPath.section == 0 {
            add = UIButton().then {
                $0.setTitle("Add", for: .normal)
                $0.frame = .zero
                $0.titleLabel?.textAlignment = .center
                $0.titleLabel?.font = UIFont.systemFont(ofSize: 12)
                $0.backgroundColor = .darkGray
                $0.titleLabel?.adjustsFontSizeToFitWidth = true
                $0.titleLabel?.textColor = .blackWhite
                $0.clipsToBounds = true
                $0.layer.cornerRadius = 12
                $0.addTarget(self, action: #selector(self.launchAddController), for: .touchUpInside)
                $0.translatesAutoresizingMaskIntoConstraints = false
            }
            headerView.addSubview(add)
            NSLayoutConstraint.activate([
                add.widthAnchor.constraint(equalToConstant: 45),
                add.topAnchor.constraint(equalTo: headerView.topAnchor,constant: 8),
                add.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -8),
                add.rightAnchor.constraint(equalTo: headerView.rightAnchor, constant: -8)
            ])
        }
        headerView.addSubview(stack)
        stack.addArrangedSubViews([icon,headerLabel])
        NSLayoutConstraint.activate([
            //stack.widthAnchor.constraint(equalToConstant: indexPath.section == 0 ? 120 : 133),
            stack.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 8),
            stack.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -8),
            stack.leftAnchor.constraint(equalTo: headerView.leftAnchor, constant: 8)
        ])
        headerView.largeContentTitle = sectionTitle[indexPath.section]
        headerView.backgroundColor = .clear
        return headerView
    }
    @objc func launchAddController() {
        isEditingCell = false
        let addController = AddViewController()
        addController.delegate = self
        let nav = UINavigationController(rootViewController: addController)
        nav.modalPresentationStyle = .popover
        nav.preferredContentSize = CGSize(width: 270, height: 200)
        nav.popoverPresentationController?.sourceView = add
        nav.popoverPresentationController?.sourceRect = CGRect(origin: .zero, size: add.bounds.size)
        nav.popoverPresentationController?.permittedArrowDirections = .any
        nav.popoverPresentationController?.delegate = self
        self.present(nav, animated: true, completion: nil)
//        let options = SheetOptions(useInlineMode:true)
//        sheetController = SheetViewController(controller: nav, sizes: [.fixed(250),.intrinsic], options: options)
//        sheetController.allowPullingPastMaxHeight = false
//
//        self.delegate.openAddViewController(sheet: sheetController)
    }
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
    @objc func allClear() {
        titleCell[1].removeAll()
        iconCell[1].removeAll()
        _titleCell = titleCell
        _iconCell = iconCell
        UserDefaults.standard.setValue([], forKey: "tmp")
        collectionView.reloadSections(IndexSet(integer: 1))
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let cell : NewPageIconCell = collectionView.dequeueReusableCell(withReuseIdentifier: "MyCell", for: indexPath as IndexPath) as! NewPageIconCell
        cell.delegate = self
        cell.isUserInteractionEnabled = true
        cell.setIconAndUrl(url: _iconCell[indexPath.section][indexPath.item], title: _titleCell[indexPath.section][indexPath.item], size: 500,isEditing: isEditingCell)
        
        cellLongPressGesture = UILongPressGestureRecognizer(target: self, action:#selector(startVibe(_:)))
        cell.addGestureRecognizer(cellLongPressGesture)
        
        if self.isEditingCell {
            cell.startVibrateAnimation(range: 3.0)
        } else {
            cell.stopVibrateAnimation()
        }
        return cell
    }
    @objc func startVibe(_ sender:UILongPressGestureRecognizer) {
        if sender.state == .began {
            isEditingCell = !isEditingCell
        }
    }
}
extension NewPageViewController : AddViewControllerDelegate {
    func reload() {
        _titleCell = titleCell
        _iconCell = iconCell
        collectionView.removeFromSuperview()
        setCollectionView()
    }
}
extension NewPageViewController : NewPageIconCellDelegate {
    func removeCell(cell: NewPageIconCell) {
        let alertController = UIAlertController(title: "", message: "Do you really want to delete this?", preferredStyle: .alert)
        let yes = UIAlertAction(title: "Yes", style: .destructive, handler: {_ in
            let index = self.getIndex(cell: cell)
            if let section = index.0,let row = index.1 {
                self.iconCell[section].remove(at: row)
                self.titleCell[section].remove(at: row)
                
                self.reload()
            }
        })
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: {_ in
            self.isEditingCell = false
        })
        alertController.addAction(cancel)
        alertController.addAction(yes)
        self.present(alertController, animated: true, completion: nil)
    }
    func getIndex(cell:NewPageIconCell) -> (Int?,Int?) {//section row
        let url = cell.url
        var counter = 0
        for iconUrl in iconCell[0] {
            if url == iconUrl {
                return (0,counter)
            }
            counter+=1
        }
        counter = 0
        for iconUrl in iconCell[1] {
            if url == iconUrl {
                return (1,counter)
            }
            counter+=1
        }
        return (nil,nil)
    }
}
protocol Crop{}
extension Crop {
    func cropThumbnailImage(image :UIImage, w:Int, h:Int) -> UIImage {
        let origRef    = image.cgImage
        let origWidth  = Int(origRef!.width)
        let origHeight = Int(origRef!.height)
        var resizeWidth:Int = 0, resizeHeight:Int = 0

        if (origWidth < origHeight) {
            resizeWidth = w
            resizeHeight = origHeight * resizeWidth / origWidth
        } else {
            resizeHeight = h
            resizeWidth = origWidth * resizeHeight / origHeight
        }

        let resizeSize = CGSize.init(width: CGFloat(resizeWidth), height: CGFloat(resizeHeight))

        UIGraphicsBeginImageContext(resizeSize)

        image.draw(in: CGRect.init(x: 0, y: 0, width: CGFloat(resizeWidth), height: CGFloat(resizeHeight)))

        let resizeImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        let cropRect  = CGRect.init(x: CGFloat((resizeWidth - w) / 2), y: CGFloat((resizeHeight - h) / 2), width: CGFloat(w), height: CGFloat(h))
        let cropRef   = resizeImage!.cgImage!.cropping(to: cropRect)
        let cropImage = UIImage(cgImage: cropRef!)

        return cropImage
    }
}
extension UIView {
    func startVibrateAnimation(range: Double = 2.0, speed: Double = 0.15, isSync: Bool = false) {
        if self.layer.animation(forKey: "VibrateAnimationKey") != nil {
            return
        }
        let animation: CABasicAnimation
        animation = CABasicAnimation(keyPath: "transform.rotation")
        animation.beginTime = isSync ? 0.0 : Double((Int.random(in: 0...9) + 1)) * 0.1
        animation.isRemovedOnCompletion = false
        animation.duration = speed
        animation.fromValue = range.radianValue
        animation.toValue = -range.radianValue
        animation.repeatCount = Float.infinity
        animation.autoreverses = true
        self.layer.add(animation, forKey: "VibrateAnimationKey")
    }

    func stopVibrateAnimation() {
        self.layer.removeAnimation(forKey: "VibrateAnimationKey")
    }
}
extension Double {
    public var radianValue: Double {
        if #available(iOS 10.0, *) {
            let degreeMeasurement = Measurement(value: self, unit: UnitAngle.degrees)
            let radianMeasurement = degreeMeasurement.converted(to: .radians)
            return radianMeasurement.value
        } else {
            return self / 180 * .pi
        }
    }
}
fileprivate final class NewPageCollectionReloader {
    
    weak var collectionView:UICollectionView?
    
    init(collection:UICollectionView) {
        self.collectionView = collection
    }
    func delete(at:[IndexPath],completion:((Bool) -> Void)?) {
        collectionView?.performBatchUpdates({
            collectionView?.deleteItems(at: at)
        }, completion: completion)
        collectionView?.invalidateIntrinsicContentSize()
    }
    func insert(at:[IndexPath],completion:((Bool) -> Void)?) {
        collectionView?.performBatchUpdates({
            collectionView?.insertItems(at: at)
        }, completion: completion)
        collectionView?.invalidateIntrinsicContentSize()
    }
    func reload(at:[IndexPath],complection:((Bool) -> Void)?) {
        collectionView?.performBatchUpdates({
            collectionView?.reloadItems(at: at)
        }, completion: complection)
        collectionView?.invalidateIntrinsicContentSize()
    }
    func reloadAll(completion:((Bool) -> Void)?) {
        collectionView?.performBatchUpdates({
            collectionView?.reloadData()
        }, completion: completion)
        collectionView?.invalidateIntrinsicContentSize()
    }
}
