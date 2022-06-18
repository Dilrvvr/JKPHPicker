//
//  JKPHPickerEditViewController.swift
//  JKSwiftPhotoPicker
//
//  Created by albert on 2022/1/7.
//

import UIKit

open class JKPHPickerEditViewController: UIViewController {
    
    // MARK:
    // MARK: - Public Property
    
    public private(set) var originalImage: UIImage
    
    // MARK:
    // MARK: - Public Methods
    
    
    
    // MARK:
    // MARK: - Override
    
    public init(image: UIImage, configuration: JKPHPickerEditConfiguration) {
        
        self.originalImage = image
        self.configuration = configuration
        
        super.init(nibName: nil, bundle: nil)
    }
    
    public required init?(coder: NSCoder) {
        
        self.originalImage = UIImage()
        self.configuration = JKPHPickerEditConfiguration(clipRatio: .zero, isClipCircle: false)
        
        super.init(coder: coder)
    }
    
    open override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .black
        
        p_buildUI()
    }
    
    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        editView.frame = view.bounds
    }
    
    // MARK:
    // MARK: - Private Methods
    
    
    
    // MARK:
    // MARK: - Private Selector
    
    
    
    // MARK:
    // MARK: - Initialization & Build UI
    
    /// 创建UI 交给子类重写 super自动调用该方法 注意调用super
    private func p_buildUI() {
        
        view.addSubview(editView)
    }
    
    // MARK:
    // MARK: - Private Property
    
    private var configuration: JKPHPickerEditConfiguration
    
    private lazy var editView: JKPHPickerEditView = {
        
        let editView = JKPHPickerEditView(image: self.originalImage, configuration: self.configuration, frame: UIScreen.main.bounds)
        
        return editView
    }()
}
