//
//  ViewController.swift
//  practice
//
//  Created by Ryu on 2021/03/01.
//

import UIKit
import WebKit
import SafariServices
import Foundation
import QuickLook
import SearchTextField
import Tiercel
import FittedSheets
import GCDWebServer
import SwiftyJSON

enum mode : Int {
    case google = 1
    case yahoo = 2
    case duckduckgo = 3
    case twitter = 4
    case amazon = 5
    case wikipedia = 6
}
enum contentExist : Int {
    case exist = 1
    case notExist = 2
}
enum displayMode : Int {
    case full = 1
    case part = 2
}
var secureChecker:Bool = true
let screenWidth = UIScreen.main.bounds.size.width
let screenHeight = UIScreen.main.bounds.size.height

class BrowserViewController : UIViewController, UITextFieldDelegate, UIPopoverPresentationControllerDelegate,XMLParserDelegate, NewPageViewControllerDelegate,FaviconOptimizer,TranslationManagerDelegate,WebRequirements {

    lazy var mode = {() -> WKWebpagePreferences.ContentMode in
        if UserDefaults.standard.string(forKey: "mode") == nil {
            UserDefaults.standard.set("Mobile", forKey:"mode")
        }
        return WKWebpagePreferences.ContentMode.mobile
    }()
    
    var contentExist:contentExist = .notExist
    var historyText:[String] = []
    var modeArray = [WKWebpagePreferences.ContentMode.mobile,WKWebpagePreferences.ContentMode.desktop]
    var documentPreviewController = QLPreviewController()
    var documentUrl = URL(fileURLWithPath: "")
    var search = SearchView()
    let searchView = TopSearchbarView()
    var webView = BrowserWKWebView()
    var searchURL = "https://www.google.co.jp/search?q="
    var currentMode:mode = .google
    var progressView = UIProgressView(progressViewStyle: .bar)
    var hostHistory:[String] = []
    var suggestArray:[String] = []
    var documentDownloadTask: URLSessionTask?
    private let imageArray:[String] = ["google.png","youtube.png","duckduckgo.png","twitter.png","Amazon_icon.png","wiki.png"]
//    private let urlArray:[String] = ["https://www.google.co.jp/search?q=","https://search.yahoo.co.jp/search?p=","https://duckduckgo.com/?q=","https://mobile.twitter.com/search/?q=","https://amazon.co.jp/s?k=","https://jp.m.wikipedia.org/wiki/"]
    private let urlArray:[String] = ["https://www.google.co.jp/search?q=","https://m.youtube.com/results?search_query=","https://duckduckgo.com/?q=","https://mobile.twitter.com/search/?q=","https://amazon.co.jp/s?k=","https://jp.m.wikipedia.org/wiki/"]
    var refreshControll: UIRefreshControl!
    var contentViewController = TabCollectionViewController()
    var contentViewControllerRightConstraint:NSLayoutConstraint!
    var contentViewControllerLeftConstraint:NSLayoutConstraint!
    var contentViewControllerWidthConstraint:NSLayoutConstraint!
    var displayMode:displayMode = .part
    var favIcon:UIImage? = UIImage(named: "rocket.png")!
    var webInstances:[String : BrowserWKWebView] = [:]
    var overviewController:MenuPopupController!
    
    var newpageExist:IsNewPageViewExist! {
        didSet{
            if newpageExist == .exist {
                searchView.reloadButton.isEnabled = false
            }else{
                searchView.reloadButton.isEnabled = true
            }
        }
    }
    
    var newPage = NewPageViewController()
    var tokenArray:[String] = []
    var identifier:Bool = false
    var browserTabBarController = BrowserTabBarController()
  
    lazy var currentDictionary = { (token:String) -> [String : Any] in
        if !FileManager.default.fileExists(atPath: NSHomeDirectory() + "/Documents/CellData.json") {
            let jsonString = BrowserFileOperations.convertDictionaryToJson(dictionary: [])
            BrowserFileOperations.writingToFile(text: jsonString!, dir: "CellData.json")
        }
        let res = BrowserFileOperations.readFromFile(dir: "CellData.json")
        let array = BrowserFileOperations.getArrayFromJsonData(jsonData: res.data(using: .utf8)!) ?? []
        let index = BrowserFileOperations.searchArray(fromToken: token, array: array)
        if array.count != 0 {
            return array[index ?? 0]
        }else{
            return [:]
        }
    }
    
    //downloadSessionManager
    lazy var sessionManager: SessionManager = {
        var configuration = SessionConfiguration()
        configuration.allowsCellularAccess = true
        let path = Cache.defaultDiskCachePathClosure("Downloads")
        let cacahe = Cache("ViewController", downloadPath: path)
        let manager = SessionManager("ViewController", configuration: configuration, cache: cacahe, operationQueue: DispatchQueue(label: "com.Tiercel.SessionManager.operationQueue"))
        return manager
    }()
    
    var prepareURL:[String] = []
    var downloadView:BrowserDownloadView!
    var task:DownloadTask?
    var downloadSheet:BrowserDownloadSheet = BrowserDownloadSheet()
    var sheetController:SheetViewController!
    lazy var lastURL = prepareURL.last!
    var isTaskRunning:Bool = false
    var flag:Bool = false
    var bottomToolBar = BrowserBottomToolBar()
    var isTargetBlank:Bool = false
    var browserConfiguration:WKWebViewConfiguration!
    var fullPaths:[URL] = []
    var searchViewTopConstraint:NSLayoutConstraint!
    var bottomToolBarBottomConstraint:NSLayoutConstraint!
    private var startPoint:CGFloat = 0
    var privateWebInstances = [String:BrowserWKWebView]()
    var translationRedirect:Bool = false
    var webWindows = [WebWindow]()
    var windowButton = [WindowButton]()
    var createdWindow:WebWindow!
    
    var privateToken:String {
        get{
            return BrowserDataManager.PrivateData.token
        }
        set{
            BrowserDataManager.PrivateData.token = newValue
        }
    }
    var privateIndex:Int {
        get{
            return BrowserDataManager.PrivateData.index
        }
        set{
            BrowserDataManager.PrivateData.index = newValue
        }
    }
    var scrollState:ScrollState = .exist {
        willSet{
            webView.scrollView.panGestureRecognizer.removeTarget(self, action: nil)
        }
        didSet{
//            if scrollState == .hide {
//                //webView.scrollView.panGestureRecognizer.removeTarget(self, action: nil)
//            }
//            else if scrollState == .hiding || scrollState == .exist {
//                webView.scrollView.panGestureRecognizer.addTarget(self, action: #selector(panGesture(_:)))
//            }
            webView.scrollView.panGestureRecognizer.addTarget(self, action: #selector(panGesture(_:)))
        }
    }
    var scrollDirection:ScrollDirection = .down
    enum IsNewPageViewExist {
        case exist
        case notExist
    }
    enum ScrollState {
        case TopHiding
        case hide
        case exist
        case appearing
        case middleHiding
    }
    //MARK: viewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.background
        view.addSubview(searchView)
        //autolayout
        searchViewTopConstraint = searchView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor)
        searchViewTopConstraint.isActive = true
        searchView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor).isActive = true
        searchView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor).isActive = true
        searchView.baseView.backgroundColor = .whiteBlack
        searchView.textField.backgroundColor = .whiteBlack
        searchView.delegate = self
        search.delegate = self
        contentViewController.topBar.delegate = self
        contentViewController.topBar.data = self
        contentViewController.delegate = self
        contentViewControllerLeftConstraint = view.leftAnchor.constraint(equalTo: view.leftAnchor)
        UserDefaults.standard.register(defaults: ["suggestion" : true,"currentIndex" : 0])
        //現在のモード設定
        currentMode = .google
        //setup

