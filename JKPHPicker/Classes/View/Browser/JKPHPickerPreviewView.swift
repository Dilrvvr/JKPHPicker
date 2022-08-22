//
//  JKPHPickerPreviewView.swift
//  JKPHPicker
//
//  Created by albert on 8/22/22.
//

import UIKit
import JKSwiftLibrary

class JKPHPickerPreviewView: JKPHPickerBaseBarView {
    
    open class var defaultHeight: CGFloat { 73.0 }
    open class var itemSize: CGSize { CGSize(width: 53.0, height: 53.0) }
    
    // MARK:
    // MARK: - Public Property
    
    open private(set) var configuration: JKPHPickerConfiguration
    
    open weak var dataSource: JKPHPickerBrowserViewDataSource?
    
    open weak var browserView: JKPHPickerBrowserView?
    
    // MARK:
    // MARK: - Public Methods
    
    open func updateCurrentIndex(_ index: Int,
                                 animated: Bool) {
        currentIndex = index
        
        if currentIndex > 0 {
            
            // TODO: - JKTODO <#注释#>
            
            //self.collectionView.reloadData()
            
            let indexPath = IndexPath(item: currentIndex, section: 0)
            
            self.collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: animated)
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
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let windowSafeAreaInsets = JKSafeAreaInsets
        
        contentView.frame = CGRect(x: windowSafeAreaInsets.left, y: 0.0, width: bounds.width - (windowSafeAreaInsets.left + windowSafeAreaInsets.right), height: bounds.height)
        
        let collectionHeight = Self.itemSize.height + 0.1
        
        collectionView.frame = CGRect(x: 0.0, y: (contentView.bounds.height - collectionHeight) * 0.5, width: contentView.bounds.width, height: collectionHeight)
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
        
        contentView.addSubview(collectionView)
    }
    
    /// 布局UI 交给子类重写 super自动调用该方法 注意调用super
    override func layoutUI() {
        super.layoutUI()
        
    }
    
    /// 初始化UI数据 交给子类重写 super自动调用该方法 注意调用super
    override func initializeUIData() {
        super.initializeUIData()
        
        backgroundEffectView.effect = UIBlurEffect(style: .dark)
    }
    
    // MARK:
    // MARK: - Private Property
    
    private var currentIndex: Int = 0
    
    /// collectionView
    open private(set) lazy var collectionView: UICollectionView = {
        
        // minimumLineSpacing 跟滚动方向相同的间距
        // minimumInteritemSpacing 跟滚动方向垂直的间距
        
        let flowLayout = UICollectionViewFlowLayout()
        
        flowLayout.itemSize = Self.itemSize
        flowLayout.minimumLineSpacing = 10.0
        flowLayout.minimumInteritemSpacing = 0.0
        flowLayout.scrollDirection = .horizontal
        flowLayout.sectionInset = UIEdgeInsets(top: 0.0, left: 10.0, bottom: 0.0, right: 10.0)
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
        
        collectionView.backgroundView = nil
        collectionView.backgroundColor = nil
        
        collectionView.scrollsToTop = false
        collectionView.alwaysBounceHorizontal = true
        
        if #available(iOS 11.0, *) {
            
            collectionView.contentInsetAdjustmentBehavior = .never
        }
        
        if #available(iOS 13.0, *) {
            
            collectionView.automaticallyAdjustsScrollIndicatorInsets = false
        }
        
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: String(describing: UICollectionViewCell.self))
        collectionView.register(JKPHPickerPreviewCell.self, forCellWithReuseIdentifier: String(describing: JKPHPickerPreviewCell.self))
        
        collectionView.dataSource = self
        collectionView.delegate = self
        
        return collectionView
    }()
}

// MARK:
// MARK: - UICollectionViewDataSource & UICollectionViewDelegate

extension JKPHPickerPreviewView: UICollectionViewDataSource, UICollectionViewDelegate {
    
    open func numberOfSections(in collectionView: UICollectionView) -> Int {
        
        guard let dataSource = dataSource,
              let browserView = browserView else {
            
            return 0
        }
        
        return dataSource.numberOfSections(in: browserView)
    }
    
    open func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        guard let dataSource = dataSource,
              let browserView = browserView else {
            
            return 0
        }
        
        let photoItemArray = dataSource.browserView(browserView, photoItemArrayIn: section)
        
        return photoItemArray.count
    }
    
    open func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        guard let dataSource = dataSource,
              let browserView = browserView,
              let model = dataSource.browserView(browserView, photoItemAt: indexPath) else {
            
            return collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: UICollectionViewCell.self), for: indexPath)
        }
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: JKPHPickerPreviewCell.self), for: indexPath)
        
        guard cell is JKPHPickerPreviewCell else { return cell }
        
        let realCell = cell as! JKPHPickerPreviewCell
        
        realCell.configuration = configuration
        realCell.thumbnailImageCache = configuration.thumbnailImageCache
        realCell.model = model
        
        return realCell
    }
    
    open func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        // TODO: - JKTODO <#注释#>
        
    }
}
