//
//  JKPHPickerButton.swift
//  JKSwiftPhotoPicker
//
//  Created by albert on 2021/12/2.
//

import UIKit

open class JKPHPickerButton: UIButton {
    
    /// 高亮时是否改变alpha 默认false 为true时将不支持默认高亮
    public var isHighlightedAlpha = false
    
    open var customLayoutHandler: ((_ button: UIButton) -> Void)?
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        
        if let handler = customLayoutHandler {
            
            handler(self)
        }
    }
    
    open override var isHighlighted: Bool {
        get { super.isHighlighted }
        set {
            if isHighlightedAlpha {
                
                alpha = newValue ? 0.5 : 1.0
                
                return
            }
            super.isHighlighted = newValue
        }
    }
}
