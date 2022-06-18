//
//  JKPHPickerEngine+Export.swift
//  JKSwiftPhotoPicker
//
//  Created by albert on 2021/5/24.
//

import UIKit
import Photos

public extension JKPHPickerEngine {
    
    /// 批量导出image scale最小0.01 最大1.0(返回PHImageManagerMaximumSize即原图) pixel * scale
    static func exportImage(with photoItemArray: [JKPHPickerPhotoItem],
                            scale: CGFloat,
                            progressHandler: ((_ totalProgress: Double) -> Void)? = nil,
                            completionHandler: @escaping ((_ dataArray: [JKPHPickerImageResult]) -> Void)) {
        
        var resultArray = [JKPHPickerImageResult]()
        
        if photoItemArray.count <= 0 {
            
            if Thread.isMainThread {
                
                completionHandler(resultArray)
                
            } else {
                
                DispatchQueue.main.async {
                    
                    completionHandler(resultArray)
                }
            }
            
            return
        }
        
        var completedCache = [String : Bool]()
        
        let photoItemArrayCount = photoItemArray.count
        
        var completedCount: Int = 0
        
        let asyncClosure: ((_ index: Int, _ item: JKPHPickerPhotoItem) -> Void) = { (index, item) in
            
            let targetSize = calculateExportTargetSize(withAsset: item.asset, scale: scale)
            
            let options = exportImageOptions
            
            options.progressHandler = { progress, error, stop, info in
                
                let result = resultArray[index]
                
                result.progress = progress
                
                if let handler = progressHandler {
                    
                    var totalProgress: Double = 0.0
                    
                    for result in resultArray {
                        
                        totalProgress += result.progress
                    }
                    
                    totalProgress = totalProgress / Double(resultArray.count)
                    
                    handler(totalProgress)
                }
            }
            
            ph_requestImage(for: item.asset, targetSize: targetSize, contentMode: .aspectFill, options: options) { isCancelled, image, info in
                
                options.progressHandler = nil
                
                let result = resultArray[index]
                result.image = image
                result.thumbnailImage = item.thumbnailImage
                result.progress = 1.0
                resultArray[index] = result
                
                if let handler = progressHandler {
                    
                    var totalProgress: Double = 0.0
                    
                    for result in resultArray {
                        
                        totalProgress += result.progress
                    }
                    
                    totalProgress = totalProgress / Double(resultArray.count)
                    
                    handler(totalProgress)
                }
                
                if let isCompleted = completedCache[item.localIdentifier],
                   !isCompleted {
                    
                    completedCount += 1
                    
                    completedCache[item.localIdentifier] = true
                }
                
                if completedCount < photoItemArrayCount { return }
                
                DispatchQueue.main.async {
                    
                    completionHandler(resultArray)
                }
            }
        }
        
        for (index, item) in photoItemArray.enumerated() {
            
            // 占位 保证顺序
            resultArray.append(JKPHPickerImageResult(photoItem: item))
            
            completedCache[item.localIdentifier] = false
            
            queue.async {
                
                checkRequestThumbnailImage(photoItem: item) {
                    
                    asyncClosure(index, item)
                }
            }
        }
    }
    
