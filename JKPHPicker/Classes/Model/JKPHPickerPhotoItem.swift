//
//  JKPHPickerPhotoItem.swift
//  JKSwiftPhotoPicker
//
//  Created by AlbertCC on 2021/5/4.
//

import UIKit
import Photos
import JKSwiftLibrary

open class JKPHPickerPhotoItem: NSObject {
    
    /// 选中顺序的默认索引 -1表示未选中
    public static let defaultSelectIndex: Int = -1
    
    /// 缩放的最小比例
    public static let minimumZoomScale: CGFloat = 1.0
    
    /// 首次缩放比例
    public static let firstZoomScale: CGFloat = 2.0
    
    // MARK:
    // MARK: - Init Function
    
    /// PHAsset
    open private(set) var asset: PHAsset
    
    /// 本地标识
    open private(set) var localIdentifier: String
    
    /// 视频时长
    open private(set) var duration: TimeInterval
    
    /// 索引
    open private(set) var indexPath: IndexPath
    
    /// 初始化
    public init(asset: PHAsset, indexPath: IndexPath) {
        
        self.asset = asset
        self.localIdentifier = asset.localIdentifier
        self.duration = asset.duration
        self.indexPath = indexPath
        
        super.init()
        
        checkAsset()
    }
    
    // MARK:
    // MARK: - Public Property
    
    /// 浏览时加载失败的错误信息
    open var browserErrorMessage: String?
    
    /// 仅选中的有值
    open private(set) var thumbnailImage: UIImage?
    
    /// 是否选中
    open var isSelected = false
    
    /// 是否可以选中
    open var isSelectable = true
    
    /// 选中顺序的索引 从0开始 -1表示未选中
    open var selectIndex: Int = JKPHPickerPhotoItem.defaultSelectIndex
    
    /// 请求预览图的ID
    open var requestPreviewImageID: PHImageRequestID?
    
    /// 请求缩略图的ID
    open var requestThumbnailImageID: PHImageRequestID?
    
    /// picker中刷新回调
    open var reloadPickerHandler: ((_ photoItem: JKPHPickerPhotoItem, _ isRequestImage: Bool) -> Void)?
    
    /// browser中刷新回调
    open var reloadBrowserHandler: ((_ photoItem: JKPHPickerPhotoItem, _ isRequestImage: Bool) -> Void)?
    
    /// 预览图加载完成回调
    open var didLoadPreviewImageHandler: ((_ image: UIImage?) -> Void)?
    
    /// 处理gif播放
    open var playGifHandler: ((_ photoItem: JKPHPickerPhotoItem,_ isPlay: Bool) -> Void)?
    
    /// 编辑图片
    open var editImageHandler: ((_ item: JKPHPickerPhotoItem) -> Void)?
    
    /// 编辑后的图片size
    open var editedImageSize: CGSize = .zero
    
    open var pixelSize: CGSize {
        
        var pixelSize = CGSize(width: CGFloat(asset.pixelWidth), height: CGFloat(asset.pixelHeight))
        
        if editedImageSize.width > 0.0 && editedImageSize.height > 0.0 {
            
            pixelSize = editedImageSize
        }
        
        return pixelSize
    }
    
    /// 最大缩放比例
    open var maximumZoomScale: CGFloat {
        
        if imageSize.width <= 0.0 {
            
            return Self.firstZoomScale
        }
        
        let scale = pixelSize.width / imageSize.width * 2.0
        
        return max(scale, Self.firstZoomScale)
    }
    
    // MARK:
    // MARK: - Basic Property
    
    /// 媒体类型
    open private(set) var mediaType: JKPHPickerMediaType = .image
    
    /// 媒体类型展示名称
    open private(set) var mediaTypeDisplayName: String?
    
    /// 是否在iCloud
    open private(set) var isIniCloud = false
    
    /// 文件名称
    open private(set) var fileName: String = ""
    
    /// 是否视频
    open var isVideo: Bool { mediaType == .video }
    
    /// 是否gif
    open var isGif: Bool { mediaType == .gif }
    
    /// 是否livePhoto
    open var isLivePhoto: Bool { mediaType == .livePhoto }
    
    /// 图片尺寸
    open var imageSize: CGSize {
        
        let imageViewSize = JKPHPickerUtility.calculateBrowserImageSize(pixelSize, maxSize: JKKeyWindow.bounds.size)
        
        return imageViewSize
    }
    
    // 创建日期时间 yyyy-MM-dd HH:mm:ss
    open private(set) lazy var createDateNormalString: String = {
        
        JKStringFromDateNormal(date: asset.creationDate)
    }()
    