//        self.contentViewController.reloadArray()
        //saveDataToJson()
        setupToolBar()
        setupProgressView()
        setupContentView()
        scrollTabCollectionView()
        setupTransnlationView()
        
        saveDataToJson()
        
        
        scrollState = .exist
        
        refreshControll = UIRefreshControl()
        self.webView.scrollView.refreshControl = refreshControll
        refreshControll.addTarget(self, action: #selector(refresh(sender:)), for: .valueChanged)
        //検索エンジンタップ時の通知
        NotificationCenter.default.addObserver(self, selector: #selector(ChooseSearchEngine), name: Notification.Name(rawValue: "tap.action"), object: nil)
        //検索エンジンタップ時の通知(data)
        NotificationCenter.default.addObserver(self, selector: #selector(changeEngineImage(notification:)), name: Notification.Name("change.action"), object: nil)
        //httpブロックの通知
        NotificationCenter.default.addObserver(self, selector: #selector(httpBlock(notification:)), name: Notification.Name("block.action"), object: nil)
        //modeの通知
        NotificationCenter.default.addObserver(self, selector: #selector(modeChange(notification:)), name: Notification.Name("mode.action"), object: nil)
        //auto complete　の通知
        NotificationCenter.default.addObserver(self, selector: #selector(autocompleteChange(notification:)), name: Notification.Name("auto.action"), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(reloadWebView), name: Notification.Name("reloadWebView"), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(unableAdBlock), name: Notification.Name("unableAdBlock"), object: nil)

    }
    deinit {
        webView.removeObserver(self, forKeyPath: "estimatedProgress", context: nil)
        webView.removeObserver(self, forKeyPath: "loading", context: nil)
        webView.removeObserver(self, forKeyPath: "canGoBack", context: nil)
        webView.removeObserver(self, forKeyPath: "canGoForward", context: nil)
        webView.removeObserver(self, forKeyPath: "title", context: nil)
        webView.removeObserver(self, forKeyPath: "hasOnlySecureContent", context: nil)
    }
    var recoveryCellData:CellData?
    
    func detectClashLog() {
        if UserDefaults.standard.bool(forKey: "clashLog") {
            let res = BrowserFileOperations.readFromFile(dir: "CellData.json")
            BrowserFileOperations.removeSomeFile(files: ["favicon","snapshot","CellData.json"])
            removeUserDefaults()
        }
    }
    func removeUserDefaults() {
        let appDomain = Bundle.main.bundleIdentifier
        UserDefaults.standard.removePersistentDomain(forName: appDomain!)
    }

    override func loadView() {
        super.loadView()
        #if DEBUG
        if UserDefaults.standard.bool(forKey: "clashLog"),false {
            BrowserFileOperations.removeSomeFile(files: ["favicon","snapshot","CellData.json"])
            removeUserDefaults()
        }
        #endif
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        #if DEBUG
        if UserDefaults.standard.bool(forKey: "clashLog") {
            let alert = UIAlertController(title: "Log", message: UserDefaults.standard.string(forKey: "failLog"), preferredStyle: .alert)
            let action = UIAlertAction(title: "Cancel", style: .default, handler: nil)
            alert.addAction(action)
            self.present(alert, animated: true, completion: nil)
            print("DEBUG")
            browserTabBarController.addButtonTapped()
            saveDataToJson()
            browserTabBarController.reloadArray()
            UserDefaults.standard.setValue(false, forKey: "clashLog")
        }
        #endif
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        print("received memorywarning")
        webInstances.removeAll()
        privateWebInstances.removeAll()
    }
    private func insertPastCell() {
        let index = UserDefaults.standard.integer(forKey: "currentIndex")
        PastCellManager.pastCell = getCellInstance(at: IndexPath(row: index, section: 0))
        if PastCellManager.pastCell == nil {
            #if DEBUG
            let alert = UIAlertController(title: "nil", message: "", preferredStyle: .alert)
            let action = UIAlertAction(title: "", style: .cancel, handler: nil)
            alert.addAction(action)
            self.present(alert, animated: true, completion: nil)
            #endif
        }
        PastCellManager.batchSelected()
    }
    func setupToolBar() {
        bottomToolBar.delegate = self
        view.addSubview(bottomToolBar)
        bottomToolBarBottomConstraint = bottomToolBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        NSLayoutConstraint.activate([
            bottomToolBarBottomConstraint,
            bottomToolBar.leftAnchor.constraint(equalTo: view.leftAnchor),
            bottomToolBar.rightAnchor.constraint(equalTo: view.rightAnchor),
            bottomToolBar.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    func setupConfiguration() -> WKWebViewConfiguration {
        var configuration = WKWebViewConfiguration()
        configuration.userContentController.add(self, name: "openDocument")
        configuration.userContentController.add(self, name: "jsError")
        configuration.allowsInlineMediaPlayback = true
        configuration.allowsAirPlayForMediaPlayback = true
        configuration.allowsPictureInPictureMediaPlayback = true
        configuration.preferences.javaScriptEnabled = true
        configuration = AdBlockHelper.startAdBlocking(configuration: configuration)
        UserDefaults.standard.register(defaults: ["cookies":[]])
        if isPrivate {
            configuration.websiteDataStore = .nonPersistent()
        }else{
            configuration.websiteDataStore = WKWebsiteDataStore.default()
            configuration.processPool = WKProcessPool.shared
        }
        return configuration
    }
    func setupWebOverView() {
        webView.allowsBackForwardNavigationGestures = true
        webView.allowsLinkPreview = true
        documentPreviewController.dataSource = self
        webView.uiDelegate = self
//        webView.delegate = self
        webView.navigationDelegate = self
        webView.scrollView.delegate = self

        webView.addObserver(self, forKeyPath: "estimatedProgress", options: .new, context: nil)
        webView.addObserver(self, forKeyPath: "loading", options: .new, context: nil)
        webView.addObserver(self, forKeyPath: "canGoBack", options: .new, context: nil)
        webView.addObserver(self, forKeyPath: "canGoForward", options: .new, context: nil)
        webView.addObserver(self, forKeyPath: "title", options: .new, context: nil)
        webView.addObserver(self, forKeyPath: "hasOnlySecureContent", options: .new, context: nil)
    }
    func setupWebConstraint() {
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.topAnchor.constraint(equalTo: browserTabBarController.view.bottomAnchor).isActive = true
        webView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        webView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        webView.bottomAnchor.constraint(equalTo: bottomToolBar.topAnchor).isActive = true
    }
    func setCookies() {
        if let data = UserDefaults.standard.data(forKey: "cookies"),!isPrivate {
            (try! NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as! [HTTPCookie]).forEach {
                webView.configuration.websiteDataStore.httpCookieStore.setCookie($0, completionHandler: nil)
            }
        }
    }
    func updateWebView(configuration:WKWebViewConfiguration) {
        webView.removeFromSuperview()
        if isPrivate {
            configuration.websiteDataStore = .nonPersistent()
        }
        webView = BrowserWKWebView(frame: .zero, configuration:configuration)
        setupWebOverView()
        setCookies()
        
        view.addSubview(webView)
        setupWebConstraint()
        refreshControll = UIRefreshControl()
        self.webView.scrollView.refreshControl = refreshControll
        refreshControll.addTarget(self, action: #selector(refresh(sender:)), for: .valueChanged)
        self.view.layoutIfNeeded()
        view.bringSubviewToFront(contentViewController.view)
        view.bringSubviewToFront(bottomToolBar)
    }
    func reloadWebview(web:BrowserWKWebView) {
        webView.removeFromSuperview()
        webView = web
        setupWebOverView()
        view.addSubview(webView)
        setupWebConstraint()
        refreshControll = UIRefreshControl()
        self.webView.scrollView.refreshControl = refreshControll
        refreshControll.addTarget(self, action: #selector(refresh(sender:)), for: .valueChanged)
        self.view.layoutIfNeeded()
        view.bringSubviewToFront(contentViewController.view)
        view.bringSubviewToFront(bottomToolBar)
    }
    @discardableResult func setupWebView() -> BrowserWKWebView {
        defer{
            unableAdBlock()
        }
        webView = BrowserWKWebView(frame: .zero, configuration: setupConfiguration())
        setupWebOverView()
        view.addSubview(webView)
        setupWebConstraint()
        if let key = UserDefaults.standard.string(forKey: "currentToken") {
            let dic = currentDictionary(key)
            if let currentUrl = dic["url"] as? String {
                cellTapped(cell: nil, indexPath:IndexPath(row: UserDefaults.standard.integer(forKey: "currentIndex"), section: 0))
                if currentUrl == "New Page" {
                    //setupNewPageView()
                }else{
                    openUrl(urlString: currentUrl)
                }
            }
        }else{
            setupNewPageView()
        }
        return webView
    }
    private func setupProgressView() {
        progressView = UIProgressView(frame:.zero)
        progressView.tintColor = .red
        view.addSubview(progressView)
        progressView.translatesAutoresizingMaskIntoConstraints = false
        progressView.topAnchor.constraint(equalTo: searchView.bottomAnchor).isActive = true
        progressView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        progressView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        progressView.heightAnchor.constraint(equalToConstant: 1.7).isActive = true
        setupTabBarController()
        setupWebView()
        view.bringSubviewToFront(bottomToolBar)
    }
    func setupContentView() {
        self.addChild(contentViewController)
        view.addSubview(contentViewController.view!)
        contentViewController.didMove(toParent: self)
        contentViewController.view.translatesAutoresizingMaskIntoConstraints = false
        //removeConstraintFromContentView()
        addConstraintToContentView(constant: 250)
        contentViewController.view.topAnchor.constraint(equalTo: browserTabBarController.view.bottomAnchor).isActive = true
        //bottomBarが追加されたらautolayout変更する
        contentViewController.view.bottomAnchor.constraint(equalTo: bottomToolBar.topAnchor).isActive = true
        contentViewControllerWidthConstraint = contentViewController.view.widthAnchor.constraint(equalToConstant: 200)
        contentViewControllerWidthConstraint.isActive = true
    }
    func setupNewPageView() {
        if !checkExistNewPage() {
            newPage = NewPageViewController()
            progressView.alpha = 0
            newPage.delegate = self
            self.bottomToolBar.shareButton.isEnabled = false
            self.addChild(newPage)
            webView.addSubview(newPage.view!)
            //view.bringSubviewToFront(browserTabBarController.view)
            view.bringSubviewToFront(bottomToolBar)
            newPage.didMove(toParent: self)
            newPage.view.translatesAutoresizingMaskIntoConstraints = false
            newpageExist = .exist
            //toolbarができたら修正
            NSLayoutConstraint.activate([
                newPage.view.topAnchor.constraint(equalTo: browserTabBarController.view.bottomAnchor),
                newPage.view.bottomAnchor.constraint(equalTo: bottomToolBar.topAnchor),
                newPage.view.leftAnchor.constraint(equalTo: view.leftAnchor),
                newPage.view.rightAnchor.constraint(equalTo: view.rightAnchor)
            ])
        }
    }
    func setupTabBarController() {
        browserTabBarController = BrowserTabBarController()
        browserTabBarController.delegate = self
        self.addChild(browserTabBarController)
        view.addSubview(browserTabBarController.view!)
        browserTabBarController.didMove(toParent: self)
        browserTabBarController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            browserTabBarController.view.topAnchor.constraint(equalTo: progressView.bottomAnchor),
            browserTabBarController.view.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor),
            browserTabBarController.view.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor),
            browserTabBarController.view.heightAnchor.constraint(equalToConstant: 30)
        ])
    }
    
    var translationViewTopConstraint:NSLayoutConstraint!
    var translationView = TranslationView(frame: .zero)
    var translation:TranslationManager!
    
    func setupTransnlationView() {
        translationView.delegate = self
        view.addSubview(translationView)
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(noticingPangesture(sender:)))
        translationView.addGestureRecognizer(panGesture)
        
        translationView.translatesAutoresizingMaskIntoConstraints = false
        translationViewTopConstraint = translationView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: -110)
        NSLayoutConstraint.activate([
            translationView.widthAnchor.constraint(equalToConstant: 355),
            translationView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            translationView.heightAnchor.constraint(equalToConstant: 50),
            translationViewTopConstraint
        ])
    }
    func scrollTabCollectionView() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            self.contentViewController.collectionView.scrollToItem(at: IndexPath(row: UserDefaults.standard.integer(forKey: "currentIndex"), section: 0), at: .top, animated: true)
        }
    }
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "estimatedProgress" {

            self.progressView.alpha = 1.0

            self.progressView.setProgress(Float(webView.estimatedProgress), animated: true)

            if webView.estimatedProgress >= 1.0 {
                UIView.animate(
                    withDuration: 0.3,
                    delay: 0.0,
                    options: [.curveEaseOut],
                    animations: { [weak self] in
                        self?.progressView.alpha = 0.0
                    },completion: {
                        [weak self](finished : Bool) in
                        self?.progressView.setProgress(0.0, animated: false)
                        self?.searchView.reloadButton.addTarget(self?.searchView, action: #selector(self?.searchView.reloadPushed(sender:)), for: .touchUpInside)
                        let reloadImage = UIImage.convenienceInit(named: "refresh", size: CGSize(width: 16, height: 16))
                        self?.searchView.reloadButton.setImage(reloadImage, for: .normal)
                })
            }
        }else if keyPath == "canGoBack" {
            print("canGoBack")
            bottomToolBar.backButton.isEnabled = webView.canGoBack
        }else if keyPath == "canGoForward" {
            print("canGoBack")
            bottomToolBar.forwardButton.isEnabled = webView.canGoForward
        }else if keyPath == "title" {
            saveDataToJson()
        }else if keyPath == "hasOnlySecureContent" {
        }
    }

    func openErrorHtml() {
        searchView.textField.text = "about:blank"
        guard let path: String = Bundle.main.path(forResource: "index", ofType: "html") else { return }
        let localHTMLUrl = URL(fileURLWithPath: path, isDirectory: false)
        webView.loadFileURL(localHTMLUrl, allowingReadAccessTo: localHTMLUrl)
    }
    func checkExistNewPage() -> Bool {
        for v in view.subviews {
            if let className = v.parentViewController(),className == "NewPageViewController" {
                return true
            }
        }
        return false
    }
    func checkExistingSearchView() -> Bool {
        for subview in view.subviews {
            if String(describing: type(of: subview)) == "SearchView" {
                return true
            }
        }
        return false
    }

    func changeTopSearchbarView() {
        searchView.baseViewConstraint.isActive = false
        searchView.cancelButtonConstraint.isActive = false
        searchView.textFieldConstraint.isActive = false
        searchView.baseViewConstraintLeft.isActive = false
        searchView.googleButtonConstraint.isActive = false
        
        searchView.baseViewConstraint = searchView.baseView.rightAnchor.constraint(equalTo: searchView.rightAnchor, constant:-74)
        searchView.baseViewConstraintLeft = searchView.baseView.leftAnchor.constraint(equalTo: searchView.leftAnchor, constant: 46)
        searchView.cancelButtonConstraint = searchView.cancelButton.rightAnchor.constraint(equalTo: searchView.rightAnchor, constant: -8)
        searchView.textFieldConstraint = searchView.textField.widthAnchor.constraint(equalTo: searchView.stack.widthAnchor)
        searchView.googleButtonConstraint = searchView.googleButton2.leftAnchor.constraint(equalTo: searchView.leftAnchor, constant: 8)
        
        searchView.baseViewConstraint.isActive = true
        searchView.baseViewConstraintLeft.isActive = true
        searchView.cancelButtonConstraint.isActive = true
        searchView.textFieldConstraint.isActive = true
        searchView.googleButtonConstraint.isActive = true
        
        UIView.animate(
             withDuration: 0.2,
             delay:0,
             options:UIView.AnimationOptions.curveEaseOut,
             animations: {() -> Void in
                self.searchView.layoutIfNeeded()
        },completion: {_ in

        });
    }
    func identifyHostName(name:String) -> Bool {
        if searchURL.contains(name) {
            return true
        }else{
            return false
        }
    }
    func checkContainsSpecifiedHost() -> Bool {
        let currentHost = urlToHostName(urlString: webView.url?.absoluteString ?? "about:blank")
        let detectHosts = ["www.google","search.yahoo","duckduckgo.com","mobile.twitter.com","www.amazon","m.wikipedia.org"]
        for host in detectHosts {
            if currentHost.contains(host) && identifyHostName(name: currentHost) {
                return true
            }
        }
        return false
    }
    func addConstraintToContentView(constant:CGFloat) {
        contentViewControllerRightConstraint = contentViewController.view.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: constant)
        contentViewControllerRightConstraint.isActive = true
    }
    func addConstraintToContentView(equalTo:NSLayoutAnchor<NSLayoutXAxisAnchor>) {
        contentViewControllerRightConstraint = contentViewController.view.rightAnchor.constraint(equalTo: equalTo)
        contentViewControllerRightConstraint.isActive = true
    }
    func removeConstraintFromContentView() {
        contentViewControllerRightConstraint.isActive = false
    }
    func removeWidthConstraintFromContentView() {
        contentViewControllerWidthConstraint.isActive = false
    }
    func addLeftConstraintToContentView(equalTo:NSLayoutAnchor<NSLayoutXAxisAnchor>) {
        contentViewControllerLeftConstraint = contentViewController.view.leftAnchor.constraint(equalTo: equalTo)
        contentViewControllerLeftConstraint.isActive = true
    }
    func removeLeftConstraintFromContentView() {
        contentViewControllerLeftConstraint.isActive = false
    }
    func hideContentController(_ content:UIViewController) {
        content.willMove(toParent: nil)
        content.view.removeFromSuperview()
        content.removeFromParent()
    }
    func changeColorAfterChackingSecure() {
        var trust:CFError?
        if webView.hasOnlySecureContent && SecTrustEvaluateWithError(webView.serverTrust!, &trust) {
            searchView.shieldButton.imageView?.tintColor = .gray
        }else{
            searchView.shieldButton.imageView?.tintColor = .red
        }
    }
    private func reloadScrollViewsPangesture() {
        //reload scrollView.panGesture
        let before = scrollState
        scrollState = before
    }
    private func selectedTab() {
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {[self] in
            PastCellManager.delegate = self
            DispatchQueue.main.async {
                PastCellManager.batchDeselected()
                PastCellManager.pastCell = getCellInstance(at: IndexPath(row: UserDefaults.standard.integer(forKey: "currentIndex"), section: 0))
                PastCellManager.batchSelected()
            }
        }
    }
    func cellHandle(isClose:Bool) {
        progressView.progress = 0
        guard privateIndex >= 0 && privateIndex < privateArray.count else { return }
        selectedTab()
        let dic = isPrivate ? browserTabBarController.privateArray[privateIndex] : currentDictionary(UserDefaults.standard.string(forKey: "currentToken")!)
        if let url = dic["url"] as? String {
            if url == "New Page" {
                searchView.textField.text = ""
                searchView.shieldButton.imageView?.tintColor = .gray
                identifier = false
                if isTargetBlank {
                    updateWebView(configuration: browserConfiguration)
                }else{
                    updateWebView(configuration: setupConfiguration())
                }
                setupNewPageView()
            }else{
                newpageExist = .notExist
                hideContentController(newPage)
                searchView.textField.text = urlToHostName(urlString: url)
                let token = isPrivate ? privateToken : dic["token"] as! String
                if let instance = isPrivate ? privateWebInstances[token] : webInstances[token] {
                    identifier = true
                    reloadWebview(web: instance)
                    bottomToolBar.shareButton.isEnabled = true
                    view.bringSubviewToFront(contentViewController.view)
                }else{
                    updateWebView(configuration: setupConfiguration())
                    //a().setup()
//                    TabDataRestore(Back: dic["backlist"] as! BFList, forward: dic["forwardlist"] as! BFList, currentURL: url, webView: webView).restoreTabData()

                    identifier = false
                    openUrl(urlString: url)
                }
                changeColorAfterChackingSecure()
            }
        }else{
            openUrl(urlString: "https://google.co.jp")
        }
        if isClose {
            closeButtonTapped()
        }
        webWindowAllBringToFront()
        guard let dlview = self.downloadView else { return }
        view.bringSubviewToFront(dlview)
    }
    func webWindowAllBringToFront() {
        guard !webWindows.isEmpty else { return }
        webWindows.forEach {
            view.bringSubviewToFront($0)
        }
        windowButton.forEach {
            view.bringSubviewToFront($0)
        }
    }
    func animateTabBar() {
        self.browserTabBarController.collectionView.scrollToItem(at: IndexPath(row: 1, section: 0), at: .centeredHorizontally, animated: false)
        self.browserTabBarController.collectionView.scrollToItem(at: IndexPath(row: 0, section: 0), at: .right, animated: true)
    }
    func saveDataToJson() {
        let save = BrowserDataManager(web: webView, newpageExist: newpageExist ?? .notExist)
        save.data = self
        
        if isPrivate {
            save.savePrivateData(identifier: &identifier, view: &view, favicon: (favIcon ?? UIImage(named: "rocket.png"))!, webInstances: &privateWebInstances, mainViewController: self)
        }else{
            save.saveData(identifier: &identifier, view: &view, favicon: (favIcon ?? UIImage(named:"rocket.png"))!, webInstances: &webInstances, mainViewController: self)
        }
        var reloader = DataReloader()
        reloader.data = self
        reloader.update(at: [IndexPath(row: isPrivate ? privateIndex : UserDefaults.standard.integer(forKey: "currentIndex"), section: 0)], completionHandler: nil)
    }

    var isHandlingTabBar = false
    
    func addWebViewForTargetBlank() {
        browserTabBarController.addWebViewForTargetBlank()
        cellHandle(isClose: true)
        contentViewController.reloadArray()
    }

    func tempRemove() {
        BrowserFileOperations.deleteAllData(fullpaths: fullPaths)
        fullPaths.removeAll()
    }
    func savePDFIfSpecifiedURL(async:Bool) {
        if let url = webView.url?.absoluteString,url.contains(".pdf") {
            let closure = {[weak self] in
                guard let self = self else { return }
                let name = BrowserFileOperations.getLastDirectoryName(url: url)
                BrowserFileOperations.saveData(url:url,name:name)
                let d = BrowserFileOperations.returnDocumentsFullPath(name:name)
                self.fullPaths.append(d)
            }
            if async {
                DispatchQueue.global(qos: .default).async {
                    closure()
                }
            }else{
                closure()
            }
        }
    }
    
    func setupSheetController(title:String) {
        downloadSheet = BrowserDownloadSheet()
        downloadSheet.delegate = self
        downloadSheet.itemTitle = title
        let options = SheetOptions(
            useInlineMode: true
        )
        sheetController = SheetViewController(controller:downloadSheet,sizes: [.fixed(110),.intrinsic],options: options)
        sheetController.allowPullingPastMaxHeight = false
        sheetController.animateIn(to: view, in: self)
    }
    func errorTransition(content:String) {
        let url = searchURL + ((content.addingPercentEncoding(withAllowedCharacters: NSMutableCharacterSet.urlQueryAllowed))!)
        openUrl(urlString: url)
    }
    func changeSecureCheckerColor(color:UIColor) {
        searchView.shieldButton.imageView?.tintColor = color
    }
    func setImageForEngineButton(named: String) {
        let views = [searchView.googleButton2,searchView.googleButton]
        for v in views {
            v.setImage(UIImage.convenienceInit(named: named, size: CGSize(width: 30, height: 30)), for: .normal)
        }
    }
    //MARK: Notification methods
    @objc func ChooseSearchEngine() {
        let vc = ChooseEnginePopupController()
        vc.modalPresentationStyle = .popover
        vc.preferredContentSize = CGSize(width: 175, height: 264)
        vc.popoverPresentationController?.sourceView = checkExistingSearchView() ? searchView.googleButton2 : searchView.googleButton
        vc.popoverPresentationController?.sourceRect = CGRect(origin: CGPoint.zero, size: searchView.googleButton.bounds.size)
        vc.popoverPresentationController?.permittedArrowDirections = .up
        vc.popoverPresentationController?.delegate = self
        self.present(vc, animated: true, completion:nil)
    }
    @objc func changeEngineImage(notification:Notification?) {
        let data = notification?.userInfo!["tag"]
        guard let a = data else {
            print("empty data")
            return
        }
        switch a as! String {
            case "100":
                setImageForEngineButton(named: imageArray[0])
                searchURL = urlArray[0]
                currentMode = .google
            case "101":
                setImageForEngineButton(named: imageArray[1])
                searchURL = urlArray[1]
                currentMode = .yahoo
            case "102":
                setImageForEngineButton(named: imageArray[2])
                searchURL = urlArray[2]
                currentMode = .duckduckgo
            case "103":
                setImageForEngineButton(named: imageArray[3])
                searchURL = urlArray[3]
                currentMode = .twitter
            case "104":
                setImageForEngineButton(named: imageArray[4])
                searchURL = urlArray[4]
                currentMode = .amazon
            case "105":
                setImageForEngineButton(named: imageArray[5])
                searchURL = urlArray[5]
                currentMode = .wikipedia
            default:
                setImageForEngineButton(named: imageArray[0])
                searchURL = urlArray[0]
                currentMode = .google
        }
    }
    @objc func httpBlock(notification:Notification?) {
        let d = notification?.userInfo!["state"]
        guard let data = d else {
            print("empty data")
            return
        }
        switch data as! String {
            case "true":
                UserDefaults.standard.set(true, forKey: "blockhttp")
                AdBlockHelper.continueAdBlocking(viewController: self,elseHundler: {AdBlockHelper.startAdBlocking(viewController: self)})
                webView.reload()
                var trust:CFError?
                if webView.hasOnlySecureContent && SecTrustEvaluateWithError(webView.serverTrust!, &trust) && newpageExist == .notExist {
                    openErrorHtml()
                }
            case "false":
                AdBlockHelper.unableAdBlocking()
                webView.reload()
                UserDefaults.standard.set(false, forKey: "blockhttp")
            default:
                UserDefaults.standard.set(false, forKey: "blockhttp")
        }
    }
    @objc func modeChange(notification:Notification?) {
        let d = notification?.userInfo!["mode"]
        guard let data = d else {
            print("empty data")
            return
        }
        let st = data as! String
        mode = st == "Mobile" ? modeArray[0] : modeArray[1]
        webView.reload()
    }
    @objc func autocompleteChange(notification:Notification?) {
        let d = notification?.userInfo!["auto"]
        guard let data = d else {
            print("empty data")
            return
        }
        let st = data as! String
        let list = st == "true" ? AutoCompleteManager.currentList : [""]
        searchView.textField.filterStrings(list)
    }
    @objc func refresh(sender: UIRefreshControl) {
        guard let url = webView.url else {
            return
        }
        webView.load(URLRequest(url: url))
    }
}

