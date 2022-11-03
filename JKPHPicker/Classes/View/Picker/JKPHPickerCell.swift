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
            mediaTypeLabel.isHidden = true
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
            
            mediaTypeButton.setBackgroundImage(JKPHPickerResourceManager.image(named: mediaTypeImageName), for: .normal)
            mediaTypeButton.isHidden = false
            
            mediaTypeLabel.isHidden = true
            
        } else if let mediaTypeDisplayName = photoItem.mediaTypeDisplayName {
            
            mediaTypeLabel.text = mediaTypeDisplayName
            mediaTypeLabel.isHidden = false
            
            mediaTypeButton.isHidden = true
            
        } else {
            
            mediaTypeButton.isHidden = true
            mediaTypeLabel.isHidden = true
        }
        
        selectIconLabel.text = photoItem.isSelected ? "\(photoItem.selectIndex + 1)" : nil
        
        favoriteIconButton.isHidden = !photoItem.asset.isFavorite
        durationLabel.isHidden = !photoItem.isVideo
        
        durationLabel.text = photoItem.durationString
        
        //imageView.frame = contentView.bounds
        
        topShadowLayer.isHidden = (iCloudButton.isHidden &&
                                   mediaTypeButton.isHidden &&
                                   mediaTypeLabel.isHidden)
        
        bottomShadowLayer.isHidden = (favoriteIconButton.isHidden &&
                                      durationLabel.isHidden)
        
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
        
        let shadowLayerHeight = iconMaxWH + Self.layoutEdgeInset * 2.0
        
        topShadowLayer.frame = CGRect(x: 0.0, y: 0.0, width: contentView.bounds.width, height: shadowLayerHeight)
        bottomShadowLayer.frame = CGRect(x: 0.0, y: contentView.bounds.height - shadowLayerHeight, width: contentView.bounds.width, height: shadowLayerHeight)
        
        var iconFrame = CGRect.zero
        
        iconFrame.size = iCloudButton.sizeThatFits(CGSize(width: CGFloat.infinity, height: iconMaxWH))
        var previousSize = iconFrame.size
        
        if iconFrame.size.width > iconMaxWH {
            
            iconFrame.size.width = iconMaxWH
            iconFrame.size.height = JKGetScaleHeight(currentWidth: iconFrame.size.width, scaleWidth: previousSize.width, scaleHeight: previousSize.height)
        }
        
        //iCloudButton.frame = CGRect(x: Self.layoutEdgeInset, y: Self.layoutEdgeInset, width: 16.3, height: 15.67)
        iconFrame.origin.x = Self.layoutEdgeInset
        iconFrame.origin.y = selectIconLabel.center.y - iconFrame.height * 0.5
        iCloudButton.frame = iconFrame
        
        if !mediaTypeButton.isHidden {
            
            iconFrame.size = mediaTypeButton.sizeThatFits(CGSize(width: CGFloat.infinity, height: iconMaxWH))
            previousSize = iconFrame.size
            
            if iconFrame.size.width > iconMaxWH {
                
                iconFrame.size.width = iconMaxWH
                iconFrame.size.height = JKGetScaleHeight(currentWidth: iconFrame.size.width, scaleWidth: previousSize.width, scaleHeight: previousSize.height)
            }
            
        } else if !mediaTypeLabel.isHidden {
            
            iconFrame.size = mediaTypeLabel.sizeThatFits(CGSize(width: CGFloat.infinity, height: iconMaxWH))
        }
        
        let mediaTypeX = (iCloudButton.isHidden ? Self.layoutEdgeInset : (iCloudButton.frame.maxX + Self.layoutEdgeInset))
        iconFrame.origin.x = mediaTypeX
        iconFrame.origin.y = selectIconLabel.center.y - iconFrame.height * 0.5
        mediaTypeButton.frame = iconFrame
        mediaTypeLabel.frame = iconFrame
        
        iconFrame.size = favoriteIconButton.sizeThatFits(CGSize(width: CGFloat.infinity, height: iconMaxWH))
        previousSize = iconFrame.size
        
        if iconFrame.size.width > iconMaxWH {
            
            iconFrame.size.width = iconMaxWH
            iconFrame.size.height = JKGetScaleHeight(currentWidth: iconFrame.size.width, scaleWidth: previousSize.width, scaleHeight: previousSize.height)
        }
        
        iconFrame.origin.x = Self.layoutEdgeInset
        iconFrame.origin.y = (contentView.bounds.height - Self.layoutEdgeInset - iconFrame.height)
        
        favoriteIconButton.frame = iconFrame
        
        var size = durationLabel.sizeThatFits(CGSize(width: CGFloat.infinity, height: Self.selectIconWH))
        size.width += 2.0
        durationLabel.frame = CGRect(x: (contentView.bounds.width - Self.layoutEdgeInset - size.width), y: (favoriteIconButton.center.y - size.height * 0.5), width: size.width, height: size.height)
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
        contentView.addSubview(mediaTypeLabel)
        contentView.addSubview(favoriteIconButton)
        contentView.addSubview(durationLabel)
        contentView.addSubview(selectButton)
        contentView.addSubview(selectIconLabel)
        contentView.addSubview(nonselectableCoverView)
        
        imageView.layer.addSublayer(topShadowLayer)
        imageView.layer.addSublayer(bottomShadowLayer)
    }
    
    /// 布局UI 交给子类重写 super自动调用该方法
    open override func layoutUI() {
        super.layoutUI()
        
    }
    
    /// 初始化UI数据 交给子类重写 super自动调用该方法
    open override func initializeUIData() {
        super.initializeUIData()
        
    }
    
    // MARK:
    // MARK: - Private Property
    
    open private(set) lazy var topShadowLayer = self.createShadowLayer(isTop: true)
    open private(set) lazy var bottomShadowLayer = self.createShadowLayer(isTop: false)
    
    // MARK:
    // MARK: - Creator
    
    open func createShadowLayer(isTop: Bool) -> CAGradientLayer {
        
        let gradientLayer = CAGradientLayer()
        
        gradientLayer.isHidden = true
        
        let cgColors = [
            UIColor.black.withAlphaComponent(0.15).cgColor,
            UIColor.black.withAlphaComponent(0.0).cgColor
        ]
        
        let locationNumbers = [
            NSNumber(0.0),
            NSNumber(1.0)
        ]
        
        gradientLayer.colors = cgColors
        gradientLayer.locations = locationNumbers
        
        if isTop {
            
            gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
            gradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
            
        } else {
            
            gradientLayer.startPoint = CGPoint(x: 0.5, y: 1.0)
            gradientLayer.endPoint = CGPoint(x: 0.5, y: 0.0)
        }
        
        return gradientLayer
    }
}
