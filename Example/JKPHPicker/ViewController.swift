//
//  ViewController.swift
//  JKPHPicker
//
//  Created by albert on 06/18/2022.
//  Copyright (c) 2022 albert. All rights reserved.
//

import UIKit
import JKPHPicker
import JKSwiftLibrary
import PhotosUI
import CoreServices
import MobileCoreServices

class ViewController: UIViewController {
    
    // MARK:
    // MARK: - Public Property
    
    
    
    // MARK:
    // MARK: - Public Methods
    
    
    
    // MARK:
    // MARK: - Override
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        if #available(iOS 13.0, *) {
            return .darkContent
        } else {
            return .default
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        tipLabel.isHidden = true
        tipLabel.textColor = .red
        tipLabel.textAlignment = .center
        
        imageView.contentMode = .scaleAspectFit
        imageView.layer.borderWidth = 0.5
        imageView.layer.borderColor = UIColor.orange.cgColor
        
        imageView.isUserInteractionEnabled = true
        
        let editedTapGesture = UITapGestureRecognizer(target: self, action: #selector(tapAction(gesture:)))
        imageView.addGestureRecognizer(editedTapGesture)
        
        selectedImageView.contentMode = .scaleAspectFit
        selectedImageView.layer.borderWidth = 0.5
        selectedImageView.layer.borderColor = UIColor.orange.cgColor
        
        selectedImageView.isUserInteractionEnabled = true
        
        let selectedTapGesture = UITapGestureRecognizer(target: self, action: #selector(tapAction(gesture:)))
        selectedImageView.addGestureRecognizer(selectedTapGesture)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let imageWH = min(view.bounds.width, view.bounds.height) - 40.0
        
        let totalHeight: CGFloat = imageWH + 200.0
        
        let hstackViewSize = CGSize(width: 300.0, height: 150.0)
        hStackView.frame = CGRect(x: (view.bounds.width - hstackViewSize.width) * 0.5, y: (view.bounds.height - totalHeight) * 0.5, width: hstackViewSize.width, height: hstackViewSize.height)
        
        tipLabel.frame = CGRect(x: 15.0, y: hStackView.frame.maxY + 10.0, width: view.bounds.width - 30.0, height: 30.0)
        
        imageView.frame = CGRect(x: (view.bounds.width - imageWH) * 0.5, y: tipLabel.frame.maxY + 10.0, width: imageWH, height: imageWH)
    }
    
    @available(iOS 11.0, *)
    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        
        /*
        JKPHPicker.show(withConfiguration: nil).fromViewController(self).exportItemHandler { _ in
            
        }.exportImageHandler { _ in
            
        }.exportVideoHandler { _ in
            
        }.exportDataHandler { _ in
            
        }
         // */
    }
    
    // MARK:
    // MARK: - Private Methods
    
    private func showEditVC(image: UIImage, configuration: JKPHPickerEditConfiguration) {
        
        let vc = JKPHPickerEditViewController(image: image, configuration: configuration)
        vc.modalPresentationStyle = .fullScreen
        
        weak var weakVC = vc
        
        configuration.cancelHandler = { [weak self] configuration in
            
            guard let _ = self, let _ = weakVC else { return }
            
            weakVC?.dismiss(animated: true)
        }
        
        configuration.editResultHandler = { [weak self] configuration, editedImage in
            
            guard let _ = self, let _ = weakVC else { return }
            
            weakVC?.dismiss(animated: true)
            
            self?.imageView.image = editedImage
            
            guard let image = editedImage else {
                
                return
            }
            
            if configuration.isAutoSaveTopPhotoLibrary {
                
                return
            }
            
            var style = UIAlertController.Style.actionSheet
            
            if JKisDeviceiPad {
                
                style = .alert
            }
            
            let alert = UIAlertController(title: nil, message: nil, preferredStyle: style)
            
            alert.addAction(UIAlertAction(title: "保存到相册", style: .default, handler: { [weak self] _ in
                
                guard let _ = self else { return }
                
                self?.checkSaveImageToPhotoLibrary(image)
            }))
            
            alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: { _ in
                
            }))
            
            self?.present(alert, animated: true, completion: nil)
        }
        
        present(vc, animated: true, completion: nil)
    }
    
    private func showEditSheet(image: UIImage, isEditedImage: Bool) {
        
        let alert = UIAlertController(title: (isEditedImage ? "已编辑的图片" : "选择的原图"), message: nil, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "9 : 16可翻转", style: .default, handler: { _ in
            
            let configuration = JKPHPickerEditConfiguration(clipRatio: CGPoint(x: 9.0, y: 16.0), isClipCircle: false)
            configuration.isRatioReverseEnabled = true
            
            self.showEditVC(image: image, configuration: configuration)
        }))
        
        alert.addAction(UIAlertAction(title: "16 : 9可翻转", style: .default, handler: { _ in
            
            let configuration = JKPHPickerEditConfiguration(clipRatio: CGPoint(x: 16.0, y: 9.0), isClipCircle: false)
            configuration.isRatioReverseEnabled = true
            
            self.showEditVC(image: image, configuration: configuration)
        }))
        
        alert.addAction(UIAlertAction(title: "9 : 16不可翻转", style: .default, handler: { _ in
            
            let configuration = JKPHPickerEditConfiguration(clipRatio: CGPoint(x: 9.0, y: 16.0), isClipCircle: false)
            
            self.showEditVC(image: image, configuration: configuration)
        }))
        
        alert.addAction(UIAlertAction(title: "16 : 9不可翻转", style: .default, handler: { _ in
            
            let configuration = JKPHPickerEditConfiguration(clipRatio: CGPoint(x: 16.0, y: 9.0), isClipCircle: false)
            
            self.showEditVC(image: image, configuration: configuration)
        }))
        
        alert.addAction(UIAlertAction(title: "方形裁剪", style: .default, handler: { _ in
            
            let configuration = JKPHPickerEditConfiguration(clipRatio: CGPoint(x: 1.0, y: 1.0), isClipCircle: false)
            
            self.showEditVC(image: image, configuration: configuration)
        }))
        
        alert.addAction(UIAlertAction(title: "圆形裁剪", style: .default, handler: { _ in
            
            let configuration = JKPHPickerEditConfiguration(clipRatio: .zero, isClipCircle: true)
            
            self.showEditVC(image: image, configuration: configuration)
        }))
        
        alert.addAction(UIAlertAction(title: "自由裁剪", style: .default, handler: { _ in
            
            let configuration = JKPHPickerEditConfiguration()
            
            self.showEditVC(image: image, configuration: configuration)
        }))
        
        if isEditedImage {
            
            alert.addAction(UIAlertAction(title: "保存到相册", style: .default, handler: { _ in
                
                self.checkSaveImageToPhotoLibrary(image)
            }))
        }
        
        alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: { _ in
            
        }))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    private func checkSaveImageToPhotoLibrary(_ image: UIImage) {
        
        JKAuthorization.checkPhotoLibraryAuthorization(isAddOnly: true) { isNotDeterminedAtFirst, status in
            
            if status == .authorized || status == .limited {
                
                self.saveImageToPhotoLibrary(image)
                
                return
            }
            
            JKAuthorization.showTipAlert(viewController: self, type: .photoLibrary)
        }
    }
    
    private func saveImageToPhotoLibrary(_ image: UIImage) {
        
        let isPng = image.jk.isAlphaChannelImage
        
        var data: Data? = nil
        
        if isPng {
            
            data = image.pngData()
        }
        
        PHPhotoLibrary.shared().performChanges {
            
            if isPng, let pngData = data {
                
                let options = PHAssetResourceCreationOptions()
                
                PHAssetCreationRequest.forAsset().addResource(with: .photo, data: pngData, options: options)
                
                return
            }
            
            PHAssetChangeRequest.creationRequestForAsset(from: image)
            
        } completionHandler: { [weak self] isSuccess, error in
            
            DispatchQueue.main.async {
                
                guard let _ = self else { return }
                
                if isSuccess {
                    
                    self?.showTip(text: "保存成功")
                    
                } else {
                    
                    self?.showTip(text: error?.localizedDescription ?? "保存失败")
                }
            }
        }
    }
    
    private func solvePhotoLibraryErrorStatus(_ status: JKAuthorizationStatus) {
        
        var message: String?
        
        var verifyTitle = "确定"
        
        var verifyHandler: ((UIAlertAction) -> Void)?
        
        switch status {
            
        case .denied:
            
            verifyTitle = "去打开"
            message = "当前APP未获得相册权限\n前往设置打开？"
            
            verifyHandler = { _ in
                
                guard let settingURL = URL(string: UIApplication.openSettingsURLString) else { return }
                
                if !UIApplication.shared.canOpenURL(settingURL) { return }
                
                UIApplication.shared.open(settingURL, options: [:], completionHandler: nil)
            }
            
        case .restricted:
            
            message = "相册权限受限"
            
        default:
            return
        }
        
        let alertController = UIAlertController(title: "提示", message: message, preferredStyle: .alert)
        
        let cancelAction = UIAlertAction(title: "取消", style: .default, handler: nil)
        let verifyAction = UIAlertAction(title: verifyTitle, style: .default, handler: verifyHandler)
        
        alertController.addAction(cancelAction)
        alertController.addAction(verifyAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    private func showTip(text: String) {
        
        tipLabel.text = text
        tipLabel.alpha = 0.0
        tipLabel.isHidden = false
        
        UIView.animate(withDuration: 0.25) {
            
            self.tipLabel.alpha = 1.0
            
        } completion: { _ in
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                
                UIView.animate(withDuration: 0.25) {
                    
                    self.tipLabel.alpha = 0.0
                    
                } completion: { _ in
                    
                    self.tipLabel.isHidden = true
                    self.tipLabel.alpha = 1.0
                }
            }
        }
    }
    
    // MARK:
    // MARK: - Private Selector
    
    @objc private func tapAction(gesture: UILongPressGestureRecognizer) {
        
        guard gesture.state == .ended,
              let gestureView = gesture.view as? UIImageView,
              let image = gestureView.image else {
                  
                  return
              }
        
        if gestureView == selectedImageView {
            
            showEditSheet(image: image, isEditedImage: false)
            
            return
        }
        
        showEditSheet(image: image, isEditedImage: true)
    }
    
    private var totalMaxCount = 9
    private var videoMaxCount = 3
    private var isSelectVideoSimultaneously = true
    
    @IBAction func customJKPHPicker(_ sender: Any) {
        
        let alert = UIAlertController(title: "提示", message: nil, preferredStyle: .alert)
        
        var textField1: UITextField?
        var textField2: UITextField?
        
        alert.addTextField { [weak self] textField in
            
            guard let _ = self else { return }
            
            textField.font = UIFont.systemFont(ofSize: 15.0)
            
            textField1 = textField
            
            let leftView = UILabel(frame: CGRect(x: 0.0, y: 0.0, width: 100.0, height: 50.0))
            leftView.textColor = .darkGray
            leftView.font = UIFont.systemFont(ofSize: 15.0)
            leftView.textAlignment = .left
            leftView.text = "总的最大数量: "
            
            var leftViewSize = leftView.sizeThatFits(CGSize(width: CGFloat.infinity, height: 50.0))
            leftViewSize.width += 10.0
            leftView.frame.size = leftViewSize
            
            textField.leftView = leftView
            
            textField.leftViewMode = .always
            
            textField.text = "\(self!.totalMaxCount)"
        }
        
        alert.addTextField { [weak self] textField in
            
            guard let _ = self else { return }
            
            textField.font = UIFont.systemFont(ofSize: 15.0)
            
            textField2 = textField
            
            let leftView = UILabel(frame: CGRect(x: 0.0, y: 0.0, width: 100.0, height: 50.0))
            leftView.textColor = .darkGray
            leftView.font = UIFont.systemFont(ofSize: 15.0)
            leftView.textAlignment = .left
            leftView.text = "视频最大数量: "
            
            var leftViewSize = leftView.sizeThatFits(CGSize(width: CGFloat.infinity, height: 50.0))
            leftViewSize.width += 10.0
            leftView.frame.size = leftViewSize
            
            textField.leftView = leftView
            
            textField.leftViewMode = .always
            
            textField.text = "\(self!.videoMaxCount)"
        }
        
        let action1 = UIAlertAction(title: "同时", style: .default) { [weak self] _ in
            
            let text1 = textField1?.text ?? "9"
            let text2 = textField2?.text ?? "3"
            
            self?.totalMaxCount = Int(text1) ?? 9
            self?.videoMaxCount = Int(text2) ?? 3
            self?.isSelectVideoSimultaneously = true
            
            self?.showJKPHPicker()
        }
        
        let action2 = UIAlertAction(title: "不同时", style: .default) { [weak self] _ in
            
            let text1 = textField1?.text ?? "9"
            let text2 = textField2?.text ?? "3"
            
            self?.totalMaxCount = Int(text1) ?? 9
            self?.videoMaxCount = Int(text2) ?? 3
            self?.isSelectVideoSimultaneously = false
            
            self?.showJKPHPicker()
        }
        
        let action3 = UIAlertAction(title: "取消", style: .cancel)
        
        alert.addAction(action1)
        alert.addAction(action2)
        alert.addAction(action3)
        
        present(alert, animated: true, completion: nil)
    }
    
    private func showJKPHPicker() {
        
        var filter = JKPHPickerFilter()
        filter.selectionTypes = .all
        filter.totalMaxCount = totalMaxCount
        filter.videoMaxCount = videoMaxCount
        
        let configuration = JKPHPickerConfiguration(filter: filter)
        configuration.isEditable = true
        configuration.isShowCameraItem = true
        configuration.isShowsOriginalButton = true
        configuration.isObservePhotoLibraryChange = true
        
        configuration.isSelectVideoSimultaneously = isSelectVideoSimultaneously
        
        configuration.resultHandler = { selectedItems in
            
            JKPHPickerEngine.exportImage(with: selectedItems, scale: 1.0) { totalProgress in
                
                print("totalProgress-->\(totalProgress)")
                
            } completionHandler: { [weak self] dataArray in
                
                guard let _ = self else { return }
                
                if let firstResult = dataArray.first,
                   let firstImage = firstResult.image {
                    
                    // TODO: - JKTODO <#注释#>
                    if let data = firstImage.data {
                        
                        let maxByteCount = 5 * 1024 * 1024
                        
                        UIImage.compressAsync(image: firstImage, maxBytes: maxByteCount) { compressedImage in
                            
                            if let resizeImage = compressedImage,
                               let resizeData = resizeImage.data {
                                
                                print("原图大小: \(firstImage.size.width)x\(firstImage.size.height)  \(data.count) bytes")
                                print("压缩大小: \(resizeImage.size.width)x\(resizeImage.size.height)  \(resizeData.count) bytes")
                                print("")
                                
                                self?.selectedImageView.image = resizeImage
                                
                                self?.showEditSheet(image: resizeImage, isEditedImage: false)
                                
                                return
                            }
                            
                            self?.selectedImageView.image = firstImage
                            
                            self?.showEditSheet(image: firstImage, isEditedImage: false)
                        }
                        
                        return
                    }
                    
                    self?.selectedImageView.image = firstImage
                    
                    self?.showEditSheet(image: firstImage, isEditedImage: false)
                }
            }
        }
        
        configuration.failureHandler = { [weak self] status in
            
            guard let _ = self else { return }
            
            self?.solvePhotoLibraryErrorStatus(status)
        }
        
        JKPHPicker.show(with: configuration, from: self)
    }
    
    @IBAction func systemPHPicker(_ sender: UIButton) {
        
        if #available(iOS 14, *) {
            var configuration = PHPickerConfiguration()
            if #available(iOS 15, *) {
                configuration.selection = .default
            } else {
                // Fallback on earlier versions
            }
            configuration.selectionLimit = 1
            //configuration.filter = .any(of: [.videos, .livePhotos])
            let picker = PHPickerViewController(configuration: configuration)
            picker.delegate = self
            present(picker, animated: true, completion: nil)
        }
    }
    
    @IBAction func systemUIIMagePicker(_ sender: UIButton) {
        
        var style = UIAlertController.Style.actionSheet
        
        if JKisDeviceiPad {
            
            style = .alert
        }
        
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: style)
        
        let action1 = UIAlertAction(title: "相机", style: .default) { [weak self] _ in
            
            guard let _ = self else { return }
            
            self?.showCamera()
        }
        
        let action2 = UIAlertAction(title: "相册", style: .default) { [weak self] _ in
            
            guard let _ = self else { return }
            
            self?.showUIImagePicker()
        }
        
        let action3 = UIAlertAction(title: "取消", style: .cancel)
        
        alert.addAction(action1)
        alert.addAction(action2)
        alert.addAction(action3)
        
        present(alert, animated: true, completion: nil)
    }
    
    private func showUIImagePicker() {
        
        guard UIImagePickerController.isSourceTypeAvailable(.photoLibrary) else {
            
            return
        }
        
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.mediaTypes = [String(kUTTypeImage), String(kUTTypeMovie)]
        picker.delegate = self
        present(picker, animated: true, completion: nil)
    }
    
    private func showCamera() {
        
        guard UIImagePickerController.isSourceTypeAvailable(.camera),
              UIImagePickerController.isCameraDeviceAvailable(.rear),
              UIImagePickerController.isCameraDeviceAvailable(.front) else {
                  
                  return
              }
        
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.mediaTypes = [String(kUTTypeImage)]
        picker.cameraCaptureMode = .photo
        picker.delegate = self
        present(picker, animated: true, completion: nil)
    }
    
    // MARK:
    // MARK: - Initialization & Build UI
    
    
    
    // MARK:
    // MARK: - Private Property
    
    @IBOutlet weak var hStackView: UIStackView!
    
    @IBOutlet weak var vStackView: UIStackView!
    
    @IBOutlet private weak var imageView: UIImageView!
    
    @IBOutlet private weak var selectedImageView: UIImageView!
    
    @IBOutlet private weak var tipLabel: UILabel!
}