    /// 批量导出image data
    static func exportImageData(with photoItemArray: [JKPHPickerPhotoItem],
                                progressHandler: ((_ totalProgress: Double) -> Void)? = nil,
                                completionHandler: @escaping ((_ dataArray: [JKPHPickerImageDataResult]) -> Void)) {
        
        var resultArray = [JKPHPickerImageDataResult]()
        
        if photoItemArray.count <= 0 {
            
            if Thread.isMainThread {
                
                completionHandler(resultArray)
                
            } else {
                
                DispatchQueue.main.async {
                    
                    completionHandler(resultArray)
                }
            }
            
            return
        }
        
        var completedCache = [String : Bool]()
        
        let photoItemArrayCount = photoItemArray.count
        
        var completedCount: Int = 0
        
        let asyncClosure: ((_ index: Int, _ item: JKPHPickerPhotoItem) -> Void) = { (index, item) in
            
            let options = exportImageOptions
            
            options.progressHandler = { progress, error, stop, info in
                
                let result = resultArray[index]
                
                result.progress = progress
                
                if let handler = progressHandler {
                    
                    var totalProgress: Double = 0.0
                    
                    for result in resultArray {
                        
                        totalProgress += result.progress
                    }
                    
                    totalProgress = totalProgress / Double(resultArray.count)
                    
                    handler(totalProgress)
                }
            }
            
            ph_requestImageData(for: item.asset, options: options) { (isCancelled: Bool, imageData: Data?, dataUTI: String?, cgImageOrientation: CGImagePropertyOrientation, imageOrientation: UIImage.Orientation, info: [AnyHashable : Any]?) in
                
                options.progressHandler = nil
                
                let imageResult = resultArray[index]
                imageResult.imageData = imageData
                imageResult.progress = 1.0
                resultArray[index] = imageResult
                
                if let handler = progressHandler {
                    
                    var totalProgress: Double = 0.0
                    
                    for result in resultArray {
                        
                        totalProgress += result.progress
                    }
                    
                    totalProgress = totalProgress / Double(resultArray.count)
                    
                    handler(totalProgress)
                }
                
                if let isCompleted = completedCache[item.localIdentifier],
                   !isCompleted {
                    
                    completedCount += 1
                    
                    completedCache[item.localIdentifier] = true
                }
                
                if completedCount < photoItemArrayCount { return }
                
                DispatchQueue.main.async {
                    
                    completionHandler(resultArray)
                }
            }
        }
        
        for (index, item) in photoItemArray.enumerated() {
            
            // 保证顺序
            resultArray.append(JKPHPickerImageDataResult(photoItem: item))
            
            completedCache[item.localIdentifier] = false
            
            queue.async {
                
                checkRequestThumbnailImage(photoItem: item) {
                    
                    asyncClosure(index, item)
                }
            }
        }
    }
    
    /// 批量导出AVAsset
    static func exportVideoAVAsset(with photoItemArray: [JKPHPickerPhotoItem],
                                   progressHandler: ((_ totalProgress: Double) -> Void)? = nil,
                                   completionHandler: @escaping ((_ dataArray: [JKPHPickerVideoAssetResult]) -> Void)) {
        
        var resultArray = [JKPHPickerVideoAssetResult]()
        
        if photoItemArray.count <= 0 {
            
            if Thread.isMainThread {
                
                completionHandler(resultArray)
                
            } else {
                
                DispatchQueue.main.async {
                    
                    completionHandler(resultArray)
                }
            }
            
            return
        }
        
        var completedCache = [String : Bool]()
        
        let photoItemArrayCount = photoItemArray.count
        
        var completedCount: Int = 0
        
        let asyncClosure: ((_ index: Int, _ item: JKPHPickerPhotoItem) -> Void) = { (index, item) in
            
            let options = exportVideoOptions
            
            options.progressHandler = { progress, error, stop, info in
                
                let result = resultArray[index]
                
                result.progress = progress
                
                if let handler = progressHandler {
                    
                    var totalProgress: Double = 0.0
                    
                    for result in resultArray {
                        
                        totalProgress += result.progress
                    }
                    
                    totalProgress = totalProgress / Double(resultArray.count)
                    
                    handler(totalProgress)
                }
            }
            
            ph_requestAVAsset(for: item.asset, options: options) { isCancelled, avAsset, audioMix, info in
                
                options.progressHandler = nil
                
                let result = resultArray[index]
                result.videoAsset = avAsset
                result.progress = 1.0
                resultArray[index] = result
                
                if let handler = progressHandler {
                    
                    var totalProgress: Double = 0.0
                    
                    for result in resultArray {
                        
                        totalProgress += result.progress
                    }
                    
                    totalProgress = totalProgress / Double(resultArray.count)
                    
                    handler(totalProgress)
                }
                
                if let isCompleted = completedCache[item.localIdentifier],
                   !isCompleted {
                    
                    completedCount += 1
                    
                    completedCache[item.localIdentifier] = true
                }
                
                if completedCount < photoItemArrayCount { return }
                
                DispatchQueue.main.async {
                    
                    completionHandler(resultArray)
                }
            }
        }
        
        for (index, item) in photoItemArray.enumerated() {
            
            // 保证顺序
            resultArray.append(JKPHPickerVideoAssetResult(photoItem: item))
            
            completedCache[item.localIdentifier] = false
            
            queue.async {
                
                checkRequestThumbnailImage(photoItem: item) {
                    
                    asyncClosure(index, item)
                }
            }
        }
    }
    
