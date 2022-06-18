//
//  JKPHPickerResourceManager.swift
//  JKSwiftPhotoPicker
//
//  Created by AlbertCC on 2021/5/4.
//

import UIKit

open class JKPHPickerResourceManager: NSObject {
    
    public static let resourceBundle: Bundle = {
        
        if let path = Bundle(for: JKPHPickerResourceManager.self).path(forResource: "JKPHPickerResource", ofType: "bundle"),
           let bundle = Bundle(path: path) {
            
            return bundle
        }
        
        return Bundle()
    }()
    
    public static func image(named: String) -> UIImage? {
        
        return UIImage(named: named, in: resourceBundle, compatibleWith: nil)
    }
}