// MARK:
// MARK: - PHPickerViewControllerDelegate

extension ViewController: PHPickerViewControllerDelegate {
    
    @available(iOS 14, *)
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        
        picker.dismiss(animated: true) { [weak self] in
            
            guard let _ = self else { return }
            
            self?.solveResults(results)
        }
    }
    
    @available(iOS 14, *)
    private func solveResults(_ results: [PHPickerResult]) {
        
        guard results.count > 0 else { return }
        
        let itemProvider = results.first!.itemProvider
        
        /*
        if itemProvider.canLoadObject(ofClass: PHLivePhoto.self) {
            
            itemProvider.loadObject(ofClass: PHLivePhoto.self) { reading, error in
                
                if let livePhoto = reading as? PHLivePhoto {
                    
                    
                }
            }
            
        } else // */if itemProvider.canLoadObject(ofClass: UIImage.self) {
            
            itemProvider.loadObject(ofClass: UIImage.self) { [weak self] reading, error in
                
                guard let _ = self else { return }
                
                if let image = reading as? UIImage {
                    
                    DispatchQueue.main.async {
                        
                        self?.selectedImageView.image = image
                        
                        self?.showEditSheet(image: image, isEditedImage: false)
                    }
                }
            }
            
        } else {
            
            itemProvider.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { videoUrl, error in
                
                if let url = videoUrl {
                    
                    
                }
            }
        }
    }
    
}