    // 创建日期 yyyy-MM-dd
    open private(set) lazy var createDateDayString: String = {
        
        JKStringFromDate_yyyyMMdd_horizontal_line(date: asset.creationDate)
    }()
    
    // 创建时间 HH:mm:ss
    open private(set) lazy var createTimeString: String = {
        
        JKStringFromDate_HHmmss_colon(date: asset.creationDate)
    }()
    
    /// 视频时长 00:00 or 00:00:00
    open private(set) lazy var durationString: String = {
        
        self.updateDurationString()
    }()
    
    // MARK:
    // MARK: - Public Function
    
    /// 与另一个item同步
    open func synchronize(with photoItem: JKPHPickerPhotoItem) {
        
        isSelected = photoItem.isSelected
        isSelectable = photoItem.isSelectable
        selectIndex = photoItem.selectIndex
    }
    
    /// 更新缩略图 未选中的不更新
    open func updateThumbnailImage(_ image: UIImage?) {
        
        thumbnailImage = isSelected ? image : nil
    }
    
    /// 检查播放gif
    open func checkPlayGif(isPlay: Bool) {
        
        guard mediaType == .gif else { return }
        
        if let handler = playGifHandler {
            
            handler(self, isPlay)
        }
    }
    
    /// 在picker中刷新
    open func reloadInPicker(isRequestImage: Bool) {
        
        if let handler = reloadPickerHandler {
            
            handler(self, isRequestImage)
        }
    }
    
    /// 在browser中刷新
    open func reloadInBrowser(isRequestImage: Bool) {
        
        if let handler = reloadBrowserHandler {
            
            handler(self, isRequestImage)
        }
    }
    
    /// 执行编辑操作
    open func callEditImageHandler() {
        
        if let handler = editImageHandler {
            
            handler(self)
        }
    }
    
    /// 预览图加载完成
    open func previewImageDidLoad(_ image: UIImage?) {
        
        if let handler = didLoadPreviewImageHandler {
            
            handler(image)
            
            didLoadPreviewImageHandler = nil
        }
    }
    
    // MARK:
    // MARK: - Private Function
    
    /// 根据asset获取其它基础属性
    private func checkAsset() {
        
        if let name = asset.value(forKeyPath: "filename") as? String {
            
            fileName = name
        }
        
        if let isCloud = asset.value(forKeyPath: "isCloudPlaceholder") as? Bool,
           isCloud {
            
            isIniCloud = isCloud
        }
        
        switch asset.mediaType {
            
        case .image:
            
            mediaType = .image
            
            checkMediaType()
            
        case .video:
            
            mediaType = .video
            mediaTypeDisplayName = "Video"
            
        default:
            
            checkMediaType()
        }
    }
    
    /// 检查媒体类型
    private func checkMediaType() {
        
        if asset.mediaSubtypes.contains(.photoLive) {
            
            mediaType = .livePhoto
            mediaTypeDisplayName = "Live"
            
        } else {
            
            let suffix = NSString(string: fileName).pathExtension.lowercased()
            
            if suffix == "gif" {
                
                mediaType = .gif
                mediaTypeDisplayName = "Gif"
            }
        }
    }
    
    // MARK:
    // MARK: - 视频时长
    
    /// 计算视频时长
    private func updateDurationString() -> String {
        
        if !isVideo { return "" }
        
        var floorHour: TimeInterval = floor(duration / 3600.0)
        
        var leftSconds: TimeInterval = duration - floorHour * 3600.0
        
        var floorMinute: TimeInterval = floor(leftSconds / 60.0)
        
        leftSconds -= (floorMinute * 60.0)
        
        var secondInt: Int = Int(round(leftSconds))
        
        if secondInt >= 60 {
            
            secondInt -= 60
            
            floorMinute += 1.0
        }
        
        if floorMinute >= 60.0 {
            
            floorMinute -= 60.0
            
            floorHour += 1.0
        }
        
        var hourString = ""
        
        var minuteString = "00:"
        
        let secondString = String(format: "%02d", secondInt)
        
        if floorHour > 0.0 {
            
            hourString = String(format: "%02d:", Int(floorHour))
        }
        
        if floorMinute > 0.0 {
            
            minuteString = String(format: "%02d:", Int(floorMinute))
        }
        
        let durationText = hourString + minuteString + secondString
        
        return durationText
    }
    
    // MARK:
    // MARK: - Private Property
    
    
}
