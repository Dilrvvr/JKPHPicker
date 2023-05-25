//
//  JKPHPickerBrowserView.swift
//  JKSwiftPhotoPicker
//
//  Created by AlbertCC on 2021/5/5.
//

import UIKit
import AVFoundation
import JKSwiftLibrary

public protocol JKPHPickerBrowserViewDataSource: NSObjectProtocol {
    
    /// dismiss动画的目标rect  返回.zero则执行普通dismiss动画
    func browserView(_ browserView: JKPHPickerBrowserView, dismissTargetRectFor photoItem: JKPHPickerPhotoItem) -> CGRect
    
    /// dismiss动画view所在的容器view 返回nil则将自己作为容器view
    func browserView(_ browserView: JKPHPickerBrowserView, dismissContainerViewFor photoItem: JKPHPickerPhotoItem) -> UIView?
    
    /// 原图按钮是否应该选中
    func browserViewShouldSelectOriginalImageOn(_ browserView: JKPHPickerBrowserView) -> Bool
    
    /// 是否在预览已选中的item
    func isPreviewSelectedItems(in browserView: JKPHPickerBrowserView) -> Bool
    
    /// 预览动画的起始位置
    func browserView(_ browserView: JKPHPickerBrowserView, animationFromRectFor photoItem: JKPHPickerPhotoItem) -> CGRect
    
    /// 预览动画图片
    func browserView(_ browserView: JKPHPickerBrowserView, thumbnailImageFor photoItem: JKPHPickerPhotoItem) -> UIImage?
    
    /// section数量
    func numberOfSections(in browserView: JKPHPickerBrowserView) -> Int
    
    /// 对应section的item数组
    func browserView(_ browserView: JKPHPickerBrowserView, photoItemArrayIn section: Int) -> [JKPHPickerPhotoItem]
    
    /// 对应索引的item
    func browserView(_ browserView: JKPHPickerBrowserView, photoItemAt indexPath: IndexPath) -> JKPHPickerPhotoItem?
    
    /// item对应的索引
    func browserView(_ browserView: JKPHPickerBrowserView, indexPathFor photoItem: JKPHPickerPhotoItem) -> IndexPath?
}

public protocol JKPHPickerBrowserViewDelegate: NSObjectProtocol {
    
    /// 点击选择按钮
    func browserView(_ browserView: JKPHPickerBrowserView, didTapSelectButton button: UIButton, photoItem: JKPHPickerPhotoItem)
    
    /// 点击原图按钮
    func browserView(_ browserView: JKPHPickerBrowserView, didTapOriginalImageButton button: UIButton, photoItem: JKPHPickerPhotoItem)
    
    /// 编辑了图片
    func browserView(_ browserView: JKPHPickerBrowserView, didEdit photoItem: JKPHPickerPhotoItem)
    
    /// 即将退出
    func browserViewWillDismiss(_ browserView: JKPHPickerBrowserView)
}

public protocol JKPHPickerBrowserViewActionDelegate: NSObjectProtocol {
    
    /// 单击
    func browserViewDidSingleTap(_ browserView: JKPHPickerBrowserView)
    
    /// 播放视频
    func browserView(_ browserView: JKPHPickerBrowserView, playVideo playerItem: AVPlayerItem, photoItem: JKPHPickerPhotoItem)
}

public protocol JKPHPickerBrowserViewLifeDelegate: NSObjectProtocol {
    
    /// 即将退出
    func browserViewWillDismiss(_ browserView: JKPHPickerBrowserView)
    
    /// 已经退出
    func browserViewDidDismiss(_ browserView: JKPHPickerBrowserView)
}

open class JKPHPickerBrowserView: JKPHPickerBaseView {
    
    public static let selectIconWH: CGFloat = 21.0
    
    // MARK:
    // MARK: - Public Property
    
    open weak var dataSource: JKPHPickerBrowserViewDataSource?
    
    open weak var delegate: JKPHPickerBrowserViewDelegate?
    
    open weak var lifeDelegate: JKPHPickerBrowserViewLifeDelegate?
    
    open weak var actionDelegate: JKPHPickerBrowserViewActionDelegate?
    
    // MARK:
    // MARK: - Public Methods
    
    open func dismiss() {
        
        normalDismiss()
    }
    
    open func reloadData() {
        
        collectionView.reloadData()
        
        checkCurrentPhotoItem(scrollView: collectionView)
    }
    
