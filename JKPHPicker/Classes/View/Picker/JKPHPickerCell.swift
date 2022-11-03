//
//  JKPHPickerCell.swift
//  JKSwiftPhotoPicker
//
//  Created by AlbertCC on 2021/5/4.
//

import UIKit
import Photos
import JKSwiftLibrary

open class JKPHPickerCell: JKPHPickerBaseCell {
    
    // MARK:
    // MARK: - Public Property
    
    open override var hasSelectedCover: Bool { true }
    
    open override var model: JKPHPickerPhotoItem? {
        
        willSet {
            
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
    
    open override func reload(with photoItem: JKPHPickerPhotoItem, isRequestImage: Bool) {
        super.reload(with: photoItem, isRequestImage: isRequestImage)
        
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
        
        //imageView.frame = contentView.bounds
        
        setNeedsLayout()
        layoutIfNeeded()
    }
    
    // MARK:
    // MARK: - Override
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        
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
        
        if let photoItem = model,
           let _ = photoItem.mediaTypeImageName,
           mediaTypeButton.frame.size.width > iconMaxWH {
            
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
    
    
}