//MARK: WebView Delegate

extension BrowserViewController : WKNavigationDelegate,WKScriptMessageHandler,WKUIDelegate,QLPreviewControllerDataSource {

    func download() {
        let URL =  webView.url?.absoluteString ?? "https://google.com"
        let data = optimizeFaviconData(url:URL)
        if data.0 {
            DispatchQueue.main.async {
                self.favIcon = data.1
                self.saveDataToJson()
            }
        }else{
            FavIconFetcher.download(url:URL) { result in
                if case let .success(image) = result {
                    DispatchQueue.main.async {
                        self.favIcon = image
                        self.saveDataToJson()
                    }
                }
            }
        }
    }
    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation:WKNavigation!) {
        print("リダイレクト")
    }
    private func containsName(hostnames:[String]) -> Bool {
        return hostnames.filter { (hostname) -> Bool in
            if let url = webView.url {
                return urlToHostName(urlString: url.absoluteString).contains(hostname)
            }else {
                return false
            }
        }.count > 0
    }
    func saveCookie() {
        if isPrivate {
            webView.configuration.websiteDataStore.httpCookieStore.getAllCookies {
                if let data = try? NSKeyedArchiver.archivedData(withRootObject: $0,requiringSecureCoding: true) {
                    UserDefaults.standard.set(data, forKey: "cookies")
                }
            }
        }
    }
    func descendTranslataionView() {
        translationViewTopConstraint.isActive = false
        translationViewTopConstraint = translationView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor,constant: 30)
        view.bringSubviewToFront(translationView)
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 2, initialSpringVelocity:2, options: .curveEaseIn, animations: {
            self.translationViewTopConstraint.isActive = true
            self.view.layoutIfNeeded()
        },completion: nil)
    }
    private func ascendTranslationView() {
        translationViewTopConstraint.isActive = false
        translationViewTopConstraint = translationView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: -110)
        view.bringSubviewToFront(translationView)
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 2, initialSpringVelocity:1.5, options: .curveEaseIn, animations: {
            self.translationViewTopConstraint.isActive = true
            self.view.layoutIfNeeded()
        })
    }
    @objc func noticingPangesture(sender:UIPanGestureRecognizer) {
        let movePoint = sender.translation(in: view)
        let offsetY = movePoint.y
        switch sender.state {
        case .began,.changed:
            if offsetY < 0 {
                translationViewTopConstraint.isActive = false
                translationViewTopConstraint = translationView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor,constant: 30 + offsetY)
                translationViewTopConstraint.isActive = true
                self.view.layoutIfNeeded()
            }else{
                descendTranslataionView()
            }
        case .ended:
            if 30 + offsetY >= 0 {
                descendTranslataionView()
            }else {
                ascendTranslationView()
            }
        default:
            break
        }
    }
    func webView(_ webView2: WKWebView, didCommit navigation: WKNavigation!) {
        print("読み込み開始")
        //start favicon download
        reloadScrollViewsPangesture()
        download()
        ascendTranslationView()
        if let url = webView.url {
            let detectList = ["translate.googleusercontent.com","translate.google.com","translate.goog"]
            if !containsName(hostnames: detectList) {
                print(urlToHostName(urlString: url.absoluteString))
                DispatchQueue.main.async {[self] in
                    translation = TranslationManager(url: url)
                    //Identify the language used on the web and automatically execute descendTranslationView asynchronously if the language is different from that of the terminal.
                    translation.delegate = self
                }
            }
        }
        AdBlockHelper.continueAdBlocking(viewController: self,elseHundler: nil)
        //pdf all remove
        tempRemove()
        savePDFIfSpecifiedURL(async: true)
        //history
        searchView.textField.text = urlToHostName(urlString: webView.url?.absoluteString ?? "about:blank")
        if checkExistingSearchView() {
            search.stack.removeAllArrangedSubviews()
            search.removeFromSuperview()
            searchView.textField.resignFirstResponder()
        }
        convertReloadButtonToCancelButton()
        searchView.textField.text = urlToHostName(urlString: webView.url?.absoluteString ?? "about:blank")
        secureCheck()
    }
    private func convertReloadButtonToCancelButton() {
        searchView.reloadButton.setImage(UIImage.convenienceInit(named: "incorrect", size: CGSize(width: 18, height: 18)), for: .normal)
        searchView.reloadButton.addTarget(searchView, action: #selector(searchView.cancelPushed(sender:)), for: .touchUpInside)
    }
    private func secureCheck() {
        var trust:CFError?
        if let serverTrust = webView.serverTrust {
            if webView.hasOnlySecureContent == true && SecTrustEvaluateWithError(serverTrust, &trust) {
                searchView.shieldButton.imageView?.tintColor = .gray
                secureChecker = true
            }else{
                searchView.shieldButton.imageView?.tintColor = .systemRed
                secureChecker = false
                if UserDefaults.standard.bool(forKey: "blockhttp") {
                    webView.stopLoading()
                    webView.goBack()
                    openErrorHtml()
                }
            }
        }
    }
    func webView(_ webView2: WKWebView, didFinish navigation: WKNavigation!) {
        print("読み込み完了")
        saveCookie()
        download()
        reloadTabBar()
        progressView.progress = 1.0
        UIView.animate(withDuration: 0.3, animations: {[weak self] in self?.progressView.alpha = 0.0})
        saveFrequentlyVisitedUrl()
        self.refreshControll.endRefreshing()
    }
    private func saveFrequentlyVisitedUrl() {
        
        guard !isPrivate else { return }
        guard let url = webView.url?.absoluteString,!urlToHostName(urlString: url).contains("www.google"),let webTitle = webView.title,webTitle != "" else { return }
        
        UserDefaults.standard.register(defaults: ["tmp":[]])
        var before = UserDefaults.standard.array(forKey: "tmp")
        before?.append(url)
        UserDefaults.standard.setValue(before, forKey: "tmp")
        var tmp = UserDefaults.standard.array(forKey: "tmp")
        if UserDefaults.standard.array(forKey: "tmp")!.count > 500 {            UserDefaults.standard.setValue(tmp?.removeLast(), forKey: "tmp")
        }
        
        let urlCount = (tmp as! [String]).filter { $0 == url }.count
        
        if urlCount == 4 {
            if var history = UserDefaults.standard.array(forKey:"iconCell") as? [[String]],var title = UserDefaults.standard.array(forKey: "titleCell") as? [[String]] {
                if (UserDefaults.standard.array(forKey: "iconCell")![1] as! [String]).count == 8 {
                    history[1].removeLast()
                    title[1].removeLast()
                }
                AutoCompleteManager.delegate = self
                AutoCompleteManager.addAutoCompleteDomains(urls: [url,urlToHostName(urlString: url)])
                history[1].insert(url, at: 0)
                title[1].insert(webTitle, at: 0)
                UserDefaults.standard.setValue(history, forKey: "iconCell")
                UserDefaults.standard.setValue(title, forKey: "titleCell")
            }
        }
    }
    private func test() {
        guard !isPrivate else { return }
    }
    func webView(_ webView: WKWebView, didFailProvisionalNavigation: WKNavigation!, withError error: Error) {
        let e = error as NSError
        if e.code == -1009 {
            //not connected
            openErrorHtml()
        }else if e.code == -1003 {
            //error domain
            openErrorHtml()
        }else if e.code == -999{
            //reload button repeated hits
            searchView.textField.text = "about:blank"
        }else if e.code == 102 {
            //download
            lastURL = prepareURL.last!
            let path = lastURL as NSString
            guard path.pathExtension != "html" || path.pathExtension != "php" else { return }
            let last = BrowserFileOperations.getLastDirectoryName(url: lastURL)
            let fileName = last.components(separatedBy: "?").count > 0 ? last.components(separatedBy: "?")[0] : last
            self.setupSheetController(title: fileName)
        }
        print(e.code)
    }
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        hideNewPage()
        bottomToolBar.shareButton.isEnabled = true
        prepareURL.append((webView.url?.absoluteString)!)
    }
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, preferences: WKWebpagePreferences, decisionHandler: @escaping (WKNavigationActionPolicy, WKWebpagePreferences) -> Void) {
        preferences.preferredContentMode = mode

        guard let url = navigationAction.request.url else { return }

        if openInDocumentPreview(url) {
            decisionHandler(.cancel, preferences)
            executeDocumentDownloadScript(forAbsoluteUrl: url.absoluteString)
        } else if navigationAction.navigationType == .linkActivated {
            if !url.absoluteString.hasPrefix("http") {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
                decisionHandler(.cancel, preferences)
            }else{
                if let a = url.host,a.hasPrefix("m.youtube.com") {
                    decisionHandler(.cancel, preferences)
                    DispatchQueue.main.async {
                        webView.load(navigationAction.request)
                    }
                }else{
                    decisionHandler(.allow,preferences)
                }
            }
        }else{
            decisionHandler(.allow,preferences)
        }
    }

    public func userContentController(_ userContentController:WKUserContentController, didReceive message: WKScriptMessage) {

        debugPrint("did receive message \(message.name)")
        if (message.name == "openDocument") {
            previewDocument(messageBody: message.body as! String)
        } else if (message.name == "jsError") {
            debugPrint(message.body as! String)
        }
    }
    private func previewDocument(messageBody: String) {

        let filenameSplits = messageBody.split(separator: ";",maxSplits: 1, omittingEmptySubsequences: false)

        let filename = String(filenameSplits[0])

        let dataSplits = filenameSplits[1].split(separator: ",",maxSplits: 1, omittingEmptySubsequences: false)

        let data = Data(base64Encoded: String(dataSplits[1]))

        if (data == nil) {
            debugPrint("Could not construct data from base64")
            return
        }


        let localFileURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename.removingPercentEncoding ?? filename)

        do {
            try data!.write(to: localFileURL);
        } catch {
            debugPrint(error)
            return
        }

        DispatchQueue.main.async {
            self.documentUrl = localFileURL
            self.documentPreviewController.refreshCurrentPreviewItem()
            self.present(self.documentPreviewController, animated: true, completion: nil)
        }
    }

    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        return documentUrl as QLPreviewItem
    }
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return 1
    }

    private func openInDocumentPreview(_ url : URL) -> Bool {
        // this is specific for our application - can be everything in your application
        return url.absoluteString.contains("/APP/connector")
    }

    private func executeDocumentDownloadScript(forAbsoluteUrl absoluteUrl : String) {
        webView.evaluateJavaScript("""
                (async function download() {
                    const url = '\(absoluteUrl)';
                    try {
                        // we use a second try block here to have more detailed error information
                        // because of the nature of JS the outer try-catch doesn't know anything where the error happended
                        let res;
                        try {
                            res = await fetch(url, {
                                credentials: 'include'
                            });
                        } catch (err) {
                            window.webkit.messageHandlers.jsError.postMessage(`fetch threw, error: ${err}, url: ${url}`);
                            return;
                        }
                        if (!res.ok) {
                            window.webkit.messageHandlers.jsError.postMessage(`Response status was not ok, status: ${res.status}, url: ${url}`);
                            return;
                        }
                        const contentDisp = res.headers.get('content-disposition');
                        if (contentDisp) {
                            const match = contentDisp.match(/(^;|)\\s*filename=\\s*(\"([^\"]*)\"|([^;\\s]*))\\s*(;|$)/i);
                            if (match) {
                                filename = match[3] || match[4];
                            } else {
                                // TODO: we could here guess the filename from the mime-type (e.g. unnamed.pdf for pdfs, or unnamed.tiff for tiffs)
                                window.webkit.messageHandlers.jsError.postMessage(`content-disposition header could not be matched against regex, content-disposition: ${contentDisp} url: ${url}`);
                            }
                        } else {
                            window.webkit.messageHandlers.jsError.postMessage(`content-disposition header missing, url: ${url}`);
                            return;
                        }
                        if (!filename) {
                            const contentType = res.headers.get('content-type');
                            if (contentType) {
                                if (contentType.indexOf('application/json') === 0) {
                                    filename = 'unnamed.pdf';
                                } else if (contentType.indexOf('image/tiff') === 0) {
                                    filename = 'unnamed.tiff';
                                }
                            }
                        }
                        if (!filename) {
                            window.webkit.messageHandlers.jsError.postMessage(`Could not determine filename from content-disposition nor content-type, content-dispositon: ${contentDispositon}, content-type: ${contentType}, url: ${url}`);
                        }
                        let data;
                        try {
                            data = await res.blob();
                        } catch (err) {
                            window.webkit.messageHandlers.jsError.postMessage(`res.blob() threw, error: ${err}, url: ${url}`);
                            return;
                        }
                        const fr = new FileReader();
                        fr.onload = () => {
                            window.webkit.messageHandlers.openDocument.postMessage(`${filename};${fr.result}`)
                        };
                        fr.addEventListener('error', (err) => {
                            window.webkit.messageHandlers.jsError.postMessage(`FileReader threw, error: ${err}`)
                        })
                        fr.readAsDataURL(data);
                    } catch (err) {
                        // TODO: better log the error, currently only TypeError: Type error
                        window.webkit.messageHandlers.jsError.postMessage(`JSError while downloading document, url: ${url}, err: ${err}`)
                    }
                })();
                // null is needed here as this eval returns the last statement and we can't return a promise
                null;
        """) { (result, err) in
            if (err != nil) {
                debugPrint("JS ERR: \(String(describing: err))")
            }
        }
    }
    func linkActivated(webView: WKWebView, navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard navigationAction.request.url != nil else {
            decisionHandler(.cancel)
            return
        }
        decisionHandler(.allow)
    }

    func othersAction(webView: WKWebView, navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        print("othersAction")
        guard let isMainFrame = navigationAction.targetFrame?.isMainFrame, isMainFrame else {
            decisionHandler(.allow)
            return
        }
        guard navigationAction.request.url != nil else {
            decisionHandler(.cancel)
            return
        }
        decisionHandler(.allow)
    }
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        // alert対応
        let alertController = UIAlertController(title: "", message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default) { _ in
            completionHandler()
        }
        alertController.addAction(action)
        present(alertController, animated: true, completion: nil)
    }

    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        // confirm対応
        let alertController = UIAlertController(title: "", message: message, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
            completionHandler(false)
        }
        let okAction = UIAlertAction(title: "OK", style: .default) { _ in
            completionHandler(true)
        }

        alertController.addAction(cancelAction)
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
    }

    func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
        let alertController  = UIAlertController(title: "", message: prompt, preferredStyle: .alert)
        let okHandler: () -> Void = {
            if let textField = alertController.textFields?.first {
                completionHandler(textField.text)
            } else {
                completionHandler("")
            }
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
            completionHandler(nil)
        }
        let okAction = UIAlertAction(title: "OK", style: .default) { _ in
            okHandler()
        }
        alertController.addTextField { $0.text = defaultText }
        alertController.addAction(cancelAction)
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
    }
    public func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        switch challenge.protectionSpace.authenticationMethod {
        case NSURLAuthenticationMethodHTTPBasic:

            let alert = UIAlertController(title: "Basic認証", message: "ユーザ名とパスワードを入力してください", preferredStyle: .alert)
            alert.addTextField {
                $0.placeholder = "user"
            }
            alert.addTextField {
                $0.placeholder = "password"
                $0.isSecureTextEntry = true
            }

            let login = UIAlertAction(title: "ログイン", style: .default) { (_) in
            guard let user = alert.textFields?[0].text,
                let password = alert.textFields?[1].text
                else {
                    completionHandler(.cancelAuthenticationChallenge, nil)
                    return
            }
            let credential = URLCredential(user: user, password: password, persistence: URLCredential.Persistence.forSession)
                completionHandler(.useCredential, credential)
            }
            let cancel = UIAlertAction(title: "キャンセル", style: .cancel) { (_) in
                completionHandler(.cancelAuthenticationChallenge, nil)
            }
            alert.addAction(login)
            alert.addAction(cancel)

            present(alert, animated: true, completion: nil)

        default:
            completionHandler(.performDefaultHandling, nil)
        }
    }
    //target = _blank handler
    func webView(_ webView2: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {


        guard let url = navigationAction.request.url else {
            return nil
        }

        if url.absoluteString.range(of: "//itunes.apple.com/") != nil {
            if UIApplication.shared.responds(to: #selector(UIApplication.open(_:options:completionHandler:))) {
                UIApplication.shared.open(url, options: [UIApplication.OpenExternalURLOptionsKey.universalLinksOnly: false], completionHandler: { (finished: Bool) in
                })
            } else {
                UIApplication.shared.open(url)
                return nil
            }
        } else if !url.absoluteString.hasPrefix("http://") && !url.absoluteString.hasPrefix("https://") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
                return nil
            }
        }
        //handle if this href is target _blank
        guard let targetFrame = navigationAction.targetFrame, targetFrame.isMainFrame else {
            guard url.absoluteString.range(of: "//itunes.apple.com/") == nil else { return nil }
            guard !isPrivate else {
                openUrl(url: url)
                return nil
            }
            isTargetBlank = true
            browserConfiguration = configuration
            addWebViewForTargetBlank()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1 , execute: {[self] in
                self.isTargetBlank = false
            })
            return webView
        }
        return nil
    }
    private func setConfiguration(configuration:WKWebViewConfiguration) -> BrowserWKWebView {
        return BrowserWKWebView(frame: .zero, configuration: configuration)
    }
    private func loadUrlAsNewTab(url:URL,addWeb:Bool) {
        if addWeb {
            addWebView()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.openUrl(url: url)
        }
    }
    func webView(_ webView: WKWebView,contextMenuConfigurationForElement elementInfo: WKContextMenuElementInfo,completionHandler: @escaping (UIContextMenuConfiguration?) -> Void) {
        let configuration = UIContextMenuConfiguration(identifier: nil, previewProvider: {
            return SFSafariViewController(url: elementInfo.linkURL!)
        }, actionProvider: { elements in
                guard elements.isEmpty == false else { return nil }
                var elementsToUse = elements
                elementsToUse.remove(at: 1)
                let addNewTabAction = UIAction(title:  "Open as New Tab",image: UIImage(systemName: "plus")){ (action) in
                    self.loadUrlAsNewTab(url: elementInfo.linkURL!,addWeb: true)
                }
                let addPrivateTabAction = UIAction(title:"Open as Private Tab",image: UIImage(systemName: "eye")) {(action) in
                    self.contentViewController.privateButtonTapped()
                    self.contentViewController.topBar.privateButton.backgroundColor = .privateSelectedColor
                    self.loadUrlAsNewTab(url: elementInfo.linkURL!,addWeb: self.privateArray.count == 1 ? false : true)
                }
                var windowName = ""
                if #available(iOS 14, *) {
                    windowName = "macwindow.badge.plus"
                }else{
                    windowName = "plus.rectangle.on.rectangle"
                }
                let addWindowAction = UIAction(title: "Open as New Window", image: UIImage(systemName: windowName)) { action in
                    let webWindow = self.addWebWindow()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        webWindow.openUrl(url: elementInfo.linkURL!)
                    }
                }
                elementsToUse.insert(addNewTabAction, at: 0)
                if !self.isPrivate {
                    elementsToUse.insert(addPrivateTabAction, at: 1)
                }
                elementsToUse.insert(addWindowAction, at: 1)
                return UIMenu(children: elementsToUse)
            }
        )
        completionHandler(configuration)
    }
    func webView(_ webView: WKWebView, commitPreviewingViewController previewingViewController: UIViewController) {
        if previewingViewController is PreviewingViewController{
            self.present(previewingViewController, animated: true) { }
        }
    }
}

