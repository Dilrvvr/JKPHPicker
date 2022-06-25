//
//  JKPHPickerEngine+Album.swift
//  JKSwiftPhotoPicker
//
//  Created by AlbertCC on 2021/4/18.
//

import UIKit
import Photos

public extension JKPHPickerEngine {
    
    /// 查询所有相册 async JKPHPickerAlbumItem
    static func queryAllAlbumItem(with configuration: JKPHPickerConfiguration,
                                  _ completionHandler: @escaping ((_ albumList: [JKPHPickerAlbumItem], _ albumCache: [String : JKPHPickerAlbumItem]) -> Void)) {
        
        queue.async {
            
            fetchAllAlbumItem(with: configuration) { albumList, albumCache in
                
                DispatchQueue.main.async {
                    
                    completionHandler(albumList, albumCache)
                }
            }
        }
    }
    
    /// 获取智能相册
    static func fetchSmartAlbum() -> PHFetchResult<PHAssetCollection> {
        
        let fetchOptions = PHFetchOptions()
        
        return PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .any, options: fetchOptions)
    }
    
    /// 获取用户相册
    static func queryUserAlbum() -> PHFetchResult<PHAssetCollection> {
        
        let fetchOptions = PHFetchOptions()
        
        return PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
    }
    
    // MARK:
    // MARK: - Private Function
    
    private static func fetchOptions(with configuration: JKPHPickerConfiguration) -> PHFetchOptions? {
        
        guard configuration.filter.isOnlyDisplaySelectionTypes else {
            
            return nil
        }
        
        // 已删除重复项，可根据数量判断是否有筛选
        
        let allTypeCount = JKPHPickerPickType.all.count
        
        let selectTypeCount = configuration.filter.selectionTypes.count
        
        guard selectTypeCount > 0,
              selectTypeCount < allTypeCount else {
            
            // 未进行筛选
            
            return nil
        }
        
        var formatArray = [String]()
        var formatValueArray = [Any]()
        
        var noFormatArray = [String]()
        var noFormatValueArray = [Any]()
        
        let selectTypes = configuration.filter.selectionTypes
        
        for item in JKPHPickerPickType.all {
            
            let isContained = selectTypes.contains(item)
            
            switch item {
                
            case .image:
                
                if isContained {
                    
                    formatArray.append("mediaType = %d")
                    formatValueArray.append(PHAssetMediaType.image.rawValue)
                    
                    //} else {
                    
                    // PHAssetMediaType.image包含动图和视频，不能去除
                    //noFormatArray.append("mediaType != %d")
                    //noFormatValueArray.append(PHAssetMediaType.image.rawValue)
                }
                
            case .video:
                
                if isContained {
                    
                    formatArray.append("mediaType = %d")
                    formatValueArray.append(PHAssetMediaType.video.rawValue)
                    
                } else {
                    
                    noFormatArray.append("mediaType != %d")
                    noFormatValueArray.append(PHAssetMediaType.video.rawValue)
                }
                
            case .gif:
                
                if isContained {
                    
                    formatArray.append("playbackStyle = %d")
                    formatValueArray.append(PHAsset.PlaybackStyle.imageAnimated.rawValue)
                    
                } else {
                    
                    noFormatArray.append("playbackStyle != %d")
                    noFormatValueArray.append(PHAsset.PlaybackStyle.imageAnimated.rawValue)
                }
                
            case .livePhoto:
                
                if isContained {
                    
                    formatArray.append("(mediaSubtype & %d) != 0")
                    formatValueArray.append(PHAssetMediaSubtype.photoLive.rawValue)
                    
                } else {
                    
                    noFormatArray.append("!((mediaSubtype & %d) != 0)")
                    noFormatValueArray.append(PHAssetMediaSubtype.photoLive.rawValue)
                }
            }
        }
        
        guard formatArray.count > 0 else {
            
            return nil
        }
        
        let options = PHFetchOptions()
        
        var formatString = formatArray.joined(separator: " || ")
        
        if noFormatArray.count > 0 {
            
            formatString = "(" + formatString + ")"
            
            let noFormatString = noFormatArray.joined(separator: " && ")
            
            formatString += " && ("
            formatString += noFormatString
            formatString += ")"
            
            formatValueArray += noFormatValueArray
        }
        
        options.predicate = NSPredicate(format: formatString, argumentArray: formatValueArray)
        
        return options
    }
    
    /// 获取所有相册 JKPHPickerAlbumItem
    private static func fetchAllAlbumItem(with configuration: JKPHPickerConfiguration,
                                          _ completionHandler: ((_ albumList: [JKPHPickerAlbumItem], _ albumCache: [String : JKPHPickerAlbumItem]) -> Void)) {
        
        var albumItemArray = [JKPHPickerAlbumItem]()
        var albumCache = [String : JKPHPickerAlbumItem]()
        
        let smartAlbum = fetchSmartAlbum()
        let userAlbum = queryUserAlbum()
        
        let options = fetchOptions(with: configuration)
        
        // 遍历智能相册
        smartAlbum.enumerateObjects { assetCollection, index, stop in
            
            let isHiddenAlbum = (assetCollection.assetCollectionSubtype == .smartAlbumAllHidden)
            
            // 隐藏相册 不予展示
            if isHiddenAlbum { return }
            
            guard let albumItem = createAlbumItemWithAssetCollection(assetCollection, index: index, options: options) else {
                
                return
            }
            
            let isRecentAlbum = (assetCollection.assetCollectionSubtype == .smartAlbumUserLibrary)
            
            if isRecentAlbum { // 最近项目
                
                albumItemArray.insert(albumItem, at: 0)
                
                albumCache[albumItem.localIdentifier] = albumItem
                
                return
            }
            
            albumItemArray.append(albumItem)
            
            albumCache[albumItem.localIdentifier] = albumItem
        }
        
        // 遍历用户相册
        userAlbum.enumerateObjects { assetCollection, index, _ in
            
            guard let albumItem = createAlbumItemWithAssetCollection(assetCollection, index: index, options: options) else {
                
                return
            }
            
            albumItemArray.append(albumItem)
            
            albumCache[albumItem.localIdentifier] = albumItem
        }
        
        completionHandler(albumItemArray, albumCache)
    }
    
    /// 创建JKPHPickerAlbumItem
    private static func createAlbumItemWithAssetCollection(_ assetCollection: PHAssetCollection,
                                                           index: Int,
                                                           options: PHFetchOptions?) -> JKPHPickerAlbumItem? {
        
        let isRecentAlbum = (assetCollection.assetCollectionSubtype == .smartAlbumUserLibrary)
        
        let fetchResult = PHAsset.fetchAssets(in: assetCollection, options: options)
        
        // 非最近项目 且 没有照片 不创建  最近项目无照片也要创建
        if (!isRecentAlbum && (fetchResult.count <= 0)) { return nil }
        
        let albumItem = JKPHPickerAlbumItem(assetCollection: assetCollection, fetchResult: fetchResult)
        
        return albumItem
    }
    
    // MARK:
    // MARK: - Private Property
    
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

