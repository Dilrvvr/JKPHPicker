//
//  JKPHPickerBaseCollectionViewCell.swift
//  JKSwiftPhotoPicker
//
//  Created by albert on 2021/5/24.
//

import UIKit
import Photos
import JKSwiftLibrary

open class JKPHPickerBaseCollectionViewCell: UICollectionViewCell {
    
    /// 选中图标的宽高
    open class var selectIconWH: CGFloat { 22.0 }
    
    /// 选中按钮的宽高
    open class var selectButtonSize: CGSize { CGSize(width: 44.0, height: 44.0) }
    
    // MARK:
    // MARK: - Public Property
    
    open var thumbnailImageCache: NSCache<NSString, UIImage>?
    
    open var previewImageCache: NSCache<NSString, UIImage>?
    
    open var configuration: JKPHPickerConfiguration?
    
    open var model: JKPHPickerPhotoItem?
    
    open var photoIdentifier = ""
    
    open var hasSelectedCover: Bool { false }
    
    open var selectActionHandler: ((_ model: JKPHPickerPhotoItem?, _ button: UIButton) -> Void)?
    
    open var selectIconNormalBackgroundColor: UIColor {
        
        UIColor.black.withAlphaComponent(0.1)
    }
    
    /// selectIconLabel
    open private(set) lazy var selectIconLabel: UILabel = {
        
        let label = UILabel()
        
        label.font = UIFont.systemFont(ofSize: 11.0)
        label.textColor = .white
        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = true
        
        label.layer.backgroundColor = self.selectIconNormalBackgroundColor.cgColor
        label.layer.cornerRadius = Self.selectIconWH * 0.5
        label.layer.borderWidth = 1.0
        label.layer.borderColor = UIColor.white.cgColor
        
        return label
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
        selectCoverView.backgroundColor = JKSameRGBColor(23.0, 0.55)
        
        return selectCoverView
    }()
    
    /// 不可选中的遮盖view
    open private(set) lazy var nonselectableCoverView: UIView = {
        
        let nonselectableCoverView = UIView()
        
        nonselectableCoverView.isHidden = true
        nonselectableCoverView.isUserInteractionEnabled = false
        nonselectableCoverView.backgroundColor = JKSameRGBColor(49.0, 0.9)
        
        return nonselectableCoverView
    }()
    
    // MARK:
    // MARK: - Public Function
    
    open func updateSelectIcon(isSelected: Bool) {
        
        var selectedColor = UIColor.systemBlue
        
        if let configuration = configuration {
            
            selectedColor = configuration.mainColor
        }
        
        selectIconLabel.layer.backgroundColor = isSelected ? selectedColor.cgColor : self.selectIconNormalBackgroundColor.cgColor
        selectIconLabel.layer.borderColor = isSelected ? UIColor.clear.cgColor : UIColor.white.cgColor
        
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
    
    
    // MARK:
    // MARK: - Public Property
    
    
    
    // MARK:
    // MARK: - Public Methods
    
    
    
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
    
    // MARK:
    // MARK: - Private Methods
    
    
    
    // MARK:
    // MARK: - Private Selector
    
    
    
    // MARK:
    // MARK: - Initialization & Build UI
    
    /// 初始化自身属性 交给子类重写 super自动调用该方法 注意调用super
    open func initializeProperty() {
        
    }
    
    /// 构造函数初始化时调用 注意调用super
    open func initialization() {
        
        initializeProperty()
        createUI()
        layoutUI()
        initializeUIData()
    }
    
    /// 创建UI 交给子类重写 super自动调用该方法 注意调用super
    open func createUI() {
        
    }
    
    /// 布局UI 交给子类重写 super自动调用该方法 注意调用super
    open func layoutUI() {
        
    }
    
    /// 初始化UI数据 交给子类重写 super自动调用该方法 注意调用super
    open func initializeUIData() {
        
    }
    
    // MARK:
    // MARK: - Private Property
    
    
}