//MARK:TopSearchbarViewDelegate
extension BrowserViewController : TopSearchbarViewDelegate, SecurityCheckViewControllerDelegate {
    func loadWebView(textField: UITextField) {
        cancelButtonTapped(host: false)
        hostHistory.append(textField.text!)
        search.stack.removeAllArrangedSubviews()
        search.removeFromSuperview()
        let fieldText = textField.text!
        guard fieldText == "about:blank" else {
            if URLChecker(currentMode: currentMode).checkUrlOrNot(fieldText: fieldText) {
                let pattern = "^[\\p{Han}\\p{Hiragana}\\p{Katakana}]+"
                guard Regexp(pattern).isMatch(input: fieldText) || Regexp.checkZenkaku(fieldText: fieldText) else {
                    if fieldText.contains("http://") == true || fieldText.contains("https://") == true {
                        openUrl(urlString: fieldText)
                    }else{
                        openUrl(urlString: "https://" + fieldText)
                    }
                    searchView.textField.resignFirstResponder()
                    return
                }
                errorTransition(content: fieldText)
                //openErrorHtml()
            }else{
                if let searchText = textField.text {
                    let url = searchURL + searchText.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)!
                    openUrl(urlString: url)
                    searchView.textField.resignFirstResponder()
                }
            }
            return
        }
        openErrorHtml()
    }
    func loadURLAndDomain(url:String) {
        cancelButtonTapped(host: false)
        search.stack.removeAllArrangedSubviews()
        search.removeFromSuperview()
        guard url == "about:blank" else {
            if URLChecker(currentMode: currentMode).checkUrlOrNot(fieldText: url) {
                let pattern = "^[\\p{Han}\\p{Hiragana}\\p{Katakana}]+"
                guard Regexp(pattern).isMatch(input: url) || Regexp.checkZenkaku(fieldText: url) else {
                    if url.contains("http://") == true || url.contains("https://") == true {
                        openUrl(urlString: url)
                    }else{
                        openUrl(urlString: "https://" + url)
                    }
                    searchView.textField.resignFirstResponder()
                    return
                }
                errorTransition(content: url)
            }else{
                let url = searchURL + url.addingPercentEncoding(withAllowedCharacters:NSCharacterSet.urlQueryAllowed)!
                openUrl(urlString: url)
                searchView.textField.resignFirstResponder()
            }
            return
        }
        openErrorHtml()
    }

    @objc func reloadWebView() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.webView.reload()
        }
    }
    @objc func unableAdBlock() {
        webView.configuration.userContentController.removeAllContentRuleLists()
        webInstances.removeAll()
        reloadWebView()
        privateWebInstances.removeAll()
        if UserDefaults.standard.bool(forKey: "adblock") {
            AdBlockHelper.startAdBlocking(viewController: self)
        }
    }
    func hideNewPage() {
        if newpageExist == .exist {
            hideContentController(newPage)
            newpageExist = .notExist
        }
    }
    //delegate method
    func loadCancel() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.webView.stopLoading()
            let image = UIImage.convenienceInit(named: "refresh", size: CGSize(width: 16, height: 16))
            self.searchView.reloadButton.setImage(image, for: .normal)
            self.searchView.reloadButton.addTarget(self.searchView, action: #selector(self.searchView.reloadPushed(sender:)), for: .touchUpInside)
        }
    }
    //delegate method
    func secureButtonTapped(sender: UIButton) {
        let vc = SecurityCheckViewController()
        vc.delegate = self
        vc.modalPresentationStyle = .popover
        vc.preferredContentSize = CGSize(width: 320, height: 220)
        vc.popoverPresentationController?.sourceView = searchView.shieldButton
        vc.popoverPresentationController?.sourceRect = CGRect(origin: CGPoint.zero, size: searchView.shieldButton.bounds.size)
        vc.popoverPresentationController?.permittedArrowDirections = .any
        vc.popoverPresentationController?.delegate = self
        self.present(vc, animated: true, completion:nil)

    }
    //delegate method
    func changeView() {
        if newpageExist != .exist {
            searchView.textField.text = checkContainsSpecifiedHost() ? hostHistory.last : webView.url?.absoluteString
        }
        if contentExist == .exist {
            closeButtonTapped()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.searchView.textField.selectAll(self.searchView.textField)
        }
        changeTopSearchbarView()
        if !checkExistingSearchView() {
            view.addSubview(search)
            search.translatesAutoresizingMaskIntoConstraints = false
            search.topAnchor.constraint(equalTo: progressView.bottomAnchor).isActive = true
            search.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
            search.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
            search.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        }
    }
    //delegate method
    func cancelButtonTapped(host:Bool) {
        if newpageExist != .exist {
            searchView.textField.text = host ? urlToHostName(urlString: webView.url?.absoluteString ?? "about:blank") : searchView.textField.text
        }
        if checkExistingSearchView() {
            search.stack.removeAllArrangedSubviews()
            search.removeFromSuperview()
            searchView.textField.resignFirstResponder()
        }
        
        searchView.baseViewConstraint.isActive = false
        searchView.cancelButtonConstraint.isActive = false
        searchView.textFieldConstraint.isActive = false
        searchView.baseViewConstraintLeft.isActive = false
        searchView.googleButtonConstraint.isActive = false
        
        searchView.baseViewConstraint = searchView.baseView.rightAnchor.constraint(equalTo: searchView.rightAnchor, constant: -8)
        searchView.baseViewConstraintLeft = searchView.baseView.leftAnchor.constraint(equalTo: searchView.leftAnchor, constant: 8)
        searchView.cancelButtonConstraint = searchView.cancelButton.rightAnchor.constraint(equalTo: searchView.rightAnchor, constant: 120)
        searchView.textFieldConstraint = searchView.textField.widthAnchor.constraint(equalTo: searchView.stack.widthAnchor, multiplier: 0.5)
        searchView.googleButtonConstraint = searchView.googleButton2.leftAnchor.constraint(equalTo: searchView.leftAnchor, constant: -76)

        searchView.baseViewConstraint.isActive = true
        searchView.baseViewConstraintLeft.isActive = true
        searchView.cancelButtonConstraint.isActive = true
        searchView.textFieldConstraint.isActive = true
        searchView.googleButtonConstraint.isActive = true
        
        UIView.animate(
             withDuration: 0.2,
            delay:0,
             options:UIView.AnimationOptions.curveEaseOut,
             animations: {[weak self] () -> Void in
                self?.searchView.layoutIfNeeded()
        },completion: {_ in

        })
    }
    func rectangleButtonTapped() {

        if contentExist == .notExist {
            
            contentExist = .exist
            if !contentViewController.topBar.addButton.isEnabled && !contentViewController.topBar.cancelButton.isEnabled {
                contentViewController.topBar.addButton.isEnabled = true
                contentViewController.topBar.addButton.isEnabled = true
            }
            view.bringSubviewToFront(contentViewController.view)
            download()
            removeConstraintFromContentView()
            addConstraintToContentView(constant: 0)
            UIView.animate(
                 withDuration: 0.3,
                 delay:0,
                 options:UIView.AnimationOptions.curveEaseOut,
                 animations: {() -> Void in
                    self.view.layoutIfNeeded()
            },completion: {_ in

            });
        }else{
            closeButtonTapped()
        }
    }
    func editingChanged(sender: SearchTextField) {
        guard let searchText = sender.text,searchText != "" else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.26) {
                self.search.addCellToStack(cellArray: [])
            }
            return
        }
        guard searchText == "about:blank" else {
            if URLChecker(currentMode: currentMode).checkUrlOrNot(fieldText: searchText) {
                let pattern = "^[\\p{Han}\\p{Hiragana}\\p{Katakana}]+"
                guard Regexp(pattern).isMatch(input: searchText) || Regexp.checkZenkaku(fieldText: searchText) else {
                    if searchText.contains("http://") == true || searchText.contains("https://") == true {
                        search.addCellToStack(cellArray: [SearchViewCell(type: .suggest, text: searchText, url: searchText)])
                    }else{
                        search.addCellToStack(cellArray: [SearchViewCell(type: .suggest, text: searchText, url: "https://" + searchText)])
                    }
                    return
                }
                let url = searchURL + searchText.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)!
                search.addCellToStack(cellArray: [SearchViewCell(type: .suggest, text:  searchText, url: url)])
            }else{
                var cellViewArray:[SearchViewCell] = []
                GoogleSuggestion.searchSuggestion(searchText: searchText, count: 5) {(result) in
                    DispatchQueue.main.async {
                        if case let .success(suggest) = result {
                            suggest.forEach {
                                cellViewArray.append(SearchViewCell(type: .suggest, text: $0, url: self.searchURL + $0.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)!))
                            }
                        }
                        
                        var suggests = UserDefaults.standard.array(forKey: "Suggestion") as! [String]
                            
                        suggests = suggests.filter {
                            $0.hasPrefixAllowingHiraganaKatakana(prefix:searchText)
                        }
                        suggests.forEach {
                            cellViewArray.insert(SearchViewCell(type: .history, text: $0, url: self.searchURL + $0.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)!), at: 0)
                        }
                        self.search.addCellToStack(cellArray: cellViewArray)
                    }
                }
            }
            return
        }
    }
}
//MARK: SearchViewDelegate
extension BrowserViewController : SearchViewDelegate {
    func linkLoad(url:String) {
        hideNewPage()
        if checkExistingSearchView() {
            cancelButtonTapped(host:true)
        }
        openUrl(urlString: url)
    }
}
//MARK: TabCollectionNavigationBarDelegate
extension BrowserViewController : TabCollectionNavigationBarDelegate {

