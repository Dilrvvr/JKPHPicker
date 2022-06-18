//
//  JKPHPickerErrorCell.swift
//  JKSwiftPhotoPicker
//
//  Created by albert on 2022/3/4.
//

import UIKit

open class JKPHPickerErrorCell: UICollectionViewCell {
    
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
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        errorLabel.frame = CGRect(x: 15.0, y: (bounds.height - 300.0) * 0.5, width: bounds.width - 30.0, height: 300.0)
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
        
        contentView.addSubview(errorLabel)
    }
    
    /// 布局UI 交给子类重写 super自动调用该方法 注意调用super
    public func layoutUI() {
        
    }
    
    /// 初始化UI数据 交给子类重写 super自动调用该方法 注意调用super
    public func initializeUIData() {
        
        errorLabel.text = "唉呀，出错了~"
    }
    
    // MARK:
    // MARK: - Private Property
    
    private lazy var errorLabel: UILabel = {
        
        let label = UILabel()
        
        label.font = UIFont.systemFont(ofSize: 13.0)
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 0
        
        return label
    }()
}
