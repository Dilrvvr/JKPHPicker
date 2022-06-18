//
//  JKPHPickerNavigationBarView.swift
//  JKSwiftPhotoPicker
//
//  Created by AlbertCC on 2021/5/4.
//

import UIKit
import JKSwiftLibrary

@objc public protocol JKPHPickerNavigationBarViewDelegate: NSObjectProtocol {
    
    /// 点击返回按钮
    func navigationBarView(_ navigationBarView: JKPHPickerNavigationBarView, didTapBack button: UIButton)
    
    /// 点击关闭按钮
    func navigationBarView(_ navigationBarView: JKPHPickerNavigationBarView, didTapClose button: UIButton)
    
    /// 点击第二个左侧按钮
    func navigationBarView(_ navigationBarView: JKPHPickerNavigationBarView, didTapLeft2 button: UIButton)
    
    /// 点击最右侧按钮
    func navigationBarView(_ navigationBarView: JKPHPickerNavigationBarView, didTapRight button: UIButton)
    
    /// 点击第二个右侧按钮
    func navigationBarView(_ navigationBarView: JKPHPickerNavigationBarView, didTapRight2 button: UIButton)
}

public extension JKPHPickerNavigationBarViewDelegate where Self: UIViewController {
    
    /// 点击返回按钮
    func navigationBarView(_ navigationBarView: JKPHPickerNavigationBarView, didTapBack didTapBackButton: UIButton) {
        
        navigationController?.popViewController(animated: true)
    }
    
    /// 点击关闭按钮
    func navigationBarView(_ navigationBarView: JKPHPickerNavigationBarView, didTapCloseButton: UIButton) {
        
        dismiss(animated: true, completion: nil)
    }
}

@objc open class JKPHPickerNavigationBarView: JKPHPickerBaseBarView {
    
    // MARK:
    // MARK: - Public Property
    
    /// 导航条 标题
    open var title: String? {
        didSet { titleLabel.text = title }
    }
    
    /// 导航条 富文本标题
    open var attributedTitle: NSAttributedString? {
        didSet { titleLabel.attributedText = attributedTitle }
    }
    
    /// 代理
    open weak var delegate: JKPHPickerNavigationBarViewDelegate?
    
    /// 左右按钮 边距
    open var leftRightInset: UIEdgeInsets = UIEdgeInsets(top: 0.0, left: 15.0, bottom: 0.0, right: 15.0)
    
    /// 按钮间距
    open var itemMargin: CGFloat = 7.5
    
    /// 默认的左右按钮的宽度 默认为zero 自适应
    open var defaultButtonWidth: CGFloat = .zero
    
    /// 默认的左右按钮的宽度 默认为zero 自适应
    open var defaultButtonHeight: CGFloat = .zero
    
    /// 自定义布局contentView 在layoutSubviews()调用
    open var customLayoutContentViewHandler: ((_ barView: JKPHPickerNavigationBarView) -> Void)?
    
    /// 自定义布局子控件(autoLayout) 布局左侧按钮、titleView、右侧按钮
    open var customAutoLayoutHandler: ((_ barView: JKPHPickerNavigationBarView) -> Void)? {
        didSet {
            if let handler = customAutoLayoutHandler {
                handler(self)
            }
        }
    }
    
    /// 自定义布局subviews 在layoutSubviews()调用
    open var customLayoutSubviewsHandler: ((_ barView: JKPHPickerNavigationBarView) -> Void)?
    
    /// 在layoutSubviews()最后调用
    open var didLayoutSubviewsHandler: ((_ barView: JKPHPickerNavigationBarView) -> Void)?
    
    /// 自定义titleView
    open var customTitleView: UIView? {
        
        get { _customTitleView }
        
        set { _customTitleView = newValue }
    }
    
    /// titleLabel
    open private(set) lazy var titleLabel: UILabel = {
        
        let label = UILabel()
        
        label.font = UIFont.systemFont(ofSize: 17.0, weight: .medium)
        label.textColor = .black
        label.textAlignment = .center
        label.lineBreakMode = .byTruncatingMiddle
        
        return label
    }()
    
    /// titleView
    open private(set) lazy var titleView: UIView = {
        
        let titleView = UIView()
        
        return titleView
    }()
    