    func closeButtonTapped() {
        if contentExist == .exist {
            if displayMode == .part {
                contentExist = .notExist
                removeConstraintFromContentView()
                addConstraintToContentView(constant: 250)
                UIView.animate(withDuration: 0.3, animations: {
                    self.view.layoutIfNeeded()
                })
            }else{
                removeLeftConstraintFromContentView()
                removeConstraintFromContentView()
                contentViewControllerWidthConstraint.isActive = true
                addConstraintToContentView(constant: 250)
                UIView.animate(withDuration: 0.3, animations: {
                    self.view.layoutIfNeeded()
                },completion: { _ in
                    self.displayMode = .part
                    self.contentExist = .notExist
                    self.contentViewController.topBar.arrowButton.setImage(UIImage(systemName: "arrow.left"), for: .normal)
                })
            }
        }
    }

    func arrowButtonTapped() {
        
        if displayMode == .part {
            removeWidthConstraintFromContentView()
            addLeftConstraintToContentView(equalTo: view.leftAnchor)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
                self.displayMode = .full
                self.contentViewController.reloadArray()
            })
            UIView.animate(withDuration: 0.3, animations: {
                self.view.layoutIfNeeded()
            },completion:{ _ in
                
                self.contentViewController.topBar.arrowButton.setImage(UIImage(systemName: "arrow.right"), for: .normal)
            })
        }else{
            removeLeftConstraintFromContentView()
            removeConstraintFromContentView()
            contentViewControllerWidthConstraint.isActive = true
            addConstraintToContentView(constant: 0)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
                self.displayMode = .part
                self.contentViewController.reloadArray()
            })
            UIView.animate(withDuration: 0.3, animations: {
                self.view.layoutIfNeeded()
            },completion:{ _ in
                self.contentViewController.topBar.arrowButton.setImage(UIImage(systemName: "arrow.left"), for: .normal)
            })
        }
    }
}
//MARK:CustomWKWebDelegate
extension BrowserViewController {
//    func urlDidGet(customWebView: CustomWKWebView, arrURL: [URL]) {
//        if arrURL.isEmpty == false {
//            for temp in arrURL{
//                download(url: temp)
//            }
//        }
//    }
}
//MARK:TabCollectionNacigationBarData
extension BrowserViewController : TabCollectionNavigationBarData {
    func getData() -> displayMode {
        return displayMode
    }
}
//MARK:TabCOllectionViewControllerDelegate
extension BrowserViewController : TabCollectionViewControllerDelegate {
    