    open func solve(photoItem: JKPHPickerPhotoItem,
                    dataSource: JKPHPickerBrowserViewDataSource?,
                    delegate: JKPHPickerBrowserViewDelegate?) {
        
        guard let realDataSource = dataSource,
              let indexPath = realDataSource.browserView(self, indexPathFor: photoItem) else {
                  
                  return
              }
        
        self.dataSource = realDataSource
        self.delegate = delegate
        
        self.originalImageButton.isSelected = realDataSource.browserViewShouldSelectOriginalImageOn(self)
        
        //self.alpha = 0.0
        //self.isHidden = false
        
        photoItem.isCurrent = true
        
        currentPhotoItem = photoItem
        
        self.collectionView.isHidden = true
        self.collectionView.reloadData()
        
        self.setNeedsLayout()
        self.layoutIfNeeded()
        
        currentIndex = indexPath.item
        
        if realDataSource.isPreviewSelectedItems(in: self) {
            
            addSubview(previewView)
            
            self.previewView.dataSource = realDataSource
            self.previewView.updateCurrentIndex(currentIndex, animated: false)
        }
        
        if currentIndex > 0 {
            
            self.collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: false)
        }
        
        let fromFrame = realDataSource.browserView(self, animationFromRectFor: photoItem)
        
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        
        imageView.image = realDataSource.browserView(self, thumbnailImageFor: photoItem) ?? JKPHPickerUtility.Placeholder.darkGray
        
        imageView.frame = fromFrame
        self.contentView.addSubview(imageView)
        
        let imageSize = JKPHPickerUtility.calculateBrowserImageSize(photoItem.pixelSize, maxSize: JKKeyWindow.bounds.size)
        
        var targetY: CGFloat = 0.0
        if imageSize.height < bounds.height {
            targetY = (bounds.height - imageSize.height) * 0.5
        }
        let targetFrame = CGRect(x: (bounds.width - imageSize.width) * 0.5, y: targetY, width: imageSize.width, height: imageSize.height)
        
        setNeedsLayout()
        layoutIfNeeded()
        
        photoItem.didLoadPreviewImageHandler = { image in
            
            guard let _ = image else { return }
            
            UIView.transition(with: imageView, duration: 0.25, options: .transitionCrossDissolve) {
                
                imageView.image = image
                
            } completion: { _ in }
        }
        
        self.backgroundView.alpha = 0.0
        self.navigationBarView.alpha = 0.0
        self.bottomControlView.alpha = 0.0
        self.isHidden = false
        
