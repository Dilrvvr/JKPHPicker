//
//  JKPHPickerBarView.swift
//  JKSwiftPhotoPicker
//
//  Created by albert on 2022/3/11.
//

import UIKit
import JKSwiftLibrary

open class JKPHPickerBarView: JKPHPickerBaseBarView {
    
    // MARK:
    // MARK: - Public Property
    
    /// 是否位于屏幕底部 默认false 为true时自动适配底部安全区域
    open var isAtScreenBottom = false
    
    /// layoutSubviews完成后的回调
    open var didLayoutSubviewsHandler: ((_ barView: JKPHPickerBarView) -> Void)?
    
    /// topLineView
    open private(set) lazy var topLineView: UIView = {
        
        let topLineView = UIView()
        
        topLineView.isHidden = true
        topLineView.isUserInteractionEnabled = false
        topLineView.backgroundColor = JKLineLightColor
        
        return topLineView
    }()
    
    /// bottomLineView
    open private(set) lazy var bottomLineView: UIView = {
        
        let bottomLineView = UIView()
        
        bottomLineView.isHidden = true
        bottomLineView.isUserInteractionEnabled = false
        bottomLineView.backgroundColor = JKLineLightColor
        
        return bottomLineView
    }()
    
    // MARK:
    // MARK: - Public Methods
    
    open func updateContentViewLayout() {
        
        guard isAtScreenBottom else {
            
            contentView.frame = bounds
            
            return
        }
        
        let windowSafeAreaInsets = JKSafeAreaInsets
        
        contentView.frame = CGRect(x: windowSafeAreaInsets.left, y: 0.0, width: bounds.width - (windowSafeAreaInsets.left + windowSafeAreaInsets.right), height: bounds.height - windowSafeAreaInsets.bottom)
    }
    
    // MARK:
    // MARK: - Override
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        
        updateContentViewLayout()
        
        topLineView.frame = CGRect(x: 0.0, y: 0.0, width: bounds.width, height: JKLineThickness)
        bottomLineView.frame = CGRect(x: 0.0, y: bounds.height - JKLineThickness, width: bounds.width, height: JKLineThickness)
        
        if let handler = didLayoutSubviewsHandler {
            
            handler(self)
        }
    }
    
    // MARK:
    // MARK: - Private Methods
    
    
    
    // MARK:
    // MARK: - Private Selector
    
    
    
    // MARK:
    // MARK: - Initialization & Build UI
    
    /// 初始化自身属性 交给子类重写 super自动调用该方法 注意调用super
    open override func initializeProperty() {
        super.initializeProperty()
        
    }
    
    /// 构造函数初始化时调用 注意调用super
    open override func initialization() {
        super.initialization()
        
    }
    
    /// 创建UI 交给子类重写 super自动调用该方法 注意调用super
    open override func createUI() {
        super.createUI()
        
        addSubview(topLineView)
        addSubview(bottomLineView)
    }
    
    /// 布局UI 交给子类重写 super自动调用该方法 注意调用super
    open override func layoutUI() {
        super.layoutUI()
        
    }
    
    /// 初始化UI数据 交给子类重写 super自动调用该方法 注意调用super
    open override func initializeUIData() {
        super.initializeUIData()
        
    }
    
    // MARK:
    // MARK: - Private Property
    
    
}
