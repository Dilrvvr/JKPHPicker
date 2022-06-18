//
//  JKPHPickerEditConfiguration.swift
//  JKSwiftPhotoPicker
//
//  Created by AlbertCC on 2022/1/12.
//

import UIKit

open class JKPHPickerEditConfiguration: NSObject {
    
    /// clipRatio: 裁剪比例 x/y任意一项小于等于0则表示自由裁剪 默认.zert
    /// isClipCircle: 是否裁剪圆形 默认false  赋值true则clipRatio强制改为CGPoint(x: 1.0, y: 1.0)
    public required init(clipRatio: CGPoint = .zero, isClipCircle: Bool = false) {
        
        self.initialClipRatio = (isClipCircle ? CGPoint(x: 1.0, y: 1.0) : clipRatio)
        self.isClipCircle = isClipCircle
        
        super.init()
        
        resetRatio()
        
        isRatioReverseEnabled = !isClipRatio
    }
    
    // MARK:
    // MARK: - Public Property
    
    /// 是否裁剪圆形 赋值true clipRatio则强制改为CGPoint(x: 1.0, y: 1.0)
    open private(set) var isClipCircle: Bool
    
    /// 裁剪宽高比 任意一项小于等于0则表示自由裁剪
    open private(set) var clipRatio: CGPoint {
        
        get {
            
            if isClipCircle {
                
                return CGPoint(x: 1.0, y: 1.0)
            }
            
            return _clipRatio
        }
        
        set {
            
            _clipRatio = newValue
            
            initialClipRatio = newValue
        }
    }
    
    /// 是否按比例裁剪 非按比例裁剪表示可自由裁剪
    open var isClipRatio: Bool {
        
        isClipCircle || (clipRatio.x > 0.0 && clipRatio.y > 0.0)
    }
    
    /// 裁剪比例是否可以反转 如16:9旋转后变为9:16 默认false
    /// 自由裁剪下默认true
    open var isRatioReverseEnabled = false
    
    /// 是否自动保存到相册
    open var isAutoSaveTopPhotoLibrary = false
    
    /// 编辑完成的回调
    open var editResultHandler: ((_ configuration: JKPHPickerEditConfiguration, _ editedImage: UIImage?) -> Void)?
    
    /// 点击取消的回调
    open var cancelHandler: ((_ configuration: JKPHPickerEditConfiguration) -> Void)?
    
    // MARK:
    // MARK: - Public Func
    
    /// 反转裁剪比例 仅isRatioReverseEnabled为true有效
    open func reverseRatio() {
        
        guard isRatioReverseEnabled else { return }
        
        _clipRatio = CGPoint(x: clipRatio.y, y: clipRatio.x)
    }
    
    /// 修改自定义裁剪比例，仅自由裁剪有效
    open func updateToCustomRatio(_ ratio: CGPoint) {
        
        guard initialClipRatio.x <= 0.0,
              initialClipRatio.y <= 0.0 else {
                  
                  return
              }
        
        _clipRatio = ratio
    }
    
    /// 重置裁剪比例
    open func resetRatio() {
        
        _clipRatio = initialClipRatio
    }
    
    // MARK:
    // MARK: - Private Property
    
    /// 初始的裁剪比例
    private var initialClipRatio: CGPoint = .zero
    
    /// 裁剪比例
    private var _clipRatio: CGPoint = .zero
}