        UIView.animate(withDuration: 0.45, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.0, options: .curveEaseOut) {
            
            imageView.frame = targetFrame
            self.backgroundView.alpha = 1.0
            self.navigationBarView.alpha = 1.0
            self.bottomControlView.alpha = 1.0
            
        } completion: { _ in
            
            self.collectionView.isHidden = false
            
            UIView.transition(with: imageView, duration: 0.15, options: .transitionCrossDissolve) {
                
                imageView.alpha = 0.0
                
            } completion: { _ in
                
                imageView.removeFromSuperview()
                
                photoItem.checkPlayGif(isPlay: true)
            }
        }
    }
    
    /// 方向即将改变
    open func viewOrientationWillChange() {
        
        collectionView.collectionViewLayout.invalidateLayout()
    }
    
    /// 方向已经改变
    open func viewOrientationDidChange() {
        
        updateNavigationTitle(photoItem: currentPhotoItem)
        
        guard let item = currentPhotoItem, let realDataSource = dataSource else { return }
        
        let itemCount = realDataSource.browserView(self, photoItemArrayIn: 0).count
        
        guard currentIndex >= 0,
              itemCount > currentIndex else {
                  
                  return
              }
        
        let indexPath = IndexPath(item: currentIndex, section: 0)
        
        updateLayout()
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.15) {
            
            self.collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: false)
            self.collectionView.reloadItems(at: [indexPath])
            
            item.checkPlayGif(isPlay: true)
            
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.1) {
                
                item.reloadInBrowser(isRequestImage: false)
            }
        }
    }
    
    // MARK:
    // MARK: - Override
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        updateLayout()
    }
    
    private func updateLayout() {
        
        if let dataSource = dataSource,
           dataSource.isPreviewSelectedItems(in: self) {
            
            let previewHeight = JKPHPickerPreviewView.defaultHeight
            previewView.frame = CGRect(x: 0.0, y: bottomControlView.frame.minY - previewHeight, width: bounds.width, height: previewHeight)
        }
        
        collectionView.frame = CGRect(x: -JKPHPickerUtility.browserInset.left, y: 0.0, width: contentView.bounds.width + JKPHPickerUtility.browserInset.left + JKPHPickerUtility.browserInset.right, height: contentView.bounds.height)
        
        flowLayout.itemSize = collectionView.bounds.size
        
        if let editView = imageEditView {
            
            editView.frame = bounds
        }
    }
    
    override func layoutBottomControlViewUI() {
        super.layoutBottomControlViewUI()
        
        let barContentView = bottomControlView.contentView
        
        editButton.frame = CGRect(x: 5.0, y: 0.0 * 0.5, width: 60.0, height: barContentView.bounds.height)
    }
    
    // MARK:
    // MARK: - Private Methods
    
    private func updateNavigationTitle(photoItem: JKPHPickerPhotoItem?) {
        
        guard let item = photoItem else {
            
            navigationBarView.attributedTitle = nil
            
            return
        }
        
        if JKisDeviceiPad ||
            JKisLandscape {
            
            navigationBarView.attributedTitle = nil
            
            navigationBarView.title = item.createDateNormalString
            
            return
        }
        
        navigationBarView.title = nil
        
        var dayString: String = item.createDateDayString
        let timeString: String = item.createTimeString
        
        if dayString.count > 0 &&
            timeString.count > 0 {
            dayString += "\n"
        }
        
        let para = NSMutableParagraphStyle()
        para.alignment = .center
        para.lineSpacing = 3.0
        
        var attributes = [NSAttributedString.Key : Any]()
        attributes[.foregroundColor] = UIColor.white
        attributes[.font] = UIFont.systemFont(ofSize: 15.0)
        attributes[.paragraphStyle] = para
        
        let attrM = NSMutableAttributedString(string: dayString, attributes: attributes)
        
        var attributes1 = [NSAttributedString.Key : Any]()
        attributes1[.foregroundColor] = UIColor.white
        attributes1[.font] = UIFont.systemFont(ofSize: 11.0)
        attributes1[.paragraphStyle] = para
        
        let attr1 = NSMutableAttributedString(string: timeString, attributes: attributes1)
        
        attrM.append(attr1)
        
        navigationBarView.attributedTitle = attrM
    }
    
    private func updateSelectIcon(photoItem: JKPHPickerPhotoItem?) {
        
        guard let photoItem = photoItem else {
            
            selectIconLabel.text = nil
            selectIconLabel.layer.backgroundColor = nil
            selectIconLabel.layer.borderColor = UIColor.white.cgColor
            
            return
        }
        
        selectIconLabel.text = photoItem.isSelected ? "\(photoItem.selectIndex + 1)" : nil
        selectIconLabel.layer.backgroundColor = photoItem.isSelected ? configuration.mainColor.cgColor : nil
        selectIconLabel.layer.borderColor = photoItem.isSelected ? UIColor.clear.cgColor : UIColor.white.cgColor
        
        photoItem.reloadInPreview(isRequestImage: false)
    }
    
    open override func showBottomControl(_ animated: Bool) {
        super.showBottomControl(animated)
        
        guard let dataSource = dataSource,
              dataSource.isPreviewSelectedItems(in: self) else {
            
            return
        }
        
        if !animated {
            
            previewView.isHidden = false
            
            return
        }
        
        previewView.alpha = 0.0
        previewView.isHidden = false
        
        UIView.transition(with: bottomControlView, duration: 0.25, options: .transitionCrossDissolve) {
            
            self.previewView.alpha = 1.0
            
        } completion: { _ in
            
        }
    }
    
    open override func hideBottomControl(_ animated: Bool) {
        super.hideBottomControl(animated)
        
        guard let dataSource = dataSource,
              dataSource.isPreviewSelectedItems(in: self) else {
            
            return
        }
        
        if !animated {
            
            previewView.isHidden = true
            
            return
        }
        
        UIView.transition(with: bottomControlView, duration: 0.25, options: .transitionCrossDissolve) {
            
            self.previewView.alpha = 0.0
            
        } completion: { _ in
            
            self.previewView.isHidden = true
            self.previewView.alpha = 1.0
        }
    }
    
    // MARK:
    // MARK: - Private Selector
    
    /// editButtonClick
    @objc private func editButtonClick(button: UIButton) {
        
        guard let item = currentPhotoItem else { return }
        
        button.jk.relayoutIndicatorViewToCenter()
        button.jk.startIndicatorLoading()
        isUserInteractionEnabled = false
        
        if configuration.isExportOriginalImage {
            
            JKPHPickerEngine.exportImage(with: [item], scale: 1.0, progressHandler: nil) { [weak self] resultArray in
                
                guard let result = resultArray.first,
                      let image = result.image else {
                          
                          self?.editButton.jk.stopIndicatorLoading()
                          self?.isUserInteractionEnabled = true
                          
                          return
                      }
                
                self?.showImageEditView(photoItem: item, image: image)
            }
            
            return
        }
        
        if let cachedImage = configuration.previewImageCache.object(forKey: NSString(string: item.localIdentifier)) {
            
            showImageEditView(photoItem: item, image: cachedImage)
            
            return
        }
        
        JKPHPickerEngine.requestPreviewImage(for: item.asset) { [weak self] isCancelled, image, info in
            
            guard let _ = self else { return }
            
            if isCancelled || (image == nil) {
                
                JKPHPickerToastView.show(in: self, message: "图片加载失败")
                
                self?.editButton.jk.stopIndicatorLoading()
                self?.isUserInteractionEnabled = true
                
                return
            }
            
            self?.showImageEditView(photoItem: item, image: image!)
        }
    }
    
    private var imageEditView: JKPHPickerEditView?
    
    private func showImageEditView(photoItem: JKPHPickerPhotoItem, image: UIImage) {
        
        if let _ = imageEditView {
            
            return
        }
        
        editButton.jk.stopIndicatorLoading()
        isUserInteractionEnabled = true
        
        configuration.editConfiguration.cancelHandler = { [weak self] _ in
            
            guard let _ = self else { return }
            
            self?.dismissImageEditView()
        }
        
        configuration.editConfiguration.editResultHandler = { [weak self] _, image in
            
            guard let _ = self else { return }
            
            self?.dismissImageEditView()
            
            guard let image = image else { return }
            
            self?.cacheEditImage(image)
        }
        
        let editView = JKPHPickerEditView(image: image, configuration: configuration.editConfiguration, frame: bounds)
        addSubview(editView)
        imageEditView = editView
        
        editView.transform = CGAffineTransform(translationX: bounds.width, y: 0.0)
        
        UIView.transition(with: editView, duration: 0.25, options: .transitionCrossDissolve) {
            
            editView.transform = .identity
            
        } completion: { _ in
            
        }
    }
    
    private func dismissImageEditView() {
        
        guard let editView = imageEditView else { return }
        
        imageEditView = nil
        
        UIView.transition(with: editView, duration: 0.25, options: .transitionCrossDissolve) {
            
            editView.transform = CGAffineTransform(translationX: self.bounds.width, y: 0.0)
            
        } completion: { _ in
            
            editView.removeFromSuperview()
        }
    }
    
    private func cacheEditImage(_ image: UIImage) {
        
        guard let item = currentPhotoItem else { return }
        
        configuration.editedImageDict[item.localIdentifier] = image
        
        if let cgImage = image.cgImage {
            
            item.editedImageSize = CGSize(width: cgImage.width, height: cgImage.height)
            
        } else {
            
            item.editedImageSize = CGSize(width: image.size.width * image.scale, height: image.size.height * image.scale)
        }
        
        item.reloadInBrowser(isRequestImage: true)
        item.reloadInPicker(isRequestImage: true)
        
        if let _ = delegate {
            
            delegate?.browserView(self, didEdit: item)
        }
    }
    
    /// 点击原图按钮
    open override func originalImageButtonClick(button: UIButton) {
        
        super.originalImageButtonClick(button: button)
        
        guard let currentPhotoItem = currentPhotoItem else { return }
        
        if let delegate = delegate {
            
            delegate.browserView(self, didTapOriginalImageButton: button, photoItem: currentPhotoItem)
        }
        
        if let dataSource = dataSource {
            
            originalImageButton.isSelected = dataSource.browserViewShouldSelectOriginalImageOn(self)
        }
        
        updateSelectIcon(photoItem: currentPhotoItem)
    }
    
    /// 点击选中按钮
    @objc open func selectButtonClick(button: UIButton) {
        
        guard let currentPhotoItem = currentPhotoItem else { return }
        
        if let delegate = delegate {
            
            delegate.browserView(self, didTapSelectButton: button, photoItem: currentPhotoItem)
        }
        
        updateSelectIcon(photoItem: currentPhotoItem)
    }
    
    // MARK:
    // MARK: - Initialization & Build UI
    
    /// 初始化自身属性 交给子类重写 super自动调用该方法
    open override func initializeProperty() {
        super.initializeProperty()
        
        isHidden = true
    }
    
    /// 构造函数初始化时调用 注意调用super
    open override func initialization() {
        super.initialization()
        
        collectionView.register(JKPHPickerBrowserCell.self, forCellWithReuseIdentifier: String(describing: JKPHPickerBrowserCell.self))
        collectionView.register(JKPHPickerErrorCell.self, forCellWithReuseIdentifier: String(describing: JKPHPickerErrorCell.self))
    }
    
    /// 创建UI 交给子类重写 super自动调用该方法
    open override func createUI() {
        super.createUI()
        
        addSubview(bottomControlView)
        
        contentView.insertSubview(collectionView, at: 0)
        
        navigationBarView.contentView.addSubview(selectButton)
        navigationBarView.contentView.addSubview(selectIconLabel)
        
        bottomControlView.contentView.addSubview(editButton)
    }
    
    /// 布局UI 交给子类重写 super自动调用该方法
    open override func layoutUI() {
        super.layoutUI()
        
        navigationBarView.didLayoutSubviewsHandler = { [weak self] barView in
            
            guard let _ = self else { return }
            
            let barContentView = barView.contentView
            
            self?.selectIconLabel.frame = CGRect(x: barContentView.bounds.width - 15.0 - Self.selectIconWH, y: (barContentView.bounds.height - Self.selectIconWH) * 0.5, width: Self.selectIconWH, height: Self.selectIconWH)
            
            self?.selectButton.frame = CGRect(x: 0.0, y: 0.0, width: Self.selectIconWH + 30.0, height: barContentView.bounds.height)
            self?.selectButton.center = self!.selectIconLabel.center
        }
    }
    
    /// 初始化UI数据 交给子类重写 super自动调用该方法
    open override func initializeUIData() {
        super.initializeUIData()
        
        clipsToBounds = true
        
        editButton.isHidden = !configuration.isEditable
        
        navigationBarView.defaultButtonWidth = 60.0
        
        navigationBarView.titleLabel.numberOfLines = 0
        
        backgroundView.backgroundColor = .black
        
        navigationBarView.titleLabel.font = UIFont.systemFont(ofSize: 13.0)
        navigationBarView.titleLabel.textColor = .white
        
        flowLayout.scrollDirection = .horizontal
        flowLayout.minimumLineSpacing = 0.0
        flowLayout.minimumInteritemSpacing = 0.0
        
        collectionView.isPagingEnabled = true
        collectionView.scrollsToTop = false
        collectionView.alwaysBounceHorizontal = true
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
    }
    
    // MARK:
    // MARK: - Private Property
    
    private var currentIndex: Int = 0
    
    private var currentPhotoItem: JKPHPickerPhotoItem? {
        
        willSet {
            
            if let preItem = currentPhotoItem,
               let currentItem = newValue,
               currentItem == preItem  {
                
                return
            }
            
            updateNavigationTitle(photoItem: newValue)
            
            if let item = newValue {
                
                if configuration.isShowsOriginalButton {
                    
                    originalImageButton.isHidden = !item.isSelectable
                }
                
                selectButton.isHidden = !item.isSelectable
                
            } else {
                
                originalImageButton.isHidden = true
                
                selectButton.isHidden = true
            }
            
            selectIconLabel.alpha = selectButton.isHidden ? 0.1 : 1.0
            
            updateSelectIcon(photoItem: newValue)
        }
        
        didSet {
            
            guard let currentPhotoItem = currentPhotoItem,
                  configuration.isEditable else {
                
                editButton.isHidden = true
                
                return
            }
            
            editButton.isHidden = !currentPhotoItem.isSelectable
        }
    }
    
    private lazy var editButton: UIButton = {
        
        let titleColor = UIColor.white
        
        let editButton = UIButton(type: .custom)
        editButton.setTitle("编辑", for: .normal)
        editButton.titleLabel?.font = UIFont.systemFont(ofSize: 15.0)
        editButton.setTitleColor(titleColor, for: .normal)
        editButton.setTitleColor(titleColor.withAlphaComponent(0.5), for: .highlighted)
        
        editButton.contentHorizontalAlignment = .left
        editButton.titleEdgeInsets = UIEdgeInsets(top: 0.0, left: 10.0, bottom: 0.0, right: -10.0)
        
        editButton.addTarget(self, action: #selector(editButtonClick(button:)), for: .touchUpInside)
        
        return editButton
    }()
    
    /// selectIconLabel
    open private(set) lazy var selectIconLabel: UILabel = {
        
        let label = UILabel()
        
        label.font = UIFont.systemFont(ofSize: 11.0)
        label.textColor = .white
        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = true
        
        label.layer.cornerRadius = Self.selectIconWH * 0.5
        label.layer.borderWidth = 1.0
        label.layer.borderColor = UIColor.white.cgColor
        
        return label
    }()
    
    private lazy var selectButton: UIButton = {
        
        let button = UIButton(type: .custom)
        
        button.addTarget(self, action: #selector(selectButtonClick(button:)), for: .touchUpInside)
        
        return button
    }()
    
    private lazy var previewView: JKPHPickerPreviewView = {
        
        let previewView = JKPHPickerPreviewView(frame: CGRect(x: 0.0, y: 0.0, width: JKScreenWidth, height: JKPHPickerPreviewView.defaultHeight), configuration: self.configuration)
        
        previewView.browserView = self
        
        previewView.didSelectItemHandler = { [weak self] photoItem, indexPath in
            
            guard let _ = self else { return }
            
            self?.solvePreviewDidSelectItem(photoItem: photoItem, indexPath: indexPath)
        }
        
        return previewView
    }()
    
    private func solvePreviewDidSelectItem(photoItem: JKPHPickerPhotoItem,
                                           indexPath: IndexPath) {
        
        if photoItem.isCurrent { return }
        
        photoItem.isCurrent = true
        photoItem.reloadInPreview(isRequestImage: false)
        
        if let _ = currentPhotoItem {
            
            currentPhotoItem?.isCurrent = false
            currentPhotoItem?.reloadInPreview(isRequestImage: false)
        }
        
        currentPhotoItem = photoItem
        currentIndex = indexPath.item
        
        collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        
        self.previewView.updateCurrentIndex(currentIndex, animated: true)
    }
    
    private var previousOrientationIndex: Int?
    
    private var isControlHidden: Bool = false
}

// MARK:
// MARK: - UICollectionViewDataSource & UICollectionViewDelegate

extension JKPHPickerBrowserView {
    
    open func numberOfSections(in collectionView: UICollectionView) -> Int {
        
        guard let realDataSource = dataSource else { return 0 }
        
        return realDataSource.numberOfSections(in: self)
    }
    
    open override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        guard let realDataSource = dataSource else { return 0 }
        
        let photoItemArray = realDataSource.browserView(self, photoItemArrayIn: section)
        
        return photoItemArray.count
    }
    
    open override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        guard let _ = dataSource,
              let model = dataSource?.browserView(self, photoItemAt: indexPath) else {
                  
                  return collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: JKPHPickerErrorCell.self), for: indexPath)
              }
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: JKPHPickerBrowserCell.self), for: indexPath)
        
        guard cell is JKPHPickerBrowserCell else {
            
            return collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: JKPHPickerErrorCell.self), for: indexPath)
        }
        
        let realCell = cell as! JKPHPickerBrowserCell
        
        realCell.configuration = configuration
        realCell.thumbnailImageCache = configuration.thumbnailImageCache
        realCell.previewImageCache = configuration.previewImageCache
        realCell.model = model
        
        solveCellHandler(realCell)
        
        return cell
    }
}