    func cellTapped(cell:TabCollectionViewCell?,indexPath:IndexPath) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            self.contentViewController.collectionView.scrollToItem(at: indexPath, at: .centeredVertically, animated: true)
            self.browserTabBarController.collectionView.scrollToItem(at:indexPath,at:.centeredHorizontally,animated:true)
        }
        cellHandle(isClose: true)
    }
    //this method is called when addbutton tapped
    func cellTapped() {
        cellHandle(isClose: true)
    }

    func isDisplayNewPage(display:Bool) {
        if display {
            updateWebView(configuration: setupConfiguration())
            setupNewPageView()
            newpageExist = .exist
        }else{
            hideContentController(newPage)
            newpageExist = .notExist
        }
    }

    func didDeleteCell(token:String,index:Int) {
        if isPrivate {

            privateWebInstances.removeValue(forKey: token)
            webView.removeFromSuperview()
            progressView.progress = 0

            let arr = privateArray
            let arrCount = arr.count
            //Shift the cell when it's removed
            if arrCount != 0 {
                if index >= 0 && index < arr.count {
                    let replaceToken = arr[index]["token"] as! String
                    privateToken = replaceToken
                    cellHandle(isClose: false)
                }else{
                    guard index - 1 >= 0 && index - 1 < arr.count else { return }
                    let replaceToken = arr[index - 1]["token"] as! String
                    privateToken = replaceToken
                    privateIndex = index - 1
                    cellHandle(isClose: false)
                }
            }
        }else{
            guard token == UserDefaults.standard.string(forKey: "currentToken")! else { return }
            webInstances.removeValue(forKey: token)
            webView.removeFromSuperview()
            progressView.progress = 0
            contentViewController.reloadArray()
            let arr = contentViewController.array()
            let arrayCount = arr.count
            if arrayCount != 0 {
                if index >= 0 && index < arr.count {
                    let replaceToken = arr[index]["token"] as! String
                    UserDefaults.standard.setValue(replaceToken, forKey: "currentToken")
                    cellHandle(isClose: false)
                }else{
                    guard index - 1 >= 0 && index - 1 < arr.count else { return }
                    let replaceToken = arr[index - 1]["token"] as! String
                    UserDefaults.standard.setValue(replaceToken, forKey: "currentToken")
                    UserDefaults.standard.setValue(index - 1, forKey: "currentIndex")
                    cellHandle(isClose: false)
                }
            }
        }
    }
    func scrollTabBar() {
        animateTabBar()
    }
    func isTouchedTabBar() -> Bool {
        return isHandlingTabBar
    }

    func touchedTabBar(bool:Bool) {
        isHandlingTabBar = bool
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            self.isHandlingTabBar = !bool
        }
    }
    func getContentMode() -> displayMode {
        return displayMode
    }
    func getContentExistMode() -> contentExist {
        return contentExist
    }
    func changeEntireColor(color:UIColor) {
        view.backgroundColor = color
        searchView.backgroundColor = color
        BrowserTabBarController.cellColor = color
        bottomToolBar.backgroundColor = color
        contentViewController.topBar.backgroundColor = color
        MenuPopupController.cellColor = color
        
        if isPrivate {
            searchView.baseView.backgroundColor = .systemGray3
            searchView.textField.backgroundColor = .systemGray3
        }else{
            searchView.textField.backgroundColor = .whiteBlack
            searchView.baseView.backgroundColor = .whiteBlack
        }
    }
}
//MARK:BrowserDownloadSheetDelegate
extension BrowserViewController : BrowserDownloadSheetDelegate {
    func deleteDownloadViewNoSession() {
        downloadView.removeFromSuperview()
        isTaskRunning = false
    }
    func downloadStart() {
        if flag {
            downloadView.removeFromSuperview()
        }
        if isTaskRunning {
            if var cueArray = UserDefaults.standard.stringArray(forKey: "cue") {
                cueArray.append(lastURL)
                UserDefaults.standard.setValue(cueArray, forKey: "cue")
            }else{
                UserDefaults.standard.setValue([lastURL], forKey: "cue")
            }
            sheetController.attemptDismiss(animated: true)
        }else{
            flag = false
            let last = BrowserFileOperations.getLastDirectoryName(url: lastURL)
            let fileName = last.components(separatedBy: "?").count > 0 ? last.components(separatedBy: "?")[0] : last
            task = sessionManager.download(lastURL,fileName: fileName)
            sheetController.attemptDismiss(animated: true)
            setupDownloadView(title: fileName)
            self.downloadView.progressByte.text = "Loading..."
            isTaskRunning = true
            task?.progress(onMainQueue: true) { [weak self] (task) in
                let progress = task.progress.fractionCompleted
                self?.downloadView.progressView.setProgress(Float(progress), animated: false)
                self?.downloadView.progressByte.text = "\(task.progress.completedUnitCount.tr.convertBytesToString())/\(task.progress.totalUnitCount.tr.convertBytesToString())"
            }.success {[weak self] (task) in
                print("complete")
                guard FileManager.default.fileExists(atPath: Cache.defaultDiskCachePathClosure("Downloads") + "/File/" + fileName) else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {                    self?.sessionManager.remove(self?.lastURL ?? "")
                        self?.task = self?.sessionManager.download(self?.lastURL ?? "")
                    }
                    return
                }
                self?.writeTaskURL(task: task)
                self?.isTaskRunning = false
                self?.downloadView.cancelLabel.setTitle("Look", for: .normal)
                self?.downloadView.cancelLabel.addTarget(self, action: #selector(self?.downloadsButtonTapped), for: .touchUpInside)
                self?.cueHandle(true)
                self?.downloadView.progressByte.text = "\(task.progress.completedUnitCount.tr.convertBytesToString())/\(task.progress.totalUnitCount.tr.convertBytesToString())"
                self?.flag = true
            }.failure { [weak self] (task) in
                self?.isTaskRunning = false
                print("failure")
            }
        }
    }
    func cueHandle(_ type:Bool) {
        if isTaskRunning {
            sessionManager.totalCancel()
            isTaskRunning = false
        }
        if var cue = UserDefaults.standard.stringArray(forKey: "cue"),0 < cue.count {
            self.prepareURL.append(cue[0])
            lastURL = self.prepareURL.last!
            print(lastURL)
            print("prepare\(prepareURL)")
            if type {
                self.deleteDownloadViewNoSession()
            }
            self.downloadStart()
            cue.remove(at: 0)
            UserDefaults.standard.setValue(cue, forKey: "cue")
        }
    }
    func writeTaskURL(task:DownloadTask) {
        if !FileManager.default.fileExists(atPath: NSHomeDirectory() + "/Documents/task.txt") {
            BrowserFileOperations.writingToFile(text: "", dir: "task.txt")
        }
        let urls = BrowserFileOperations.readFromFile(dir: "task.txt")
        if urls == "" {
            BrowserFileOperations.writingToFile(text:task.url.absoluteString, dir: "task.txt")
        }else{
            BrowserFileOperations.writingToFile(text: urls + "\n" + task.url.absoluteString, dir: "task.txt")
        }
    }
    //fixed
    func setupDownloadView(title:String) {
        downloadView = BrowserDownloadView(title:title)
        downloadView.delegate = self
        view.addSubview(downloadView)
        view.bringSubviewToFront(downloadView)
        NSLayoutConstraint.activate([
            downloadView.heightAnchor.constraint(equalToConstant: 55),
            downloadView.bottomAnchor.constraint(equalTo: bottomToolBar.topAnchor),
            downloadView.leftAnchor.constraint(equalTo: view.leftAnchor),
            downloadView.rightAnchor.constraint(equalTo: view.rightAnchor)
        ])
    }
}
//MARK:BrowserDownloadViewDelegate
extension BrowserViewController : BrowserDownloadViewDelegate {
    func deleteDownloadView() {
        sessionManager.totalCancel()
        downloadView.removeFromSuperview()
        isTaskRunning = false
        cueHandle(false)
    }
}
//MARK:BrowserTabBarControllerDelegate
extension BrowserViewController : BrowserTabBarControllerDelegate {
    struct WindowManager {
        enum WebWindowAnimationState {
            case nothing
            case isMinExpanded
            case isMaxExpanded
            case isEndedExpandAll
        }
        static var windowState:WebWindowAnimationState = .nothing
        static var windowBeforeWidth:Float!
        static var windowAfterWidth:Float!//is equal to cell width
    }
    struct WebWindowState {
        static var identifier:Bool = false
    }
    func tabToWebWindow(_ sender: BrowserTabLongPressGesture) {
        
        let token = sender.cell.token
        var pIndex:Int? = 0
        if isPrivate {
            pIndex = BrowserFileOperations.searchArray(fromToken: token, array: privateArray)
        }
        let url = isPrivate ? privateArray[pIndex ?? 0]["url"] as! String : currentDictionary(token)["url"] as! String
        let movePoint = sender.location(in: view)
        let viewWidth = view.frame.width
        let viewHeight = view.frame.height
        
        switch sender.state {
        case .began:
            createdWindow = addWebWindow(at: movePoint, width: 2*viewWidth/3, height: 2*viewHeight/3)
            if let indexPath = browserTabBarController.collectionView.indexPathForItem(at: sender.location(in: browserTabBarController.collectionView)),let cell = browserTabBarController.collectionView.cellForItem(at: indexPath) as? BrowserTabBarCell,!WebWindowState.identifier {
                browserTabBarController.didDeleteTab(cell: cell)
                webWindowAllBringToFront()
                browserTabBarController.collectionView.scrollToItem(at: IndexPath(row: UserDefaults.standard.integer(forKey: "currentIndex"), section: 0), at: .centeredHorizontally, animated: true)

            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) {
                self.createdWindow.openUrl(urlString: url)
            }
            WebWindowState.identifier = false
        case .changed:
            if let indexPath = browserTabBarController.collectionView.indexPathForItem(at: sender.location(in: browserTabBarController.collectionView)),let _ = browserTabBarController.collectionView.cellForItem(at: indexPath) as? BrowserTabBarCell {
                createdWindow.navigation.plusIcon.alpha = 1
            }else{
                createdWindow.navigation.plusIcon.alpha = 0
            }
            createdWindow.frame = CGRect(x: movePoint.x - view.bounds.size.width/3, y:  movePoint.y, width: 2*view.bounds.size.width/3,height: 2*view.bounds.size.height/3)
            
        case .ended:
            if let indexPath = browserTabBarController.collectionView.indexPathForItem(at: sender.location(in: browserTabBarController.collectionView)),let _ = browserTabBarController.collectionView.cellForItem(at: indexPath) as? BrowserTabBarCell {
                
                createdWindow.navigation.plusIcon.alpha = 0
                
                var reloader = DataReloader(tab: browserTabBarController, collection: contentViewController)
                reloader.insert(at: [indexPath], completionHandler: nil)
                
                let data = BrowserDataManager(array: isPrivate ? privateArray : browserTabBarController.array())
                data.fetchWebWindowDataToTab(at: indexPath.row, favicon: (createdWindow.favicon ?? UIImage(named: "rocket.png"))!, webView: createdWindow.webView)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {[unowned self] in
                    browserTabBarController.collectionView.scrollToItem(at: IndexPath(row: isPrivate ? privateIndex : UserDefaults.standard.integer(forKey: "currentIndex"), section: 0), at: .centeredHorizontally, animated: true)
                    contentViewController.collectionView.scrollToItem(at: IndexPath(row: isPrivate ? privateIndex : UserDefaults.standard.integer(forKey: "currentIndex"), section: 0), at: .centeredHorizontally, animated: true)
                }
                cellTapped()
                print("privateIndex",privateIndex)
                createdWindow.removeFromSuperview()
            }
            WebWindowState.identifier = false
        default:
            break
        }
    }
    private func webWindowAnimate(duration:CFTimeInterval = 0.1,from:Float = 0.66,to:Float = 1,webWindow:WebWindow) {
        let group = CAAnimationGroup()
        group.duration = duration
        group.fillMode = .forwards
        group.isRemovedOnCompletion = false
        let animation1 = CABasicAnimation(keyPath: "transform.scale.x")
        animation1.fromValue = from
        animation1.toValue = to
        let animation2 = CABasicAnimation(keyPath: "transform.scale.y")
        animation2.fromValue = from
        animation2.toValue = to
        group.animations = [animation1,animation2]
        webWindow.layer.add(group, forKey: nil)
    }
    @discardableResult func addWebWindow(at:CGPoint,from:Float = 0.66,to:Float = 1,width:CGFloat, height:CGFloat) -> WebWindow {
        let webWindow = WebWindow(frame:CGRect(x: at.x - view.bounds.size.width/3, y: at.y, width: width, height: height))
        webWindowAnimate(duration: 0.1, from: from, to: to, webWindow: webWindow)
        webWindow.delegate = self
        view.addSubview(webWindow)
        webWindows.append(webWindow)
        return webWindow
    }
    func changeTextFieldBlank() {
        searchView.textField.text = ""
    }
    func reloadTabBar() {
        saveDataToJson()
        browserTabBarController.reloadArray()
    }
    func reloadTabCollection() {
        contentViewController.reloadArray()
    }
}
//MARK:BrowserBottomToolBarDelegate
extension BrowserViewController : BrowserBottomToolBarDelegate {
    func webWindowAllRemove() {
        let alertControllrer = UIAlertController(title: "", message: "Do you want to delete all windows?", preferredStyle: .actionSheet)
        let yes = UIAlertAction(title: "Yes", style: .default, handler: {_ in
            self.webWindows.forEach {$0.removeFromSuperview()}
            self.windowButton.forEach {$0.removeFromSuperview()}
            self.windowButton.removeAll()
            self.webWindows.removeAll()
        })
        let cancel = UIAlertAction(title: "Cancel", style: .destructive, handler: {_ in })
        alertControllrer.addAction(yes)
        alertControllrer.addAction(cancel)
        self.present(alertControllrer, animated: true, completion: nil)
    }

