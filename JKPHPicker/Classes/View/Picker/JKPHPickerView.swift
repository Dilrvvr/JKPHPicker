//
//  JKPHPickerView.swift
//  JKSwiftPhotoPicker
//
//  Created by AlbertCC on 2021/5/4.
//

import UIKit
import Photos
import JKSwiftLibrary

public protocol JKPHPickerViewDelegate: NSObjectProtocol {
    
    /// 所在控制器
    func pickerViewInViewController(_ pickerView: JKPHPickerView) -> UIViewController
    
    /// 选中某一item
    func pickerView(_ pickerView: JKPHPickerView,
                    didSelect photoItem: JKPHPickerPhotoItem)
    
    /// 退出picker
    func pickerViewDismiss(_ pickerView: JKPHPickerView)
    
    /// 退出预览
    func pickerViewDismissBrowser(_ pickerView: JKPHPickerView)
    
    /// 刷新预览
    func pickerViewReloadBrowser(_ pickerView: JKPHPickerView)
}

open class JKPHPickerView: JKPHPickerBaseView {
    
    // MARK:
    // MARK: - Public Property
    
    open weak var delegate: JKPHPickerViewDelegate?
    
    open private(set) var selectedPhotoItemArray = [JKPHPickerPhotoItem]()
    
    // MARK:
    // MARK: - Public Methods
    
    /// 方向即将改变
    open func viewOrientationWillChange() {
        
        if collectionView.indexPathsForVisibleItems.count <= 0 { return }
        
        let centerPoint = CGPoint(x: bounds.width * 0.5 + 2.0, y: bounds.height * 0.5)
        
        let convertPoint = convert(centerPoint, to: collectionView)
        
        previousOrientationIndexPath = collectionView.indexPathForItem(at: convertPoint)
    }
    
