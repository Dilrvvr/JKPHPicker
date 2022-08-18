//
//  JKPHPickerViewController.swift
//  JKSwiftPhotoPicker
//
//  Created by AlbertCC on 2021/5/4.
//

import UIKit
import AVKit
import PhotosUI
import JKSwiftLibrary

open class JKPHPickerViewController: JKPHPickerBaseViewController {
    
    // MARK:
    // MARK: - Public Function
    
    open class func show(with configuration: JKPHPickerConfiguration,
                         from viewController: UIViewController,
                         completion: ((_ topNavigationController: UINavigationController?) -> Void)? = nil) {
        
        let vc = JKPHPickerViewController(configuration: configuration)
        let nav = JKPHPickerNavigationController(rootViewController: vc)
        
        viewController.present(nav, animated: true) { [weak nav] in
            
            if let handler = completion {
                
                handler(nav)
            }
        }
        
        // TODO: - JKTODO Warning: Attempt to present <JKSwiftPhotoPicker.JKPHPickerNavigationController: 0x10509d600> on <JKSwiftPhotoPicker.ViewController: 0x10600bcf0> whose view is not in the window hierarchy!
    }
    
    // MARK:
    // MARK: - Override
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    open override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        checkViewOrientationWillChange()
    }
    
    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        pickerView.frame = view.bounds
        
        if let _ = browserView {
            
            browserView?.frame = view.bounds
        }
        
        checkViewOrientationDidChange()
    }
    
    open override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation { .fade }
    
    open override var prefersStatusBarHidden: Bool {
        
        if JKisDeviceiPad {
            
            return statusBarHidden
        }
        
        if JKisLandscape {
            
            return true
        }
        
        return statusBarHidden
    }
    
    open override func viewOrientationWillChange() {
        
        pickerView.viewOrientationWillChange()
        
        if let _ = browserView {
            
            browserView?.viewOrientationWillChange()
        }
    }
    
    open override func viewOrientationDidChange() {
        
        pickerView.viewOrientationDidChange()
        
        if let _ = browserView {
            
            browserView?.viewOrientationDidChange()
        }
    }
    
    // MARK:
    // MARK: - Private Function
    
    private func dismissPicker() {
        
        guard let _ = navigationController else {
            
            dismiss(animated: true, completion: nil)
            
            return
        }
        
        navigationController?.dismiss(animated: true, completion: nil)
    }
    
    // MARK:
    // MARK: - Private Selector
    
    
    
    // MARK:
    // MARK: - Build UI
    
    /// p_buildUI
    open override func p_buildUI() {
        super.p_buildUI()
        
        view.insertSubview(pickerView, at: 0)
    }
    
    // MARK:
    // MARK: - Private Property
    
    private var statusBarHidden = false {
        didSet {
            setNeedsStatusBarAppearanceUpdate()
        }
    }
    
    /// pickerView
    private lazy var pickerView: JKPHPickerView = {
        
        let pickerView = JKPHPickerView(frame: view.bounds, configuration: self.configuration)
        
        pickerView.delegate = self
        pickerView.navigationBarDelegate = self
        
        return pickerView
    }()
    
    /// browserView
    private weak var browserView: JKPHPickerBrowserView?
    
    open func createBrowserView() -> JKPHPickerBrowserView {
        
        let browserView = JKPHPickerBrowserView(frame: view.bounds, configuration: self.configuration)
        
        browserView.lifeDelegate = self
        browserView.actionDelegate = self
        
        return browserView
    }
}

// MARK:
// MARK: - JKPHPickerViewDelegate

extension JKPHPickerViewController: JKPHPickerViewDelegate {
    
    open func pickerViewInViewController(_ pickerView: JKPHPickerView) -> UIViewController {
        
        return self
    }
    
    open func pickerViewDismissBrowser(_ pickerView: JKPHPickerView) {
        
        guard let _ = browserView else { return }
        
        browserView?.dismiss()
    }
    
    open func pickerViewDismiss(_ pickerView: JKPHPickerView) {
        
        dismissPicker()
    }
    
    open func pickerViewReloadBrowser(_ pickerView: JKPHPickerView) {
        
        guard let _ = browserView else { return }
        
        browserView?.reloadData()
    }
    
    open func pickerView(_ pickerView: JKPHPickerView,
                         didSelect photoItem: JKPHPickerPhotoItem) {
        
        if let _ = browserView {
            
            browserView?.removeFromSuperview()
        }
        
        let realBrowserView = createBrowserView()
        view.addSubview(realBrowserView)
        browserView = realBrowserView
        
        browserView?.solve(photoItem: photoItem, dataSource: pickerView, delegate: pickerView)
    }
}

// MARK:
// MARK: - JKPHPickerNavigationBarDelegate

extension JKPHPickerViewController: JKPHPickerNavigationBarDelegate {
    
    open func navigationBarView(_ navigationBarView: JKPHPickerNavigationBarView, didTapBack button: UIButton) {
        
        //navigationController?.popViewController(animated: true)
    }
    
    open func navigationBarView(_ navigationBarView: JKPHPickerNavigationBarView, didTapClose button: UIButton) {
        
        dismissPicker()
    }
    
    open func navigationBarView(_ navigationBarView: JKPHPickerNavigationBarView, didTapLeft2 button: UIButton) {
        
    }
    
    open func navigationBarView(_ navigationBarView: JKPHPickerNavigationBarView, didTapRight button: UIButton) {
        
    }
    
    open func navigationBarView(_ navigationBarView: JKPHPickerNavigationBarView, didTapRight2 button: UIButton) {
        
    }
}

// MARK:
// MARK: - JKPHPickerBrowserViewLifeDelegate

extension JKPHPickerViewController: JKPHPickerBrowserViewLifeDelegate {
    
    open func browserViewWillDismiss(_ browserView: JKPHPickerBrowserView) {
        
        statusBarHidden = false
    }
    
    open func browserViewDidDismiss(_ browserView: JKPHPickerBrowserView) {
        
    }
}

// MARK:
// MARK: - JKPHPickerBrowserViewActionDelegate

extension JKPHPickerViewController: JKPHPickerBrowserViewActionDelegate {
    
    open func browserView(_ browserView: JKPHPickerBrowserView, playVideo playerItem: AVPlayerItem, photoItem: JKPHPickerPhotoItem) {
        
        try? AVAudioSession.sharedInstance().setActive(true)
        try? AVAudioSession.sharedInstance().setCategory(.playback)
        
        let vc = AVPlayerViewController()
        vc.allowsPictureInPicturePlayback = false
        
        let player = AVPlayer(playerItem: playerItem)
        vc.player = player
        
        present(vc, animated: true) {
            
            player.play()
        }
    }
    
    open func browserViewDidSingleTap(_ browserView: JKPHPickerBrowserView) {
        
        statusBarHidden = !statusBarHidden
    }
}
