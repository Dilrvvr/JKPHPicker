//
//  JKPHPickerBrowserCell.swift
//  JKSwiftPhotoPicker
//
//  Created by AlbertCC on 2021/5/5.
//

import UIKit
import Photos
import PhotosUI
import AVKit
import WebKit
import JKSwiftLibrary

open class JKPHPickerBrowserCell: JKPHPickerBaseCollectionViewCell {
    
    private static var bottomControlHeight: CGFloat {
        
        49.0 + JKBottomSafeAreaInset
    }
    
    // MARK:
    // MARK: - Public Property
    
    open var playVideoHandler: ((_ photoItem: JKPHPickerPhotoItem, _ playerItem: AVPlayerItem) -> Void)?
    
    open var singleTapActionHandler: ((_ photoItem: JKPHPickerPhotoItem) -> Void)?
    
    open var slideToDismissHandler: ((_ photoItem: JKPHPickerPhotoItem, _ browserCell: JKPHPickerBrowserCell) -> Void)?
    
    open var slideBackgroundAlphaHandler: ((_ photoItem: JKPHPickerPhotoItem, _ slideAlpha: CGFloat, _ animated: Bool) -> Void)?
    
    open var panGestureDidBeganHandler: ((_ photoItem: JKPHPickerPhotoItem) -> Void)?
    
    open var panGestureDidEndHandler: ((_ photoItem: JKPHPickerPhotoItem) -> Void)?
    
    /// imageView
    open private(set) lazy var imageView: JKPHPickerUIImageView = {
        
        let imageView = JKPHPickerUIImageView()
        
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        imageView.isUserInteractionEnabled = true
        
        if #available(iOS 13.0, *) {
            imageView.jk_indicatorView.overrideUserInterfaceStyle = .light
            imageView.jk_indicatorView.style = .large
        } else {
            imageView.jk_indicatorView.style = .whiteLarge
        }
        
        imageView.jk_indicatorView.color = .lightGray
        
