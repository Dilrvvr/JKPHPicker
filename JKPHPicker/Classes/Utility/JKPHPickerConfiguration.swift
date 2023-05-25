//
//  JKPHPickerConfiguration.swift
//  JKSwiftPhotoPicker
//
//  Created by albert on 2021/12/8.
//

import UIKit
import JKSwiftLibrary

public typealias JKPHPickerPickType = [JKPHPickerMediaType]

public extension Array where Element == JKPHPickerMediaType {

    static let image: JKPHPickerPickType = [.image]
    static let video: JKPHPickerPickType = [.video]
    static let gif: JKPHPickerPickType = [.gif]
    static let livePhoto: JKPHPickerPickType = [.livePhoto]
    static let all: JKPHPickerPickType = [.image, .video, .gif, .livePhoto]
}

//public struct JKPHPickerPickType: OptionSet {
//    
//    public let rawValue: Int
//    
//    public init(rawValue: Int) {
//        
//        self.rawValue = rawValue
//    }
//    
//    public static let image = JKPHPickerPickType(rawValue: 1 << 0)
//    public static let video = JKPHPickerPickType(rawValue: 1 << 1)
//    public static let gif = JKPHPickerPickType(rawValue: 1 << 2)
//    public static let livePhoto = JKPHPickerPickType(rawValue: 1 << 3)
//    public static let all: JKPHPickerPickType = [.image, .video, .gif, .livePhoto]
//}

public struct JKPHPickerFilter {
    
    public static let defaultFilter = JKPHPickerFilter()
    
    /// 是否仅展示可选择类型
    public var isOnlyDisplaySelectionTypes = true
    
    /// 可选择类型 内部将删除重复项
    public var selectionTypes: JKPHPickerPickType = .all
    
    /// 可选数量 默认9 小于0表示不限制数量
    public var totalMaxCount: Int = 9
    
    /// 视频最多可选数量 默认1 小于0表示不限制数量
    public var videoMaxCount: Int = 1
    
    public init() {}
}

open class JKPHPickerConfiguration: NSObject {
    
    public required init(filter: JKPHPickerFilter = .defaultFilter) {
        
        var correctedFilter = filter
        
        var tempArr = JKPHPickerPickType()
        
        // 删除重复项
        for item in correctedFilter.selectionTypes {
            
            if tempArr.contains(item) {
                
                continue
            }
            
            tempArr.append(item)
        }
        
        // 排序
        tempArr.sort { type1, type2 in
            
            type1.rawValue < type2.rawValue
        }
        
        correctedFilter.selectionTypes = tempArr
        
        self.filter = correctedFilter
        
        super.init()
    }
    
    public let filter: JKPHPickerFilter
    
    open var failureHandler: ((_ status: JKAuthorizationStatus) -> Void)?
    
    open var resultHandler: ((_ selectedItems: [JKPHPickerPhotoItem]) -> Void)?
    
    /// 返回几列 最少3列
    open var columnCountHandler: (() -> Int)?
    
    /// 视频是否可以与其它类型同时选择 默认true
    open var isSelectVideoSimultaneously = true
    
    /// 是否监听相册变化 默认false
    open var isObservePhotoLibraryChange = false
    
    /// 是否导出原图 默认false
    open var isExportOriginalImage = false
    
    /// 是否展示原图按钮 默认false
    open var isShowsOriginalButton = false
    
    /// 是否展示相机拍照 默认false
    open var isShowCameraItem = false
    
    /// 是否使用系统相机拍照 默认false
    //open var isUseSystemCamera = false
    
    /// 是否可以编辑 默认false
    open var isEditable = false
    
    /// 完成按钮文字
    open var completeButtonTitle = "完成"
    
    /// 主颜色
    open var mainColor = UIColor.systemBlue {
        
        didSet {
            
            editConfiguration.mainColor = mainColor
        }
    }
    
    open var editConfiguration = JKPHPickerEditConfiguration(clipRatio: .zero, isClipCircle: false)
    