    func backButtonTapped() {
        webView.goBack()
    }
    
    func forwardButtonTapped() {
        webView.goForward()
    }
    
    func addWebView() {
        browserTabBarController.addButtonTapped()
        cellHandle(isClose: true)
        contentViewController.reloadArray()
    }
    
    @discardableResult func addWebWindow() -> WebWindow {
        let webWindow = WebWindow(frame:CGRect(x: 0, y: 0, width: 2*view.bounds.size.width/3, height: 2*view.bounds.size.height/3))
        webWindow.center = CGPoint(x: view.bounds.size.width/2 + CGFloat(Float.random(in: -70...70)), y:view.bounds.size.height/2  + CGFloat(Float.random(in: -70...70)))
        let animation = CABasicAnimation(keyPath: "transform.scale")
        animation.duration = 0.15
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false
        animation.fromValue = 0
        animation.toValue = 1
        webWindow.layer.add(animation, forKey: nil)
        webWindow.delegate = self
        view.addSubview(webWindow)
        webWindows.append(webWindow)
        return webWindow
    }
    
    func overviewButtonTapped() {
        overviewController = MenuPopupController()
        overviewController.delegate = self
        overviewController.modalPresentationStyle = .popover
        overviewController.preferredContentSize = CGSize(width: 200, height: 221)
        overviewController.popoverPresentationController?.sourceView = bottomToolBar.overviewButton
        overviewController.popoverPresentationController?.sourceRect = CGRect(origin: CGPoint.zero, size: bottomToolBar.overviewButton.bounds.size)
        overviewController.popoverPresentationController?.permittedArrowDirections = .any
        overviewController.popoverPresentationController?.delegate = self
        self.present(overviewController, animated: true, completion:nil)
    }
    func getCurrentImage() -> UIImage {
        return BrowserFileOperations.readImage(dir:"favicon/\(currentDictionary(UserDefaults.standard.string(forKey: "currentToken")!)["favicon"] ?? "").png")!
    }
    
    func shareButtonTapped() {
        guard newpageExist == .notExist else { return }
        let url = webView.url!
        var activity = [] as [Any]
        if BrowserFileOperations.getLastDirectoryName(url: url.absoluteString).contains(".pdf") {
            if !(0 < fullPaths.count) {
                savePDFIfSpecifiedURL(async: false)
            }
            activity = [fullPaths.last!]
        }else{
            activity = [url]
        }
        let activityVC = UIActivityViewController(activityItems: activity, applicationActivities: nil)
        activityVC.popoverPresentationController?.sourceView = bottomToolBar.shareButton
        activityVC.popoverPresentationController?.sourceRect = bottomToolBar.shareButton.bounds
        self.present(activityVC, animated: true, completion: nil)
    }
    func onLongPress() {
        let alert: UIAlertController = UIAlertController(title: "削除", message: "\(contentViewController.array().count)個のタブを全て削除しますか？", preferredStyle:  UIAlertController.Style.actionSheet)
        let delete: UIAlertAction = UIAlertAction(title: "Delete", style: UIAlertAction.Style.default, handler:{
            (action: UIAlertAction!) -> Void in
            BrowserFileOperations.removeSomeFile(files: ["CellData.json","favicon","snapshot"])
            self.browserTabBarController.addButtonTapped()
            self.contentViewController.reloadArray()
        })
        let cancelAction: UIAlertAction = UIAlertAction(title: "cancel", style: UIAlertAction.Style.cancel, handler:{
            (action: UIAlertAction!) -> Void in
            print("cancelAction")
        })
        alert.addAction(delete)
        alert.addAction(cancelAction)
        self.present(alert, animated: true, completion: nil)
    }
    func getCellInstance(at:IndexPath) -> (BrowserTabBarCell?, TabCollectionViewCell?) {
        if let tabbarCell = browserTabBarController.collectionView.cellForItem(at: at) as? BrowserTabBarCell {
            if let tabCell = contentViewController.collectionView.cellForItem(at: at) as? TabCollectionViewCell {
                return (tabbarCell,tabCell)
            }else{
                return (tabbarCell,nil)
            }
        }else{
            if let tabCell = contentViewController.collectionView.cellForItem(at: at) as? TabCollectionViewCell {
                return (nil,tabCell)
            }else{
                return (nil,nil)
            }
        }
    }
}
//MARK:MenuPopupControllerDelegate
extension BrowserViewController : MenuPopupControllerDelegate {
    func settingsButtonTapped() {
        self.dismiss(animated: true, completion: nil)
        let uvc = SettingsViewController()
        let nav = UINavigationController(rootViewController: uvc)
        self.present(nav, animated: true, completion: nil)
    }
    func historyButtonTapped() {
        self.dismiss(animated: true, completion: nil)
        let his = HistoryViewController()
        self.present(his, animated: true, completion: nil)
    }
    func bookmarkButtonTapped() {
        self.dismiss(animated: true, completion: nil)
        let book = BookmarkViewController()
        self.present(book, animated: true, completion: nil)
    }
    @objc func downloadsButtonTapped() {
        self.dismiss(animated: true, completion: nil)
        let uvc = DownloadListViewController()
        uvc.delegate = self
        let nav = UINavigationController(rootViewController: uvc)
        self.present(nav, animated: true, completion: nil)
    }
}
//MARK:DownloadListViewControllerDelegate
extension BrowserViewController : DownloadListViewControllerDelegate {
    func deleteAllDownloadItem() {
        sessionManager.totalRemove()
        BrowserFileOperations.writingToFile(text: "", dir: "task.txt")
    }
    func deleteDownloadItem(url: String) {
        sessionManager.remove(url)
    }
    func dismissAlertIndicator() {
        self.dismiss(animated: false, completion: nil)
    }
}
//MARK:UIScrollViewDelegate
extension BrowserViewController : UIScrollViewDelegate {
    enum ScrollDirection {
        case up
        case down
    }
    private func fullWebView() {
        print("delta:full")
        let statusBarHeight = self.view.window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0
        let maxTopBarHeight = statusBarHeight + searchView.frame.size.height + progressView.frame.size.height + browserTabBarController.view.frame.size.height
        let maxBottomToolBarHeight = bottomToolBar.bounds.size.height + view.safeAreaInsets.bottom
        searchViewTopConstraint.isActive = false
        bottomToolBarBottomConstraint.isActive = false
        searchViewTopConstraint = searchView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: -maxTopBarHeight)
        bottomToolBarBottomConstraint = bottomToolBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: maxBottomToolBarHeight)
        searchViewTopConstraint.isActive = true
        bottomToolBarBottomConstraint.isActive = true
        
    }
    @objc func panGesture(_ sender:UIPanGestureRecognizer) {
        print("delta:",scrollState,scrollDirection)
        let delta = sender.translation(in: view)
        let point = sender.location(in: view)
        let deltaY = delta.y
        let statusBarHeight = self.view.window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0
        let maxTopBarHeight = statusBarHeight + searchView.frame.size.height + progressView.frame.size.height + browserTabBarController.view.frame.size.height
        let maxBottomToolBarHeight = bottomToolBar.bounds.size.height + view.safeAreaInsets.bottom
        if deltaY > 0 {
            scrollDirection = .up
        }else{
            scrollDirection = .down
        }

        guard -deltaY < maxTopBarHeight else {
            scrollState = .hide
            fullWebView()
            view.layoutIfNeeded()
            return
        }
        if deltaY < 0 && abs(deltaY) < maxTopBarHeight && (scrollState == .exist || scrollState == .TopHiding) {
            print("delta:first")
            //decend topBar and bottomToolBar
            webView.scrollView.setContentOffset(.zero, animated: false)
            scrollState = .TopHiding
            searchViewTopConstraint.isActive = false
            bottomToolBarBottomConstraint.isActive = false
            searchViewTopConstraint = searchView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: deltaY)
            bottomToolBarBottomConstraint = bottomToolBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -deltaY)
            searchViewTopConstraint.isActive = true
            bottomToolBarBottomConstraint.isActive = true
            view.layoutIfNeeded()
        }else if ((deltaY > 0 && webView.scrollView.contentOffset.y < 0) || (scrollState == .appearing && scrollDirection == .up)) && scrollState != .exist {
            if scrollState == .hide {
                startPoint = point.y
            }
            let changeY = abs(startPoint - point.y)
            let constantTop = (-maxTopBarHeight + changeY) >= 0 ? 0 : -maxTopBarHeight + changeY
            let constantBottom = (maxBottomToolBarHeight - changeY) <= 0 ? 0 : maxBottomToolBarHeight - changeY
            guard constantTop < 0 else {
                scrollState = .exist
                identityOfWebView()
                UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 2, initialSpringVelocity:1.5, options: [.allowUserInteraction,.curveEaseIn], animations: {
                    self.view.layoutSubviews()
                })
                return
            }
            print(changeY)
            scrollState = .appearing
            webView.scrollView.setContentOffset(.zero, animated: false)
            searchViewTopConstraint.isActive = false
            bottomToolBarBottomConstraint.isActive = false
            searchViewTopConstraint = searchView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: constantTop)
            bottomToolBarBottomConstraint = bottomToolBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: constantBottom)
            searchViewTopConstraint.isActive = true
            bottomToolBarBottomConstraint.isActive = true
            view.layoutIfNeeded()
        }else if scrollState == .middleHiding && scrollDirection == .down {
            
        }
    }
    func identityOfWebView() {
        searchViewTopConstraint.isActive = false
        bottomToolBarBottomConstraint.isActive = false
        searchViewTopConstraint = searchView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor)
        bottomToolBarBottomConstraint = bottomToolBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        searchViewTopConstraint.isActive = true
        bottomToolBarBottomConstraint.isActive = true
    }
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if scrollState == .TopHiding && scrollDirection == .down {
            fullWebView()
            scrollState = .hide
            UIView.animate(withDuration: 0.25, delay: 0, usingSpringWithDamping: 2, initialSpringVelocity:1.5, options: .allowUserInteraction, animations: {
                self.view.layoutIfNeeded()
            })
        }else if scrollState == .hide && scrollDirection == .up {
            identityOfWebView()
            scrollState = .exist
            UIView.animate(withDuration: 0.25, delay: 0, usingSpringWithDamping: 2, initialSpringVelocity:1.5, options: .allowUserInteraction, animations: {
                self.view.layoutSubviews()
            })
        }else if scrollState == .appearing && scrollDirection == .up {
            identityOfWebView()
            scrollState = .exist
            UIView.animate(withDuration: 0.25, delay: 0, usingSpringWithDamping: 2, initialSpringVelocity:1.5, options: .allowUserInteraction, animations: {
                self.view.layoutSubviews()
            })
        }
    }
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
    }
}
extension BrowserViewController : UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        print("recognize")
        return true
    }
}