    /// 方向已经改变
    open func viewOrientationDidChange() {
        
        guard let indexPath = previousOrientationIndexPath else { return }
        
        previousOrientationIndexPath = nil
        
        if indexPath.item < 0 || indexPath.item >= photoItemDataArray.count { return }
        
        setNeedsLayout()
        layoutIfNeeded()
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.15) {
            
            self.collectionView.setNeedsLayout()
            self.collectionView.layoutIfNeeded()
            self.collectionView.reloadData()
            
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.1) {
                
                self.collectionView.scrollToItem(at: indexPath, at: .centeredVertically, animated: false)
            }
        }
    }
    
    // MARK:
    // MARK: - Override
    
    deinit {
        
        removePhotoLibraryObserver()
    }
    
    open override func didMoveToSuperview() {
        super.didMoveToSuperview()
        
        guard let _ = superview else { return }
        
        if !didFirstMoveToSuperView {
            
            didFirstMoveToSuperView = true
            
            sendRequest()
        }
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        
        updateLayout()
    }
    
    private func updateLayout() {
        
        contentView.jk_indicatorView.center = CGPoint(x: contentView.bounds.width * 0.5, y: contentView.bounds.height * 0.5)
        
        albumView.frame = CGRect(x: 0.0, y: JKNavigationBarHeight, width: bounds.width, height: bounds.height - JKNavigationBarHeight)
        
        limitTipView.frame = CGRect(x: 0.0, y: bottomControlView.frame.minY - 44.0, width: bounds.width, height: 44.0)
        limitJumpButton.frame = limitTipView.bounds
        
        let safeInset = JKSafeAreaInsets
        
        collectionView.frame = CGRect(x: safeInset.left, y: 0.0, width: bounds.width - safeInset.left - safeInset.right, height: bounds.height)
        
        var insetBottom = bottomControlView.bounds.height
        
        if !limitTipView.isHidden {
            
            insetBottom += limitTipView.bounds.height
        }
        
        collectionView.contentInset = UIEdgeInsets(top: navigationBarView.frame.maxY, left: 0.0, bottom: insetBottom, right: 0.0)
        collectionView.scrollIndicatorInsets = collectionView.contentInset
        
        layoutTitleView()
        
        updateCompleteButtonLayout()
    }
    
    private func layoutBottomControlViewUI() {
        
        let barContentView = bottomControlView.contentView
        
        var completeButtonSize = completeButton.sizeThatFits(CGSize(width: CGFloat.infinity, height: 44.0))
        completeButtonSize.width += 16.0
        completeButtonSize.width = max(56.0, completeButtonSize.width)
        completeButtonSize.height = min(barContentView.bounds.height - 6.0, 32.0)
        
        completeButton.frame = CGRect(x: barContentView.bounds.width - 15.0 - completeButtonSize.width, y: (barContentView.bounds.height - completeButtonSize.height) * 0.5, width: completeButtonSize.width, height: completeButtonSize.height)
        
        previewButton.frame = CGRect(x: 15.0, y: (barContentView.bounds.height - completeButtonSize.height) * 0.5, width: completeButtonSize.width, height: completeButtonSize.height)
    }
    
    private func updateCompleteButtonLayout() {
        
        // TODO: - JKTODO <#注释#>
        if let handler = bottomControlView.didLayoutSubviewsHandler {
            
            handler(bottomControlView)
        }
    }
    
    // MARK:
    // MARK: - Private Methods
    
    private var albumDataArray = [JKPHPickerAlbumItem]()
    
    private var albumListCache = [String : JKPHPickerAlbumItem]()
    
    private func selectFirstAlbum() {
        
        currentAlbum = nil
        
        guard let firstAlbum = albumDataArray.first else { return }
        
        firstAlbum.isSelected = true
        
        currentAlbum = firstAlbum
    }
    
    private func solveData(albumArray: [JKPHPickerAlbumItem],
                           albumCache: [String : JKPHPickerAlbumItem]) {
        
        albumDataArray = albumArray
        albumListCache = albumCache
        
        guard let previousAlbum = currentAlbum,
              let refreshAlbum = albumListCache[previousAlbum.localIdentifier] else {
                  
                  // 之前未选中 或 之前选中的相册已不存在/无法访问
                  
                  selectFirstAlbum()
                  
                  albumView.updateAlbumDataArray(albumDataArray)
                  
                  return
              }
        
        refreshAlbum.isSelected = true
        
        currentAlbum = refreshAlbum
        
        albumView.updateAlbumDataArray(albumDataArray)
    }
    
    private func sendRequest() {
        
        requestAlbumList()
    }
    
    private func requestAlbumList() {
        
        if isRequestingAlbum { return }
        
        isRequestingAlbum = true
        
        contentView.jk.startIndicatorLoading()
        
        // 获取相册列表
        JKPHPickerEngine.queryAllAlbumItem(with: configuration) { [weak self] (albumArray, albumCache) in
            
            guard let _ = self else { return }
            
            self?.isRequestingAlbum = false
            
            self?.contentView.jk.stopIndicatorLoading()
            
            if self!.isNeedReloadAlbum { // 需要刷新相册列表
                
                self?.isNeedReloadAlbum = false
                
                self?.reloadForPhotoLibraryDidChange()
                
                return
            }
            
            self?.solveData(albumArray: albumArray, albumCache: albumCache)
            
            guard let album = self?.currentAlbum else { return }
            
            self?.requestPhotoList(in: album)
        }
    }
    
    private func requestPhotoList(in album: JKPHPickerAlbumItem) {
        
        if isRequestingAlbum || isRequesting { return }
        
        isRequesting = true
        
        contentView.jk.startIndicatorLoading()
        
        JKPHPickerEngine.queryAllPhotoItem(in: currentAlbum!, seletedCache: selectedPhotoItemCache, configuration: configuration) { [weak self] dataArray, refreshSeletedCache, photoItemCache in
            
            guard let _ = self else { return }
            
            self?.isRequesting = false
            
            self?.contentView.jk.stopIndicatorLoading()
            
            if self!.isNeedReloadPhoto { // 需要刷新照片列表
                
                self?.isNeedReloadPhoto = false
                
                self?.reloadForPhotoLibraryDidChange()
                
                return
            }
            
            self?.solveData(dataArray: dataArray, refreshSeletedCache: refreshSeletedCache, photoItemCache: photoItemCache)
        }
    }
    
    private func solveData(dataArray: [JKPHPickerPhotoItem],
                           refreshSeletedCache: [String : JKPHPickerPhotoItem],
                           photoItemCache: [String : JKPHPickerPhotoItem]) {
        
        photoItemDataArray.removeAll()
        photoItemDataArray += dataArray
        
        photoItemListCache = photoItemCache
        
        updateSelectedCache(refreshSeletedCache)
        
        // TODO: - JKTODO <#注释#>
        
        collectionView.reloadData()
        
        if let _ = delegate {
            
            // 刷新浏览器
            delegate?.pickerViewReloadBrowser(self)
        }
        
        let itemCount = collectionView.numberOfItems(inSection: 0)
        
        if itemCount <= 0 { return }
        
        let indexPath = IndexPath(item: itemCount - 1, section: 0)
        
        collectionView.scrollToItem(at: indexPath, at: .bottom, animated: false)
    }
    
    private func updateSelectedCache(_ refreshSeletedCache: [String : JKPHPickerPhotoItem]) {
        
        var updatedArray = [JKPHPickerPhotoItem]()
        var updatedCache = [String : JKPHPickerPhotoItem]()
        
        // TODO: - JKTODO <#注释#>
        
        for item in selectedPhotoItemArray {
            
            var refreshItem: JKPHPickerPhotoItem
            
            if let cachedItem = photoItemListCache[item.localIdentifier] {
                
                refreshItem = cachedItem
                
            } else {
                
                refreshItem = item
            }
            
            refreshItem.isSelected = true
            refreshItem.isSelectable = true
            
            updatedArray.append(refreshItem)
            
            updatedCache[item.localIdentifier] = refreshItem
            
            refreshItem.selectIndex = (updatedArray.count - 1)
        }
        
        selectedPhotoItemArray = updatedArray
        selectedPhotoItemCache = updatedCache
        
        // TODO: - JKTODO <#注释#>
        updateBottomButtonUI()
        checkUpdateNextSelectTypes()
    }
    
    /// layoutTitleView
    private func layoutTitleView() {
        
        var contentViewY: CGFloat = JKStatusBarHeight
        
        if JKisLandscape && JKisDeviceiPhone { contentViewY = 0.0 }
        
        let titleHeight: CGFloat = JKNavigationBarHeight - contentViewY
        
        let titleLabelSize = titleLabel.sizeThatFits(CGSize(width: CGFloat.infinity, height: titleHeight))
        
        titleLabel.frame = CGRect(x: 0.0, y: 0.0, width: titleLabelSize.width + 2.0, height: titleHeight)
        
        let titleArrowImageWH: CGFloat = 18.0
        titleArrowImageView.frame = CGRect(x: titleLabel.frame.maxX + 5.0, y: (titleHeight - titleArrowImageWH) * 0.5, width: titleArrowImageWH, height: titleArrowImageWH)
        
        let titleViewCenter = titleView.center
        
        titleView.frame.size = CGSize(width: titleArrowImageView.frame.maxX, height: titleHeight)
        
        titleView.center = titleViewCenter
    }
    
    /// 检查更新下一次可选类型
    private func checkUpdateNextSelectTypes() {
        
        var firstSelectType: JKPHPickerMediaType?
        
        if let firstItem = selectedPhotoItemArray.first {
            
            firstSelectType = firstItem.mediaType
        }
        
        let currentTypes = configuration.nextSelectTypesWithFirstSelectedType(firstSelectType, selectedCount: selectedPhotoItemArray.count, videoSelectedCount: videoSelectedCount)
        
        guard let previousTypes = nextSelectTypes else {
            
            // 首次赋值
            
            nextSelectTypes = currentTypes
            
            return
        }
        
        nextSelectTypes = currentTypes
        
        guard previousTypes.count == currentTypes.count else {
            
            // 更新后数量不一致
            
            // 更新是否可选
            updateSelectable(nextSelectTypes: currentTypes)
            
            return
        }
        
        // 更新后数量一致，进行比对
        
        for index in 0..<currentTypes.count {
            
            let previousType = previousTypes[index]
            let currentType = currentTypes[index]
            
            // 有不一致的
            if previousType != currentType {
                
                // 更新是否可选
                updateSelectable(nextSelectTypes: currentTypes)
                
                return
            }
        }
    }
    
    /// 更新是否可选择
    private func updateSelectable(nextSelectTypes: JKPHPickerPickType) {
        
        for item in photoItemDataArray {
            
            if item.isSelected { continue }
            
            let isSelectable = item.isSelectable
            
            item.isSelectable = nextSelectTypes.contains(item.mediaType)
            
            if item.isSelectable == isSelectable { continue }
            
            item.reloadInPicker(isRequestImage: false)
        }
    }
    
    private func resetCompleteButtonUI() {
        
        completeButton.setTitle("完成", for: .normal)
        completeButton.isEnabled = false
        
        updateCompleteButtonLayout()
    }
    
    private func updateBottomButtonUI() {
        
        previewButton.isEnabled = (selectedPhotoItemArray.count > 0)
        
        if configuration.filter.totalMaxCount == 0 {
            
            resetCompleteButtonUI()
            
            return
        }
        
        guard let firstItem = selectedPhotoItemArray.first else {
            
            resetCompleteButtonUI()
            
            return
        }
        
        completeButton.isEnabled = (selectedPhotoItemArray.count > 0)
        
        var buttonTitle = "完成"
        
        if configuration.isSelectVideoSimultaneously { // 照片/视频可以同时选择
            
            if configuration.filter.totalMaxCount > 0 {
                
                buttonTitle += "(\(selectedPhotoItemArray.count)/\(configuration.filter.totalMaxCount))"
                
            } else {
                
                buttonTitle += "(\(selectedPhotoItemArray.count))"
            }
            
            completeButton.setTitle(buttonTitle, for: .normal)
            
            updateCompleteButtonLayout()
            
            return
        }
        
        if firstItem.mediaType == .video { // 仅可继续选择视频
            
            if configuration.filter.videoMaxCount == 0 {
                
                resetCompleteButtonUI()
                
                return
            }
            
            if configuration.filter.totalMaxCount > 0 {
                
                if configuration.filter.videoMaxCount > 0 {
                    
                    let maxCount = min(configuration.filter.videoMaxCount, configuration.filter.totalMaxCount)
                    
                    buttonTitle += "(\(selectedPhotoItemArray.count)/\(maxCount))"
                    
                } else {
                    
                    buttonTitle += "(\(selectedPhotoItemArray.count)/\(configuration.filter.totalMaxCount))"
                }
                
            } else {
                
                if configuration.filter.videoMaxCount > 0 {
                    
                    buttonTitle += "(\(selectedPhotoItemArray.count)/\(configuration.filter.videoMaxCount))"
                    
                } else {
                    
                    buttonTitle += "(\(selectedPhotoItemArray.count))"
                }
            }
            
        } else { // 仅可继续选择非视频
            
            if configuration.filter.totalMaxCount > 0 {
                
                buttonTitle += "(\(selectedPhotoItemArray.count)/\(configuration.filter.totalMaxCount))"
                
            } else {
                
                buttonTitle += "(\(selectedPhotoItemArray.count))"
            }
        }
        
        completeButton.setTitle(buttonTitle, for: .normal)
        
        updateCompleteButtonLayout()
    }
    
    private func removePhotoLibraryObserver() {
        
        if isPhotoLibraryObserverAdded {
            
            isPhotoLibraryObserverAdded = false
            
            PHPhotoLibrary.shared().unregisterChangeObserver(self)
        }
    }
    
    // MARK:
    // MARK: - Private Selector
    
    /// titleViewClick
    @objc private func titleClick(button: UIButton) {
        
        if albumView.isHidden {
            
            albumView.show()
            
            return
        }
        
        albumView.dismiss()
    }
    
    open override func originalImageButtonClick(button: UIButton) {
        
        isExportOriginalImage = !isExportOriginalImage
    }
    
    /// 预览已选
    @objc private func previewButtonClick(button: UIButton) {
        
        isPreviewSelected = true
        
        guard let firstItem = selectedPhotoItemArray.first else { return }
        
        delegate?.pickerView(self, didSelect: firstItem)
    }
    
    /// completeButtonClick
    @objc private func completeButtonClick(button: UIButton) {
        
        guard selectedPhotoItemArray.count > 0 else { return }
        
        removePhotoLibraryObserver()
        
        if let _ = delegate {
            
            delegate?.pickerViewDismiss(self)
        }
        
        // 加上缩略图，获取失败时可提供缩略图
        for item in selectedPhotoItemArray {
            
            if let image = configuration.thumbnailImageCache.object(forKey: NSString(string: item.localIdentifier)) {
                
                item.updateThumbnailImage(image)
            }
        }
        
        if let handler = configuration.resultHandler {
            
            handler(selectedPhotoItemArray)
        }
        
        // TODO: - JKTODO <#注释#>
        
        return;
        
        let selectedItemArray = selectedPhotoItemArray
        
        JKPHPickerEngine.exportVideoAVAsset(with: selectedItemArray) { resultArray in
            
            print(resultArray)
        }
        
        return;
        
        JKPHPickerEngine.exportLivePhoto(with: selectedItemArray, scale: 1.0) { resultArray in
            
            print(resultArray)
        }
        
        return;
        JKPHPickerEngine.exportImageData(with: selectedItemArray) { resultArray in
            
            for item in resultArray {
                
                if let data = item.imageData,
                   let image = UIImage(data: data) {
                    
                    print(image)
                }
            }
        }
        
        return;
        // 750 481
        JKPHPickerEngine.exportImage(with: selectedItemArray, scale: 1.0) { resultArray in
            
            print(resultArray)
        }
    }
    
    /// limitJumpButtonClick
    @objc private func limitJumpButtonClick(button: UIButton) {
        
        isTapLimitedItem = true
        
        if !configuration.isObservePhotoLibraryChange {
            
            NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive(note:)), name: UIApplication.didBecomeActiveNotification, object: nil)
        }
        
        JKAPPUtility.jumpToAppSetting()
    }
    
    @objc private func applicationDidBecomeActive(note: Notification) {
        
        NotificationCenter.default.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)
        
        isTapLimitedItem = false
        
        if configuration.isObservePhotoLibraryChange { return }
        
        sendRequest()
    }
    
    // MARK:
    // MARK: - Initialization & Build UI
    
    /// 初始化自身属性 交给子类重写 super自动调用该方法
    open override func initializeProperty() {
        super.initializeProperty()
        
    }
    
    /// 构造函数初始化时调用 注意调用super
    open override func initialization() {
        super.initialization()
        
        extraActionModelArray.removeAll()
        
        if configuration.isShowCameraItem {
            
            let cameraModel = JKPHPickerActionModel()
            cameraModel.reuseID = String(describing: JKPHPickerCameraCell.self)
            
            cameraModel.actionHandler = { model in
                
                // TODO: - JKTODO <#注释#>
            }
            
            extraActionModelArray.append(cameraModel)
        }
        
        JKAuthorization.checkPhotoLibraryAuthorization { [weak self] isNotDeterminedAtFirst, status in
            
            guard let _ = self else { return }
            
            self?.solvePhotoLibraryAuthorization(status: status)
        }
    }
    
    private func solvePhotoLibraryAuthorization(status: JKAuthorizationStatus) {
        
        limitTipView.isHidden = (status != .limited)
        
        guard ((status == .authorized) ||
               (status == .limited)) else {
            
            return
        }
        
        guard configuration.isObservePhotoLibraryChange else {
            
            if #available(iOS 15, *) {
                
                guard status == .limited else { return }
                
                // 未监听相册变化的情况下也可以由iOS15的新API刷新可访问照片的变化
                addLimitedModel()
            }
            
            return
        }
        
        if isPhotoLibraryObserverAdded { return }
        
        isPhotoLibraryObserverAdded = true
        
        PHPhotoLibrary.shared().register(self)
        
        if #available(iOS 14, *) {
            
            guard status == .limited else { return }
            
            addLimitedModel()
        }
    }
    
    private func addLimitedModel() {
        
        if #available(iOS 14, *) {
            
            let limitedModel = JKPHPickerActionModel()
            limitedModel.reuseID = String(describing: JKPHPickerAddMoreCell.self)
            
            limitedModel.actionHandler = { [weak self] model in
                
                guard let _ = self,
                      let _ = self?.delegate,
                      let vc = self?.delegate?.pickerViewInViewController(self!) else {
                    
                    return
                }
                
                if #available(iOS 15, *) {
                    
                    PHPhotoLibrary.shared().presentLimitedLibraryPicker(from: vc) { _ in
                        
                        guard let _ = self else { return }
                        
                        if self!.configuration.isObservePhotoLibraryChange {
                            
                            return
                        }
                        
                        self?.sendRequest()
                    }
                    
                } else {
                    
                    PHPhotoLibrary.shared().presentLimitedLibraryPicker(from: vc)
                }
            }
            
            extraActionModelArray.insert(limitedModel, at: 0)
            
            if isRequesting { return }
            
            collectionView.reloadData()
        }
    }
    
    /// 创建UI 交给子类重写 super自动调用该方法
    open override func createUI() {
        super.createUI()
        
        insertSubview(albumView, aboveSubview: navigationBarView)
        
        contentView.insertSubview(collectionView, at: 0)
        contentView.insertSubview(limitTipView, aboveSubview: collectionView)
        
        limitTipView.addSubview(limitJumpButton)
        
        bottomControlView.contentView.addSubview(previewButton)
        bottomControlView.contentView.addSubview(completeButton)
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
        
        navigationBarView.customTitleView = titleView
        
        if #available(iOS 13.0, *) {
            contentView.jk_indicatorView.overrideUserInterfaceStyle = .light
            contentView.jk_indicatorView.style = .medium
        } else {
            contentView.jk_indicatorView.style = .white
        }
        
        contentView.jk_indicatorView.color = .white
    }
    
    // MARK:
    // MARK: - Private Property
    
    private lazy var isTapLimitedItem = false
    
    private lazy var photoItemDataArray = [JKPHPickerPhotoItem]()
    
    private lazy var photoItemListCache = [String : JKPHPickerPhotoItem]()
    
    private lazy var extraActionModelArray = [JKPHPickerActionModel]()
    
    /// 是否预览选中的item
    private lazy var isPreviewSelected = false
    
    private var previewArrray: [JKPHPickerPhotoItem] {
        
        isPreviewSelected ? selectedPhotoItemArray : photoItemDataArray
    }
    
    private var nextSelectTypes: JKPHPickerPickType?
    
    private var isPhotoLibraryObserverAdded = false
    
    private var videoSelectedCount: Int = 0
    
    // TODO: - JKTODO <#注释#>
    private var isExportOriginalImage: Bool = false {
        didSet {
            originalImageButton.isSelected = isExportOriginalImage
            configuration.isExportOriginalImage = isExportOriginalImage
        }
    }
    
    private var selectedPhotoItemCache = [String : JKPHPickerPhotoItem]()
    
    private var didFirstMoveToSuperView = false
    
    private var previousOrientationIndexPath: IndexPath?
    
    private let titleArrowWH: CGFloat = 18.0
    
    private var currentAlbum: JKPHPickerAlbumItem? {
        didSet {
            titleLabel.text = currentAlbum?.albumTitle
            layoutTitleView()
        }
    }
    
    /// titleButton
    private lazy var titleView: UIButton = {
        
        let titleView = UIButton(type: .system)
        
        titleView.addSubview(titleLabel)
        titleView.addSubview(titleArrowImageView)
        
        titleView.addTarget(self, action: #selector(titleClick(button:)), for: .touchUpInside)
        
        return titleView
    }()
    
    /// titleLabel
    private lazy var titleLabel: UILabel = {
        
        let label = UILabel()
        
        label.font = UIFont.systemFont(ofSize: 17.0, weight: .medium)
        label.textColor = .white
        label.textAlignment = .left
        label.text = "照片"
        
        return label
    }()
    
    /// titleArrowImageView
    private lazy var titleArrowImageView: UIImageView = {
        
        let titleArrowImageView = UIImageView()
        
        titleArrowImageView.image = JKPHPickerResourceManager.image(named: "arrow_down_white")
        
        return titleArrowImageView
    }()
    
    /// 预览已选
    private lazy var previewButton: UIButton = {
        
        let previewButton = UIButton(type: .custom)
        
        previewButton.isEnabled = false
        previewButton.contentHorizontalAlignment = .left
        previewButton.titleLabel?.font = UIFont.systemFont(ofSize: 15.0)
        previewButton.setTitleColor(.white, for: .normal)
        previewButton.setTitleColor(UIColor.white.withAlphaComponent(0.5), for: .highlighted)
        previewButton.setTitleColor(UIColor.white.withAlphaComponent(0.4), for: .disabled)
        previewButton.setTitle("预览", for: .normal)
        
        previewButton.addTarget(self, action: #selector(previewButtonClick(button:)), for: .touchUpInside)
        
        return previewButton
    }()
    
    /// completeButton
    private lazy var completeButton: UIButton = {
        
        let completeButton = UIButton(type: .custom)
        
        completeButton.backgroundColor = UIColor.systemBlue
        completeButton.isEnabled = false
        completeButton.layer.cornerRadius = 3.0
        completeButton.titleLabel?.font = UIFont.systemFont(ofSize: 15.0)
        completeButton.setTitleColor(.white, for: .normal)
        completeButton.setTitleColor(UIColor.white.withAlphaComponent(0.5), for: .highlighted)
        completeButton.setTitleColor(UIColor.white.withAlphaComponent(0.4), for: .disabled)
        completeButton.setTitle("完成", for: .normal)
        
        completeButton.addTarget(self, action: #selector(completeButtonClick(button:)), for: .touchUpInside)
        
        return completeButton
    }()
    
    /// albumView
    private lazy var albumView: JKPHPickerAlbumView = {
        
        let albumView = JKPHPickerAlbumView(frame: CGRect(x: 0.0, y: JKNavigationBarHeight, width: bounds.width, height: bounds.height - JKNavigationBarHeight), configuration: self.configuration)
        
        albumView.delegate = self
        albumView.isHidden = true
        
        return albumView
    }()
    
    /// flowLayout
    private lazy var flowLayout: UICollectionViewFlowLayout = {
        
        let flowLayout = UICollectionViewFlowLayout()
        
        flowLayout.scrollDirection = .vertical
        flowLayout.minimumLineSpacing = 1.0
        flowLayout.minimumInteritemSpacing = 1.0
        
        return flowLayout
    }()
    
    /// contentView
    private lazy var collectionView: UICollectionView = {
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: self.flowLayout)
        
        collectionView.scrollsToTop = true
        collectionView.backgroundView = nil
        collectionView.backgroundColor = .clear
        collectionView.alwaysBounceVertical = true
        collectionView.showsHorizontalScrollIndicator = false
        
        if #available(iOS 11.0, *) {
            collectionView.contentInsetAdjustmentBehavior = .never
        }
        if #available(iOS 13.0, *) {
            collectionView.automaticallyAdjustsScrollIndicatorInsets = false
        }
        
        collectionView.register(JKPHPickerCell.self, forCellWithReuseIdentifier: String(describing: JKPHPickerCell.self))
        collectionView.register(JKPHPickerAddMoreCell.self, forCellWithReuseIdentifier: String(describing: JKPHPickerAddMoreCell.self))
        collectionView.register(JKPHPickerCameraCell.self, forCellWithReuseIdentifier: String(describing: JKPHPickerCameraCell.self))
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: String(describing: UICollectionViewCell.self))
        
        collectionView.dataSource = self
        collectionView.delegate = self
        
        return collectionView
    }()
    
    /// limitTipView
    private lazy var limitTipView: JKPHPickerBarView = {
        
        let limitTipView = JKPHPickerBarView(frame: CGRect(x: 0.0, y: 0.0, width: self.bounds.width, height: 44.0))
        
        limitTipView.isHidden = true
        limitTipView.backgroundEffectView.effect = UIBlurEffect(style: .dark)
        
        return limitTipView
    }()
    
    private lazy var limitJumpButton: UIButton = {
        
        let limitJumpButton = JKPHPickerButton(type: .custom)
        
        limitJumpButton.isHighlightedAlpha = true
        
        let limitTip = "当前仅可访问部分照片，建议允许访问「所有照片」"
        
        limitJumpButton.titleLabel?.font = UIFont.systemFont(ofSize: 13.0)
        limitJumpButton.titleLabel?.numberOfLines = 0
        limitJumpButton.setTitleColor(JKSameRGBColor(158.0), for: .normal)
        limitJumpButton.setTitle(limitTip, for: .normal)
        limitJumpButton.contentHorizontalAlignment = .left
        
        limitJumpButton.setImage(JKPHPickerResourceManager.image(named: "nav_go_gray"), for: .normal)
        
        limitJumpButton.customLayoutHandler = { button in
            
            guard let label = button.titleLabel,
                  let imageView = button.imageView else {
                      
                      return
                  }
            
            let leftRightInset: CGFloat = 15.0
            let margin: CGFloat = 10.0
            
            let imageViewSize = CGSize(width: 12.0, height: 12.0)
            imageView.frame.size = imageViewSize
            imageView.frame.origin.x = button.bounds.width - leftRightInset - imageView.bounds.width
            imageView.frame.origin.y = (button.bounds.height - imageViewSize.height) * 0.5
            
            label.frame = CGRect(x: leftRightInset, y: 0.0, width: imageView.frame.minX - margin - leftRightInset, height: button.bounds.height)
        }
        
        limitJumpButton.addTarget(self, action: #selector(limitJumpButtonClick(button:)), for: .touchUpInside)
        
        return limitJumpButton
    }()
    
    private var changeTimes = 0
    
    private var isNeedReloadAlbum = false
    
    private var isNeedReloadPhoto = false
    
    private var isRequesting = false
    
    private var isRequestingAlbum = false
    
    private var isDelayingReload = false
}