    /// backButton default isHidden false
    open private(set) lazy var backButton: UIButton = {
        
        let button = UIButton(type: .custom)
        
        button.frame = CGRect(x: 0.0, y: 0.0, width: 44.0, height: 44.0)
        button.setImage(JKPHPickerResourceManager.image(named: "nav_back"), for: .normal)
        
        button.addTarget(self, action: #selector(backButtonClick(button:)), for: .touchUpInside)
        
        return button
    }()
    
    /// closeButton default isHidden true
    open private(set) lazy var closeButton: UIButton = {
        
        let button = UIButton(type: .custom)
        
        button.isHidden = true
        button.frame = CGRect(x: 0.0, y: 0.0, width: 44.0, height: 44.0)
        button.setImage(JKPHPickerResourceManager.image(named: "nav_close"), for: .normal)
        
        button.addTarget(self, action: #selector(closeButtonClick(button:)), for: .touchUpInside)
        
        return button
    }()
    
    /// 第二个左侧按钮 default isHidden true
    open private(set) lazy var leftButton2: UIButton = {
        
        let button = UIButton(type: .custom)
        
        button.isHidden = true
        button.frame = CGRect(x: 0.0, y: 0.0, width: 44.0, height: 44.0)
        
        button.addTarget(self, action: #selector(leftButton2Click(button:)), for: .touchUpInside)
        
        return button
    }()
    
    /// 最右侧按钮size 某一值小于等于0则自动适配
    open var rightButtonSize: CGSize = .zero
    
    /// 最右侧按钮 default isHidden true
    open private(set) lazy var rightButton: UIButton = {
        
        let button = UIButton(type: .custom)
        
        button.isHidden = true
        button.frame = CGRect(x: 0.0, y: 0.0, width: 44.0, height: 44.0)
        
        button.addTarget(self, action: #selector(rightButtonClick(button:)), for: .touchUpInside)
        
        return button
    }()
    
    /// 第二个右侧按钮 default isHidden true
    open private(set) lazy var rightButton2: UIButton = {
        
        let button = UIButton(type: .custom)
        
        button.isHidden = true
        button.frame = CGRect(x: 0.0, y: 0.0, width: 44.0, height: 44.0)
        
        button.addTarget(self, action: #selector(rightButton2Click(button:)), for: .touchUpInside)
        
        return button
    }()
    
    /// bottomLineView
    open private(set) lazy var bottomLineView: UIView = {
        
        let bottomLineView = UIView()
        
        bottomLineView.isUserInteractionEnabled = false
        
        bottomLineView.backgroundColor = JKLineLightColor
        
        return bottomLineView
    }()
    
    // MARK:
    // MARK: - open Methods
    
    
    
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
        
        updateLayout()
    }
    
    // MARK:
    // MARK: - Private Methods
    
    private func updateLayout() {
        
        layoutContentView()
        
        bottomLineView.frame = CGRect(x: 0.0, y: bounds.height - JKLineThickness, width: bounds.width, height: JKLineThickness)
        
        if let _ = customAutoLayoutHandler { // 使用了自动约束布局
            
            if let closure = didLayoutSubviewsHandler { // 布局完成回调
                
                closure(self)
            }
            
            return
        }
        
        if let handler = customLayoutSubviewsHandler { // 自定义布局contentView上的子控件
            
            handler(self)
            
            if let closure = didLayoutSubviewsHandler { // 布局完成回调
                
                closure(self)
            }
            
            return
        }
        
        layoutContentSubviews()
        
        if let closure = didLayoutSubviewsHandler { // 布局完成回调
            
            closure(self)
        }
    }
    
    private func layoutContentView() {
        
        if let handler = customLayoutContentViewHandler { // 自定义布局contentView
            
            handler(self)
            
            return
        }
        
        // contentView 顶部Y为状态栏高度 （iPhone横屏时为0）
        var contentViewY: CGFloat = JKStatusBarHeight
        
        if JKisLandscape && JKisDeviceiPhone { contentViewY = 0.0 }
        
        let windowSafeAreaInsets = JKSafeAreaInsets
        
        contentView.frame = CGRect(x: windowSafeAreaInsets.left, y: contentViewY, width: bounds.width - (windowSafeAreaInsets.left + windowSafeAreaInsets.right), height: bounds.height - contentViewY)
    }
    
    private func layoutContentSubviews() {
        
        let buttonWH: CGFloat = contentView.bounds.height
        
        var buttonSize = CGSize(width: defaultButtonWidth, height: defaultButtonHeight)
        
        if buttonSize.width == .zero {
            
            buttonSize.width = buttonWH
        }
        
        if buttonSize.height == .zero {
            
            buttonSize.height = buttonWH
        }
        
        backButton.frame = CGRect(x: leftRightInset.left, y: 0.0, width: buttonSize.width, height: buttonSize.height)
        
        closeButton.frame = backButton.frame
        
        let leftButton2X: CGFloat = (backButton.isHidden && closeButton.isHidden) ? backButton.frame.minX : backButton.frame.maxX + itemMargin
        leftButton2.frame = CGRect(x: leftButton2X, y: backButton.frame.minY, width: buttonSize.width, height: buttonSize.height)
        
        var rightSize = CGSize(width: buttonWH, height: buttonWH)
        
        if rightButtonSize.width > 0.0 {
            
            rightSize.width = rightButtonSize.width
        }
        
        if rightButtonSize.height > 0.0 {
            
            rightSize.height = rightButtonSize.height
        }
        
        rightButton.frame = CGRect(x: contentView.bounds.width - leftRightInset.right - rightSize.width, y: (contentView.bounds.height - rightSize.height), width: rightSize.width, height: rightSize.height)
        
        let rightButton2X: CGFloat = rightButton.isHidden ? rightButton.frame.minX : (rightButton.frame.minX - itemMargin - buttonSize.width)
        rightButton2.frame = CGRect(x: rightButton2X, y: rightButton.frame.minY, width: buttonSize.width, height: buttonSize.height)
        
        var titleViewLeft: CGFloat = backButton.frame.maxX + itemMargin
        
        if (!leftButton2.isHidden || (backButton.isHidden && closeButton.isHidden)) {
            titleViewLeft = leftButton2.frame.maxX + itemMargin
            if leftButton2.isHidden {
                titleViewLeft = 0.0
            }
        }
        
        var titleViewRight: CGFloat = contentView.bounds.width - (rightButton.frame.minX - itemMargin)
        
        if !rightButton2.isHidden || rightButton.isHidden {
            titleViewRight = contentView.bounds.width - (rightButton2.frame.minX - itemMargin)
            if rightButton2.isHidden {
                titleViewRight = 0.0
            }
        }
        
        let titleViewX: CGFloat = max(titleViewLeft, titleViewRight)
        
        titleView.frame = CGRect(x: titleViewX, y: 0.0, width: contentView.bounds.width - titleViewX * 2.0, height: contentView.bounds.height)
        
        titleLabel.frame = titleView.bounds
        
        if let _ = _customTitleView {
            
            var frame = _customTitleView!.frame
            
            if frame.width > titleView.bounds.width {
                frame.size.width = titleView.bounds.width
            }
            
            if frame.size.height > titleView.bounds.height {
                frame.size.height = titleView.bounds.height
            }
            
            frame.origin.x = (titleView.bounds.width - frame.width) * 0.5
            frame.origin.y = (titleView.bounds.height - frame.height) * 0.5
            
            _customTitleView!.frame = frame
        }
    }
    
    // MARK:
    // MARK: - Private Selector
    
    /// 返回
    @objc private func backButtonClick(button: UIButton) {
        
        guard let _ = delegate else { return }
        
        delegate?.navigationBarView(self, didTapBack: button)
    }
    
    /// 关闭
    @objc private func closeButtonClick(button: UIButton) {
        
        guard let _ = delegate else { return }
        
        delegate?.navigationBarView(self, didTapClose: button)
    }
    
    /// 第二个左侧按钮
    @objc private func leftButton2Click(button: UIButton) {
        
        guard let _ = delegate else { return }
        
        delegate?.navigationBarView(self, didTapLeft2: button)
    }
    
    /// 点击最右侧按钮
    @objc private func rightButtonClick(button: UIButton) {
        
        guard let _ = delegate else { return }
        
        delegate?.navigationBarView(self, didTapRight: button)
    }
    
    /// 第二个右侧按钮
    @objc private func rightButton2Click(button: UIButton) {
        
        guard let _ = delegate else { return }
        
        delegate?.navigationBarView(self, didTapRight2: button)
    }
    
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
        
        addSubview(bottomLineView)
        
        contentView.addSubview(titleView)
        contentView.addSubview(backButton)
        contentView.addSubview(closeButton)
        contentView.addSubview(leftButton2)
        contentView.addSubview(rightButton)
        contentView.addSubview(rightButton2)
        
        titleView.addSubview(titleLabel)
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
    
    /// _customTitleView
    private var _customTitleView: UIView? {
        
        willSet {
            
            _customTitleView?.removeFromSuperview()
        }
        
        didSet {
            
            guard let _ = _customTitleView else {
                
                titleLabel.isHidden = false
                
                return
            }
            
            titleLabel.isHidden = true
            
            titleView.addSubview(_customTitleView!)
        }
    }
}
