//
//  JKPHPickerUtility.swift
//  JKSwiftPhotoPicker
//
//  Created by AlbertCC on 2021/5/4.
//

import UIKit
import JKSwiftLibrary

public enum JKPHPickerImageRequestType {
    case unknown
    case thumbnail
    case preview
}

public func JKPrint(_ message: String) {
    
    let time = JKAbsolutePrintTime(CFAbsoluteTimeGetCurrent())
    
    print(time + " " + message)
}

public struct JKPHPickerUtility {
    
    /// 缩略图尺寸
    static let thumbnailSize = CGSize(width: 100.0, height: 100.0)
    
    /// 浏览图片的边距
    static let browserInset: UIEdgeInsets = UIEdgeInsets(top: 0.0, left: 15.0, bottom: 0.0, right: 15.0)
    
    static var lightBackgroundColor: UIColor { JKSameRGBColor(247.0) }
    
    static var darkBackgroundColor: UIColor { JKSameRGBColor(53.0) }
    
    static func calculateBrowserImageSize(_ pixelSize: CGSize,
                                          maxSize: CGSize) -> CGSize {
        
        guard maxSize.width > 0.0,
              maxSize.height > 0.0 else {
            
            let width = min(JKScreenBounds.width, JKScreenBounds.height)
            
            return CGSize(width: width, height: width)
        }
        
        guard pixelSize.width > 0.0,
              pixelSize.height > 0.0 else {
            
            let width = min(maxSize.width, maxSize.height)
            
            return CGSize(width: width, height: width)
        }
        
        var width = maxSize.width
        
        var height = width * pixelSize.height / pixelSize.width
        
        if height > maxSize.height {
            
            height = maxSize.height
            width = pixelSize.width * height / pixelSize.height
        }
        
        return CGSize(width: width, height: height)
    }
    
    static func calculateClipImageSize(_ pixelSize: CGSize,
                                       maxSize: CGSize,
                                       minSize: CGSize,
                                       isRatio: Bool,
                                       isClipRect: Bool) -> CGSize {
        
        var width = maxSize.width
        
        if pixelSize.width <= 0.0 ||
            pixelSize.height <= 0.0 {
            
            return CGSize(width: width, height: width)
        }
        
        var height = width * pixelSize.height / pixelSize.width
        
        if isRatio {
            
            if height < maxSize.height {
                
                height = maxSize.height
                
                width = JKGetScaleWidth(currentHeight: height, scaleWidth: pixelSize.width, scaleHeight: pixelSize.height)
            }
            
        } else {
            
            if height > maxSize.height {
                
                height = maxSize.height
                
                width = JKGetScaleWidth(currentHeight: height, scaleWidth: pixelSize.width, scaleHeight: pixelSize.height)
            }
        }
        
        if width < minSize.width {
            
            width = minSize.width
            
            height = JKGetScaleHeight(currentWidth: width, scaleWidth: pixelSize.width, scaleHeight: pixelSize.height)
        }
        
        if height < minSize.height {
            
            height = minSize.height
            
            width = JKGetScaleWidth(currentHeight: height, scaleWidth: pixelSize.width, scaleHeight: pixelSize.height)
        }
        
        if isClipRect && !isRatio {
            
            width = min(width, maxSize.width)
            height = min(height, maxSize.height)
        }
        
        return CGSize(width: width, height: height)
    }
    
    struct Placeholder {
        
        static let darkGray = JKCreateImage(color: .darkGray, size: CGSize(width: 1.0, height: 1.0))
    }
    
    static var minimumColumnCount: Int { 3 }
    
    static var pickerColumnCount: Int {
        
        if JKisDeviceiPhone {
            
            return JKisLandscape ? 6 : 4
        }
        
        let columnCount = Int(floor(JKKeyWindow.bounds.width / 100.0))
        
        return columnCount
    }
}