// MARK:
// MARK: - PHPhotoLibraryChangeObserver

extension JKPHPickerView: PHPhotoLibraryChangeObserver {
    
    public func photoLibraryDidChange(_ changeInstance: PHChange) {
        
        changeTimes += 1
        
        //JKPrint("photoLibraryDidChange-->\(changeTimes)")
        
        DispatchQueue.main.async { [weak self] in
            
            guard let _ = self else { return }
            
            self?.solvePhotoLibraryDidChange(changeInstance)
        }
    }
    
    /// 处理相册变更
    private func solvePhotoLibraryDidChange(_ changeInstance: PHChange) {
        
        // 正在等待延迟刷新
        if isDelayingReload { return }
        
        isDelayingReload = true
        
        // 延迟0.5s执行，防止频繁收到变动导致刷新频繁
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            
            guard let _ = self else { return }
            
            self?.isDelayingReload = false
            
            self?.delaySolvePhotoLibraryDidChange()
        }
    }
    
    /// 延迟刷新
    private func delaySolvePhotoLibraryDidChange() {
        
        if isRequestingAlbum { // 正在加载相册列表
            
            // 标记需要先刷新相册
            isNeedReloadAlbum = true
            
            return
        }
        
        if isRequesting { // 正在加载照片列表
            
            // 标记需要刷新
            isNeedReloadPhoto = true
            
            return
        }
        
        reloadForPhotoLibraryDidChange()
    }
    
    /// 因相册变更 执行刷新
    private func reloadForPhotoLibraryDidChange() {
        
        // 清除缓存
        configuration.previewImageCache.removeAllObjects()
        configuration.thumbnailImageCache.removeAllObjects()
        
        // 刷新所有数据
        sendRequest()
    }
}

