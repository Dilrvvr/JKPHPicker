//
//  JKPHPickerBaseCollectionViewCell.swift
//  JKSwiftPhotoPicker
//
//  Created by albert on 2021/5/24.
//

import UIKit
import Photos

open class JKPHPickerBaseCollectionViewCell: UICollectionViewCell {
    
    /// 选中图标的宽高
    public static let selectIconWH: CGFloat = 24.0
    
    /// 选中按钮的宽高
    public static let selectButtonSize: CGSize = CGSize(width: 44.0, height: 44.0)
    
    // MARK:
    // MARK: - Public Property
    
    open var thumbnailImageCache: NSCache<NSString, UIImage>?
    
    open var previewImageCache: NSCache<NSString, UIImage>?
    
    open var configuration: JKPHPickerConfiguration?
    
    open var model: JKPHPickerPhotoItem?
    
    open var photoIdentifier = ""
    
    open var hasSelectedCover: Bool { false }
    
    open var selectActionHandler: ((_ model: JKPHPickerPhotoItem?, _ button: UIButton) -> Void)?
    
    /// selectIconImageView
    open private(set) lazy var selectIconImageView: UIImageView = {
        
        let imageView = UIImageView()
        
        imageView.isHidden = true
        imageView.contentMode = .scaleAspectFill
        imageView.image = JKPHPickerResourceManager.image(named: "select_off")
        
        imageView.layer.cornerRadius = Self.selectIconWH * 0.5
        
        return imageView
    }()
    
    open private(set) lazy var selectButton: UIButton = {
        
        let button = UIButton(type: .custom)
        
        button.isHidden = true
        button.addTarget(self, action: #selector(selectButtonClick(button:)), for: .touchUpInside)
        
        return button
    }()
    
    open private(set) lazy var selectCoverView: UIView = {
        
        let selectCoverView = UIView()
        
        selectCoverView.isHidden = true
        selectCoverView.isUserInteractionEnabled = false
        selectCoverView.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        
        return selectCoverView
    }()
    
    /// 不可选中的遮盖view
    open private(set) lazy var nonselectableCoverView: UIView = {
        
        let selectCoverView = UIView()
        
        selectCoverView.isHidden = true
        selectCoverView.isUserInteractionEnabled = false
        selectCoverView.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        
        return selectCoverView
    }()
    
    // MARK:
    // MARK: - Public Function
    
    open func updateSelectIcon(isSelected: Bool) {
        
        let imageName = isSelected ? "select_on" : "select_off"
        
        selectIconImageView.image = JKPHPickerResourceManager.image(named: imageName)
        
        if hasSelectedCover {
            
            selectCoverView.isHidden = !isSelected
        }
    }
    
    // MARK:
    // MARK: - Public Selector
    
    /// selectButtonClick
    @objc open func selectButtonClick(button: UIButton) {
        
        if let handler = selectActionHandler {
            
            handler(model, button)
        }
    }
}
