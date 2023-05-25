//
//  JKPHPickerBaseView.swift
//  JKSwiftPhotoPicker
//
//  Created by albert on 2021/5/24.
//

import UIKit
import JKSwiftLibrary

public protocol JKPHPickerNavigationBarDelegate: JKPHPickerNavigationBarViewDelegate {
    
}

open class JKPHPickerBaseView: JKPHPickerUIView {
    
    public static var bottomControlHeight: CGFloat {
        
        if JKisDeviceiPad {
            
            return 44.0 + JKBottomSafeAreaInset
        }
        
        if JKisLandscape {
            
            return (JKScreenHeight > 400.0 ? 44.0 : 32.0) + JKBottomSafeAreaInset
        }
        
        return 44.0 + JKBottomSafeAreaInset
    }
    
    // MARK:
    // MARK: - Public Property
    
    open private(set) var configuration: JKPHPickerConfiguration
    
    open weak var navigationBarDelegate: JKPHPickerNavigationBarDelegate?
    
    open private(set) lazy var originalImageButton: UIButton = {
        
        let button = JKPHPickerButton(type: .custom)
        
        button.setImage(JKPHPickerResourceManager.image(named: "select_off"), for: .normal)
        button.setImage(JKPHPickerResourceManager.image(named: "select_on"), for: .selected)
        button.setImage(JKPHPickerResourceManager.image(named: "select_on"), for: [.selected, .highlighted])
        
        button.adjustsImageWhenHighlighted = false
        
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17.0)
        button.setTitleColor(.white, for: .normal)
        button.setTitle("原图", for: .normal)
        
        button.customLayoutHandler = { button in
            
            var labelFrame = button.titleLabel?.frame ?? .zero
            var imageFrame = button.imageView?.frame ?? .zero
            imageFrame.size = CGSize(width: 20.0, height: 20.0)
            
            imageFrame.origin.x = (button.bounds.width - imageFrame.width - labelFrame.width - 5.0) * 0.5
            imageFrame.origin.y = (button.bounds.height - imageFrame.height) * 0.5
            labelFrame.origin.x = imageFrame.maxX + 5.0
            
            button.titleLabel?.frame = labelFrame
            button.imageView?.frame = imageFrame
        }
        
        button.imageView?.contentMode = .scaleAspectFit
        button.imageView?.layer.cornerRadius = 10.0
        //button.imageView?.backgroundColor = UIColor.black.withAlphaComponent(0.2)
        
        button.imageEdgeInsets = UIEdgeInsets(top: 0.0, left: 0.0, bottom: 0.0, right: 2.5)
        button.titleEdgeInsets = UIEdgeInsets(top: 0.0, left: 2.5, bottom: 0.0, right: 0.0)
        
        button.addTarget(self, action: #selector(originalImageButtonClick(button:)), for: .touchUpInside)
        
        return button
    }()
    
    /// navigationBarView
    open private(set) lazy var navigationBarView: JKPHPickerNavigationBarView = {
        
        let navigationBarView = JKPHPickerNavigationBarView()
        
        navigationBarView.backgroundEffectView.effect = UIBlurEffect(style: .dark)
        navigationBarView.bottomLineView.backgroundColor = JKLineDarkColor
        navigationBarView.backButton.isHidden = true
        navigationBarView.closeButton.isHidden = false
        
        navigationBarView.closeButton.contentHorizontalAlignment = .left
        
        navigationBarView.closeButton.setImage(JKPHPickerResourceManager.image(named: "nav_close_white"), for: .normal)
        
        navigationBarView.delegate = self
        
        return navigationBarView
    }()
    
    /// bottomControlView
    open private(set) lazy var bottomControlView: JKPHPickerBarView = {
        
        let bottomControlView = JKPHPickerBarView()
        
        bottomControlView.isAtScreenBottom = true
        bottomControlView.backgroundEffectView.effect = UIBlurEffect(style: .dark)
        bottomControlView.topLineView.isHidden = false
        bottomControlView.topLineView.backgroundColor = JKLineDarkColor
        
        return bottomControlView
    }()
    
