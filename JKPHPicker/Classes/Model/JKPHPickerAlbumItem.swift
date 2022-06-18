//
//  JKPHPickerAlbumItem.swift
//  JKSwiftPhotoPicker
//
//  Created by AlbertCC on 2021/4/18.
//

import Foundation
import Photos

open class JKPHPickerAlbumItem: NSObject {
    
    // MARK:
    // MARK: - Init Function
    
    /// 相册
    open private(set) var assetCollection: PHAssetCollection
    
    /// 本地标识
    open private(set) var localIdentifier: String
    
    /// 相册的结果集
    open private(set) var fetchResult: PHFetchResult<PHAsset>
    
    /// 相册图片数量
    open private(set) var photoCount: Int
    
    /// 初始化
    public init(assetCollection: PHAssetCollection,
                fetchResult: PHFetchResult<PHAsset>) {
        
        self.assetCollection = assetCollection
        self.localIdentifier = assetCollection.localIdentifier
        self.fetchResult = fetchResult
        self.photoCount = fetchResult.count
        
        if let asset = fetchResult.lastObject {
            
            let item = JKPHPickerPhotoItem(asset: asset, indexPath: IndexPath(row: 0, section: 0))
            
            thumbnailPhotoItem = item
        }
        
        if let localizedTitle = assetCollection.localizedTitle {
            
            if let title = Self.albumTitleDictionary[localizedTitle]  {
                
                albumTitle = title
                
            } else {
                
                albumTitle = localizedTitle
            }
        }
        
        super.init()
    }
    
    // MARK:
    // MARK: - Property
    
    /// 是否选中
    open var isSelected = false
    
    /// 预览图photoItem
    open private(set) var thumbnailPhotoItem: JKPHPickerPhotoItem?
    
    /// 相册标题
    open private(set) var albumTitle: String = ""
    
    /// 更新选中状态
    open var updateSelectStatusHandler: ((_ albumItem: JKPHPickerAlbumItem) -> Void)?
    
    /// 更新照片数量
    open var updatePhotoCountHandler: ((_ albumItem: JKPHPickerAlbumItem) -> Void)?
    
    // MARK:
    // MARK: - Function
    
    /// 更新选中状态
    open func callUpdateSelectStatusHandler() {
        
        if let handler = updateSelectStatusHandler {
            
            handler(self)
        }
    }
    
    /// 更新照片数量
    open func updatePhotoCount(_ count: Int) {
        
        if count == photoCount { return }
        
        photoCount = count
        
        if let handler = updatePhotoCountHandler {
            
            handler(self)
        }
    }
    
    // MARK:
    // MARK: - Private
    
    private static let albumTitleDictionary: [String : String] = {
        [
            "Recents" : "最近项目",
            "Recently Added" : "最近添加",
            "All Photos" : "所有照片",
            "Camera Roll" : "相机胶卷",
            "Favorites" : "个人收藏",
            "Videos" : "视频",
            "Selfies" : "自拍",
            "Live Photos" : "实况照片",
            "Portrait" : "人像",
            "Panoramas" : "全景照片",
            "Screenshots" : "截屏",
            "Animated" : "动图",
            "Slo-mo" : "慢动作"
        ]
    }()
}