        return imageView
    }()
    
    open override var model: JKPHPickerPhotoItem? {
        
        willSet {
            
            errorLabel.isHidden = true
            
            previousImageViewSize = .zero
            
            if let item = model,
               let requestID = item.requestPreviewImageID {
                
                if (newValue == nil) || (newValue! != item) {
                    
                    JKPHPickerEngine.cancelImageRequest(requestID)
                    item.requestPreviewImageID = nil
                }
            }
            
            imageView.image = nil
            
            gifPlayView.isHidden = true
            livePhotoView.isHidden = true
            
            videoPlayButton.isUserInteractionEnabled = true
            updateVideoPlayButtonHidden(true, animated: false)
            
            stopPlayGif()
        }
        
        didSet {
            
            guard let item = model else { return }
            
            item.reloadBrowserHandler = { [weak self] (photoItem: JKPHPickerPhotoItem, isRequestImage: Bool) in
                
                guard let _ = self else { return }
                
                self?.reload(with: photoItem, isRequestImage: isRequestImage)
            }
            
            var isTouching = false
            
            if let pinchGesture = scrollView.pinchGestureRecognizer,
               pinchGesture.state == .changed {
                
                pinchGesture.state = .cancelled
                
                isTouching = true
            }
            
            if panGesture.state == .changed {
                
                panGesture.state = .cancelled
                
                isTouching = true
            }
            
            guard isTouching else {
                
                reload(with: item, isRequestImage: true)
                
                return
            }
            
            reload(with: item, isRequestImage: false)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
                
                guard let _ = self,
                      let md = self?.model,
                      item == md else {
                          
                          return
                      }
                
                self?.reload(with: item, isRequestImage: true)
            }
        }
    }
    
    // MARK:
    // MARK: - Public Methods
    
    private func reload(with photoItem: JKPHPickerPhotoItem, isRequestImage: Bool) {
        
        guard let item = model, item == photoItem else { return }
        
        panGesture.isEnabled = true
        
        singleTapGesture.isEnabled = true
        doubleTapGesture.isEnabled = true
        
        scrollView.setZoomScale(1.0, animated: false)
        
        scrollView.minimumZoomScale = JKPHPickerPhotoItem.minimumZoomScale
        scrollView.maximumZoomScale = photoItem.maximumZoomScale
        scrollView.contentOffset = .zero
        scrollView.contentSize = CGSize(width: photoItem.imageSize.width, height: photoItem.imageSize.height)
        
        updateVideoPlayButtonHidden(!photoItem.isVideo, animated: true)
        
        updateImageLayout()
        
        setNeedsLayout()
        layoutIfNeeded()
        
        if isRequestImage {
            
            startLoadImageRequest(photoItem: photoItem)
        }
        
        photoItem.playGifHandler = { [weak self] photoItem, isPlay in
            
            guard let _ = self, photoItem.mediaType == .gif else { return }
            
            self?.solvePlayGif(photoItem: photoItem, isPlay: isPlay)
        }
    }
    
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
        
        errorLabel.frame = CGRect(x: 15.0, y: 0.0, width: imageContainerView.bounds.width - 30.0, height: imageContainerView.bounds.height)
    }
    
    private func updateLayout() {
        
        containerView.frame = CGRect(x: JKPHPickerUtility.browserInset.left, y: 0.0, width: contentView.bounds.width - JKPHPickerUtility.browserInset.left - JKPHPickerUtility.browserInset.right, height: contentView.bounds.height)
        
        statusBarCoverView.frame = CGRect(x: 0.0, y: 0.0, width: containerView.bounds.width, height: JKStatusBarHeight)
        
        scrollView.frame = containerView.bounds
        
        videoPlayButton.frame = CGRect(x: (contentView.bounds.width - 52.0) * 0.5, y: (contentView.bounds.height - 52.0) * 0.5, width: 52.0, height: 52.0)
        
        guard let item = model else {
            
            previousImageViewSize = .zero
            
            return
        }
        
        if !previousImageViewSize.equalTo(.zero) &&
            previousImageViewSize.equalTo(item.imageSize) {
            
            return
        }
        
        previousImageViewSize = item.imageSize
        
        updateImageLayout()
        
        updateScrollViewContentInset()
    }
    
    private func updateImageLayout() {
        
        guard let photoItem = model else { return }
        
        let imageViewSize = photoItem.imageSize
        
        imageContainerView.frame = CGRect(x: 0.0, y: 0.0, width: imageViewSize.width, height: imageViewSize.height)
        
        imageView.frame = imageContainerView.bounds
        
        livePhotoView.frame = imageView.frame
        gifPlayView.frame = imageView.frame
    }
    
    // MARK:
    // MARK: - Private Methods
    
    private func solvePlayGif(photoItem: JKPHPickerPhotoItem, isPlay: Bool) {
        
        guard let item = model,
              item == photoItem,
              item.mediaType == .gif else {
                  
                  return
              }
        
        if isPlay {
            
            requestGif(photoItem: item)
            
            return
        }
        
        stopPlayGif()
    }
    
    private func stopPlayGif() {
        
        gifPlayView.loadHTMLString("", baseURL: nil)
        
        if let requestID = requestGifDataID {
            
            JKPHPickerEngine.cancelImageRequest(requestID)
        }
    }
    
    private func updateVideoPlayButtonHidden(_ isHidden: Bool, animated: Bool) {
        
        guard let item = model, item.mediaType == .video else {
            
            videoPlayButton.isHidden = true
            
            return
        }
        
        guard animated else {
            
            videoPlayButton.isHidden = isHidden
            
            return
        }
        
        var animations: (() -> Void)? = nil
        var completion: ((_ finished: Bool) -> Void)? = nil
        
        if isHidden {
            
            animations = {
                
                self.videoPlayButton.alpha = 0.0
            }
            
            completion = { _ in
                
                self.videoPlayButton.isHidden = true
                self.videoPlayButton.alpha = 1.0
            }
            
        } else {
            
            videoPlayButton.alpha = 0.0
            videoPlayButton.isHidden = false
            
            animations = {
                
                self.videoPlayButton.alpha = 1.0
            }
        }
        
        UIView.transition(with: videoPlayButton, duration: 0.25, options:.transitionCrossDissolve, animations: animations, completion: completion)
    }
    
    /// 加载图片
    private func startLoadImageRequest(photoItem: JKPHPickerPhotoItem) {
        
        requestImage(photoItem: photoItem)
        
        switch photoItem.mediaType {
            
        case .video: // 视频
            
            break
            
        case .gif: // gif
            
            break
            
        case .livePhoto: // livePhoto
            
            requestLivePhoto(photoItem: photoItem)
            
        default:
            break
        }
    }
    
    /// 加载图片
    private func requestImage(photoItem: JKPHPickerPhotoItem) {
        
        errorLabel.isHidden = true
        
        imageView.setPhotoPickerImage(with: photoItem, configuration: configuration, imageCache: previewImageCache, requestType: .preview) { [weak self] photoItem, image, info, error in
            
            guard let _ = self else { return }
            
            if let error = error {
                
                self?.errorLabel.text = error.localizedDescription
                self?.errorLabel.isHidden = false
                
                //JKPHPickerToastView.show(in: self, message: error.localizedDescription)
            }
            
            if let _ = image,
               let cache = self?.previewImageCache {
                
                cache.setObject(image!, forKey: NSString(string: photoItem.localIdentifier))
            }
            
            if let handler = photoItem.didLoadPreviewImageHandler {
                
                handler(image)
            }
        }
    }
    
    private lazy var errorLabel: UILabel = {
        
        let label = UILabel()
        
        label.font = UIFont.systemFont(ofSize: 15.0)
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 0
        
        return label
    }()
    
    /// 加载gif
    private func requestGif(photoItem: JKPHPickerPhotoItem) {
        
        if photoIdentifier.count > 0 {
            
            if photoIdentifier == photoItem.localIdentifier { // 标识一致
                
                // 判断是否正在请求中
                
                if let _ = requestGifDataID { // 正在请求中
                    
                    return
                }
                
            } else { // 标识不一致
                
                // 取消之前的请求
                if let requestID = requestGifDataID {
                    
                    JKPHPickerEngine.cancelImageRequest(requestID)
                    
                    requestGifDataID = nil
                }
            }
        }
        
        let requestID = JKPHPickerEngine.requestImageData(for: photoItem.asset, deliveryMode: .highQualityFormat) { [weak self] isCancelled, imageData, dataUTI, cgImageOrientation, imageOrientation, info in
            
            guard let _ = self else { return }
            
            if let requestID = self?.requestGifDataID,
               let realInfo = info,
               let resultID = realInfo[PHImageResultRequestIDKey] as? PHImageRequestID,
               requestID == resultID {
                
                self?.requestGifDataID = nil
            }
            
            if isCancelled { return }
            
            self?.solve(gifData: imageData, originalAsset: photoItem.asset)
        }
        
        requestGifDataID = requestID
    }
    
    /// 处理 gif data 结果
    private func solve(gifData: Data?, originalAsset: PHAsset) {
        
        guard let item = model, originalAsset == item.asset else { return }
        
        requestGifDataID = nil
        
        guard let _ = gifData else {
            
            stopPlayGif()
            
            return
        }
        
        gifPlayView.isHidden = false
        
        gifPlayView.load(gifData!, mimeType: "image/gif", characterEncodingName: "", baseURL: URL(fileURLWithPath: ""))
    }
    
    /// 加载livePhoto
    private func requestLivePhoto(photoItem: JKPHPickerPhotoItem) {
        
        if photoIdentifier.count > 0 {
            
            if photoIdentifier == photoItem.localIdentifier { // 标识一致
                
                // 判断是否正在请求中
                
                if let _ = requestLivePhotoID { // 正在请求中
                    
                    return
                }
                
            } else { // 标识不一致
                
                // 取消之前的请求
                if let requestID = requestLivePhotoID {
                    
                    JKPHPickerEngine.cancelImageRequest(requestID)
                    
                    requestLivePhotoID = nil
                }
            }
        }
        
        let requestID = JKPHPickerEngine.requestPreviewLivePhoto(for: photoItem.asset) { [weak self] isCancelled, livePhoto, info in
            
            guard let _ = self else { return }
            
            if let requestID = self?.requestLivePhotoID,
               let realInfo = info,
               let resultID = realInfo[PHImageResultRequestIDKey] as? PHImageRequestID,
               requestID == resultID {
                
                self?.requestLivePhotoID = nil
            }
            
            if isCancelled { return }
            
            self?.solve(livePhoto: livePhoto, originalAsset: photoItem.asset)
        }
        
        requestLivePhotoID = requestID
    }
    
    /// 处理livePhoto结果
    private func solve(livePhoto: PHLivePhoto?, originalAsset: PHAsset) {
        
        guard let item = model, originalAsset == item.asset else { return }
        
        requestLivePhotoID = nil
        
        guard let _ = livePhoto else {
            
            livePhotoView.isHidden = true
            livePhotoView.livePhoto = nil
            
            return
        }
        
        livePhotoView.isHidden = false
        livePhotoView.livePhoto = livePhoto
    }
    
    private func solveRequestError(info: [AnyHashable: Any]?) {
        
        guard let _ = info, let error = info![PHImageErrorKey] as? Error else {
            
            return
        }
        
        JKPHPickerToastView.show(in: self, message: error.localizedDescription)
    }
    
    private func updateScrollViewContentInset() {
        
        var leftRight: CGFloat = (scrollView.frame.width - imageContainerView.frame.width) * 0.5
        var topBottom: CGFloat = (scrollView.frame.height - imageContainerView.frame.height) * 0.5
        
        //let contentSizeWidth = leftRight >= 0.0 ? 0.0 : imageContainerView.frame.width
        //let contentSizeHeight = topBottom >= 0.0 ? 0.0 : imageContainerView.frame.height
        
        leftRight = max(0.0, leftRight)
        topBottom = max(0.0, topBottom)
        
        scrollView.contentInset = UIEdgeInsets(top: topBottom, left: leftRight, bottom: topBottom, right: leftRight)
        
        //scrollView.contentSize = CGSize(width: contentSizeWidth, height: contentSizeHeight)
    }
    
    private func revertImageViewCenter() {
        
        UIView.animate(withDuration: 0.25) {
            
            self.imageContainerView.center = self.imageContainerOriginalCenter
            
        } completion: { _ in
            
            self.updateVideoPlayButtonHidden(false, animated: true)
        }
    }
    
    // MARK:
    // MARK: - Private Selector
    
    /// videoPlayButtonClick
    @objc private func videoPlayButtonClick(button: UIButton) {
        
        guard let item = model, item.mediaType == .video else { return }
        
        // TODO: - JKTODO <#注释#>
        
        if photoIdentifier.count > 0 {
            
            if photoIdentifier == item.localIdentifier { // 标识一致
                
                // 判断是否正在请求中
                
                if let _ = requestPlayerItemID { // 正在请求中
                    
                    return
                }
                
            } else { // 标识不一致
                
                // 取消之前的请求
                if let requestID = requestPlayerItemID {
                    
                    JKPHPickerEngine.cancelImageRequest(requestID)
                    
                    requestPlayerItemID = nil
                }
            }
        }
        
        videoPlayButton.isUserInteractionEnabled = false
        
        if let requestID = requestPlayerItemID {
            
            // 取消之前的请求
            JKPHPickerEngine.cancelImageRequest(requestID)
        }
        
        let videoPlayWrapper = videoPlayButton.jk
        videoPlayWrapper.relayoutIndicatorViewToCenter()
        videoPlayWrapper.startIndicatorLoading()
        
        let requestID = JKPHPickerEngine.requestPlayerItem(for: item.asset, deliveryMode: .highQualityFormat) { [weak self] isCancelled, playerItem, info in
            
            guard let _ = self else { return }
            
            if let requestID = self?.requestPlayerItemID,
               let realInfo = info,
               let resultID = realInfo[PHImageResultRequestIDKey] as? PHImageRequestID,
               requestID == resultID {
                
                self?.requestPlayerItemID = nil
            }
            
            if isCancelled { return }
            
            videoPlayWrapper.stopIndicatorLoading()
            
            self?.solvePlayerItem(playerItem: playerItem, info: info, originalAsset: item.asset)
            
            self?.videoPlayButton.isUserInteractionEnabled = true
        }
        
        requestPlayerItemID = requestID
    }
    
    private func solvePlayerItem(playerItem: AVPlayerItem?,
                                 info: [AnyHashable : Any]?,
                                 originalAsset: PHAsset) {
        
        guard let item = model, originalAsset == item.asset else { return }
        
        requestPlayerItemID = nil
        
        solveRequestError(info: info)
        
        if let _ = playerItem,
           let handler = playVideoHandler{
            
            handler(model!, playerItem!)
        }
    }
    
    @objc private func panGestureAction(gesture: UIPanGestureRecognizer) {
        
        switch gesture.state {
            
        case .began:
            
            updateVideoPlayButtonHidden(true, animated: true)
            
            if let _ = panGestureDidBeganHandler,
               let _ = model {
                
                panGestureDidBeganHandler!(model!)
            }
            
            imageContainerOriginalCenter = imageContainerView.center
            
            statusBarCoverView.isUserInteractionEnabled = false
            
            singleTapGesture.isEnabled = false
            doubleTapGesture.isEnabled = false
            
            scrollView.isScrollEnabled = false
            
        case .changed:
            
            let translation = gesture.translation(in: gesture.view)
            
            var distance = imageContainerView.center.y - imageContainerOriginalCenter.y
            
            distance = distance >= 0.0 ? distance : -distance
            
            distance = min(alphaZeroDistance, distance)
            
            slideAlpha = (alphaZeroDistance - distance) / alphaZeroDistance
            
            if let _ = slideBackgroundAlphaHandler,
               let _ = model {
                
                slideBackgroundAlphaHandler!(model!, slideAlpha, false)
            }
            
            imageContainerView.center = CGPoint(x: imageContainerView.center.x, y: imageContainerView.center.y + translation.y)
            
            gesture.setTranslation(.zero, in: gesture.view)
            
        case .cancelled:
            
            singleTapGesture.isEnabled = true
            doubleTapGesture.isEnabled = true
            
            scrollView.isScrollEnabled = true
            
            slideAlpha = 1.0
            
            slideBackgroundAlphaHandler!(model!, slideAlpha, true)
            
            revertImageViewCenter()
            
            if let _ = panGestureDidEndHandler {
                panGestureDidEndHandler!(model!)
            }
            
        default:
            
            singleTapGesture.isEnabled = true
            doubleTapGesture.isEnabled = true
            
            scrollView.isScrollEnabled = true
            
            let velocity = gesture.velocity(in: gesture.view)
            
            let sum: Float = Float((velocity.x * velocity.x) + (velocity.y * velocity.y))
            
            let magnitude: CGFloat = CGFloat(sqrtf(sum))
            
            let slideMult: CGFloat = magnitude / 200.0
            
            let slideFactor: CGFloat = slideMult * 0.8
            
            let finalCenterY: CGFloat = imageContainerView.center.y + (velocity.x * slideFactor)
            
            var distance = finalCenterY - imageContainerOriginalCenter.y
            
            distance = distance >= 0 ? distance : -distance
            
            guard let _ = slideToDismissHandler,
                  let _ = model else {
                      
                      revertImageViewCenter()
                      
                      return
                  }
            
            if distance >= dismissDistance { // 距离达到dismiss距离
                
                // 执行dismiss
                slideToDismissHandler!(model!, self)
                
            } else { // 距离未达到dismiss距离
                
                // 还原
                
                slideAlpha = 1.0
                
                slideBackgroundAlphaHandler!(model!, slideAlpha, true)
                
                revertImageViewCenter()
                
                if let _ = panGestureDidEndHandler {
                    panGestureDidEndHandler!(model!)
                }
            }
        }
    }
    
    /// 单击状态栏位置
    @objc private func singleTapStatusBarLocationAction(gesture: UITapGestureRecognizer) {
        
        scrollView.setContentOffset(CGPoint(x: scrollView.contentOffset.x, y: -scrollView.contentInset.top), animated: true)
    }
    
    /// 单击
    @objc private func singleTapAction(gesture: UITapGestureRecognizer) {
        
        guard let _ = model else { return }
        
        if let _ = singleTapActionHandler {
            
            singleTapActionHandler!(model!)
        }
    }
    
    /// 双击
    @objc private func doubleTapAction(gesture: UITapGestureRecognizer) {
        
        let location: CGPoint = gesture.location(in: gesture.view)
        
        let point = imageContainerView.convert(location, from: gesture.view)
        
        // 双击缩小
        if (scrollView.zoomScale > 1.0) {
            
            scrollView.setZoomScale(1.0, animated: true)
            
            return
        }
        
        // 双击放大
        let maxZoomScale = scrollView.maximumZoomScale
        
        let rect: CGRect = CGRect(x: point.x - 5.0, y: point.y - 5.0, width: 10.0, height: 10.0)
        
        scrollView.maximumZoomScale = JKPHPickerPhotoItem.firstZoomScale
        
        scrollView.zoom(to: rect, animated: true)
        
        scrollView.maximumZoomScale = maxZoomScale
    }
    
    // MARK:
    // MARK: - Custom Delegates
    
    
    
    // MARK:
    // MARK: - Initialization & Build UI
    
    /// 初始化自身属性 交给子类重写 super自动调用该方法
    open func initializeProperty() {
        
    }
    
    /// 构造函数初始化时调用 注意调用super
    open func initialization() {
        
        initializeProperty()
        createUI()
        layoutUI()
        initializeUIData()
        
        singleTapGesture.require(toFail: doubleTapGesture)
        
        containerView.addGestureRecognizer(panGesture)
        containerView.addGestureRecognizer(singleTapGesture)
        containerView.addGestureRecognizer(doubleTapGesture)
    }
    
    /// 创建UI 交给子类重写 super自动调用该方法
    open func createUI() {
        
        contentView.insertSubview(containerView, at: 0)
        contentView.addSubview(videoPlayButton)
        
        containerView.addSubview(scrollView)
        containerView.addSubview(statusBarCoverView)
        
        scrollView.addSubview(imageContainerView)
        
        imageContainerView.addSubview(imageView)
        imageContainerView.addSubview(livePhotoView)
        imageContainerView.addSubview(gifPlayView)
        imageContainerView.addSubview(errorLabel)
    }
    
    /// 布局UI 交给子类重写 super自动调用该方法
    open func layoutUI() {
        
    }
    
    /// 初始化UI数据 交给子类重写 super自动调用该方法
    open func initializeUIData() {
        
    }
    
    // MARK:
    // MARK: - Private Property
    
    open var previousImageViewSize: CGSize = .zero
    
    private var imageContainerOriginalCenter: CGPoint = .zero
    
    private var dismissDistance: CGFloat = 200.0
    private var alphaZeroDistance: CGFloat = 320.0
    
    private var slideAlpha: CGFloat = 1.0
    
    private var requestPlayerItemID: PHImageRequestID?
    
    private var requestLivePhotoID: PHImageRequestID?
    
    private var requestGifDataID: PHImageRequestID?
    
    /// singleTapGesture
    private lazy var singleTapGesture: UITapGestureRecognizer = {
        
        let singleTapGesture = UITapGestureRecognizer(target: self, action: #selector(singleTapAction(gesture:)))
        
        singleTapGesture.numberOfTouchesRequired = 1
        singleTapGesture.numberOfTapsRequired = 1
        
        return singleTapGesture
    }()
    
    /// doubleTapGesture
    private lazy var doubleTapGesture: UITapGestureRecognizer = {
        
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(doubleTapAction(gesture:)))
        
        doubleTapGesture.numberOfTouchesRequired = 1
        doubleTapGesture.numberOfTapsRequired = 2
        
        return doubleTapGesture
    }()
    
    private lazy var panGesture: UIPanGestureRecognizer = {
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(panGestureAction(gesture:)))
        
        panGesture.maximumNumberOfTouches = 1
        panGesture.delegate = self
        
        return panGesture
    }()
    
    /// containerView
    private lazy var containerView: UIView = {
        
        let containerView = UIView()
        
        return containerView
    }()
    
    /// scrollView
    private lazy var scrollView: UIScrollView = {
        
        let scrollView = UIScrollView()
        
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        
        if #available(iOS 11.0, *) {
            
            scrollView.contentInsetAdjustmentBehavior = .never
        }
        
        if #available(iOS 13.0, *) {
            
            scrollView.automaticallyAdjustsScrollIndicatorInsets = false
        }
        
        scrollView.delegate = self
        
        return scrollView
    }()
    
    private lazy var livePhotoView: PHLivePhotoView = {
        
        let livePhotoView = PHLivePhotoView()
        
        livePhotoView.isHidden = true
        
        return livePhotoView
    }()
    
    private lazy var gifPlayView: WKWebView = {
        
        let jsString = "var meta = document.createElement('meta'); meta.setAttribute('name', 'viewport'); meta.setAttribute('content', 'width=device-width'); document.getElementsByTagName('head')[0].appendChild(meta); var imgs = document.getElementsByTagName('img');for (var i in imgs){imgs[i].style.width='100%';imgs[i].style.height='100%';}"
        //let jsString = "var imgs = document.getElementsByTagName('img');for (var i in imgs){imgs[i].style.width='100%';}"
        
        let userScript = WKUserScript(source: jsString, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        let userContentController = WKUserContentController()
        userContentController.addUserScript(userScript)
        
        let configuration = WKWebViewConfiguration()
        configuration.userContentController = userContentController
        
        let preferences = WKPreferences()
        preferences.javaScriptEnabled = true
        preferences.javaScriptCanOpenWindowsAutomatically = true
        configuration.preferences = preferences
        
        let gifPlayView = WKWebView(frame: .zero, configuration: configuration)
        
        gifPlayView.isHidden = true
        gifPlayView.isOpaque = false
        gifPlayView.backgroundColor = nil
        gifPlayView.isUserInteractionEnabled = false
        gifPlayView.scrollView.isScrollEnabled = false
        gifPlayView.scrollView.showsVerticalScrollIndicator = false
        gifPlayView.scrollView.showsHorizontalScrollIndicator = false
        if #available(iOS 11.0, *) {
            gifPlayView.scrollView.contentInsetAdjustmentBehavior = .never
        }
        if #available(iOS 13.0, *) {
            gifPlayView.scrollView.automaticallyAdjustsScrollIndicatorInsets = false
        }
        
        return gifPlayView
    }()
    
    private lazy var videoPlayButton: UIButton = {
        
        let button = UIButton(type: .custom)
        
        button.isHidden = true
        button.layer.backgroundColor = UIColor.black.withAlphaComponent(0.4).cgColor
        button.layer.cornerRadius = 26.0
        button.setBackgroundImage(JKPHPickerResourceManager.image(named: "video_play"), for: .normal)
        
        if #available(iOS 13.0, *) {
            button.jk_indicatorView.overrideUserInterfaceStyle = .light
            button.jk_indicatorView.style = .medium
        } else {
            button.jk_indicatorView.style = .gray
        }
        
        button.jk_indicatorView.color = .darkGray
        
        button.addTarget(self, action: #selector(videoPlayButtonClick(button:)), for: .touchUpInside)
        
        return button
    }()
    
    /// imageContainerView
    private lazy var imageContainerView: UIView = {
        
        let view = UIView()
        
        return view
    }()
    
    /// statusBarCoverView
    private lazy var statusBarCoverView: UIView = {
        
        let statusBarCoverView = UIView()
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(singleTapStatusBarLocationAction(gesture:)))
        
        statusBarCoverView.addGestureRecognizer(tapGesture)
        
        return statusBarCoverView
    }()
}