// MARK:
// MARK: - UICollectionViewDataSource & UICollectionViewDelegate

extension JKPHPickerView: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    open func numberOfSections(in collectionView: UICollectionView) -> Int {
        
        return 1
    }
    
    open func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return photoItemDataArray.count + extraActionModelArray.count
    }
    
    open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let itemWH = (collectionView.bounds.width - CGFloat(JKPHPickerUtility.pickerColumnCount)) / CGFloat(JKPHPickerUtility.pickerColumnCount)
        
        let itemSize = CGSize(width: itemWH, height: itemWH)
        
        return itemSize
    }
    
    open func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if photoItemDataArray.count > indexPath.item {
            
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: JKPHPickerCell.self), for: indexPath)
            
            if (cell is JKPHPickerCell) {
                
                let realCell = cell as! JKPHPickerCell
                
                realCell.configuration = configuration
                realCell.thumbnailImageCache = configuration.thumbnailImageCache
                realCell.model = photoItemDataArray[indexPath.item]
                
                solveCellHandler(realCell)
            }
            
            return cell
        }
        
        let index = indexPath.item - photoItemDataArray.count
        
        guard index >= 0,
              index < extraActionModelArray.count else {
                  
                  let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: UICollectionViewCell.self), for: indexPath)
                  
                  return cell
              }
        
        let actionModel = extraActionModelArray[index]
        
        guard actionModel.reuseID.count > 0 else {
            
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: UICollectionViewCell.self), for: indexPath)
            
            return cell
        }
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: actionModel.reuseID, for: indexPath)
        
        return cell
    }
    
    private func solveCellHandler(_ cell: JKPHPickerCell) {
        
        cell.selectActionHandler = { [weak self] (model: JKPHPickerPhotoItem?, button: UIButton) in
            
            guard let _ = self, let _ = model else { return }
            
            self?.updatePhotoItemSelectStatus(model!)
        }
    }
    
    private func updatePhotoItemSelectStatus(_ photoItem: JKPHPickerPhotoItem) {
        
        checkUpdateSelectStatus(photoItem: photoItem)
        
        updateBottomButtonUI()
        
        checkUpdateNextSelectTypes()
    }
    
    private func executeUpdateSelectStatus(_ photoItem: JKPHPickerPhotoItem) {
        
        guard photoItemDataArray.contains(photoItem) else { return }
        
        let previousSelectCount: Int = selectedPhotoItemArray.count
        
        // 是否在选中数组中
        let isPreviousInSelectArray: Bool = selectedPhotoItemArray.contains(photoItem)
        
        // 在选中数组中的索引
        var previousIndexInSelectArray: Int = -1
        
        // 如果在选中数组中 先移除
        if isPreviousInSelectArray {
            
            guard let index = selectedPhotoItemArray.firstIndex(of: photoItem) else {
                
                return
            }
            
            previousIndexInSelectArray = index
            
            selectedPhotoItemArray.remove(at: index)
            
            selectedPhotoItemCache.removeValue(forKey: photoItem.localIdentifier)
        }
        
        if !photoItem.isSelected { // 选中
            
            if !photoItem.isSelectable { return }
            
//            if configuration.isSelectNone { return }
            
//            if selectedPhotoItemArray.count >= configuration.selectPhotoMaxCount {
//
//                // TODO: - JKTODO <#注释#>
//
//                return
//            }
        }
        
        photoItem.isSelected = !photoItem.isSelected
        
        if photoItem.isSelected { // 选中
            
            if photoItem.isVideo {
                
                videoSelectedCount += 1
            }
            
            selectedPhotoItemArray.append(photoItem)
            
            selectedPhotoItemCache[photoItem.localIdentifier] = photoItem
            
            // 之前不在选中数组中
            guard isPreviousInSelectArray else {
                
                photoItem.selectIndex = selectedPhotoItemArray.count - 1
                
                reloadPhotoItem(photoItem)
                
                return
            }
            
            // 之前在选中数组中，表示出错了，刷新一下整个选中数组吧
            refreshSelectedPhotoItemArray()
            
            return
        }
        
        // 取消选中
        
        if photoItem.isVideo {
            
            videoSelectedCount -= 1
        }
        
        // 清空选中顺序索引
        photoItem.selectIndex = JKPHPickerPhotoItem.defaultSelectIndex
        
        reloadPhotoItem(photoItem)
        
        // 之前不在选中数组中，表示出错了，刷新一下整个选中数组吧
        guard isPreviousInSelectArray else {
            
            refreshSelectedPhotoItemArray()
            
            return
        }
        
        // 取消的是最后一个，前面已经更新过，不再刷新整个选中数组
        if previousIndexInSelectArray >= 0 &&
            (previousIndexInSelectArray == previousSelectCount - 1) {
            
            return
        }
        
        // 取消的不是最后一个，需要刷新整个选中数组
        refreshSelectedPhotoItemArray()
    }
    
    private func refreshSelectedPhotoItemArray() {
        
        for (index, value) in selectedPhotoItemArray.enumerated() {
            
            if value.selectIndex == index { continue }
            
            value.selectIndex = index
            
            reloadPhotoItem(value)
        }
    }
    
    private func reloadPhotoItem(_ photoItem: JKPHPickerPhotoItem) {
        
        if let handler = photoItem.reloadPickerHandler {
            
            handler(photoItem, false)
            
        } else {
            
            collectionView.reloadItems(at: [photoItem.indexPath])
        }
    }
    
    open func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        isPreviewSelected = false
        
        guard let _ = delegate else { return }
        
        guard photoItemDataArray.count > indexPath.item else {
            
            let index = indexPath.item - photoItemDataArray.count
            
            guard index >= 0,
                  index < extraActionModelArray.count else {
                      
                      return
                  }
            
            let actionModel = extraActionModelArray[index]
            
            if let handler = actionModel.actionHandler {
                
                handler(actionModel)
            }
            
            return
        }
        
        let item = photoItemDataArray[indexPath.item]
        
        delegate?.pickerView(self, didSelect: item)
        
        
        // TODO: - JKTODO delete
        return;
        let arr = PHAssetResource.assetResources(for: item.asset)
        print("---------------------------------")
        for resource in arr {
            
            print(resource)
        }
        print("---------------------------------")
    }
}