// MARK:
// MARK: - Unused

public extension JKPHPickerEngine {
    
    /// 获取所有相册 PHAssetCollection
    static func fetchAllAssetCollection() -> [PHAssetCollection] {
        
        var assetCollectionArray = [PHAssetCollection]()
        
        let smartAlbum = fetchSmartAlbum()
        let userAlbum = queryUserAlbum()
        
        smartAlbum.enumerateObjects { assetCollection, index, _ in
            
            let isRecentAlbum = (assetCollection.assetCollectionSubtype == .smartAlbumUserLibrary)
            
            if isRecentAlbum { // 最近项目
                
                assetCollectionArray.insert(assetCollection, at: 0)
                
                return
            }
            
            let isHiddenAlbum = (assetCollection.assetCollectionSubtype == .smartAlbumAllHidden)
            
            if isHiddenAlbum { // 隐藏相册
                
                return
            }
            
            assetCollectionArray.append(assetCollection)
        }
        
        userAlbum.enumerateObjects { assetCollection, index, _ in
            
            assetCollectionArray.append(assetCollection)
        }
        
        return assetCollectionArray
    }
    
    /// 获取文件夹中的相册 使用PHAssetCollection.fetchTopLevelUserCollectionsWithOptions 才需要判断是否文件夹
    static func fetchAlbumListFrom(collectionList: PHCollectionList) -> [PHAssetCollection] {
        
        let fetchOptions = PHFetchOptions()
        
        let result = PHAssetCollection.fetchCollections(in: collectionList, options: fetchOptions)
        
        var assetCollectionArray = [PHAssetCollection]()
        
        result.enumerateObjects { subCollection, index, _ in
            
            if subCollection.isKind(of: PHCollectionList.self) {
                
                assetCollectionArray += fetchAlbumListFrom(collectionList: (subCollection as! PHCollectionList))
                
                return
            }
            
            let isAlbum = (subCollection is PHAssetCollection)
            
            if !isAlbum { return }
            
            assetCollectionArray.append(subCollection as! PHAssetCollection)
        }
        
        return assetCollectionArray
    }
}
