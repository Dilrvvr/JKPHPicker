//
//  JKPHPicker.swift
//  JKSwiftPhotoPicker
//
//  Created by AlbertCC on 2021/5/4.
//

// 可在info.plist添加`PHPhotoLibraryPreventAutomaticLimitedAccessAlert`键值为YES
// 以避免有限照片访问时自动弹出更多选择框

import UIKit
import AVFoundation
import Photos
import JKSwiftLibrary

/// 媒体类型
public enum JKPHPickerMediaType: Int {
    
    /// 未知类型
    //case unknow = 0
    
    /// 图片
    case image
    
    /// 视频
    case video
    
    /// gif动图
    case gif
    
    /// livePhoto实况照片
    case livePhoto
}

public protocol JKPHPickerResultProtocol {
    
    func exportItem(completionHandler: ((_ itemArray: [JKPHPickerPhotoItem]) -> Void))
    
    func exportImage(completionHandler: ((_ imageArray: [UIImage?]) -> Void))
    
    func exportImageData(completionHandler: ((_ dataArray: [Data?]) -> Void))
    
    func exportVideo(completionHandler: ((_ videoArray: [AVAsset?]) -> Void))
    
    func exportLivePhoto(completionHandler: ((_ livePhotoArray: [PHLivePhoto?]) -> Void))
}

public struct JKPHPicker {
    
    public static func show(withConfiguration configuration: JKPHPickerConfiguration?) -> JKPHPicker {
        
        let config = (configuration == nil) ? JKPHPickerConfiguration() : configuration!
        
        let picker = JKPHPicker(configuration: config)
        
        return picker
    }
    
    /// 使用控制器
    public static func show(with configuration: JKPHPickerConfiguration,
                            from sourceViewController: UIViewController) {
        
        JKAuthorization.checkPhotoLibraryAuthorization { isNotDeterminedAtFirst, status in
            
            switch status {
                
            case .authorized, .limited:
                
                JKPHPickerViewController.show(with: configuration, from: sourceViewController)
                
            default:
                
                if let handler = configuration.failureHandler {
                    
                    handler(status)
                }
            }
        }
    }
    
    /// 使用
    public static func show(with configuration: JKPHPickerConfiguration?,
                            in view: UIView) -> JKPHPicker {
        
        let config = (configuration == nil) ? JKPHPickerConfiguration() : configuration!
        
        let picker = JKPHPicker(configuration: config)
        
        return picker
    }
    
    public func fromViewController(_ viewController: UIViewController?) -> JKPHPickerResultProtocol {
        
        return self
    }
    
    public func inContainerView(_ containerView: UIView?) -> JKPHPickerResultProtocol {
        
        return self
    }
    
    public private(set) var configuration: JKPHPickerConfiguration
    
    // MARK:
    // MARK: - Private
    
}

extension JKPHPicker: JKPHPickerResultProtocol {
    
    public func exportItem(completionHandler: (([JKPHPickerPhotoItem]) -> Void)) {
        
    }
    
    public func exportImage(completionHandler: (([UIImage?]) -> Void)) {
        
    }
    
    public func exportImageData(completionHandler: (([Data?]) -> Void)) {
        
    }
    
    public func exportVideo(completionHandler: (([AVAsset?]) -> Void)) {
        
    }
    
    public func exportLivePhoto(completionHandler: (([PHLivePhoto?]) -> Void)) {
        
    }
}
