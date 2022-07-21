//
//  JKPHPickerCell.swift
//  JKSwiftPhotoPicker
//
//  Created by AlbertCC on 2021/5/4.
//

import UIKit
import Photos
import JKSwiftLibrary

open class JKPHPickerCell: JKPHPickerBaseCollectionViewCell {
    
    private static let layoutEdgeInset: CGFloat = 5.0
    
    // MARK:
    // MARK: - Public Property
    
    open override var hasSelectedCover: Bool { true }
    
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
            
            favoriteIconButton.isHidden = true
            durationLabel.isHidden = true
            iCloudButton.isHidden = true
            mediaTypeButton.isHidden = true
            nonselectableCoverView.isHidden = true
            
            updateSelectIcon(isSelected: false)
        }
        
        didSet {
            
            guard let item = model else { return }
            
            item.reloadPickerHandler = { [weak self] (photoItem: JKPHPickerPhotoItem, isRequestImage: Bool) in
                
                guard let _ = self else { return }
                
                self?.reload(with: photoItem, isRequestImage: isRequestImage)
            }
            
            reload(with: item, isRequestImage: true)
        }
    }
    
    // MARK:
    // MARK: - Public Methods
    
    private func reload(with photoItem: JKPHPickerPhotoItem, isRequestImage: Bool) {
        
        guard let item = model, item == photoItem else { return }
        
        nonselectableCoverView.isHidden = photoItem.isSelectable
        
        selectButton.isHidden = !photoItem.isSelectable
        selectIconLabel.isHidden = selectButton.isHidden
        
        updateSelectIcon(isSelected: photoItem.isSelected)
        
        iCloudButton.isHidden = !photoItem.isIniCloud
        
        if let mediaTypeImageName = photoItem.mediaTypeImageName {
            
            mediaTypeButton.setTitle(nil, for: .normal)
            mediaTypeButton.setBackgroundImage(JKPHPickerResourceManager.image(named: mediaTypeImageName), for: .normal)
            mediaTypeButton.isHidden = false
            
        } else if let mediaTypeDisplayName = photoItem.mediaTypeDisplayName {
            
            mediaTypeButton.setTitle(mediaTypeDisplayName, for: .normal)
            mediaTypeButton.setBackgroundImage(nil, for: .normal)
            mediaTypeButton.isHidden = false
            
        } else {
            
            mediaTypeButton.isHidden = true
        }
        
        selectIconLabel.text = photoItem.isSelected ? "\(photoItem.selectIndex + 1)" : nil
        
        favoriteIconButton.isHidden = !photoItem.asset.isFavorite
        durationLabel.isHidden = !photoItem.isVideo
        
        durationLabel.text = photoItem.durationString
        
        imageView.frame = contentView.bounds
        
        setNeedsLayout()
        layoutIfNeeded()
        
        if isRequestImage {
            
            imageView.setPhotoPickerImage(with: photoItem, configuration: configuration, imageCache: thumbnailImageCache, requestType: .thumbnail) { [weak self] photoItem, image, info, error in
                
                guard let _ = self,
                      let image = image,
                      let cache = self?.thumbnailImageCache else {
                          
                          return
                      }
                
                cache.setObject(image, forKey: NSString(string: photoItem.localIdentifier))
            }
        }
    }
    
    // MARK:
    // MARK: - Override
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        initialization()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        initialization()
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        
        imageView.frame = contentView.bounds
        
        selectCoverView.frame = contentView.bounds
        
        nonselectableCoverView.frame = contentView.bounds
        
        selectIconLabel.frame = CGRect(x: contentView.bounds.width - Self.selectIconWH - Self.layoutEdgeInset, y: Self.layoutEdgeInset, width: Self.selectIconWH, height: Self.selectIconWH)
        
        selectButton.frame = CGRect(x: contentView.bounds.width - Self.selectButtonSize.width, y: 0.0, width: Self.selectButtonSize.width, height: Self.selectButtonSize.height)
        
        let iconMaxWH: CGFloat = 18.0
        
        iCloudButton.sizeToFit()
        
        var previousSize = iCloudButton.frame.size
        
        iCloudButton.frame.size.height = iconMaxWH
        iCloudButton.frame.size.width = JKGetScaleWidth(currentHeight: iCloudButton.frame.size.height, scaleWidth: previousSize.width, scaleHeight: previousSize.height)
        
        if iCloudButton.frame.size.width > iconMaxWH {
            
            iCloudButton.frame.size.width = iconMaxWH
            iCloudButton.frame.size.height = JKGetScaleHeight(currentWidth: iCloudButton.frame.size.width, scaleWidth: previousSize.width, scaleHeight: previousSize.height)
        }
        
        //iCloudButton.frame = CGRect(x: Self.layoutEdgeInset, y: Self.layoutEdgeInset, width: 16.3, height: 15.67)
        iCloudButton.frame.origin.x = Self.layoutEdgeInset
        iCloudButton.center.y = selectIconLabel.center.y
        
        mediaTypeButton.sizeToFit()
        previousSize = mediaTypeButton.frame.size
        
        mediaTypeButton.frame.size.height = iconMaxWH
        mediaTypeButton.frame.size.width = JKGetScaleWidth(currentHeight: mediaTypeButton.frame.size.height, scaleWidth: previousSize.width, scaleHeight: previousSize.height)
        
        if mediaTypeButton.frame.size.width > iconMaxWH {
            
            mediaTypeButton.frame.size.width = iconMaxWH
            mediaTypeButton.frame.size.height = JKGetScaleHeight(currentWidth: mediaTypeButton.frame.size.width, scaleWidth: previousSize.width, scaleHeight: previousSize.height)
        }
        
        let mediaTypeX = (iCloudButton.isHidden ? Self.layoutEdgeInset : (iCloudButton.frame.maxX + Self.layoutEdgeInset))
        mediaTypeButton.frame.origin.x = mediaTypeX
        mediaTypeButton.center.y = selectIconLabel.center.y
        
        favoriteIconButton.sizeToFit()
        previousSize = favoriteIconButton.frame.size
        
        favoriteIconButton.frame.size.height = iconMaxWH
        favoriteIconButton.frame.size.width = JKGetScaleWidth(currentHeight: favoriteIconButton.frame.size.height, scaleWidth: previousSize.width, scaleHeight: previousSize.height)
        
        if favoriteIconButton.frame.size.width > iconMaxWH {
            
            favoriteIconButton.frame.size.width = iconMaxWH
            favoriteIconButton.frame.size.height = JKGetScaleHeight(currentWidth: favoriteIconButton.frame.size.width, scaleWidth: previousSize.width, scaleHeight: previousSize.height)
        }
        
        favoriteIconButton.frame.origin.y = (contentView.bounds.height - Self.layoutEdgeInset - favoriteIconButton.bounds.height)
        
        if iCloudButton.isHidden,
           mediaTypeButton.isHidden {
            
            favoriteIconButton.frame.origin.x = Self.layoutEdgeInset
            
        } else if iCloudButton.isHidden {
            
            if let titleLabel = mediaTypeButton.titleLabel,
               let _ = titleLabel.text {
                
                favoriteIconButton.center.x = mediaTypeButton.frame.minX + titleLabel.bounds.width * 0.5
                
            } else {
                
                favoriteIconButton.center.x = mediaTypeButton.center.x
            }
            
        } else {
            
            favoriteIconButton.center.x = iCloudButton.center.x
        }
        
        var size = durationLabel.sizeThatFits(CGSize(width: CGFloat.infinity, height: Self.selectIconWH))
        size.width += 2.0
        durationLabel.frame = CGRect(x: (contentView.bounds.width - Self.layoutEdgeInset - size.width), y: 0.0, width: size.width, height: size.height)
        
        //durationLabel.frame.origin.y = contentView.bounds.height - Self.layoutEdgeInset - size.height
        
        durationLabel.center.y = favoriteIconButton.center.y
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
    open func initializeProperty() {
        
    }
    
    /// 构造函数初始化时调用 注意调用super
    open func initialization() {
        
        initializeProperty()
        createUI()
        layoutUI()
        initializeUIData()
    }
    
    /// 创建UI 交给子类重写 super自动调用该方法
    open func createUI() {
        
        contentView.addSubview(imageView)
        contentView.addSubview(selectCoverView)
        contentView.addSubview(iCloudButton)
        contentView.addSubview(mediaTypeButton)
        contentView.addSubview(favoriteIconButton)
        contentView.addSubview(durationLabel)
        contentView.addSubview(selectButton)
        contentView.addSubview(selectIconLabel)
        contentView.addSubview(nonselectableCoverView)
    }
    
    /// 布局UI 交给子类重写 super自动调用该方法
    open func layoutUI() {
        
    }
    
    /// 初始化UI数据 交给子类重写 super自动调用该方法
    open func initializeUIData() {
        
        //self.makeShadow(view: selectIconLabel)
    }
    
    // MARK:
    // MARK: - Private Property
    
    /// imageView
    private lazy var imageView: JKPHPickerUIImageView = {
        
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
    
    private lazy var iCloudButton: UIButton = {
        
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
    
    private lazy var mediaTypeFont = UIFont.systemFont(ofSize: 11.0)
    
    /// 类型图标
    private lazy var mediaTypeButton: UIButton = {
        
        let button = UIButton(type: .custom)
        
        button.isHidden = true
        button.isUserInteractionEnabled = false
        button.contentHorizontalAlignment = .left
        button.imageView?.contentMode = .scaleAspectFit
        button.contentEdgeInsets = .zero
        button.titleLabel?.font = self.mediaTypeFont
        
        self.makeShadow(view: button)
        
        return button
    }()
    
    /// 收藏的图标
    private lazy var favoriteIconButton: UIButton = {
        
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
    private lazy var durationLabel: UILabel = {
        
        let label = UILabel()
        
        label.font = UIFont.systemFont(ofSize: 11.0)
        label.textColor = .white
        label.textAlignment = .right
        
        self.makeShadow(view: label)
        
        return label
    }()
    
    private var shadowColor: CGColor {
        
        UIColor.black.withAlphaComponent(0.4).cgColor
    }
    
    private func makeShadow(view: UIView) {
        
        view.layer.shadowColor = self.shadowColor
        view.layer.shadowOffset = .zero
        view.layer.shadowOpacity = 1.0
        view.layer.shadowRadius = 1.0
    }
}