// MARK:
// MARK: - UIImagePickerControllerDelegate

extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    open func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        
        picker.dismiss(animated: true, completion: nil)
    }
    
    open func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        picker.dismiss(animated: true) {
            
            if let image = info[.originalImage] as? UIImage { // 图片
                
                self.selectedImageView.image = image
                
                self.showEditSheet(image: image, isEditedImage: false)
                
            } else if let videoUrl = info[.mediaURL] as? URL,
                      FileManager.default.fileExists(atPath: videoUrl.path) { // 视频
                
            }
        }
    }
}


/** 分隔线
 
 浅色模式
 
 分隔线 frame = (0.0, 65.66666666666667, 428.0, 0.3333333333333333) r = 0.23529411764705882 g = 0.23529411764705882 b = 0.2627450980392157 a = 0.29
 分隔线 RGB r = 0.23529411764705882 g = 0.23529411764705882 b = 0.2627450980392157 a = 0.29
 
 60,60,67,0.29
 
 分隔线 #AARRGGBB = #493C3C43
 分隔线 #RRGGBB = #3C3C43
 
 
 
 
 深色模式
 
 分隔线 frame = (0.0, 65.66666666666667, 428.0, 0.3333333333333333) r = 0.32941176470588235 g = 0.32941176470588235 b = 0.34509803921568627 a = 0.6
 分隔线 RGB r = 0.32941176470588235 g = 0.32941176470588235 b = 0.34509803921568627 a = 0.6
 
 84,84,88,0.6
 
 分隔线 #AARRGGBB = #99545458
 分隔线 #RRGGBB = #545458
 
 */