    /// flowLayout
    open private(set) lazy var flowLayout: UICollectionViewFlowLayout = {
        
        let flowLayout = UICollectionViewFlowLayout()
        
        return flowLayout
    }()
    
    /// collectionView
    open private(set) lazy var collectionView: UICollectionView = {
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: self.flowLayout)
        
        collectionView.backgroundView = nil
        collectionView.backgroundColor = .clear
        
        if #available(iOS 11.0, *) {
            collectionView.contentInsetAdjustmentBehavior = .never
        }
        
        if #available(iOS 13.0, *) {
            collectionView.automaticallyAdjustsScrollIndicatorInsets = false
        }
        
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: String(describing: UICollectionViewCell.self))
        
        collectionView.dataSource = self
        collectionView.delegate = self
        
        return collectionView
    }()
    
    // MARK:
    // MARK: - Public Methods
    
    /// originalImageButtonClick
    @objc open func originalImageButtonClick(button: UIButton) {
        
    }
    
    /// showNavigationBarView
    open func showNavigationBarView(_ animated: Bool) {
        
        if !animated {
            
            navigationBarView.isHidden = false
            
            return
        }
        
        navigationBarView.alpha = 0.0
        navigationBarView.isHidden = false
        
        UIView.transition(with: navigationBarView, duration: 0.25, options: .transitionCrossDissolve) {
            
            self.navigationBarView.alpha = 1.0
            
        } completion: { _ in
            
        }
    }
    
    /// hideNavigationBarVier
    open func hideNavigationBarVier(_ animated: Bool) {
        
        if !animated {
            
            navigationBarView.isHidden = true
            
            return
        }
        
        UIView.transition(with: navigationBarView, duration: 0.25, options: .transitionCrossDissolve) {
            
            self.navigationBarView.alpha = 0.0
            
        } completion: { _ in
            
            self.navigationBarView.isHidden = true
            self.navigationBarView.alpha = 1.0
        }
    }
    
    open func showBottomControl(_ animated: Bool) {
        
        if !animated {
            
            bottomControlView.isHidden = false
            
            return
        }
        
        bottomControlView.alpha = 0.0
        bottomControlView.isHidden = false
        
        UIView.transition(with: bottomControlView, duration: 0.25, options: .transitionCrossDissolve) {
            
            self.bottomControlView.alpha = 1.0
            
        } completion: { _ in
            
        }
    }
    
    open func hideBottomControl(_ animated: Bool) {
        
        if !animated {
            
            bottomControlView.isHidden = true
            
            return
        }
        
        UIView.transition(with: bottomControlView, duration: 0.25, options: .transitionCrossDissolve) {
            
            self.bottomControlView.alpha = 0.0
            
        } completion: { _ in
            
            self.bottomControlView.isHidden = true
            self.bottomControlView.alpha = 1.0
        }
    }
    
    // MARK:
    // MARK: - Override
    
    public init(frame: CGRect, configuration: JKPHPickerConfiguration) {
        
        self.configuration = configuration
        
        super.init(frame: frame)
    }
    
    public required init?(coder: NSCoder) {
        
        self.configuration = JKPHPickerConfiguration()
        
        super.init(coder: coder)
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        
        navigationBarView.frame = CGRect(x: 0.0, y: 0.0, width: bounds.width, height: JKNavigationBarHeight)
        
        let bottomHeight = Self.bottomControlHeight
        
        bottomControlView.frame = CGRect(x: 0.0, y: bounds.height - bottomHeight, width: bounds.width, height: bottomHeight)
        
        bottomControlView.setNeedsLayout()
        bottomControlView.layoutIfNeeded()
        
        originalImageButton.sizeToFit()
        
        let originalImageButtonWidth: CGFloat = originalImageButton.bounds.width + 10.0
        
        originalImageButton.frame = CGRect(x: (bottomControlView.contentView.bounds.width - originalImageButtonWidth) * 0.5, y: 0.0, width: originalImageButtonWidth, height: bottomControlView.contentView.bounds.height)
    }
    
    // MARK:
    // MARK: - Private Methods
    
    func layoutBottomControlViewUI() {
        
        let barContentView = bottomControlView.contentView
        
        let buttonSize = completeButtonSize
        
        completeButton.frame = CGRect(x: barContentView.bounds.width - 15.0 - buttonSize.width, y: (barContentView.bounds.height - buttonSize.height) * 0.5, width: buttonSize.width, height: buttonSize.height)
    }
    
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
        
        addSubview(bottomControlView)
        addSubview(navigationBarView)
        
        bottomControlView.contentView.addSubview(completeButton)
        bottomControlView.contentView.addSubview(originalImageButton)
    }
    
    /// 布局UI 交给子类重写 super自动调用该方法
    open override func layoutUI() {
        super.layoutUI()
        
        bottomControlView.didLayoutSubviewsHandler = { [weak self] barView in
            
            guard let _ = self else { return }
            
            self?.layoutBottomControlViewUI()
        }
    }
    
    /// 初始化UI数据 交给子类重写 super自动调用该方法
    open override func initializeUIData() {
        super.initializeUIData()
        
        originalImageButton.isHidden = !configuration.isShowsOriginalButton
        
        completeButton.setTitle(configuration.completeButtonTitle, for: .normal)
    }
    
    // MARK:
    // MARK: - Private Property
    
    var completeButtonSize: CGSize {
        
        var buttonSize = self.completeButton.sizeThatFits(CGSize(width: CGFloat.infinity, height: 44.0))
        
        buttonSize.width += 16.0
        buttonSize.width = max(56.0, buttonSize.width)
        buttonSize.height = min(self.bottomControlView.contentView.bounds.height - 6.0, 32.0)
        
        return buttonSize
    }
    
    /// completeButton
    private(set) lazy var completeButton: UIButton = {
        
        let completeButton = UIButton(type: .custom)
        
        completeButton.backgroundColor = configuration.mainColor
        completeButton.isEnabled = false
        completeButton.layer.cornerRadius = 3.0
        completeButton.titleLabel?.font = UIFont.systemFont(ofSize: 15.0)
        completeButton.setTitleColor(.white, for: .normal)
        completeButton.setTitleColor(UIColor.white.withAlphaComponent(0.5), for: .highlighted)
        completeButton.setTitleColor(UIColor.white.withAlphaComponent(0.4), for: .disabled)
        
        return completeButton
    }()
}

