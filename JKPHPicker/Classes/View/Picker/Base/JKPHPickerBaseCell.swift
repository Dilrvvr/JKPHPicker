//
//  JKPHPickerBaseCell.swift
//  JKPHPicker
//
//  Created by albert on 8/22/22.
//

import UIKit
import Photos
import JKSwiftLibrary

open class JKPHPickerBaseCell: JKPHPickerBaseCollectionViewCell {
    
    open class var layoutEdgeInset: CGFloat { 5.0 }
    
    // MARK:
    // MARK: - Public Property
    
    /// 缩略图
    open var currentImage: UIImage? { imageView.image }
    
    open override var model: JKPHPickerPhotoItem? {
        
        willSet {
            
            if let item = model,
               let requestID = item.requestThumbnailImageID {
                
                if (newValue == nil) || (newValue! != item) {
                    
                    JKPHPickerEngine.cancelImageRequest(requestID)
                    item.requestThumbnailImageID = nil
                }
            }
            
            imageView.image = nil
        }
        
        didSet {
            
        }
    }
    
    // MARK:
    // MARK: - Public Methods
    
    open func reload(with photoItem: JKPHPickerPhotoItem, isRequestImage: Bool) {
        
        guard let item = model, item == photoItem else { return }
        
        guard isRequestImage else { return }
        
        imageView.setPhotoPickerImage(with: photoItem, configuration: configuration, imageCache: thumbnailImageCache, requestType: .thumbnail) { [weak self] photoItem, image, info, error in
            
            guard let _ = self,
                  let image = image,
                  let cache = self?.thumbnailImageCache else {
                
                return
            }
            
            cache.setObject(image, forKey: NSString(string: photoItem.localIdentifier))
        }
    }
    
    // MARK:
    // MARK: - Override
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        
        imageView.frame = contentView.bounds
    }
    
    // MARK:
    // MARK: - Private Methods
    
    
    
    // MARK:
    // MARK: - Private Selector
    
    
    
    // MARK:
    // MARK: - Custom Delegates
    
    
    
    // MARK:
    // MARK: - Initialization & Build UI
    
    /// 初始化自身属性 交给子类重写 super自动调用该方法
    open override func initializeProperty() {
        super.initializeProperty()
        
    }
    
    /// 构造函数初始化时调用 注意调用super
    open override func initialization() {
        super.initialization()
        
    }
    
    /// 创建UI 交给子类重写 super自动调用该方法
    open override func createUI() {
        super.createUI()
        
        contentView.addSubview(imageView)
    }
    
    /// 布局UI 交给子类重写 super自动调用该方法
    open override func layoutUI() {
        super.layoutUI()
        
    }
    
    /// 初始化UI数据 交给子类重写 super自动调用该方法
    open override func initializeUIData() {
        super.initializeUIData()
        
        //self.makeShadow(view: selectIconLabel)
    }
    
    // MARK:
    // MARK: - Private Property
    
    /// imageView
    open private(set) lazy var imageView: JKPHPickerUIImageView = {
        
        let imageView = JKPHPickerUIImageView()
        
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        
        if #available(iOS 13.0, *) {
            imageView.jk_indicatorView.overrideUserInterfaceStyle = .light
            imageView.jk_indicatorView.style = .medium
        } else {
            imageView.jk_indicatorView.style = .white
        }
        
        imageView.jk_indicatorView.color = .lightGray
        
        return imageView
    }()
    
    open private(set) lazy var iCloudButton: UIButton = {
        
        let button = UIButton(type: .custom)
        
        button.isUserInteractionEnabled = false
        
        var image: UIImage?
        
        if #available(iOS 13.0, *) {
            
            let systemImage = UIImage(systemName: "icloud.and.arrow.down")
            
            if let _ = systemImage {
                
                image = systemImage?.withTintColor(.white, renderingMode: .alwaysOriginal)
            }
        }
        
        if image == nil {
            
            image = JKPHPickerResourceManager.image(named: "icloud_download_icon")
        }
        
        button.setBackgroundImage(image, for: .normal)
        
        self.makeShadow(view: button)
        
        return button
    }()
    
    open private(set) lazy var mediaTypeFont = UIFont.systemFont(ofSize: 11.0)
    
    /// 类型图标
    open private(set) lazy var mediaTypeButton: UIButton = {
        
        let button = UIButton(type: .custom)
        
        button.isHidden = true
        button.isUserInteractionEnabled = false
        button.contentHorizontalAlignment = .left
        button.imageView?.contentMode = .scaleAspectFit
        button.contentEdgeInsets = .zero
        button.titleLabel?.font = self.mediaTypeFont
        button.titleLabel?.adjustsFontSizeToFitWidth = true
        
        self.makeShadow(view: button)
        
        return button
    }()
    
    /// 收藏的图标
    open private(set) lazy var favoriteIconButton: UIButton = {
        
        let button = UIButton(type: .custom)
        
        button.isUserInteractionEnabled = false
        button.contentHorizontalAlignment = .left
        button.contentVerticalAlignment = .bottom
        
        var image: UIImage?
        
        if #available(iOS 13.0, *) {
            
            let systemImage = UIImage(systemName: "heart.fill")
            
            if let _ = systemImage {
                
                image = systemImage?.withTintColor(.white, renderingMode: .alwaysOriginal)
            }
        }
        
        if image == nil {
            
            image = JKPHPickerResourceManager.image(named: "heart_fill_icon")
        }
        
        button.setBackgroundImage(image, for: .normal)
        
        self.makeShadow(view: button)
        
        return button
    }()
    
    /// durationLabel
    open private(set) lazy var durationLabel: UILabel = {
        
        let label = UILabel()
        
        label.font = UIFont.systemFont(ofSize: 11.0)
        label.textColor = .white
        label.textAlignment = .right
        
        self.makeShadow(view: label)
        
        return label
    }()
    
    open var shadowColor: CGColor {
        
        UIColor.black.withAlphaComponent(0.4).cgColor
    }
    
    open func makeShadow(view: UIView) {
        
        view.layer.shadowColor = self.shadowColor
        view.layer.shadowOffset = .zero
        view.layer.shadowOpacity = 1.0
        view.layer.shadowRadius = 1.0
    }
}