extension UIColor {
    
    func toHexString(containNumberSign: Bool = true, containAlpha: Bool = false) -> String {
        
        var r: CGFloat = 0.0
        var g: CGFloat = 0.0
        var b: CGFloat = 0.0
        var a: CGFloat = 0.0
        
        getRed(&r, green: &g, blue: &b, alpha: &a)
        
        r = r * 255.0
        g = g * 255.0
        b = b * 255.0
        a = a * 255.0
        
        let numberSign = containNumberSign ? "#" : ""
        
        if containAlpha {
            
            let rgba = Int(a) << 24 | Int(r) << 16 | Int(g) << 8 | Int(b)
            
            return String(format: "%@%08X", numberSign, rgba)
        }
        
        let rgb = Int(r) << 16 | Int(g) << 8 | Int(b)
        
        return String(format: "%@%06X", numberSign, rgb)
    }
}

// TODO: - JKTODO <#注释#>
extension UIImage {
    
    var data: Data? {
        
        let isPng = jk.isAlphaChannelImage
        
        return isPng ? pngData() : jpegData(compressionQuality: 1.0)
    }
    
    static func compressAsync(image: UIImage?, maxBytes: Int, completion: ((_ compressedImage: UIImage?) -> Void)?) {
        
        guard let realImage = image else {
            
            if let handler = completion {
                
                handler(nil)
            }
            
            return
        }
        
        JKGlobalQueue.async {
            
            let image = compress(image: realImage, maxBytes: maxBytes)
            
            DispatchQueue.main.async {
                
                if let handler = completion {
                    
                    handler(image)
                }
            }
        }
    }
    
