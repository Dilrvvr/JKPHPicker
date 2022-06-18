//
//  JKPHPickerActionModel.swift
//  JKSwiftPhotoPicker
//
//  Created by AlbertCC on 2022/1/20.
//

import UIKit

open class JKPHPickerActionModel: NSObject {
    
    open var reuseID = ""
    
    open var title: String?
    
    open var imageName: String?
    
    open var actionHandler: ((_ model: JKPHPickerActionModel) -> Void)?
}