// MARK:
// MARK: - JKPHPickerAlbumViewDelegate

extension JKPHPickerView: JKPHPickerAlbumViewDelegate {
    
    open func albumView(_ albumView: JKPHPickerAlbumView, didSelect album: JKPHPickerAlbumItem) {
        
        if isNeedReloadAlbum {
            
            isNeedReloadAlbum = false
            
            reloadForPhotoLibraryDidChange()
            
            return
        }
        
        if let previousAlbum = currentAlbum {
            
            // 选中了同一个
            if album == previousAlbum { return }
            
            previousAlbum.isSelected = false
            previousAlbum.callUpdateSelectStatusHandler()
        }
        
        album.isSelected = true
        album.callUpdateSelectStatusHandler()
        
        currentAlbum = album
        
        requestPhotoList(in: album)
    }
    
    open func albumViewWillShow(_ albumView: JKPHPickerAlbumView) {
        
        collectionView.scrollsToTop = false
        
        UIView.animate(withDuration: 0.25) {
            
            self.titleArrowImageView.transform = CGAffineTransform(rotationAngle: CGFloat.pi - 0.01)
        }
    }
    
    open func albumViewWillDismiss(_ albumView: JKPHPickerAlbumView) {
        
        collectionView.scrollsToTop = true
        
        UIView.animate(withDuration: 0.25) {
            
            self.titleArrowImageView.transform = CGAffineTransform.identity
        }
    }
}