extension BrowserViewController : PrivateDataCore { }
//MARK:DataReloaderDataSource
extension BrowserViewController : DataReloaderDataSource {
    func getRequiredInstance() -> (BrowserTabBarController, TabCollectionViewController) {
        return (browserTabBarController,contentViewController)
    }
}
//MARK: AutoCompleteManagerDelegate
extension BrowserViewController : AutoCompleteManagerDelegate {
    func fetchTopSearchbarViewDelegate() -> TopSearchbarView {
        return searchView
    }
}
//MARK: TranslationViewDelegate
extension BrowserViewController : TranslationViewDelegate {
    ///This method is called when a language other than the one set in the terminal is used by detecting the language.
    ///We use Google's translation api.
    func translateTapped() {
        ascendTranslationView()
        translation.translate()
    }
    
}
//MARK: CAAnimationDelegate
extension BrowserViewController : CAAnimationDelegate {
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        if flag,let minimizingWindow = anim.value(forKey: "minimizingWindow") as? WebWindow {
            minimizingWindow.isHidden = true
            let animation = CABasicAnimation(keyPath: "transform.scale").then {
                $0.duration = 0.15
                $0.fillMode = .forwards
                $0.isRemovedOnCompletion = false
                $0.fromValue = 0
                $0.toValue = 1
            }
            let icon = WindowButton().then { button in
                button.webWindow = minimizingWindow
                button.frame = CGRect(center: minimizingWindow.center, size: CGSize(width: 50, height: 50))
                button.setImage(minimizingWindow.favicon, for: .normal)
                button.circle()
                button.addTarget(self, action: #selector(windowIconTapped(_:)), for: .touchUpInside)
                let panGesture = WindowPanGesture(target: self, action: #selector(dragingWindowIcon(_:)))
                panGesture.windowButton = button
                button.addGestureRecognizer(panGesture)
            }
            icon.layer.add(animation, forKey: nil)
            view.addSubview(icon)
            windowButton.append(icon)
        }
        else if flag,let webWindow = anim.value(forKey: "minimizingButton") as? WebWindow {
            webWindow.isHidden = false
            view.bringSubviewToFront(webWindow)
            let animation = CABasicAnimation(keyPath: "transform.scale")
            animation.duration = 0.15
            animation.fillMode = .forwards
            animation.isRemovedOnCompletion = false
            animation.fromValue = 0
            animation.toValue = 1
            webWindow.layer.add(animation, forKey: nil)
            let statusBarHeight = view.window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0
            if webWindow.frame.minY < statusBarHeight {
                webWindow.frame = CGRect(x: webWindow.frame.minX, y: statusBarHeight, width: webWindow.frame.width, height: webWindow.frame.height)
            }
        }
    }
    @objc func windowIconTapped(_ sender:WindowButton) {
        defer {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                sender.removeFromSuperview()
            }
        }
        let webWindow = sender.webWindow
        let animation = CABasicAnimation(keyPath: "transform.scale")
        animation.fillMode = .forwards
        animation.duration = 0.15
        animation.isRemovedOnCompletion = false
        animation.fromValue = 1
        animation.toValue = 0
        animation.delegate = self
        animation.setValue(webWindow, forKey: "minimizingButton")
        sender.layer.add(animation, forKey: nil)
    }
    @objc func dragingWindowIcon(_ sender:WindowPanGesture) {
        let button = sender.windowButton!
        let webWindow = button.webWindow!
        view.bringSubviewToFront(button)
        let movePoint = sender.translation(in: button)
        guard button.frame.minY + movePoint.y > (view.window?.windowScene?.statusBarManager?.statusBarFrame.height)! else {return}
        button.center = CGPoint(x: button.center.x + movePoint.x, y: button.center.y + movePoint.y)
        webWindow.center = CGPoint(x: button.center.x + movePoint.x, y: button.center.y + movePoint.y)
        sender.setTranslation(.zero, in: button)
    }
}
//MARK: WebWindowDelegate
extension BrowserViewController : WebWindowDelegate {
    //we don't use thie method
    func plusIconTapped() {}

    func removeWindow(window: WebWindow) {
        window.removeFromSuperview()
        webWindows = webWindows.filter { $0 != window }
        windowButton.filter { $0.window == window }.forEach { $0.removeFromSuperview() }
        windowButton = windowButton.filter { $0.window != window }
    }
    
    func minimizeWindow(window: WebWindow) {
        let animation = CABasicAnimation(keyPath: "transform.scale")
        animation.duration = 0.15
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false
        animation.fromValue = 1
        animation.autoreverses = false
        animation.toValue = 0
        animation.delegate = self
        animation.setValue(window, forKey: "minimizingWindow")
        window.layer.add(animation, forKey: nil)
    }
    
    func shrinkWebWindow(_ sender: UIPanGestureRecognizer,window:WebWindow) {
        view.bringSubviewToFront(window)
        let movePoint = sender.translation(in: window)
        let xOffset = movePoint.x
        let yOffset = movePoint.y
        guard window.frame.width + xOffset > 100 else { return }
        guard window.frame.height + yOffset > 100 else { return }
        window.frame = CGRect(x: window.frame.minX, y: window.frame.minY, width: window.frame.width + xOffset, height: window.frame.height + yOffset)
        sender.setTranslation(.zero, in: window)
    }
    
    func moveWebWindow(_ sender: UIPanGestureRecognizer,window:WebWindow) {
        view.bringSubviewToFront(window)
        let movePoint = sender.translation(in: window)
        let xOffset = movePoint.x
        let yOffset = movePoint.y

        switch sender.state {
        case .began,.changed:
            if let indexPath = browserTabBarController.collectionView.indexPathForItem(at: sender.location(in: browserTabBarController.collectionView)) {
                window.navigation.plusIcon.alpha = 1
            }else{
                window.navigation.plusIcon.alpha = 0
            }
            guard window.frame.minY + yOffset > (view.window?.windowScene?.statusBarManager?.statusBarFrame.height)! else {return}
            window.center = CGPoint(x:window.center.x + xOffset, y:window.center.y + yOffset)
            sender.setTranslation(.zero, in: window)
        case .ended:
            if let indexPath = browserTabBarController.collectionView.indexPathForItem(at: sender.location(in: browserTabBarController.collectionView)) {
                print(indexPath)
                window.navigation.plusIcon.alpha = 0
                
                let data = BrowserDataManager(array: isPrivate ? privateArray : browserTabBarController.array())
                data.fetchWebWindowDataToTab(at: indexPath.row, favicon: (window.favicon ?? UIImage(named: "rocket.png"))!, webView: window.webView)
                
                var reloader = DataReloader(tab: browserTabBarController, collection: contentViewController)
                reloader.insert(at: [indexPath], completionHandler: nil)
                //switch tab
                cellTapped()
                print("privateIndex",privateIndex)
                DispatchQueue.main.async {
                    self.browserTabBarController.collectionView.scrollToItem(at: IndexPath(row: self.isPrivate ? self.privateIndex : UserDefaults.standard.integer(forKey: "currentIndex"), section: 0), at: .centeredHorizontally, animated: true)
                    self.contentViewController.collectionView.scrollToItem(at: IndexPath(row: self.isPrivate ? self.privateIndex : UserDefaults.standard.integer(forKey: "currentIndex"), section: 0), at: .centeredHorizontally, animated: true)
                }
                window.removeFromSuperview()
            }
        default:
            break
        }
    }
}
extension BrowserViewController : PastCellManagerDelegate {
    func getMainInstance() -> BrowserViewController {
        return self
    }
    
}
extension String {
    func hasPrefixes(prefixes:[String]) -> Bool {
        for prefix in prefixes {
            if self.hasPrefix(prefix) {
                return true
            }
        }
        return false
    }
    func hasPrefixAllowingHiraganaKatakana(prefix:String) -> Bool{
        //prefix is searchText
        //self is suggestion
        if (self.isHiragana && prefix.isHiragana) || self.isKatakana && prefix.isKatakana {
            return hasPrefix(prefix)
        }
        else if self.isKatakana && prefix.isHiragana {
            return hasPrefix(prefix.hiraganaToKatakana())
        }
        else {//if self.isHiragana && prefix.isKatakana {
            return hasPrefix(prefix.katakanaTohiragana())
        }
    }
}
fileprivate extension BrowserFileOperations {
    class func deleteAllData(fullpaths:[URL]) {
        fullpaths.forEach{BrowserFileOperations.deleteData(fullPath: $0)}
    }
}

struct URLChecker {
    var currentMode:mode
    init(currentMode:mode) {
        self.currentMode = currentMode
    }
    public func checkUrlOrNot(fieldText:String) -> Bool {
        
        return (fieldText.contains("http://") == true || fieldText.contains(".dev") == true || fieldText.contains("www.") == true || fieldText.contains(".co.") == true || fieldText.contains(".jp") == true || fieldText.contains(".com") == true || fieldText.contains(".org") == true || fieldText.contains(".io") == true || fieldText.contains(".go") == true || fieldText.contains(".net") == true || fieldText.contains(".gov") == true || fieldText.contains(".int") == true || fieldText.contains("https://") == true || fieldText.contains(".be") == true || fieldText.contains(".eu") == true || fieldText.contains(".de") == true || fieldText.contains(".es") == true || fieldText.contains(".me") == true) && (currentMode == .google || currentMode == .yahoo || currentMode == .duckduckgo)
    }
}
extension WKProcessPool {
    static var shared = WKProcessPool()
    func reset() {
        WKProcessPool.shared = WKProcessPool()
    }
}
final class FavIconFetcher : NSObject {
    private static var baseURL:String = "https://www.google.com/s2/favicons?sz=256&domain_url="
    
    enum FavError : Error {
        case invalidURLString
        case failedToFetchData
    }
    //async
    static func download(url:String , response:@escaping (Result<UIImage,FavError>) -> ()) {
        let iconURL:String = FavIconFetcher.baseURL + url
        guard let link = URL(string: iconURL) else {
            response(.failure(.invalidURLString))
            return
        }
        DispatchQueue.global().async {
            if let imageData = try? Data(contentsOf: link),let image = UIImage(data: imageData) {
                if image.size == CGSize(width: 16, height: 16) {
                    response(.success(UIImage(named: "rocket.png")!))
                }else{
                    response(.success(image))
                }
            }else{
                response(.failure(.failedToFetchData))
            }
        }
    }
    //unsafe
    static func syncDownload(url:String) -> UIImage? {
        let iconURL:String = FavIconFetcher.baseURL + url
        if let imageData = try? Data(contentsOf: URL(string: iconURL)!),let image = UIImage(data: imageData) {
            return image
        }else{
            return nil
        }
    }
    private static func getBlankIcon() -> UIImage? {
        print("getBlankIcon")
        var blank:UIImage?
        blank = syncDownload(url:"https://github.com")
        return blank
    }
    static var blankIcon = getBlankIcon()
}
extension WKHTTPCookieStore {
    func setCookies(cookies:[HTTPCookie]) {
        cookies.forEach {setCookie($0, completionHandler: nil)}
    }
}
protocol WebRequirements : PrivateDataCore where Self:WKNavigationDelegate {
    var webView:BrowserWKWebView {get set}
}
extension WebRequirements {
    func urlToHostName(urlString:String) -> String {
        let component: NSURLComponents = NSURLComponents(string: urlString)!
        return component.host ?? ""
    }
    func openUrl(urlString: String) {
        if let url = URL(string: urlString) {
            let request = NSURLRequest(url: url)
            webView.load(request as URLRequest)
        }
    }
    func openUrl(urlString:String,web:WKWebView) {
        let url = URL(string: urlString)
        let request = NSURLRequest(url: url!)
        web.load(request as URLRequest)
    }
    func openUrl(url:URL) {
        let request = NSURLRequest(url:url)
        webView.load(request as URLRequest)
    }
    func openHtml(html:String) {
        webView.loadHTMLString(html, baseURL: nil)
    }
}
class WindowButton : UIButton {
    var webWindow:WebWindow!
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
class WindowPanGesture : UIPanGestureRecognizer {
    var windowButton:WindowButton!
    override init(target: Any?, action: Selector?) {
        super.init(target: target, action: action)
    }
}
