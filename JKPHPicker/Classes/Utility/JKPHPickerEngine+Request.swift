//
//  JKPHPickerEngine+Request.swift
//  JKSwiftPhotoPicker
//
//  Created by AlbertCC on 2021/5/9.
//

import UIKit
import Photos
import JKSwiftLibrary

public extension JKPHPickerEngine {
    
    /// 缩略图的放大比例 JKScreenScale * 1.15 可展示png透明
    static let thumbnailScale: CGFloat = JKScreenScale >= 3.0 ? 2.0 : 1.8//JKScreenScale * 1.15
    
    static let previewScale: CGFloat = 0.8//0.618
    
    // Result's handler info dictionary keys
    
    // PHImageResultIsInCloudKey: String
    // key (NSNumber): result is in iCloud, meaning a new request will need to get issued (with networkAccessAllowed set) to get the result
    
    // PHImageResultIsDegradedKey: String
    // key (NSNumber): result  is a degraded image (only with async requests), meaning other images will be sent unless the request is cancelled in the meanwhile (note that the other request may fail if, for example, data is not available locally and networkAccessAllowed was not specified)
    
    // PHImageResultRequestIDKey: String
    // key (NSNumber): Request ID of the request for this result
    
    // PHImageCancelledKey: String
    // key (NSNumber): result is not available because the request was cancelled
    
    //PHImageErrorKey: String
    
    /// 取消图片请求
    static func cancelImageRequest(_ requestID: PHImageRequestID) {
        
        PHImageManager.default().cancelImageRequest(requestID)
    }
    