// MARK:
// MARK: - 处理cell事件

extension JKPHPickerBrowserView {
    
    /// 处理cell回调
    private func solveCellHandler(_ cell: JKPHPickerBrowserCell) {
        
        cell.playVideoHandler = { [weak self] photoItem, playerItem in
            
            guard let _ = self else { return }
            
            self?.solvePlayVideo(photoItem: photoItem, playerItem: playerItem)
        }
        
        cell.panGestureDidBeganHandler = { [weak self] photoItem in
            
            guard let _ = self else { return }
            
            self?.solveCellPanGestureDidBegan(photoItem: photoItem)
        }
        
        cell.panGestureDidEndHandler = { [weak self] photoItem in
            
            guard let _ = self else { return }
            
            self?.solveCellPanGestureDidEnd(photoItem: photoItem)
        }
        
        // 滑动退出时更新背景alpha
        cell.slideBackgroundAlphaHandler = { [weak self] photoItem, slideAlpha, animated in
            
            guard let _ = self else { return }
            
            let animateHandler: (() -> Void) = { [weak self] in
                
                guard let _ = self else { return }
                
                self?.backgroundView.alpha = slideAlpha
                self?.navigationBarView.alpha = slideAlpha
                self?.bottomControlView.alpha = slideAlpha
                
                if let dataSource = self?.dataSource,
                   dataSource.isPreviewSelectedItems(in: self!) {
                    
                    self?.previewView.alpha = slideAlpha
                }
            }
            
            if animated {
                
                UIView.animate(withDuration: 0.25, animations: animateHandler)
                
            } else {
                
                animateHandler()
            }
        }
        
        // 单击
        cell.singleTapActionHandler = { [weak self] photoItem in
            
            guard let _ = self else { return }
            
            self?.solveCellSingleTap(photoItem: photoItem)
        }
        
        // 滑动退出
        cell.slideToDismissHandler = { [weak self] photoItem, browserCell in
            
            guard let _ = self else { return }
            
            self?.dismiss(photoItem: photoItem, browserCell: browserCell)
        }
    }
    
