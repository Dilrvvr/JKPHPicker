//
//  JKPHPickerBaseBarView.swift
//  JKSwiftPhotoPicker
//
//  Created by albert on 2022/3/11.
//

import UIKit

open class JKPHPickerBaseBarView: UIView {
    
    // MARK:
    // MARK: - Public Property
    
    /// backgroundView 默认是 backgroundEffectView
    open var backgroundView: UIView? {
        
        get { _backgroundView }
        
        set { _backgroundView = newValue }
    }
    
    /// contentView
    open private(set) lazy var contentView: UIView = {
        
        let contentView = UIView()
        
        return contentView
    }()
    
    /// 一个UIVisualEffectView，默认作为背景
    open private(set) lazy var backgroundEffectView: UIVisualEffectView = {
        
        let backgroundEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .light))
        
        backgroundEffectView.isUserInteractionEnabled = false
        
        return backgroundEffectView
    }()
    
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
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        
        if let _ = _backgroundView {
            
            _backgroundView?.frame = bounds
        }
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
        
        backgroundView = backgroundEffectView
        
        addSubview(contentView)
    }
    
    /// 布局UI 交给子类重写 super自动调用该方法 注意调用super
    open func layoutUI() {
        
    }
    
    /// 初始化UI数据 交给子类重写 super自动调用该方法 注意调用super
    open func initializeUIData() {
        
    }
    
    // MARK:
    // MARK: - Private Property
    
    /// _backgroundView
    private var _backgroundView: UIView? {
        
        willSet {
            
            if let _ = _backgroundView {
                
                _backgroundView?.removeFromSuperview()
            }
        }
        
        didSet {
            
            guard let _ = _backgroundView else { return }
            
            insertSubview(_backgroundView!, at: 0)
        }
    }
}