    /// 缩略图缓存
    open private(set) lazy var thumbnailImageCache: NSCache<NSString, UIImage> = {
        
        let cache = NSCache<NSString, UIImage>()
        
        cache.name = "JKPHPickerThumbnailCache"
        cache.countLimit = 200
        
        return cache
    }()
    
    /// 预览图缓存
    open private(set) lazy var previewImageCache: NSCache<NSString, UIImage> = {
        
        let cache = NSCache<NSString, UIImage>()
        
        cache.name = "JKPHPickerPreviewImageCache"
        cache.countLimit = 20
        
        return cache
    }()
    
    /// 已编辑图片缓存
    open lazy var editedImageDict = [String : UIImage]()
    
    open func nextSelectTypesWithFirstSelectedType(_ selectedType: JKPHPickerMediaType?,
                                                   selectedCount: Int,
                                                   videoSelectedCount: Int) -> JKPHPickerPickType {
        
        let totalMaxCount = filter.totalMaxCount
        let videoMaxCount = filter.videoMaxCount
        let selectTypes = filter.selectionTypes
        
        if totalMaxCount == 0 { // 不可选择任何类型
            
            return JKPHPickerPickType()
        }
        
        var shouldSelectTypes = selectTypes
        
        if videoMaxCount == 0 { // 不可选择视频
            
            // 移除视频类型
            shouldSelectTypes = selectTypes.filter({ $0 != .video })
        }
        
        if isSelectVideoSimultaneously { // 视频可以与其它类型同时选择
            
            if totalMaxCount < 0 { // 无数量限制
                
                if videoMaxCount > 0 { // 视频有数量限制
                    
                    if videoSelectedCount >= videoMaxCount { // 视频数量达到最大
                        
                        // 移除视频类型
                        let types = shouldSelectTypes.filter({ $0 != .video })
                        
                        return types
                    }
                    
                    return shouldSelectTypes
                }
                
                return shouldSelectTypes
            }
            
            // 有数量限制
            
            if selectedCount >= totalMaxCount { // 已选数量达到最大
                
                return JKPHPickerPickType()
            }
            
            if videoMaxCount > 0 { // 视频有数量限制
                
                if videoSelectedCount >= videoMaxCount {
                    
                    // 移除视频类型
                    let types = shouldSelectTypes.filter({ $0 != .video })
                    
                    return types
                }
            }
            
            return shouldSelectTypes
        }
        
        // 视频和其它类型不可同时选择
        
        guard let firstSelectedType = selectedType else { // 尚未选择
            
            return shouldSelectTypes
        }
        
        guard firstSelectedType == .video else { // 第1个选择的不是视频
            
            if shouldSelectTypes.contains(.video) { // 当前可选类型包含视频
                
                // 移除视频类型
                shouldSelectTypes = shouldSelectTypes.filter({ $0 != .video })
            }
            
            if totalMaxCount > 0 { // 有数量限制
                
                if selectedCount >= totalMaxCount { // 已选数量达到最大
                    
                    return JKPHPickerPickType()
                }
            }
            
            return shouldSelectTypes
        }
        
        // 第1个选择的是视频
        
        // 仅可继续选择视频类型
        shouldSelectTypes = [.video]
        
        if totalMaxCount > 0 { // 有数量限制
            
            if selectedCount >= totalMaxCount { // 已选数量达到最大
                
                return JKPHPickerPickType()
            }
            
            if videoMaxCount > 0 { // 视频有数量限制
                
                let maxCount = min(videoMaxCount, totalMaxCount)
                
                if videoSelectedCount >= maxCount { // 视频已选数量达到最大
                    
                    return JKPHPickerPickType()
                }
            }
            
            return shouldSelectTypes
        }
        
        // 无数量限制
        
        if videoMaxCount > 0 { // 视频有数量限制
            
            if videoSelectedCount >= videoMaxCount {
                
                return JKPHPickerPickType()
            }
        }
        
        return shouldSelectTypes
    }
}
