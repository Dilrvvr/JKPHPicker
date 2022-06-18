//
//  JKPHPickerBaseViewController.swift
//  JKSwiftPhotoPicker
//
//  Created by AlbertCC on 2021/5/5.
//

import UIKit
import JKSwiftLibrary

open class JKPHPickerBaseViewController: UIViewController {
    
    // MARK:
    // MARK: - Pubic Property
    
    open private(set) var configuration: JKPHPickerConfiguration
    
    open var previousViewSize: CGSize = .zero
    
    open var isPreviousLandscape: Bool = false
    
    // MARK:
    // MARK: - Public Function
    /*
    open func checkOrientationAfterDidLayoutSubviews() {
        
        if isOrientationWillChange {
            
            let isEqualSize: Bool = __CGSizeEqualToSize(view.bounds.size, willTransitionToSize)
            
            if isEqualSize {
                
                isOrientationWillChange = false
                
                viewOrientationDidChange()
            }
        }
    }
    // */
    
    /// 方向即将改变
    open func viewOrientationWillChange() {
        
    }
    
    /// 方向已经改变
    open func viewOrientationDidChange() {
        
    }
    
    // MARK:
    // MARK: - Override
    
    public init(configuration: JKPHPickerConfiguration) {
        
        self.configuration = configuration
        
        super.init(nibName: nil, bundle: nil)
    }
    
    public required init?(coder: NSCoder) {
        
        self.configuration = JKPHPickerConfiguration()
        
        super.init(coder: coder)
    }

    open override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = JKPHPickerUtility.darkBackgroundColor
        
        if #available(iOS 11.0, *) {} else {
            automaticallyAdjustsScrollViewInsets = false
        }
        
        p_buildUI()
    }
    
    open override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        if __CGSizeEqualToSize(previousViewSize, .zero) {
            
            previousViewSize = view.bounds.size
            isPreviousLandscape = JKisLandscape
        }
    }
    
    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        print("\(Self.self)-->view.frame-->\(view.frame)")
        print("\(Self.self)-->view.bounds-->\(view.bounds)")
        
        //contentView.frame = view.bounds
        
        //navigationBarView.frame = CGRect(x: 0.0, y: 0.0, width: view.bounds.width, height: JKNavigationBarHeight)
        
        //indicatorView.center = view.center
    }
    
    open func checkViewOrientationWillChange() {
        
        // TODO: - JKTODO <#注释#>
        return;
        
        if __CGSizeEqualToSize(previousViewSize, view.bounds.size) {
            
            return
        }
        
        if (JKisPortrait != isPreviousLandscape) { // 屏幕旋转
            
            viewOrientationWillChange()
            
            return
        }
        
        // 屏幕未旋转  判断是否分屏
        
        guard JKisSplitScreenCapable else { // 非可分屏设备
            
            return
        }
        
        // 可分屏设备
        
        viewOrientationWillChange()
    }
    
    open func checkViewOrientationDidChange() {
        
        if __CGSizeEqualToSize(previousViewSize, view.bounds.size) {
            
            return
        }
        
        if (JKisLandscape != isPreviousLandscape) { // 屏幕旋转
            
            previousViewSize = view.bounds.size
            isPreviousLandscape = JKisLandscape
            
            viewOrientationDidChange()
            
            return
        }
        
        // 屏幕未旋转  判断是否分屏
        
        guard JKisSplitScreenCapable else { // 非可分屏设备
            
            return
        }
        
        // 可分屏设备
        
        previousViewSize = view.bounds.size
        isPreviousLandscape = JKisLandscape
        
        viewOrientationDidChange()
    }
    
    ///*
    open override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        let isEqualSize: Bool = __CGSizeEqualToSize(size, willTransitionToSize)

        if isEqualSize { return }

        willTransitionToSize = size

        isOrientationWillChange = true

        viewOrientationWillChange()
    }
     // */
    
    open override var modalPresentationCapturesStatusBarAppearance: Bool {
        set { super.modalPresentationCapturesStatusBarAppearance = newValue }
        get { true }
    }
    
    open override var preferredStatusBarStyle: UIStatusBarStyle {
        
        .lightContent
    }
    
    // MARK:
    // MARK: - Build UI
    
    open func p_buildUI() {
        
        //view.insertSubview(contentView, at: 0)
        //view.addSubview(navigationBarView)
        //view.addSubview(indicatorView)
    }
    
    // MARK:
    // MARK: - Property
    
    private var willTransitionToSize: CGSize = .zero
    
    private var isOrientationWillChange: Bool = false
}
