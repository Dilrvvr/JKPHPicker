//
//  JKPHPickerEngine+Photo.swift
//  JKSwiftPhotoPicker
//
//  Created by AlbertCC on 2021/5/5.
//

import UIKit
import Photos

public extension JKPHPickerEngine {
    
    /// 根据PHAssetCollection获取相簿中所有照片
    static func queryAllPhotoItem(in albumItem: JKPHPickerAlbumItem,
                                  seletedCache: [String : JKPHPickerPhotoItem],
                                  configuration: JKPHPickerConfiguration,
                                  completionHandler: @escaping ((_ photoItemArray: [JKPHPickerPhotoItem], _ refreshSeletedCache: [String : JKPHPickerPhotoItem], _ photoItemCache: [String : JKPHPickerPhotoItem]) -> Void)) {
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        queue.async {
            
            fetchAllPhotoItemFromAlbum(albumItem, seletedCache: seletedCache, configuration: configuration) { photoItemArray, seletedCache, photoItemCache in
                
                DispatchQueue.main.async {
                    
                    let endTime = CFAbsoluteTimeGetCurrent()
                    
                    print("startTime-->\(startTime)\nendTime-->\(endTime)\nduration-->\(endTime - startTime)")
                    
                    completionHandler(photoItemArray, seletedCache, photoItemCache)
                }
            }
        }
    }
    
    // MARK:
    // MARK: - Private Function
    
    /// 获取某一相册结果集中所有照片 JKPHPickerPhotoItem
    private static func fetchAllPhotoItemFromAlbum(_ albumItem: JKPHPickerAlbumItem,
                                                   seletedCache: [String : JKPHPickerPhotoItem],
                                                   configuration: JKPHPickerConfiguration,
                                                   completionHandler: @escaping ((_ photoItemArray: [JKPHPickerPhotoItem], _ refreshSeletedCache: [String : JKPHPickerPhotoItem], _ photoItemCache: [String : JKPHPickerPhotoItem]) -> Void)) {
        
        var firstSelectType: JKPHPickerMediaType?
        
        var videoCount: Int = 0
        
        if seletedCache.count > 0 {
            
            let firstItem = seletedCache.first!.value
            
            firstSelectType = firstItem.mediaType
            
            for item in seletedCache {
                
                if item.value.isVideo {
                    
                    videoCount += 1
                }
            }
        }
        
        let nextSelectTypes = configuration.nextSelectTypesWithFirstSelectedType(firstSelectType, selectedCount: seletedCache.count, videoSelectedCount: videoCount)
        
        var cache = seletedCache
        
        var photoItemArray = [JKPHPickerPhotoItem]()
        
        var photoItemCache = [String : JKPHPickerPhotoItem]()
        
        albumItem.fetchResult.enumerateObjects { asset, index, _ in
            
            let indexPath = IndexPath(item: index, section: 0)
            
            let photoItem = JKPHPickerPhotoItem(asset: asset, indexPath: indexPath)
            
            if let item = cache[asset.localIdentifier] {
                
                photoItem.synchronize(with: item)
                
                cache[asset.localIdentifier] = photoItem
            }
            
            photoItem.isSelectable = nextSelectTypes.contains(photoItem.mediaType)
            
            photoItemArray.append(photoItem)
            
            photoItemCache[photoItem.localIdentifier] = photoItem
            
            if let image = configuration.editedImageDict[photoItem.localIdentifier] {
                
                if let cgImage = image.cgImage {
                    
                    photoItem.editedImageSize = CGSize(width: cgImage.width, height: cgImage.height)
                    
                } else {
                    
                    photoItem.editedImageSize = CGSize(width: image.size.width * image.scale, height: image.size.height * image.scale)
                }
                
            } else {
                
                photoItem.editedImageSize = .zero
            }
        }
        
        DispatchQueue.main.async {
            
            albumItem.updatePhotoCount(photoItemArray.count)
        }
        
        completionHandler(photoItemArray, cache, photoItemCache)
    }
}