    private func solvePlayVideo(photoItem: JKPHPickerPhotoItem, playerItem: AVPlayerItem) {
        
        guard let _ = actionDelegate else { return }
        
        actionDelegate?.browserView(self, playVideo: playerItem, photoItem: photoItem)
    }
    
    private func solveCellPanGestureDidBegan(photoItem: JKPHPickerPhotoItem) {
        
        navigationBarView.isUserInteractionEnabled = false
        bottomControlView.isUserInteractionEnabled = false
    }
    
    private func solveCellPanGestureDidEnd(photoItem: JKPHPickerPhotoItem) {
        
        navigationBarView.isUserInteractionEnabled = true
        bottomControlView.isUserInteractionEnabled = true
    }
    
    private func solveCellSingleTap(photoItem: JKPHPickerPhotoItem) {
        
        if let _ = actionDelegate {
            
            actionDelegate!.browserViewDidSingleTap(self)
        }
        
        isControlHidden = !isControlHidden
        
        updateControlUI()
    }
    
    private func updateControlUI() {
        
        if isControlHidden {
            
            hideNavigationBarVier(true)
            
            hideBottomControl(true)
            
            return
        }
        
        showNavigationBarView(true)
        
        showBottomControl(true)
    }
}

// MARK:
// MARK: - Dismiss

