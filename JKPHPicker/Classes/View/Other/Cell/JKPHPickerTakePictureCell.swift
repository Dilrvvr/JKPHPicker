//
//  JKPHPickerTakePictureCell.swift
//  JKSwiftPhotoPicker
//
//  Created by AlbertCC on 2022/1/20.
//

import UIKit
import JKSwiftLibrary

open class JKPHPickerTakePictureCell: UICollectionViewCell {
    
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
    
    open override var isHighlighted: Bool {
        
        didSet {
            
            contentView.alpha = isHighlighted ? 0.5 : 1.0
        }
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        let imageWH: CGFloat = min(contentView.bounds.width, contentView.bounds.height) * 0.5
        
        imageView.frame = CGRect(x: (contentView.bounds.width - imageWH) * 0.5, y: (contentView.bounds.height - imageWH) * 0.5, width: imageWH, height: imageWH)
    }
    
    // MARK:
    // MARK: - Private Methods
    
    
    
    // MARK:
    // MARK: - Private Selector
    
    
    
    // MARK:
    // MARK: - Initialization & Build UI
    
    /// 初始化自身属性 交给子类重写 super自动调用该方法 注意调用super
    public func initializeProperty() {
        
    }
    
    /// 构造函数初始化时调用 注意调用super
    public func initialization() {
        
        initializeProperty()
        createUI()
        layoutUI()
        initializeUIData()
    }
    
    /// 创建UI 交给子类重写 super自动调用该方法 注意调用super
    public func createUI() {
        
        contentView.addSubview(imageView)
    }
    
    /// 布局UI 交给子类重写 super自动调用该方法 注意调用super
    public func layoutUI() {
        
    }
    
    /// 初始化UI数据 交给子类重写 super自动调用该方法 注意调用super
    public func initializeUIData() {
        
        backgroundColor = JKSameRGBColor(63.0)
    }
    
    // MARK:
    // MARK: - Private Property
    
    private lazy var imageView: UIImageView = {
        
        let imageView = UIImageView()
        
        imageView.image = JKPHPickerResourceManager.image(named: "take_picture")
        
        return imageView
    }()
}