    static func compress(image: UIImage?, maxBytes: Int) -> UIImage? {
        
        guard let realImage = image else { return nil }
        
        let isPng = realImage.jk.isAlphaChannelImage
        
        var data: Data?
        
        if isPng {
            
            data = realImage.pngData()
            
        } else {
            
            data = realImage.jpegData(compressionQuality: 1.0)
        }
        
        guard let imageData = data else {
            
            return nil
        }
        
        if imageData.count <= maxBytes {
            
            return realImage
        }
        
        let compressScale = Double(maxBytes) / Double(imageData.count)
        
        let compressSize = CGSize(width: realImage.size.width * compressScale, height: realImage.size.height * compressScale)
        
        guard let image = resizeImageData(imageData, pixelSize: compressSize) else {
            
            return nil
        }
        
        return compress(image: image, maxBytes: maxBytes)
    }
    
    static func resizeImage(_ image: UIImage, pixelSize: CGSize) -> UIImage? {
        
        guard let data = image.data else { return nil }
        
        return resizeImageData(data, pixelSize: pixelSize)
    }
    
    static func resizeImageData(_ data: Data, pixelSize: CGSize) -> UIImage? {
        
        //let imageSource = CGImageSourceCreateWithURL(url, nil)
        guard let imageSource = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        
        let maxPixelSize = max(pixelSize.width, pixelSize.height)
        
        // kCGImageSourceThumbnailMaxPixelSize为生成缩略图的大小
        let options: [NSString: Any] = [
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
            kCGImageSourceCreateThumbnailFromImageAlways: true
        ]
        
        let resizedImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options as CFDictionary).flatMap {
            
            UIImage(cgImage: $0)
        }
        
        return resizedImage
    }
}