extension JKPHPickerBrowserView {
    
    private func preDismiss() {
        
        if let currentPhotoItem = currentPhotoItem {
            
            currentPhotoItem.isCurrent = false
        }
        
        if let delegate = delegate {
            
            delegate.browserViewWillDismiss(self)
        }
        
        if let lifeDelegate = lifeDelegate {
            
            lifeDelegate.browserViewWillDismiss(self)
        }
    }
    
    /// 退出
    private func dismiss(photoItem: JKPHPickerPhotoItem,
                         browserCell: JKPHPickerBrowserCell) {
        
        guard let _ = dataSource,
              let _ = browserCell.imageView.superview else {
            
            normalDismiss()
            
            return
        }
        
        // dismiss动画的目标rect
        var toRect = dataSource!.browserView(self, dismissTargetRectFor: photoItem)
        
        // 返回.zero 执行普通消失动画
        if toRect.equalTo(.zero) {
            
            let dismissWH: CGFloat = 100.0
            
            toRect = CGRect(x: (JKScreenWidth - dismissWH) * 0.5, y: JKScreenHeight, width: dismissWH, height: dismissWH)
        }
        
        let containerView: UIView = dataSource!.browserView(self, dismissContainerViewFor: photoItem) ?? self
        
        if toRect.minY > containerView.bounds.maxY {
            
            toRect.origin.y = containerView.bounds.maxY
            
        } else if toRect.maxY < containerView.bounds.minY {
            
            toRect.origin.y = containerView.bounds.minY - toRect.height
        }
        
        let tempContainerView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: containerView.bounds.width, height: containerView.bounds.height))
        containerView.addSubview(tempContainerView)
        
        let tempBackgroundView = UIView(frame: tempContainerView.bounds)
        tempBackgroundView.alpha = backgroundView.alpha
        tempBackgroundView.backgroundColor = backgroundView.backgroundColor
        tempContainerView.addSubview(tempBackgroundView)
        
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.image = browserCell.imageView.image
        
        let fromRect = browserCell.imageView.superview!.convert(browserCell.imageView.frame, to: containerView)
        imageView.frame = fromRect
        containerView.addSubview(imageView)
        
        isHidden = true
        
        preDismiss()
        
        UIView.animate(withDuration: 0.35, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.1, options: .curveEaseIn) {
            
            imageView.frame = toRect
            
            tempBackgroundView.alpha = 0.0
            
        } completion: { _ in
            
            UIView.transition(with: imageView, duration: 0.15, options: .transitionCrossDissolve) {

                imageView.alpha = 0.0

            } completion: { _ in

                imageView.removeFromSuperview()
            }
            
            tempContainerView.removeFromSuperview()
            
            if let lifeDelegate = self.lifeDelegate {
                
                lifeDelegate.browserViewDidDismiss(self)
            }
            
            self.removeFromSuperview()
        }
    }
    
    /// 普通方式退出
    private func normalDismiss() {
        
        let imageView = UIImageView(frame: self.bounds)
        
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.image = self.contentView.jk.snapshot
        addSubview(imageView)
        
        contentView.isHidden = true
        
        preDismiss()
        
        UIView.animate(withDuration: 0.35, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.1, options: .curveEaseIn) {
            
            imageView.transform = CGAffineTransform(translationX: 0.0, y: imageView.bounds.height).scaledBy(x: 0.25, y: 0.25)
            
            self.backgroundView.alpha = 0.0
            
        } completion: { _ in
            
            imageView.removeFromSuperview()
            
            if let lifeDelegate = self.lifeDelegate {
                
                lifeDelegate.browserViewDidDismiss(self)
            }
            
            self.removeFromSuperview()
        }
    }
}

