//
//  JKPHPickerUIImageView.swift
//  JKSwiftPhotoPicker
//
//  Created by albert on 2022/1/20.
//

import UIKit
import Photos
import JKSwiftLibrary

open class JKPHPickerUIImageView: UIImageView {
    
    /// 加载图片
    open func setPhotoPickerImage(with photoItem: JKPHPickerPhotoItem?,
                                  configuration: JKPHPickerConfiguration?,
                                  imageCache: NSCache<NSString, UIImage>?,
                                  requestType: JKPHPickerImageRequestType,
                                  completionHandler: ((_ photoItem: JKPHPickerPhotoItem, _ image: UIImage?, _ info: [AnyHashable : Any]?, _ error: Error?) -> Void)? = nil)  {
        
        guard let item = photoItem else { return }
        
        if let config = configuration,
           let editedImage = config.editedImageDict[item.localIdentifier] {
            
            self.jk.stopIndicatorLoading()
            
            self.image = editedImage
            
            if let handler = completionHandler {
                
                handler(item, editedImage, nil, nil)
            }
            
            return
        }
        
        if requestType == .thumbnail,
           let _ = item.thumbnailImage {
            
            self.jk.stopIndicatorLoading()
            
            self.image = item.thumbnailImage
            
            if let handler = completionHandler {
                
                handler(item, item.thumbnailImage, nil, nil)
            }
            
            return
        }
        
        if let cache = imageCache,
           let cachedImage = cache.object(forKey: NSString(string: item.localIdentifier)) {
            
            self.jk.stopIndicatorLoading()
            
            self.image = cachedImage
            
            /*
            if requestType == .thumbnail {
                
                item.updateThumbnailImage(cachedImage)
            } // */
            
            if let handler = completionHandler {
                
                handler(item, cachedImage, nil, nil)
            }
            
            return
        }
        
        if self.photoIdentifier.count > 0 {
            
            if self.photoIdentifier == item.localIdentifier { // 标识一致
                
                // 判断是否正在请求中
                
                if let _ = self.requestImageID { // 正在请求中
                    
                    return
                }
                
            } else { // 标识不一致
                
                // 取消之前的请求
                if let requestID = self.requestImageID {
                    
                    JKPHPickerEngine.cancelImageRequest(requestID)
                    
                    self.requestImageID = nil
                }
            }
        }
        
        // 首次加载图片
        if self.image == nil {
            
            // 占位图
            self.image = JKPHPickerUtility.Placeholder.darkGray
        }
        
        self.photoIdentifier = item.localIdentifier
        
        self.jk.relayoutIndicatorViewToCenter()
        self.jk.startIndicatorLoading()
        
        var requestID: PHImageRequestID = 0
        
        let handler: ((_ isCancelled: Bool, _ image: UIImage?, _ info: [AnyHashable : Any]?) -> Void) = { isCancelled, image, info in
            
            if isCancelled { return }
            
            self.jk.stopIndicatorLoading()
            
            self.solvePhotoPicker(loadedImage: image, photoItem: item, info: info, completionHandler: completionHandler)
        }
        
        switch requestType {
            
        case .thumbnail: // 缩略图
            
            let targetWidth = (JKKeyWindow.bounds.width - CGFloat(JKPHPickerUtility.pickerColumnCount)) / CGFloat(JKPHPickerUtility.pickerColumnCount)
            
            requestID = JKPHPickerEngine.requestThumbnailImage(for: item.asset, targetWidth: targetWidth, completionHandler: handler)
            
            item.requestThumbnailImageID = requestID
            
        case .preview: // 预览图
            
            if item.isVideo { // 视频请求第一帧
                
                requestID = JKPHPickerEngine.requestVideoPreviewImage(for: item.asset, deliveryMode: .mediumQualityFormat) { isCancelled, image, avAsset, audioMix, info in
                    
                    if isCancelled { return }
                    
                    self.jk.stopIndicatorLoading()
                    
                    self.solvePhotoPicker(loadedImage: image, photoItem: item, info: info, completionHandler: completionHandler)
                }
                
                item.requestPreviewImageID = requestID
                
            } else {
                
                requestID = JKPHPickerEngine.requestPreviewImage(for: item.asset, completionHandler: handler)
                
                item.requestPreviewImageID = requestID
            }
            
        default:
            break
        }
        
        self.requestImageID = requestID
    }
    
    /// 处理图片结果
    private func solvePhotoPicker(loadedImage: UIImage?,
                                  photoItem: JKPHPickerPhotoItem,
                                  info: [AnyHashable : Any]?,
                                  completionHandler: ((_ photoItem: JKPHPickerPhotoItem, _ image: UIImage?, _ info: [AnyHashable : Any]?, _ error: Error?) -> Void)?) {
        
        // localIdentifier不同
        if self.photoIdentifier.count > 0,
           self.photoIdentifier != photoItem.localIdentifier {
            
            return
        }
        
        self.image = loadedImage ?? JKPHPickerUtility.Placeholder.darkGray
        
        let resultInfo = info ?? [AnyHashable : Any]()
        
        // 请求错误
        if let error = resultInfo[PHImageErrorKey] as? Error {
            
            if let handler = completionHandler {
                
                handler(photoItem, loadedImage, info, error)
            }
            
            self.requestImageID = nil
            
            return
        }
        
        // 请求成功
        
        if let handler = completionHandler {
            
            handler(photoItem, loadedImage, info, nil)
        }
        
        self.requestImageID = nil
    }
    
    // MARK:
    // MARK: - Private Property
    
    /// 预览图
    var requestImageID: PHImageRequestID?
    
    /// 照片的localIdentifier
    var photoIdentifier: String = ""
}
