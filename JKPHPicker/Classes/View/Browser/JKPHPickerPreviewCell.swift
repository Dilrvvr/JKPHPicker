//
//  JKPHPickerPreviewCell.swift
//  JKPHPicker
//
//  Created by albert on 8/22/22.
//

import UIKit

class JKPHPickerPreviewCell: JKPHPickerBaseCell {
    
    // MARK:
    // MARK: - Public Property
    
    override var model: JKPHPickerPhotoItem? {
        
        didSet {
            
            guard let item = model else { return }
            
            item.reloadPreviewHandler = { [weak self] (photoItem: JKPHPickerPhotoItem, isRequestImage: Bool) in
                
                guard let _ = self else { return }
                
                self?.reload(with: photoItem, isRequestImage: isRequestImage)
            }
            
            reload(with: item, isRequestImage: true)
        }
    }
    
    // MARK:
    // MARK: - Public Methods
    
    override func reload(with photoItem: JKPHPickerPhotoItem, isRequestImage: Bool) {
        super.reload(with: photoItem, isRequestImage: isRequestImage)
        
        guard let item = model, item == photoItem else { return }
        
        layer.borderWidth = photoItem.isCurrent ? 2.0 : 0.0
        
        nonselectableCoverView.isHidden = photoItem.isSelected
    }
    
    // MARK:
    // MARK: - Override
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        nonselectableCoverView.frame = contentView.bounds
    }
    
    // MARK:
    // MARK: - Private Methods
    
    
    
    // MARK:
    // MARK: - Private Selector
    
    
    
    // MARK:
    // MARK: - Initialization & Build UI
    
    /// 初始化自身属性 交给子类重写 super自动调用该方法 注意调用super
    override func initializeProperty() {
        super.initializeProperty()
        
    }
    
    /// 构造函数初始化时调用 注意调用super
    override func initialization() {
        super.initialization()
        
    }
    
    /// 创建UI 交给子类重写 super自动调用该方法 注意调用super
    override func createUI() {
        super.createUI()
        
        contentView.addSubview(nonselectableCoverView)
    }
    
    /// 布局UI 交给子类重写 super自动调用该方法 注意调用super
    override func layoutUI() {
        super.layoutUI()
        
    }
    
    /// 初始化UI数据 交给子类重写 super自动调用该方法 注意调用super
    override func initializeUIData() {
        super.initializeUIData()
        
        layer.borderColor = UIColor.systemBlue.cgColor
    }
    
    // MARK:
    // MARK: - Private Property
    
    
}