// MARK:
// MARK: - JKPHPickerBrowserViewDataSource & JKPHPickerBrowserViewDelegate

extension JKPHPickerView: JKPHPickerBrowserViewDataSource, JKPHPickerBrowserViewDelegate {
    
    open func isPreviewSelectedItems(in browserView: JKPHPickerBrowserView) -> Bool {
        
        return isPreviewSelected
    }
    
    /// section数量
    open func numberOfSections(in browserView: JKPHPickerBrowserView) -> Int {
        
        return 1
    }
    
    /// 预览动画的起始位置
    open func browserView(_ browserView: JKPHPickerBrowserView, animationFromRectFor photoItem: JKPHPickerPhotoItem) -> CGRect {
        
        let fromSize = CGSize(width: 100.0, height: 100.0)
        
        let fromFrame = CGRect(x: (browserView.bounds.width - fromSize.width) * 0.5, y: (browserView.bounds.height - fromSize.height) * 0.5, width: fromSize.width, height: fromSize.height)
        
        guard photoItemDataArray.contains(photoItem),
              let index = photoItemDataArray.firstIndex(of: photoItem) else {
                  
                  return fromFrame
              }
        
        let indexPath = IndexPath(item: index, section: 0)
        
        guard let cell = collectionView.cellForItem(at: indexPath) else {
            
            return fromFrame
        }
        
        let convertRect = collectionView.convert(cell.frame, to: browserView)
        
        if convertRect.equalTo(.zero) {
            
            return fromFrame
        }
        
        return convertRect
    }
    
