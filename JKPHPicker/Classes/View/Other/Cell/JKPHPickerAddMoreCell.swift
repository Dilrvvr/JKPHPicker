//
//  JKPHPickerAddMoreCell.swift
//  JKSwiftPhotoPicker
//
//  Created by AlbertCC on 2022/1/20.
//

import UIKit
import JKSwiftLibrary

open class JKPHPickerAddMoreCell: UICollectionViewCell {
    
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
        
        var desLabelSize = desLabel.sizeThatFits(CGSize(width: CGFloat.infinity, height: CGFloat.infinity))
        desLabelSize.height += 2.0
        desLabelSize.width = contentView.bounds.width
        
        let imageWH: CGFloat = 24.0
        
        let imageLabelMargin: CGFloat = 5.0
        
        let totalHeight = imageWH + imageLabelMargin + desLabelSize.height
        
        imageView.frame = CGRect(x: (contentView.bounds.width - imageWH) * 0.5, y: (contentView.bounds.height - totalHeight) * 0.5, width: imageWH, height: imageWH)
        
        desLabel.frame = CGRect(x: 0.0, y: imageView.frame.maxY + imageLabelMargin, width: desLabelSize.width, height: desLabelSize.height)
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
        contentView.addSubview(desLabel)
    }
    
    /// 布局UI 交给子类重写 super自动调用该方法 注意调用super
    public func layoutUI() {
        
    }
    
    /// 初始化UI数据 交给子类重写 super自动调用该方法 注意调用super
    public func initializeUIData() {
        
        backgroundColor = JKSameRGBColor(63.0)
        
        desLabel.text = "添加更多\n可访问照片"
    }
    
    // MARK:
    // MARK: - Private Property
    
    private lazy var imageView: UIImageView = {
        
        let imageView = UIImageView()
        
        imageView.image = JKPHPickerResourceManager.image(named: "add_icon_gray")
        
        return imageView
    }()
    
    private lazy var desLabel: UILabel = {
        
        let label = UILabel()
        
        label.font = UIFont.systemFont(ofSize: 13.0)
        label.textColor = JKSameRGBColor(158.0)
        label.textAlignment = .center
        label.numberOfLines = 0
        
        return label
    }()
}