    /// 批量导出LivePhoto scale最小0.01 最大1.0(返回PHImageManagerMaximumSize) pixel * scale
    static func exportLivePhoto(with photoItemArray: [JKPHPickerPhotoItem],
                                scale: CGFloat,
                                progressHandler: ((_ totalProgress: Double) -> Void)? = nil,
                                completionHandler: @escaping ((_ dataArray: [JKPHPickerLivePhotoResult]) -> Void)) {
        
        var resultArray = [JKPHPickerLivePhotoResult]()
        
        if photoItemArray.count <= 0 {
            
            if Thread.isMainThread {
                
                completionHandler(resultArray)
                
            } else {
                
                DispatchQueue.main.async {
                    
                    completionHandler(resultArray)
                }
            }
            
            return
        }
        
        var completedCache = [String : Bool]()
        
        let photoItemArrayCount = photoItemArray.count
        
        var completedCount: Int = 0
        
        let asyncClosure: ((_ index: Int, _ item: JKPHPickerPhotoItem) -> Void) = { (index, item) in
            
            let options = exportLivePhotoOptions
            
            options.progressHandler = { progress, error, stop, info in
                
                let result = resultArray[index]
                
                result.progress = progress
                
                if let handler = progressHandler {
                    
                    var totalProgress: Double = 0.0
                    
                    for result in resultArray {
                        
                        totalProgress += result.progress
                    }
                    
                    totalProgress = totalProgress / Double(resultArray.count)
                    
                    handler(totalProgress)
                }
            }
            
            let targetSize = calculateExportTargetSize(withAsset: item.asset, scale: scale)
            
            ph_requestLivePhoto(for: item.asset, targetSize: targetSize, contentMode: .aspectFill, options: options) { isCancelled, livePhoto, info in
                
                options.progressHandler = nil
                
                let result = resultArray[index]
                result.livePhoto = livePhoto
                result.progress = 1.0
                resultArray[index] = result
                
                if let handler = progressHandler {
                    
                    var totalProgress: Double = 0.0
                    
                    for result in resultArray {
                        
                        totalProgress += result.progress
                    }
                    
                    totalProgress = totalProgress / Double(resultArray.count)
                    
                    handler(totalProgress)
                }
                
                if let isCompleted = completedCache[item.localIdentifier],
                   !isCompleted {
                    
                    completedCount += 1
                    
                    completedCache[item.localIdentifier] = true
                }
                
                if completedCount < photoItemArrayCount { return }
                
                DispatchQueue.main.async {
                    
                    completionHandler(resultArray)
                }
            }
        }
        
        for (index, item) in photoItemArray.enumerated() {
            
            // 保证顺序
            resultArray.append(JKPHPickerLivePhotoResult(photoItem: item))
            
            completedCache[item.localIdentifier] = false
            
            queue.async {
                
                checkRequestThumbnailImage(photoItem: item) {
                    
                    asyncClosure(index, item)
                }
            }
        }
    }
    