    /// 预览动画图片
    open func browserView(_ browserView: JKPHPickerBrowserView, thumbnailImageFor photoItem: JKPHPickerPhotoItem) -> UIImage? {
        
        var thumbnailImage: UIImage? = nil
        
        if let image = configuration.editedImageDict[photoItem.localIdentifier] {
            
            thumbnailImage = image
            
        } else if photoItemDataArray.contains(photoItem),
                  let cell = collectionView.cellForItem(at: photoItem.indexPath) as? JKPHPickerCell {
            
            thumbnailImage = cell.currentImage ?? JKPHPickerUtility.Placeholder.darkGray
            
        } else if let cachedImage = configuration.thumbnailImageCache.object(forKey: NSString(string: photoItem.localIdentifier)) {
            
            thumbnailImage = cachedImage
            
        } else {
            
            thumbnailImage = JKPHPickerUtility.Placeholder.darkGray
        }
        
        return thumbnailImage
    }
    
    /// 对应section的item数组
    open func browserView(_ browserView: JKPHPickerBrowserView, photoItemArrayIn section: Int) -> [JKPHPickerPhotoItem] {
        
        return previewArrray
    }
    
    /// item对应的索引
    open func browserView(_ browserView: JKPHPickerBrowserView, indexPathFor photoItem: JKPHPickerPhotoItem) -> IndexPath? {
        
        guard previewArrray.contains(photoItem),
              let index = previewArrray.firstIndex(of: photoItem) else {
                  
                  return nil
              }
        
        return IndexPath(item: index, section: 0)
    }
    
