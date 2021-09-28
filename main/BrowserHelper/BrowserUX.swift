//
//  SizeManager.swift
//  main
//
//  Created by Ryu on 2021/05/16.
//

import Foundation
import UIKit

struct BrowserUX : PrivateDataCore {
    ///entire
    static let screenWidth = UIScreen.main.bounds.size.width
    static let screenHeight = UIScreen.main.bounds.size.height
    ///tabCollectionView property must be initialized when access property
    static var tabCollectionView = UIView()
    
    var tabbarView:UIView
    var cellData:CellData
    
    static let webWindowNavigationHeight = CGFloat(24)
    
    static var portraitBase:CGFloat {
        return getBaseSize(base: .short)
    }
    static var landscapeBase:CGFloat {
        return getBaseSize(base: .long)
    }
    ///Size of tab collection cell
    static let normalCellSize = CGFloat(180)
    
    
    enum Base {
        case long
        case short
    }
    
    enum PhoneType {
        
        case mobilePortrait
        case mobileLandscape
        case padPortrait
        case padLandscape
        case notIdentified
        
        var tabCellSize:CGSize {
            switch self {
            case .mobileLandscape:
                return CGSize(width: landscapeBase/4 - 5, height: landscapeBase/4 - 5)
            case .mobilePortrait:
                return CGSize(width: portraitBase/2 - 5, height: portraitBase/2 - 5)
            case .padLandscape:
                return CGSize(width: landscapeBase/6 - 7, height: landscapeBase/6 - 7)
            case .padPortrait:
                return CGSize(width: portraitBase/4 - 7, height: portraitBase/4 - 7)
            default:
                return CGSize(width: portraitBase/2 - 5, height: portraitBase/2 - 5)
            }
        }
        
        init() {
            let device = UIDevice.current.userInterfaceIdiom
            if let interfaceOrientation = UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.windowScene?.interfaceOrientation {
                switch interfaceOrientation {
                case .portrait:
                    self = device == .phone ? .mobilePortrait : .padPortrait
                default:
                    self = device == .phone ? .mobileLandscape : .padLandscape
                }
            }else{
                self = .notIdentified
            }
        }
    }
    
    static func getBaseSize(base:Base) -> CGFloat {
        switch base {
        case .short:
            return Self.tabCollectionView.bounds.size.width > Self.tabCollectionView.bounds.size.height ? Self.tabCollectionView.bounds.size.height : Self.tabCollectionView.bounds.size.width
        default:
            return Self.tabCollectionView.bounds.size.width < Self.tabCollectionView.bounds.size.height ? Self.tabCollectionView.bounds.size.height : Self.tabCollectionView.bounds.size.width
        }
    }
    
    var tabBarCellSize:CGSize {
        let width = tabbarView.bounds.size.width / 150
        let fl = Int(floor(width))
        for i in 1...fl {
            if isPrivate ? privateArray.count == i : cellData.count == i {
                return CGSize(width: tabbarView.bounds.size.width/CGFloat(i), height: tabbarView.bounds.size.height)
            }
        }
        return CGSize(width: 150, height: tabbarView.bounds.size.height)
    }
    
    init(tabBar:UIView,cellData:CellData) {
        self.tabbarView = tabBar
        self.cellData = cellData
    }
}
