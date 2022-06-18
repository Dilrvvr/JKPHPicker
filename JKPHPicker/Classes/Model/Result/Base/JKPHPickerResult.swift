//
//  JKPHPickerResult.swift
//  JKSwiftPhotoPicker
//
//  Created by albert on 2022/1/19.
//

import UIKit

open class JKPHPickerResult: NSObject {
    
    open var progress: Double = 0.0
    
    open private(set) var photoItem: JKPHPickerPhotoItem
    
    public required init(photoItem: JKPHPickerPhotoItem) {
        
        self.photoItem = photoItem
        
        super.init()
    }
}
