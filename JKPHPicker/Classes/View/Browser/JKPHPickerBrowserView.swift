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
    
    public static let selectIconWH: CGFloat = 20.0
    
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
                    datasource: JKPHPickerBrowserViewDataSource?,
                    delegate: JKPHPickerBrowserViewDelegate?) {
        
        guard let realDataSource = datasource,
              let indexPath = realDataSource.browserView(self, indexPathFor: photoItem) else {
                  
                  return
              }
        
        currentIndex = indexPath.item
        
        self.dataSource = realDataSource
        self.delegate = delegate
        
        self.originalImageButton.isSelected = realDataSource.browserViewShouldSelectOriginalImageOn(self)
        
        self.alpha = 0.0
        self.isHidden = false
        
        currentPhotoItem = photoItem
        
        self.collectionView.isHidden = true
        self.collectionView.reloadData()
        
        self.setNeedsLayout()
        self.layoutIfNeeded()
        
        if currentIndex > 0 {
            
            self.collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: false)
        }
        
        let fromFrame = realDataSource.browserView(self, animationFromRectFor: photoItem)
        
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        
        imageView.image = datasource?.browserView(self, thumbnailImageFor: photoItem) ?? JKPHPickerUtility.Placeholder.darkGray
        
        imageView.frame = fromFrame
        self.contentView.addSubview(imageView)
        
        let imageSize = JKPHPickerUtility.calculateBrowserImageSize(photoItem.pixelSize, maxSize: JKKeyWindow.bounds.size)
        let targetFrame = CGRect(x: (bounds.width - imageSize.width) * 0.5, y: (bounds.height - imageSize.height) * 0.5, width: imageSize.width, height: imageSize.height)
        
        setNeedsLayout()
        layoutIfNeeded()
        
        photoItem.didLoadPreviewImageHandler = { image in
            
            guard let _ = image else { return }
            
            UIView.transition(with: imageView, duration: 0.25, options: .transitionCrossDissolve) {
                
                imageView.image = image
                
            } completion: { _ in }
        }
        
        UIView.animate(withDuration: 0.45, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.0, options: .curveEaseOut) {
            
            imageView.frame = targetFrame
            self.alpha = 1.0
            
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
        
        collectionView.frame = CGRect(x: -JKPHPickerUtility.browserInset.left, y: 0.0, width: contentView.bounds.width + JKPHPickerUtility.browserInset.left + JKPHPickerUtility.browserInset.right, height: contentView.bounds.height)
        
        flowLayout.itemSize = collectionView.bounds.size
        
        if let editView = imageEditView {
            
            editView.frame = bounds
        }
    }
    
    private func layoutBottomControlViewUI() {
        
        let barContentView = bottomControlView.contentView
        
        editButton.frame = CGRect(x: 5.0, y: 0.0 * 0.5, width: 60.0, height: barContentView.bounds.height)
        
        selectIconImageView.frame = CGRect(x: barContentView.bounds.width - 15.0 - Self.selectIconWH, y: (barContentView.bounds.height - Self.selectIconWH) * 0.5, width: Self.selectIconWH, height: Self.selectIconWH)
        
        selectButton.frame = CGRect(x: 0.0, y: 0.0, width: Self.selectIconWH + 30.0, height: barContentView.bounds.height)
        selectButton.center = selectIconImageView.center
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
    
    private func updateSelectIcon(isSelected: Bool) {
        
        let imageName = isSelected ? "select_on" : "select_off"
        
        selectIconImageView.image = JKPHPickerResourceManager.image(named: imageName)
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
        
        guard let _ = currentPhotoItem else { return }
        
        if let _ = delegate {
            
            delegate!.browserView(self, didTapOriginalImageButton: button, photoItem: currentPhotoItem!)
        }
        
        if let _ = dataSource {
            
            originalImageButton.isSelected = dataSource!.browserViewShouldSelectOriginalImageOn(self)
        }
        
        updateSelectIcon(isSelected: currentPhotoItem!.isSelected)
    }
    
    /// 点击选中按钮
    @objc open func selectButtonClick(button: UIButton) {
        
        guard let _ = currentPhotoItem else { return }
        
        if let _ = delegate {
            
            delegate!.browserView(self, didTapSelectButton: button, photoItem: currentPhotoItem!)
        }
        
        updateSelectIcon(isSelected: currentPhotoItem!.isSelected)
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
        
        bottomControlView.contentView.addSubview(editButton)
        bottomControlView.contentView.addSubview(selectButton)
        bottomControlView.contentView.addSubview(selectIconImageView)
    }
    
    /// 布局UI 交给子类重写 super自动调用该方法
    open override func layoutUI() {
        super.layoutUI()
        
        bottomControlView.didLayoutSubviewsHandler = { [weak self] _ in
            
            guard let _ = self else { return }
            
            self?.layoutBottomControlViewUI()
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
        
        navigationBarView.rightButton.isUserInteractionEnabled = false
        navigationBarView.rightButton.contentHorizontalAlignment = .right
        navigationBarView.rightButton.setTitleColor(.white, for: .normal)
        navigationBarView.rightButton.titleLabel?.adjustsFontSizeToFitWidth = true
        navigationBarView.rightButton.titleLabel?.font = UIFont.systemFont(ofSize: 13.0)
        flowLayout.scrollDirection = .horizontal
        flowLayout.minimumLineSpacing = 0.0
        flowLayout.minimumInteritemSpacing = 0.0
        
        collectionView.isPagingEnabled = true
        collectionView.scrollsToTop = false
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
            
            navigationBarView.rightButton.isHidden = true
            
            updateNavigationTitle(photoItem: newValue)
            
            if let item = newValue {
                
                if let realDataSource = dataSource,
                   realDataSource.isPreviewSelectedItems(in: self) {
                    
                    navigationBarView.rightButton.isHidden = false
                    navigationBarView.setNeedsLayout()
                    
                    let itemCount = realDataSource.browserView(self, photoItemArrayIn: 0).count
                    
                    navigationBarView.rightButton.setTitle("\(currentIndex + 1)/\(itemCount)", for: .normal)
                }
                
                if configuration.isShowsOriginalButton {
                    
                    originalImageButton.isHidden = !item.isSelectable
                }
                
                selectButton.isHidden = !item.isSelectable
                selectIconImageView.isHidden = selectButton.isHidden
                
            } else {
                
                originalImageButton.isHidden = true
                
                selectButton.isHidden = true
                selectIconImageView.isHidden = true
            }
            
            updateSelectIcon(isSelected: newValue?.isSelected ?? false)
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
    
    /// selectIconImageView
    private lazy var selectIconImageView: UIImageView = {
        
        let imageView = UIImageView()
        
        imageView.contentMode = .scaleAspectFill
        imageView.image = JKPHPickerResourceManager.image(named: "select_off")
        
        imageView.layer.cornerRadius = Self.selectIconWH * 0.5
        
        return imageView
    }()
    
    private lazy var selectButton: UIButton = {
        
        let button = UIButton(type: .custom)
        
        button.addTarget(self, action: #selector(selectButtonClick(button:)), for: .touchUpInside)
        
        return button
    }()
    
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
            
            let animateHandler: (() -> Void) = {
                
                self?.backgroundView.alpha = slideAlpha
                self?.navigationBarView.alpha = slideAlpha
                self?.bottomControlView.alpha = slideAlpha
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
    
    private func preDismiss() {
        
        if let _ = delegate {
            
            delegate?.browserViewWillDismiss(self)
        }
        
        if let _ = lifeDelegate {
            
            lifeDelegate?.browserViewWillDismiss(self)
        }
    }
    
    /// 退出
    private func dismiss(photoItem: JKPHPickerPhotoItem, browserCell: JKPHPickerBrowserCell) {
        
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
        
        preDismiss()
        
        let tempBackgroundView = UIView()
        tempBackgroundView.alpha = backgroundView.alpha
        tempBackgroundView.backgroundColor = backgroundView.backgroundColor
        containerView.addSubview(tempBackgroundView)
        
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.image = browserCell.imageView.image
        
        let fromRect = browserCell.imageView.superview!.convert(browserCell.imageView.frame, to: containerView)
        imageView.frame = fromRect
        containerView.addSubview(imageView)
        
        isHidden = true
        
        UIView.animate(withDuration: 0.35, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.1, options: .curveEaseIn) {
            
            imageView.frame = toRect
            
            tempBackgroundView.alpha = 0.0
            
        } completion: { _ in
            
            UIView.transition(with: imageView, duration: 0.25, options: .transitionCrossDissolve) {
                
                imageView.alpha = 0.0
                
            } completion: { _ in
                
                imageView.removeFromSuperview()
            }
            
            tempBackgroundView.removeFromSuperview()
            
            self.removeFromSuperview()
            
            if let _ = self.lifeDelegate {
                
                self.lifeDelegate!.browserViewDidDismiss(self)
            }
        }
    }
    
    /// 普通方式退出
    private func normalDismiss() {
        
        preDismiss()
        
        let imageView = UIImageView()
        
        imageView.frame = self.bounds
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.image = self.jk.snapshot
        addSubview(imageView)
        
        collectionView.isHidden = true
        
        UIView.animate(withDuration: 0.25) {
            
            // TODO: - JKTODO <#注释#> 生硬
            
            imageView.alpha = 0.0
            //imageView.transform = CGAffineTransform(translationX: 0.0, y: imageView.bounds.height)//CGAffineTransform(scaleX: 1.5, y: 1.5)
            
            self.alpha = 0.0
            
        } completion: { _ in
            
            imageView.removeFromSuperview()
            self.removeFromSuperview()
            
            if let _ = self.lifeDelegate {
                
                self.lifeDelegate!.browserViewDidDismiss(self)
            }
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
        
        currentIndex = index
        currentPhotoItem = photoItemArray[currentIndex]
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