// MARK:
// MARK: - UIScrollViewDelegate

extension JKPHPickerBrowserView {
    
    open func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        
        navigationBarView.isUserInteractionEnabled = false
        bottomControlView.isUserInteractionEnabled = false
        
        if let item = currentPhotoItem {
            
            item.checkPlayGif(isPlay: false)
        }
        
        checkCurrentPhotoItem(scrollView: scrollView)
    }
    
    open func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        
        navigationBarView.isUserInteractionEnabled = true
        bottomControlView.isUserInteractionEnabled = true
    }
    
    open func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        
        checkCurrentPhotoItem(scrollView: scrollView)
        
        if let item = currentPhotoItem {
            
            item.checkPlayGif(isPlay: true)
        }
    }
    
    private func checkCurrentPhotoItem(scrollView: UIScrollView) {
        
        guard let realDataSource = dataSource else { return }
        
        let photoItemArray = realDataSource.browserView(self, photoItemArrayIn: 0)
        
        guard scrollView.bounds.width > 0 else { return }
        
        let index: Int = Int(scrollView.contentOffset.x / scrollView.bounds.width)
        
        guard index >= 0,
              photoItemArray.count > index else {
            
            // TODO: - JKTODO <#注释#>
            
            return
        }
        
        if let _ = currentPhotoItem {
            
            currentPhotoItem?.isCurrent = false
            currentPhotoItem?.reloadInPreview(isRequestImage: false)
        }
        
        currentIndex = index
        currentPhotoItem = photoItemArray[currentIndex]
        
        currentPhotoItem?.isCurrent = true
        currentPhotoItem?.reloadInPreview(isRequestImage: false)
        
        if let dataSource = dataSource,
           dataSource.isPreviewSelectedItems(in: self) {
            
            self.previewView.updateCurrentIndex(currentIndex, animated: true)
        }
    }
}

// MARK:
// MARK: - JKPHPickerNavigationBarViewDelegate

extension JKPHPickerBrowserView {
    
    open override func navigationBarView(_ navigationBarView: JKPHPickerNavigationBarView, didTapClose button: UIButton) {
        
        closeToDismiss()
    }
    
    private func closeToDismiss() {
        
        guard let item = currentPhotoItem,
              let realDataSource = dataSource,
              let indexPath = realDataSource.browserView(self, indexPathFor: item),
              let browserCell = collectionView.cellForItem(at: indexPath) as? JKPHPickerBrowserCell else {
                  
                  normalDismiss()
                  
                  return
              }
        
        dismiss(photoItem: item, browserCell: browserCell)
    }
}
