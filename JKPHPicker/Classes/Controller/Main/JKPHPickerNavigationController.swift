//
//  JKPHPickerNavigationController.swift
//  JKSwiftPhotoPicker
//
//  Created by AlbertCC on 2021/5/4.
//

import UIKit

open class JKPHPickerNavigationController: UINavigationController {
    
    // MARK:
    // MARK: - Public Property
    
    
    
    // MARK:
    // MARK: - Public Methods
    
    
    
    // MARK:
    // MARK: - Override
    
    public override init(rootViewController: UIViewController) {
        super.init(rootViewController: rootViewController)
        
        initialization()
    }
    
    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        initialization()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        initialization()
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        clearNavigationBar()
    }
    
    open override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        
        topViewController?.preferredStatusBarUpdateAnimation ?? .none
    }
    
    open override var prefersStatusBarHidden: Bool {
        
        topViewController?.prefersStatusBarHidden ?? false
    }
    
    open override var modalPresentationCapturesStatusBarAppearance: Bool {
        set { super.modalPresentationCapturesStatusBarAppearance = newValue }
        get { true }
    }
    
    // MARK:
    // MARK: - Private Methods
    
    private func clearNavigationBar() {
        
        isNavigationBarHidden = true
    }
    
    // MARK:
    // MARK: - Private Selector
    
    
    
    // MARK:
    // MARK: - Initialization & Build UI
    
    open func initialization() {
        
        modalPresentationStyle = .fullScreen
    }
    
    // MARK:
    // MARK: - Private Property
    
    
}