    /// 获取缩略图 回调在主线程
    @discardableResult
    static func requestThumbnailImage(for asset: PHAsset,
                                      targetWidth: CGFloat,
                                      completionHandler: @escaping (_ isCancelled: Bool, _ image: UIImage?, _ info: [AnyHashable : Any]?) -> Void) -> PHImageRequestID {
        
        guard targetWidth > 0 else {
            
            if Thread.isMainThread {
                
                completionHandler(false, nil, nil)
                
            } else {
                
                DispatchQueue.main.async {
                    
                    completionHandler(false, nil, nil)
                }
            }
            
            return 0
        }
        
        let targetSize = calculateThumbnailTargetSize(withTargetWidth: targetWidth, asset: asset)
        
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.version = .current
        
        return ph_requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFill, options: options) { isCancelled, image, info in
            
            DispatchQueue.main.async {
                
                completionHandler(isCancelled, image, info)
            }
        }
    }
    
    /// 获取预览图 回调在主线程
    @discardableResult
    static func requestPreviewImage(for asset: PHAsset,
                                    completionHandler: @escaping (_ isCancelled: Bool, _ image: UIImage?, _ info: [AnyHashable : Any]?) -> Void) -> PHImageRequestID {
        
        let targetSize = calculatePreviewTargetSize(withAsset: asset)
        
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.version = .current
        options.deliveryMode = .highQualityFormat
        
        return ph_requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFill, options: options) { isCancelled, image, info in
            
            DispatchQueue.main.async {
                
                completionHandler(isCancelled, image, info)
            }
        }
    }
    
    /// 获取 image data 回调在主线程
    @discardableResult
    static func requestImageData(for asset: PHAsset,
                                 deliveryMode: PHImageRequestOptionsDeliveryMode = .highQualityFormat,
                                 completionHandler: @escaping (_ isCancelled: Bool, _ imageData: Data?, _ dataUTI: String?, _ cgImageOrientation: CGImagePropertyOrientation, _ imageOrientation: UIImage.Orientation, _ info: [AnyHashable : Any]?) -> Void) -> PHImageRequestID {
        
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.version = .current
        options.deliveryMode = deliveryMode
        
        return ph_requestImageData(for: asset, options: options) { isCancelled, imageData, dataUTI, cgImageOrientation, imageOrientation, info in
            
            DispatchQueue.main.async {
                
                completionHandler(isCancelled, imageData, dataUTI, cgImageOrientation, imageOrientation, info)
            }
        }
    }
    
    /// 获取视频预览图（第一帧） 回调在主线程
    @discardableResult
    static func requestVideoPreviewImage(for asset: PHAsset,
                                         deliveryMode: PHVideoRequestOptionsDeliveryMode = .highQualityFormat,
                                         completionHandler: @escaping (_ isCancelled: Bool, _ image: UIImage?, _ avAsset: AVAsset?, _ audioMix: AVAudioMix?, _ info: [AnyHashable : Any]?) -> Void) -> PHImageRequestID {
        
        let options = PHVideoRequestOptions()
        options.isNetworkAccessAllowed = true
        options.version = .current
        options.deliveryMode = deliveryMode
        
        return ph_requestVideoPreviewImage(for: asset, options: options) { isCancelled, image, avAsset, audioMix, info in
            
            DispatchQueue.main.async {
                
                completionHandler(isCancelled, image, avAsset, audioMix, info)
            }
        }
    }
    
    /// 请求playerItem 回调在主线程
    @discardableResult
    static func requestPlayerItem(for asset: PHAsset,
                                  deliveryMode: PHVideoRequestOptionsDeliveryMode = .highQualityFormat,
                                  completionHandler: @escaping (_ isCancelled: Bool, _ playerItem: AVPlayerItem?, _ info: [AnyHashable : Any]?) -> Void) -> PHImageRequestID {
        
        let options = PHVideoRequestOptions()
        options.isNetworkAccessAllowed = true
        options.version = .current
        options.deliveryMode = deliveryMode
        
        return ph_requestPlayerItem(for: asset, options: options) { isCancelled, playerItem, info in
            
            DispatchQueue.main.async {
                
                completionHandler(isCancelled, playerItem, info)
            }
        }
    }
    
    /// 获取预览LivePhoto 回调在主线程
    @discardableResult
    static func requestPreviewLivePhoto(for asset: PHAsset,
                                        deliveryMode: PHImageRequestOptionsDeliveryMode = .highQualityFormat,
                                        completionHandler: @escaping (_ isCancelled: Bool, _ livePhoto: PHLivePhoto?, _ info: [AnyHashable : Any]?) -> Void) -> PHImageRequestID {
        
        let targetSize = calculatePreviewTargetSize(withAsset: asset)
        
        let options = PHLivePhotoRequestOptions()
        options.isNetworkAccessAllowed = true
        options.version = .current
        options.deliveryMode = deliveryMode
        options.version = .current
        
        return ph_requestLivePhoto(for: asset, targetSize: targetSize, contentMode: .aspectFill, options: options) { isCancelled, livePhoto, info in
            
            DispatchQueue.main.async {
                
                completionHandler(isCancelled, livePhoto, info)
            }
        }
    }
    
    /// 请求 url 回调在主线程
    @discardableResult
    static func requestImageUrl(for asset: PHAsset,
                                completionHandler: @escaping (_ isCancelled: Bool, _ url: URL?, _ info: [AnyHashable : Any]) -> Void) -> PHContentEditingInputRequestID {
        
        let options = PHContentEditingInputRequestOptions()
        options.isNetworkAccessAllowed = true
        options.canHandleAdjustmentData = { _ in
            
            return false
        }
        
        return ph_requestUrl(for: asset, options: options) { isCancelled, url, info in
            
            DispatchQueue.main.async {
                
                completionHandler(isCancelled, url, info)
            }
        }
    }
    
    // MARK:
    // MARK: - PHImageManager Request Action
    
    /// 请求image
    @discardableResult
    static func ph_requestImage(for asset: PHAsset,
                                targetSize: CGSize,
                                contentMode: PHImageContentMode,
                                options: PHImageRequestOptions?,
                                completionHandler: @escaping (_ isCancelled: Bool, _ image: UIImage?, _ info: [AnyHashable : Any]?) -> Void) -> PHImageRequestID {
        
        return PHImageManager.default().requestImage(for: asset, targetSize: targetSize, contentMode: contentMode, options: options) { image, info in
            
            var isCancelled = false
            
            if let _ = info,
               let cancelValue = info![PHImageCancelledKey],
               cancelValue is NSNumber {
                
                isCancelled = (cancelValue as! NSNumber).boolValue
            }
            
            completionHandler(isCancelled, image, info)
        }
    }
    
    /// 请求image data 大于等于iOS13使用cgImageOrientation，否则使用imageOrientation
    @discardableResult
    static func ph_requestImageData(for asset: PHAsset,
                                    options: PHImageRequestOptions?,
                                    completionHandler: @escaping ((_ isCancelled: Bool, _ imageData: Data?, _ dataUTI: String?, _ cgImageOrientation: CGImagePropertyOrientation, _ imageOrientation: UIImage.Orientation, _ info: [AnyHashable : Any]?) -> Void)) -> PHImageRequestID {
        
        if #available(iOS 13, *) {
            
            return PHImageManager.default().requestImageDataAndOrientation(for: asset, options: options) { (imageData: Data?, dataUTI: String?, orientation: CGImagePropertyOrientation, info: [AnyHashable : Any]?) in
                
                var isCancelled = false
                
                if let _ = info,
                   let cancelValue = info![PHImageCancelledKey],
                   cancelValue is NSNumber {
                    
                    isCancelled = (cancelValue as! NSNumber).boolValue
                }
                
                var imageOrientation: UIImage.Orientation = .up
                
                switch orientation {
                case .upMirrored:
                    imageOrientation = .upMirrored
                case .down:
                    imageOrientation = .down
                case .downMirrored:
                    imageOrientation = .downMirrored
                case .leftMirrored:
                    imageOrientation = .leftMirrored
                case .right:
                    imageOrientation = .right
                case .rightMirrored:
                    imageOrientation = .rightMirrored
                case .left:
                    imageOrientation = .left
                default:
                    break
                }
                
                completionHandler(isCancelled, imageData, dataUTI, orientation, imageOrientation, info)
            }
            
        } else {
            
            return PHImageManager.default().requestImageData(for: asset, options: options) { (imageData: Data?, dataUTI: String?, orientation: UIImage.Orientation, info: [AnyHashable : Any]?) in
                
                var isCancelled = false
                
                if let _ = info,
                   let cancelValue = info![PHImageCancelledKey],
                   cancelValue is NSNumber {
                    
                    isCancelled = (cancelValue as! NSNumber).boolValue
                }
                
                var propertyOrientation: CGImagePropertyOrientation = .up
                
                switch orientation {
                case .upMirrored:
                    propertyOrientation = .upMirrored
                case .down:
                    propertyOrientation = .down
                case .downMirrored:
                    propertyOrientation = .downMirrored
                case .leftMirrored:
                    propertyOrientation = .leftMirrored
                case .right:
                    propertyOrientation = .right
                case .rightMirrored:
                    propertyOrientation = .rightMirrored
                case .left:
                    propertyOrientation = .left
                default:
                    break
                }
                
                completionHandler(isCancelled, imageData, dataUTI, propertyOrientation, orientation, info)
            }
        }
    }
    
    /// 请求AVAsset  遇到 AVComposition 将自动转为 AVURLAsset
    @discardableResult
    static func ph_requestAVAsset(for asset: PHAsset,
                                  options: PHVideoRequestOptions?,
                                  completionHandler: @escaping (_ isCancelled: Bool, _ avAsset: AVAsset?, _ audioMix: AVAudioMix?, _ info: [AnyHashable : Any]?) -> Void) -> PHImageRequestID {
        
        return PHImageManager.default().requestAVAsset(forVideo: asset, options: options) { avAsset, audioMix, info in
            
            var isCancelled = false
            
            if let _ = info,
               let cancelValue = info![PHImageCancelledKey],
               cancelValue is NSNumber {
                
                isCancelled = (cancelValue as! NSNumber).boolValue
            }
            
            if let realAvAsset = avAsset,
               realAvAsset is AVComposition {
                
                let compostion = realAvAsset as! AVComposition
                
                convertCompositionToUrlAsset(composition: compostion) { urlAsset in
                    
                    completionHandler(isCancelled, urlAsset, audioMix, info)
                }
                
                return
            }
            
            completionHandler(isCancelled, avAsset, audioMix, info)
        }
    }
    
    /// 获取视频预览图（第一帧）
    @discardableResult
    static func ph_requestVideoPreviewImage(for asset: PHAsset,
                                            options: PHVideoRequestOptions,
                                            completionHandler: @escaping (_ isCancelled: Bool, _ image: UIImage?, _ avAsset: AVAsset?, _ audioMix: AVAudioMix?, _ info: [AnyHashable : Any]?) -> Void) -> PHImageRequestID {
        
        return ph_requestAVAsset(for: asset, options: options) { (isCancelled: Bool, avAsset: AVAsset?, audioMix: AVAudioMix?, info: [AnyHashable : Any]?) in
            
            if isCancelled {
                
                completionHandler(true, nil, avAsset, audioMix, info)
                
                return
            }
            
            guard let _ = avAsset else {
                
                completionHandler(false, nil, avAsset, audioMix, info)
                
                return
            }
            
            if Thread.isMainThread { // 当前主线程
                
                queue.async { // 异步执行
                    
                    getVideoFirstFrame(avAsset: avAsset!) { image in
                        
                        completionHandler(false, image, avAsset, audioMix, info)
                    }
                }
                
                return
            }
            
            // 当前非主线程
            
            getVideoFirstFrame(avAsset: avAsset!) { image in
                
                completionHandler(false, image, avAsset, audioMix, info)
            }
        }
    }
    
    /// 请求playerItem
    @discardableResult
    static func ph_requestPlayerItem(for asset: PHAsset,
                                     options: PHVideoRequestOptions?,
                                     completionHandler: @escaping (_ isCancelled: Bool, _ playerItem: AVPlayerItem?, _ info: [AnyHashable : Any]?) -> Void) -> PHImageRequestID {
        
        return PHImageManager.default().requestPlayerItem(forVideo: asset, options: options) { playerItem, info in
            
            var isCancelled = false
            
            if let _ = info,
               let cancelValue = info![PHImageCancelledKey],
               cancelValue is NSNumber {
                
                isCancelled = (cancelValue as! NSNumber).boolValue
            }
            
            completionHandler(isCancelled, playerItem, info)
        }
    }
    
    /// 请求LivePhoto
    @discardableResult
    static func ph_requestLivePhoto(for asset: PHAsset,
                                    targetSize: CGSize,
                                    contentMode: PHImageContentMode,
                                    options: PHLivePhotoRequestOptions?,
                                    completionHandler: @escaping (_ isCancelled: Bool, _ livePhoto: PHLivePhoto?, _ info: [AnyHashable : Any]?) -> Void) -> PHImageRequestID {
        
        return PHImageManager.default().requestLivePhoto(for: asset, targetSize: targetSize, contentMode: contentMode, options: options) { livePhoto, info in
            
            var isCancelled = false
            
            if let _ = info,
               let cancelValue = info![PHLivePhotoInfoCancelledKey],
               cancelValue is NSNumber {
                
                isCancelled = (cancelValue as! NSNumber).boolValue
            }
            
            completionHandler(isCancelled, livePhoto, info)
        }
    }
    
    /// 请求 url
    @discardableResult
    static func ph_requestUrl(for asset: PHAsset,
                              options: PHContentEditingInputRequestOptions?,
                              completionHandler: @escaping (_ isCancelled: Bool, _ url: URL?, _ info: [AnyHashable : Any]) -> Void) -> PHContentEditingInputRequestID {
        
        return asset.requestContentEditingInput(with: options) { editingInput, info in
            
            var isCancelled = false
            
            if let cancelValue = info[PHContentEditingInputCancelledKey],
               cancelValue is NSNumber {
                
                isCancelled = (cancelValue as! NSNumber).boolValue
            }
            
            var url: URL?
            
            if let _ = editingInput {
                
                url = editingInput?.fullSizeImageURL
            }
            
            completionHandler(isCancelled, url, info)
        }
    }
    
    // MARK:
    // MARK: - 计算 targetSize
    
    /// 计算缩略图大小 targetWidth将乘以屏幕的scale
    static func calculateThumbnailTargetSize(withTargetWidth targetWidth: CGFloat, asset: PHAsset) -> CGSize {
        
        if asset.pixelWidth <= 0 ||
            asset.pixelHeight <= 0 ||
            targetWidth <= 0.0 {
            
            return JKPHPickerUtility.thumbnailSize
        }
        
        let maxWH: CGFloat = max(JKScreenWidth, JKScreenHeight)
        
        var width: CGFloat = targetWidth * Self.thumbnailScale
        width = min(width, CGFloat(asset.pixelWidth))
        width = min(width, maxWH)
        
        var height = JKGetScaleHeight(currentWidth: width, scaleWidth: CGFloat(asset.pixelWidth), scaleHeight: CGFloat(asset.pixelHeight))
        
        let minHeight: CGFloat = width
        
        if height >= minHeight &&
            height <= maxWH {
            
            return CGSize(width: width, height: height)
        }
        
        height = min(height, maxWH)
        height = max(height, minHeight)
        
        width = JKGetScaleWidth(currentHeight: height, scaleWidth: CGFloat(asset.pixelWidth), scaleHeight: CGFloat(asset.pixelHeight))
        
        return CGSize(width: width, height: height)
    }
    
    /// 计算预览图大小
    static func calculatePreviewTargetSize(withAsset asset: PHAsset) -> CGSize {
        
        let pixelSize = CGSize(width: CGFloat(asset.pixelWidth), height: CGFloat(asset.pixelHeight))
        
        guard pixelSize.width > 0.0,
              pixelSize.height > 0.0 else {
                  
                  return JKPHPickerUtility.thumbnailSize
              }
        
        let screenScale: CGFloat = JKScreenScale
        
        var width: CGFloat = min(JKScreenWidth, JKScreenHeight) * screenScale
        width = min(width, pixelSize.width)
        
        var minHeight: CGFloat = width
        minHeight = min(minHeight, pixelSize.height * Self.previewScale)
        
        var height = JKGetScaleHeight(currentWidth: width, scaleWidth: pixelSize.width, scaleHeight: pixelSize.height)
        
        if height < minHeight {
            
            height = minHeight
            
            width = JKGetScaleWidth(currentHeight: height, scaleWidth: pixelSize.width, scaleHeight: pixelSize.height)
        }
        
        return CGSize(width: width, height: height)
    }
    
    /// 计算导出图片大小 scale最小0.01 最大1.0(返回PHImageManagerMaximumSize即原图) pixel * scale
    static func calculateExportTargetSize(withAsset asset: PHAsset, scale: CGFloat) -> CGSize {
        
        if asset.pixelWidth <= 0 ||
            asset.pixelHeight <= 0 {
            
            return JKPHPickerUtility.thumbnailSize
        }
        
        if scale >= 1.0 { return PHImageManagerMaximumSize }
        
        let zoomScale: CGFloat = max(0.01, scale)
        
        let width: CGFloat = CGFloat(asset.pixelWidth) * zoomScale
        let height: CGFloat = CGFloat(asset.pixelHeight) * zoomScale
        
        return CGSize(width: width, height: height)
    }
    
    // MARK:
    // MARK: - 视频预览图
    
    /// 获取视频第一帧
    static func getVideoFirstFrame(avAsset: AVAsset,
                                   completionHandler: @escaping (_ image: UIImage?) -> Void) {
        
        getVideoFrame(avAsset: avAsset, time: CMTimeMake(value: 0, timescale: 600), completionHandler: completionHandler)
    }
    
    /// 获取视频指定帧
    static func getVideoFrame(avAsset: AVAsset,
                              time: CMTime,
                              completionHandler: @escaping (_ image: UIImage?) -> Void) {
        
        let generator = AVAssetImageGenerator(asset: avAsset)
        generator.appliesPreferredTrackTransform = true
        generator.apertureMode = .encodedPixels
        
        guard let cgImage = try? generator.copyCGImage(at: time, actualTime: nil) else {
            
            completionHandler(nil)
            
            return
        }
        
        let image = UIImage(cgImage: cgImage)
        
        completionHandler(image)
    }
    
    // MARK:
    // MARK: - 类型转换
    
    /// 将 AVComposition 转为 AVURLAsset
    static func convertCompositionToUrlAsset(composition: AVComposition?,
                                             completionHandler: @escaping ((_ urlAsset: AVURLAsset?) -> Void)) {
        
        guard let realComposition = composition,
              let exporter = AVAssetExportSession(asset: realComposition, presetName: AVAssetExportPresetHighestQuality) else {
                  
                  completionHandler(nil)
                  
                  return
              }
        
        let dateString = Date().jk.format_normal + "_\(CFAbsoluteTime())"
        let exportPath = NSTemporaryDirectory() + dateString + "_video.mov"
        let exportUrl = URL(fileURLWithPath: exportPath)
        
        exporter.outputURL = exportUrl
        exporter.outputFileType = .mov
        exporter.shouldOptimizeForNetworkUse = true
        
        exporter.exportAsynchronously(completionHandler: {
            
            switch exporter.status {
                
            case .completed: // 完成
                
                guard let url = exporter.outputURL else {
                    
                    completionHandler(nil)
                    
                    return
                }
                
                let urlAsset = AVURLAsset(url: url)
                
                completionHandler(urlAsset)
                
            case .failed, .cancelled: // 失败/取消
                
                completionHandler(nil)
                
            default:
                break
            }
        })
    }
}