    /// 对应索引的item
    open func browserView(_ browserView: JKPHPickerBrowserView, photoItemAt indexPath: IndexPath) -> JKPHPickerPhotoItem? {
        
        guard indexPath.item >= 0,
              previewArrray.count > indexPath.item else {
                  
                  return nil
              }
        
        return previewArrray[indexPath.item]
    }
    
    /// dismiss动画的目标rect
    open func browserView(_ browserView: JKPHPickerBrowserView, dismissTargetRectFor photoItem: JKPHPickerPhotoItem) -> CGRect {
        
        guard let item = photoItemListCache[photoItem.localIdentifier],
              let layoutAttributes = collectionView.layoutAttributesForItem(at: item.indexPath) else {
                  
                  return .zero
              }
        
        let rect = collectionView.convert(layoutAttributes.frame, to: contentView)
        
        return rect
    }
    
    /// dismiss动画view所在的容器view 返回nil则将自己作为容器view
    open func browserView(_ browserView: JKPHPickerBrowserView, dismissContainerViewFor photoItem: JKPHPickerPhotoItem) -> UIView? {
        
        return contentView
    }
    
    /// 编辑了图片
    open func browserView(_ browserView: JKPHPickerBrowserView, didEdit photoItem: JKPHPickerPhotoItem) {
        
        guard let item = photoItemListCache[photoItem.localIdentifier] else { return }
        
        item.reloadInPicker(isRequestImage: true)
    }
    
    /// 点击选择按钮
    open func browserView(_ browserView: JKPHPickerBrowserView, didTapSelectButton button: UIButton, photoItem: JKPHPickerPhotoItem) {
        
        updatePhotoItemSelectStatus(photoItem)
    }
    
    /// 点击原图按钮
    open func browserView(_ browserView: JKPHPickerBrowserView, didTapOriginalImageButton button: UIButton, photoItem: JKPHPickerPhotoItem) {
        
        isExportOriginalImage = !isExportOriginalImage
        
        if photoItem.isSelected || !isExportOriginalImage { return }
        
        updatePhotoItemSelectStatus(photoItem)
    }
    
    /// 原图按钮是否应该选中
    open func browserViewShouldSelectOriginalImageOn(_ browserView: JKPHPickerBrowserView) -> Bool {
        
        return isExportOriginalImage
    }
    
    /// 即将退出
    open func browserViewWillDismiss(_ browserView: JKPHPickerBrowserView) {
        
        let cancelItemArray = previewArrray
        
        // TODO: - JKTODO 清空缓存/请求
        configuration.previewImageCache.removeAllObjects()
        
        JKPHPickerEngine.queue.async {
            
            // 取消所有预览图请求
            for item in cancelItemArray {
                
                guard let requestID = item.requestPreviewImageID else { continue }
                
                JKPHPickerEngine.cancelImageRequest(requestID)
            }
        }
    }
    
    private func checkUpdateSelectStatus(photoItem: JKPHPickerPhotoItem) {
        
        if let item = photoItemListCache[photoItem.localIdentifier] {
            
            if item == photoItem {
                
                executeUpdateSelectStatus(item)
                
                return
            }
            
            photoItem.isSelected = !photoItem.isSelected
            
            executeUpdateSelectStatus(item)
            
            return
        }
        
        photoItem.isSelected = !photoItem.isSelected
        
        if photoItem.isSelected {
            
            photoItem.selectIndex = selectedPhotoItemArray.count
            
            selectedPhotoItemArray.append(photoItem)
            selectedPhotoItemCache[photoItem.localIdentifier] = photoItem
            
            if photoItem.isVideo {
                
                videoSelectedCount += 1
            }
            
            return
        }
        
        guard let item = selectedPhotoItemCache[photoItem.localIdentifier],
              let index = selectedPhotoItemArray.firstIndex(of: item) else {
                  
                  return
              }
        
        if item.isVideo {
            
            videoSelectedCount -= 1
        }
        
        item.isSelected = false
        item.selectIndex = JKPHPickerPhotoItem.defaultSelectIndex
        
        selectedPhotoItemCache.removeValue(forKey: item.localIdentifier)
        selectedPhotoItemArray.remove(at: index)
        
        if index == selectedPhotoItemArray.count { return }
        
        refreshSelectedPhotoItemArray()
    }
}

// MARK:
// MARK: - JKPHPickerNavigationBarViewDelegate

extension JKPHPickerView {
    
    open override func navigationBarView(_ navigationBarView: JKPHPickerNavigationBarView, didTapClose button: UIButton) {
        
        if !albumView.isHidden {
            
            albumView.dismiss()
            
            return
        }
        
        super.navigationBarView(navigationBarView, didTapClose: button)
    }
}