    /// 批量导出url
    static func exportUrl(with photoItemArray: [JKPHPickerPhotoItem],
                          progressHandler: ((_ totalProgress: Double) -> Void)? = nil,
                          completionHandler: @escaping ((_ dataArray: [JKPHPickerImageUrlResult]) -> Void)) {
        
        var resultArray = [JKPHPickerImageUrlResult]()
        
        if photoItemArray.count <= 0 {
            
            if Thread.isMainThread {
                
                completionHandler(resultArray)
                
            } else {
                
                DispatchQueue.main.async {
                    
                    completionHandler(resultArray)
                }
            }
            
            return
        }
        
        var completedCache = [String : Bool]()
        
        let photoItemArrayCount = photoItemArray.count
        
        var completedCount: Int = 0
        
        let asyncClosure: ((_ index: Int, _ item: JKPHPickerPhotoItem) -> Void) = { (index, item) in
            
            let options = exportUrlOptions
            
            options.progressHandler = { progress, stop in
                
                let result = resultArray[index]
                
                result.progress = progress
                
                if let handler = progressHandler {
                    
                    var totalProgress: Double = 0.0
                    
                    for result in resultArray {
                        
                        totalProgress += result.progress
                    }
                    
                    totalProgress = totalProgress / Double(resultArray.count)
                    
                    handler(totalProgress)
                }
            }
            
            ph_requestUrl(for: item.asset, options: options) { isCancelled, url, info in
                
                options.progressHandler = nil
                
                let result = resultArray[index]
                result.imageURL = url
                result.progress = 1.0
                resultArray[index] = result
                
                if let handler = progressHandler {
                    
                    var totalProgress: Double = 0.0
                    
                    for result in resultArray {
                        
                        totalProgress += result.progress
                    }
                    
                    totalProgress = totalProgress / Double(resultArray.count)
                    
                    handler(totalProgress)
                }
                
                if let isCompleted = completedCache[item.localIdentifier],
                   !isCompleted {
                    
                    completedCount += 1
                    
                    completedCache[item.localIdentifier] = true
                }
                
                if completedCount < photoItemArrayCount { return }
                
                DispatchQueue.main.async {
                    
                    completionHandler(resultArray)
                }
            }
        }
        
        for (index, item) in photoItemArray.enumerated() {
            
            // 保证顺序
            resultArray.append(JKPHPickerImageUrlResult(photoItem: item))
            
            completedCache[item.localIdentifier] = false
            
            queue.async {
                
                checkRequestThumbnailImage(photoItem: item) {
                    
                    asyncClosure(index, item)
                }
            }
        }
    }
    
    // MARK:
    // MARK: - Private
    
    private static func checkRequestThumbnailImage(photoItem: JKPHPickerPhotoItem,
                                                   completionHandler: @escaping (() -> Void)) {
        
        if let _ = photoItem.thumbnailImage {
            
            completionHandler()
            
            return
        }
        
        /* 不在iCloud中且不是视频，无需请求缩略图
        // 视频的内容可能在iCloud中，无法获取首帧图
        if !photoItem.isIniCloud &&
            !photoItem.isVideo {
            
            completionHandler()
            
            return
        } // */
        
        let targetSize = JKPHPickerEngine.calculateThumbnailTargetSize(withTargetWidth: JKPHPickerUtility.thumbnailSize.width, asset: photoItem.asset)
        
        let options = PHImageRequestOptions()
        
        // 同步执行 保证只回调一次
        options.isSynchronous = true
        options.isNetworkAccessAllowed = true
        options.version = .current
        
        JKPHPickerEngine.ph_requestImage(for: photoItem.asset, targetSize: targetSize, contentMode: .aspectFill, options: options) { isCancelled, image, info in
            
            photoItem.updateThumbnailImage(image)
            
            completionHandler()
        }
    }
    
    /// 导出图片时统一使用的options
    private static var exportImageOptions: PHImageRequestOptions {
        
        let options = PHImageRequestOptions()
        
        // 同步执行 保证只回调一次
        options.isSynchronous = true
        options.isNetworkAccessAllowed = true
        options.version = .current
        options.deliveryMode = .highQualityFormat
        
        return options
    }
    
    /// 导出视频时统一使用的options
    private static var exportVideoOptions: PHVideoRequestOptions {
        
        let options = PHVideoRequestOptions()
        
        options.isNetworkAccessAllowed = true
        options.version = .current
        options.deliveryMode = .highQualityFormat
        
        return options
    }
    
    /// 导出LivePhoto时统一使用的options
    private static var exportLivePhotoOptions: PHLivePhotoRequestOptions {
        
        let options = PHLivePhotoRequestOptions()
        
        options.isNetworkAccessAllowed = true
        options.version = .current
        options.deliveryMode = .highQualityFormat
        
        return options
    }
    
    /// 导出url时统一使用的options
    private static var exportUrlOptions: PHContentEditingInputRequestOptions {
        
        let options = PHContentEditingInputRequestOptions()
        
        options.isNetworkAccessAllowed = true
        
        options.canHandleAdjustmentData = { _ in
            
            return false
        }
        
        return options
    }
}