// MARK:
// MARK: - UIScrollViewDelegate

extension JKPHPickerBrowserCell: UIScrollViewDelegate {
    
    open func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        
        print("scrollViewWillBeginDragging")
    }
    
    open func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        
        panGesture.isEnabled = false
    }
    
    open func scrollViewDidZoom(_ scrollView: UIScrollView) {
        
        print("scrollViewDidZoom")
        
        updateScrollViewContentInset()
    }
    
    open func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        
        print("scrollViewDidEndZooming")
        
        UIView.animate(withDuration: 0.25) {
            
            self.updateScrollViewContentInset()
            
        } completion: { _ in
            
        }
        
        panGesture.isEnabled = imageContainerView.frame.height <= scrollView.bounds.height
    }
    
    open func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        
        return imageContainerView
    }
}

// MARK:
// MARK: - UIGestureRecognizerDelegate

///*
extension JKPHPickerBrowserCell: UIGestureRecognizerDelegate {
    
    open func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        
        if otherGestureRecognizer == scrollView.pinchGestureRecognizer { return false }
        
        if otherGestureRecognizer.isKind(of: UIPanGestureRecognizer.self) &&
            otherGestureRecognizer != scrollView.panGestureRecognizer{
            
            return false
        }
        
        return true
    }
    
    open override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        
        guard gestureRecognizer is UIPanGestureRecognizer else { return true }
        
        let gesture = gestureRecognizer as! UIPanGestureRecognizer
        
        let velocity = gesture.velocity(in: gesture.view)
        
        if fabsf(Float(velocity.x)) >= fabsf(Float(velocity.y)) {
            
            return false
        }
        
        return true
    }
}
