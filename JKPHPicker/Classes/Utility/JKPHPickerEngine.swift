//
//  JKPHPickerEngine.swift
//  JKSwiftPhotoPicker
//
//  Created by AlbertCC on 2021/4/18.
//

import UIKit

public struct JKPHPickerEngine {
    
    static let queue = DispatchQueue(label: "com.albert.JKPHPicker")
}

public struct JKPHPickerDataCenter {
    
    /// 缩略图缓存
    public private(set) lazy var thumbnailImageCache: NSCache<NSString, UIImage> = {
        
        let cache = NSCache<NSString, UIImage>()
        
        cache.name = "JKPHPickerThumbnailCache"
        cache.countLimit = 200
        
        return cache
    }()
    
    /// 预览图缓存
    public private(set) lazy var previewImageCache: NSCache<NSString, UIImage> = {
        
        let cache = NSCache<NSString, UIImage>()
        
        cache.name = "JKPHPickerPreviewImageCache"
        cache.countLimit = 20
        
        return cache
    }()
    
    /// 已编辑图片缓存
    public lazy var editedImageDict = [String : UIImage]()
}