// MARK:
// MARK: - JKPHPickerNavigationBarViewDelegate

extension JKPHPickerBaseView: JKPHPickerNavigationBarViewDelegate {
    
    open func navigationBarView(_ navigationBarView: JKPHPickerNavigationBarView, didTapBack button: UIButton) {
        
    }

    open func navigationBarView(_ navigationBarView: JKPHPickerNavigationBarView, didTapClose button: UIButton) {
        
        if let _ = navigationBarDelegate {
            
            navigationBarDelegate!.navigationBarView(navigationBarView, didTapClose: button)
        }
    }
    
    open func navigationBarView(_ navigationBarView: JKPHPickerNavigationBarView, didTapLeft2 button: UIButton) {
        
    }
    
    open func navigationBarView(_ navigationBarView: JKPHPickerNavigationBarView, didTapRight button: UIButton) {
        
    }
    
    open func navigationBarView(_ navigationBarView: JKPHPickerNavigationBarView, didTapRight2 button: UIButton) {
        
    }
}

// MARK:
// MARK: - UICollectionViewDataSource & UICollectionViewDelegate

extension JKPHPickerBaseView: UICollectionViewDataSource, UICollectionViewDelegate {
    
    open func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return 0
    }
    
    open func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: UICollectionViewCell.self), for: indexPath)
        
        return cell
    }
}
