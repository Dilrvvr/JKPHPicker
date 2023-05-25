//
//  JKPHPickerEditView.swift
//  JKSwiftPhotoPicker
//
//  Created by albert on 2022/1/7.
//

import UIKit
import JKSwiftLibrary
import CoreImage
import Photos

open class JKPHPickerEditView: JKPHPickerUIView {
    
    private static let queue = DispatchQueue(label: "com.albert.JKPHPickerEdit")
    
    private static let lineThickness: CGFloat = 1.0//JKLineThickness
    
    private enum DragCorner: Int {
        case center = 0
        case topLeft
        case topRight
        case bottomLeft
        case bottomRight
        case topCenter
        case bottomCenter
        case leftCenter
        case rightCenter
    }
    
    private struct DragLimit {
        
        var minX: CGFloat = 0.0
        var minY: CGFloat = 0.0
        
        var maxX: CGFloat = 0.0
        var maxY: CGFloat = 0.0
        
        var minWidth: CGFloat = 0.0
        var minHeight: CGFloat = 0.0
        
        var maxWidth: CGFloat = 0.0
        var maxHeight: CGFloat = 0.0
    }
    
    private static var bottomControlHeight: CGFloat {
        
        if JKisDeviceiPad {
            
            return 44.0 + JKBottomSafeAreaInset
        }
        
        if JKisLandscape {
            
            return (JKScreenHeight > 400.0 ? 44.0 : 32.0) + JKBottomSafeAreaInset
        }
        
        return 44.0 + JKBottomSafeAreaInset
    }
    
    // MARK:
    // MARK: - Public Property
    
    public private(set) var originalImage: UIImage
    
    // MARK:
    // MARK: - Public Methods
    
    
    
    // MARK:
    // MARK: - Override
    
    private var configuration: JKPHPickerEditConfiguration
    
    public init(image: UIImage, configuration: JKPHPickerEditConfiguration, frame: CGRect) {
        
        self.originalImage = image
        self.configuration = configuration
        
        super.init(frame: frame)
    }
    
    public required init?(coder: NSCoder) {
        
        self.originalImage = UIImage()
        self.configuration = JKPHPickerEditConfiguration()
        
        super.init(coder: coder)
    }
    
    open override var isUserInteractionEnabled: Bool {
        
        didSet {
            
            let actionAlpha = isUserInteractionEnabled ? 1.0 : 0.3
            
            let animations = {
                
                self.rotateButton.alpha = actionAlpha
                self.flipButton.alpha = actionAlpha
                self.cancelButton.alpha = actionAlpha
                self.resetButton.alpha = actionAlpha
                self.completeButton.alpha = actionAlpha
            }
            
            guard isUserInteractionEnabled else {
                
                animations()
                
                return
            }
            
            UIView.animate(withDuration: 0.25, animations: animations)
        }
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        
        updateLayout()
    }
    
    private func updateClipBorderRect() {
        
        if configuration.isClipRatio {
            
            var clipWidth = borderMaxRect.width
            
            var clipHeight = JKGetScaleHeight(currentWidth: clipWidth, scaleWidth: configuration.clipRatio.x, scaleHeight: configuration.clipRatio.y)
            
            if clipHeight > borderMaxRect.height {
                
                clipHeight = borderMaxRect.height
                
                clipWidth = JKGetScaleWidth(currentHeight: clipHeight, scaleWidth: configuration.clipRatio.x, scaleHeight: configuration.clipRatio.y)
            }
            
            defaultClipBorderRect = CGRect(x: borderMaxRect.minX + (borderMaxRect.width - clipWidth) * 0.5, y: borderMaxRect.minY + (borderMaxRect.height - clipHeight) * 0.5, width: clipWidth, height: clipHeight)
            
            initialClipBorderRect = defaultClipBorderRect
            
        } else {
            
            defaultClipBorderRect = borderMaxRect
            
            let clipSize = JKPHPickerUtility.calculateClipImageSize(editedImage.size, maxSize: borderMaxRect.size, minSize: borderMinSize, isRatio: false, isClipRect: true)
            
            initialClipBorderRect = CGRect(x: borderMaxRect.minX + (borderMaxRect.width - clipSize.width) * 0.5, y: borderMaxRect.minY + (borderMaxRect.height - clipSize.height) * 0.5, width: clipSize.width, height: clipSize.height)
        }
    }
    
    private func updateLayout() {
        
        statusBarCoverView.frame = CGRect(x: 0.0, y: 0.0, width: contentView.bounds.width, height: JKStatusBarHeight)
        
        let bottomHeight = Self.bottomControlHeight
        
        bottomControlView.frame = CGRect(x: 0.0, y: bounds.height - bottomHeight, width: bounds.width, height: bottomHeight)
        
        mainScrollView.frame = contentView.bounds
        
        clipCoverView.frame = contentView.bounds
        clipCoverShapeLayer.frame = clipCoverView.bounds
        
        if previousFrame.equalTo(.zero) ||
            !previousFrame.equalTo(frame) {
            
            currentClipBorderRect = nil
        }
        
        updateMaxBorder()
        
        bottomCoverView.frame = CGRect(x: 0.0, y: borderMaxRect.maxY - Self.lineThickness, width: contentView.bounds.width, height: contentView.bounds.height - (borderMaxRect.maxY - Self.lineThickness))
        
        updateCustomRatioLayout()
        
        tempMaxBorderView.frame = borderMaxRect
        
        updateClipRectViewLayout()
        
        tempDefaultBorderView.frame = defaultClipBorderRect
        
        updateImageViewSize()
        
        updateImageLayout()
    }
    
    private func updateCustomRatioLayout() {
        
        let rotateButtonWH: CGFloat = 25.0
        
        rotateButton.frame = CGRect(x: borderMaxRect.minX + 5.0, y: borderMaxRect.maxY + (borderInsets.bottom - Self.bottomControlHeight - rotateButtonWH) * 0.5, width: rotateButtonWH, height: rotateButtonWH)
        
        flipButton.frame = CGRect(x: borderMaxRect.midX - rotateButtonWH * 0.5, y: rotateButton.frame.minY, width: rotateButtonWH, height: rotateButtonWH)
        
        customRatioButton.frame = CGRect(x: borderMaxRect.maxX - 5.0 - rotateButtonWH, y: borderMaxRect.maxY + (borderInsets.bottom - Self.bottomControlHeight - rotateButtonWH) * 0.5, width: rotateButtonWH, height: rotateButtonWH)
        
        if configuration.isClipRatio { return }
        
        guard customRatioItemButtonArray.count > 0 else { return }
        
        let selectRatioButtonSize = CGSize(width: 40.0, height: 20.0)
        
        var selectRatioButtonMargin: CGFloat = 10.0
        
        customRatioContainerView.frame = CGRect(x: borderMaxRect.minX - selectRatioButtonMargin, y: customRatioButton.frame.minY, width: borderMaxRect.maxX - (borderMaxRect.minX - selectRatioButtonMargin) - 5.0, height: rotateButtonWH)
        
        let closeCustomRatioButtonWH = min(selectRatioButtonSize.width, selectRatioButtonSize.height) * 0.8
        
        closeCustomRatioButton.frame = CGRect(x: 0.0, y: (customRatioContainerView.bounds.height - closeCustomRatioButtonWH) * 0.5, width: closeCustomRatioButtonWH + selectRatioButtonMargin * 2.0, height: closeCustomRatioButtonWH)
        
        customRatioScrollView.frame = CGRect(x: closeCustomRatioButton.frame.maxX, y: 0.0, width: customRatioContainerView.bounds.width - closeCustomRatioButton.frame.maxX, height: customRatioContainerView.bounds.height)
        let selectRatioButtonY = (customRatioScrollView.bounds.height - selectRatioButtonSize.height) * 0.5
        
        guard customRatioItemButtonArray.count > 1 else {
            
            customRatioItemButtonArray[0].frame = CGRect(x: (customRatioScrollView.bounds.width - selectRatioButtonSize.width) * 0.5, y: selectRatioButtonY, width: selectRatioButtonSize.width, height: selectRatioButtonSize.height)
            
            customRatioScrollView.contentSize = .zero
            
            return
        }
        
        let selectRatioButtonCount = CGFloat(customRatioItemButtonArray.count)
        
        let totalSelectRatioButtonWidth = selectRatioButtonSize.width * selectRatioButtonCount
        
        let totalWidth = totalSelectRatioButtonWidth + selectRatioButtonMargin * (selectRatioButtonCount - 1.0)
        
        if totalWidth < customRatioScrollView.bounds.width {
            
            selectRatioButtonMargin = (customRatioScrollView.frame.width - totalSelectRatioButtonWidth) / (selectRatioButtonCount - 1.0)
        }
        
        for (index, button) in customRatioItemButtonArray.enumerated() {
            
            button.frame = CGRect(x: (selectRatioButtonSize.width + selectRatioButtonMargin) * CGFloat(index), y: selectRatioButtonY, width: selectRatioButtonSize.width, height: selectRatioButtonSize.height)
        }
        
        customRatioScrollView.contentSize = CGSize(width: totalWidth, height: 0.0)
    }
    
    private func updateClipRectViewLayout() {
        
        if let rect = currentClipBorderRect {
            
            clipRectView.frame = rect
            
        } else {
            
            updateClipBorderRect()
            
            clipRectView.frame = initialClipBorderRect
        }
        
        updateClipRectSubviewsLayout()
        
        updateDragViewLayout()
    }
    
    private func updateDragViewLayout() {
        
        let halfDragViewWH = dragViewWH * 0.5
        let cornerWH = cornerImageWH - cornerImageThickness
        
        let leftX = clipRectView.frame.minX - halfDragViewWH + cornerWH
        let rightX = clipRectView.frame.maxX + halfDragViewWH - cornerWH
        let topY = clipRectView.frame.minY - dragViewWH * 0.5 + cornerWH
        let bottomY = clipRectView.frame.maxY + halfDragViewWH - cornerWH
        
        for item in dragViewArray {
            
            guard let corner = DragCorner(rawValue: item.tag) else {
                
                continue
            }
            
            switch corner {
            case .topLeft:
                item.center = CGPoint(x: leftX, y: topY)
            case .topRight:
                item.center = CGPoint(x: rightX, y: topY)
            case .bottomLeft:
                item.center = CGPoint(x: leftX, y: bottomY)
            case .bottomRight:
                item.center = CGPoint(x: rightX, y: bottomY)
            case .topCenter:
                item.center = CGPoint(x: clipRectView.frame.midX, y: topY)
            case .bottomCenter:
                item.center = CGPoint(x: clipRectView.frame.midX, y: bottomY)
            case .leftCenter:
                item.center = CGPoint(x: leftX, y: clipRectView.frame.midY)
            case .rightCenter:
                item.center = CGPoint(x: rightX, y: clipRectView.frame.midY)
            default:
                item.center = clipRectView.center
            }
        }
    }
    
    private func updateImageLayout() {
        
        if !previousFrame.equalTo(.zero) &&
            previousFrame.equalTo(frame) &&
            (mainScrollView.zoomScale != 1.0) &&
            !previousImageViewSize.equalTo(.zero) &&
            previousImageViewSize.equalTo(imageViewSize) {

            updateScrollViewContentInset()

            return
        }
        
        previousImageViewSize = imageViewSize
        
        previousFrame = frame
        
        if imageViewSize.width <= 0.0 { return }
        
        mainScrollView.minimumZoomScale = 1.0
        mainScrollView.setZoomScale(1.0, animated: false)
        
        mainScrollView.contentSize = CGSize(width: imageViewSize.width, height: imageViewSize.height)
        
        displayImageView.frame = CGRect(x: 0.0, y: 0.0, width: imageViewSize.width, height: imageViewSize.height)
        
        mainScrollView.minimumZoomScale = minZoomScale
        mainScrollView.maximumZoomScale = maxZoomScale
        
        updateScrollViewContentInset()
        
        var offset = CGPoint.zero
        
        offset.x = -self.mainScrollView.contentInset.left
        offset.y = -self.mainScrollView.contentInset.top
        
        if self.imageViewSize.width > self.initialClipBorderRect.width {
            
            offset.x = -self.mainScrollView.contentInset.left + (self.imageViewSize.width - self.initialClipBorderRect.width) * 0.5
        }
        
        if self.imageViewSize.height > self.initialClipBorderRect.height {
            
            offset.y = -self.mainScrollView.contentInset.top + (self.imageViewSize.height - self.initialClipBorderRect.height) * 0.5
        }
        
        mainScrollView.setContentOffset(offset, animated: false)
    }
    
    private func layoutBottomControlViewUI() {
        
        let barContentView = bottomControlView.contentView
        
        let buttonH = min(barContentView.bounds.height - 6.0, 28.0)
        let buttonSize = CGSize(width: buttonH, height: buttonH)
        let buttonY = (barContentView.bounds.height - buttonSize.height) * 0.5
        
        completeButton.frame = CGRect(x: barContentView.bounds.width - 15.0 - buttonH, y: buttonY, width: buttonH, height: buttonSize.height)
        
        cancelButton.frame = CGRect(x: 15.0, y: buttonY, width: buttonH, height: buttonSize.height)
        
        resetButton.frame = CGRect(x: (barContentView.bounds.width - buttonSize.width) * 0.5, y: buttonY, width: buttonSize.width, height: buttonSize.height)
    }
    
    // MARK:
    // MARK: - Private Methods
    
    private func resetUI(isOriginal: Bool,
                         animated: Bool,
                         animations: (() -> Void)? = nil,
                         completion: (() -> Void)? = nil) {
        
        if isOriginal {
            
            configuration.resetRatio()
            
            if !configuration.isClipRatio {
                
                if let button = selectedCustomRatioItemButton {
                    
                    updateCustomRatioItemButtonStatus(button, isSelected: false)
                    
                    selectedCustomRatioItemButton = nil
                }
                
                if let button = customRatioItemButtonArray.first {
                    
                    updateCustomRatioItemButtonStatus(button, isSelected: true)
                    
                    selectedCustomRatioItemButton = button
                }
            }
        }
        
        currentClipBorderRect = nil
        
        isUserInteractionEnabled = false
        
        if isOriginal {
            
            _editedImage = nil
        }
        
        displayImageView.image = editedImage
        
        guard animated else {
            
            mainScrollView.setZoomScale(1.0, animated: false)
            
            updateLayout()
            
            isUserInteractionEnabled = true
            
            if let handler = animations {
                
                handler()
            }
            
            if let handler = completion {
                
                handler()
            }
            
            return
        }
        
        clipCoverShapeLayer.opacity = 0.0
        
        UIView.animate(withDuration: 0.25) {
            
            self.mainScrollView.setZoomScale(1.0, animated: false)
            
            self.updateLayout()
            
            if let handler = animations {
                
                handler()
            }
            
        } completion: { _ in
            
            self.updateClipCoverShape()
            self.clipCoverShapeLayer.opacity = 1.0
            
            self.isUserInteractionEnabled = true
            
            if let handler = completion {
                
                handler()
            }
        }
    }
    
    private func updateMaxBorder() {
        
        var safeInsets = JKSafeAreaInsets
        safeInsets.left = max(safeInsets.left, safeInsets.right)
        safeInsets.right = safeInsets.left
        safeInsets.top = max(safeInsets.top, safeInsets.bottom)
        safeInsets.top = safeInsets.bottom
        
        borderInsets = UIEdgeInsets(top: safeInsets.top + 23.0, left: safeInsets.left + 20.0, bottom: Self.bottomControlHeight + 60.0, right: safeInsets.right + 20.0)
        
        let frameMinWidth = borderInsets.left + borderInsets.right
        let frameMinHeight = borderInsets.top + borderInsets.bottom
        
        if frame.width > frameMinWidth &&
            frame.height > frameMinHeight {
            
            borderMaxSize = CGSize(width: frame.width - borderInsets.left - borderInsets.right, height: frame.height - borderInsets.top - borderInsets.bottom)
            
            firstZoomWidth = frame.width
            
        } else {
            
            let windowSize = JKKeyWindow.bounds.size
            
            borderMaxSize = CGSize(width: windowSize.width - borderInsets.left - borderInsets.right, height: windowSize.height - borderInsets.top - borderInsets.bottom)
            
            firstZoomWidth = windowSize.width
        }
        
        let borderMinWH = dragViewWH + (cornerImageWH - cornerImageThickness + Self.lineThickness) * 2.0
        
        var borderMinWidth = borderMinWH
        var borderMinHeight = borderMinWH
        
        if configuration.isClipRatio {
            
            borderMinHeight = JKGetScaleHeight(currentWidth: borderMinWidth, scaleWidth: configuration.clipRatio.x, scaleHeight: configuration.clipRatio.y)
        }
        
        if borderMinHeight < borderMinWH {
            
            borderMinHeight = borderMinWH
            
            borderMinWidth = JKGetScaleWidth(currentHeight: borderMinHeight, scaleWidth: configuration.clipRatio.x, scaleHeight: configuration.clipRatio.y)
        }
        
        borderMinSize = CGSize(width: borderMinWidth, height: borderMinHeight)
        
        borderMaxRect = CGRect(x: borderInsets.left, y: borderInsets.top, width: borderMaxSize.width, height: borderMaxSize.height)
    }
    
    private func updateImageViewSize() {
        
        let borderSize = defaultClipBorderRect.size
        
        imageViewSize = JKPHPickerUtility.calculateClipImageSize(editedImage.size, maxSize: borderSize, minSize: borderMinSize, isRatio: configuration.isClipRatio, isClipRect: false)
        
        // 保留2位小数
        maxZoomScale = floor(editedImage.size.width / imageViewSize.width * 100.0) / 100.0
        maxZoomScale = max(maxZoomScale, 1.0)
    }
    
    private func updateScrollViewContentInset() {
        
        //var leftRight: CGFloat = (borderMaxSize.width - displayImageView.frame.width) * 0.5
        //var topBottom: CGFloat = (borderMaxSize.height - displayImageView.frame.height) * 0.5
        
        //leftRight = max(0.0, leftRight)
        //topBottom = max(0.0, topBottom)
        
        let borderRect = currentClipBorderRect ?? initialClipBorderRect
        
        let leftInset = borderRect.minX
        let rightInset = frame.width - borderRect.maxX
        let topInset = borderRect.minY
        let bottomInset = frame.height - borderRect.maxY
        
        mainScrollView.contentInset = UIEdgeInsets(top: topInset, left: leftInset, bottom: bottomInset, right: rightInset)
    }
    
    private func drawToFixImageOrientation() -> UIImage? {
        
        if editedImage.imageOrientation == .up {
            
            return editedImage
        }
        
        let isPng = editedImage.jk.isAlphaChannelImage
        
        let isOpaque = !isPng
        
        UIGraphicsBeginImageContextWithOptions(editedImage.size, isOpaque, editedImage.scale)
        
        editedImage.draw(in: CGRect(x: 0.0, y: 0.0, width: editedImage.size.width, height: editedImage.size.height))
        
        guard let renderImage = UIGraphicsGetImageFromCurrentImageContext() else {
            
            UIGraphicsEndImageContext()
            
            return nil
        }
        
        UIGraphicsEndImageContext()
        
        return renderImage
    }
    
    private func clipImage(isExport: Bool, completeHandler: ((_ clipedImage: UIImage?) -> Void)?) {
        
        let convertRect = convert(clipRectView.frame, to: displayImageView)
        
        Self.queue.async {
            
            self.drawToClipImage(inImageRect: convertRect, isExport: isExport) { clipedImage in
                
                guard let handler = completeHandler else { return }
                
                DispatchQueue.main.async {
                    
                    handler(clipedImage)
                }
            }
        }
    }
    
    private func drawToClipImage(inImageRect: CGRect,
                                 isExport: Bool,
                                 completeHandler: ((_ clipedImage: UIImage?) -> Void)?) {
        
        let imageViewBounds = CGRect(x: 0.0, y: 0.0, width: imageViewSize.width, height: imageViewSize.height)
        
        guard imageViewBounds.width > 0.0,
              imageViewBounds.height > 0.0 else {
                  
                  if let handler = completeHandler {
                      
                      handler(nil)
                  }
                  
                  return
              }
        
        var inImageCenter = CGPoint(x: inImageRect.midX, y: inImageRect.midY)
        
        let scale = editedImage.size.width / imageViewBounds.width
        
        inImageCenter.x *= scale
        inImageCenter.y *= scale
        
        var drawRect = inImageRect
        
        drawRect.size.width *= scale
        drawRect.size.height *= scale
        
        drawRect.origin.x = inImageCenter.x - drawRect.size.width * 0.5
        drawRect.origin.y = inImageCenter.y - drawRect.size.height * 0.5
        
        let origin = CGPoint(x: -drawRect.origin.x, y: -drawRect.origin.y)
        
        let isPng = editedImage.jk.isAlphaChannelImage
        
        let isOpaque = !isPng
        
        UIGraphicsBeginImageContextWithOptions(drawRect.size, isOpaque, editedImage.scale)
        
        if configuration.isClipCircle {
            
            guard let ctx = UIGraphicsGetCurrentContext() else {
                
                if let handler = completeHandler {
                    
                    handler(nil)
                }
                
                return
            }
            
            ctx.addEllipse(in: CGRect(x: 0.0, y: 0.0, width: drawRect.width, height: drawRect.height))
            
            ctx.clip()
        }
        
        editedImage.draw(at: origin)
        
        let clipedImage = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        
        if let handler = completeHandler {
            
            handler(clipedImage)
        }
    }
    
    private func p_clipImage(inImageRect: CGRect,
                             isExport: Bool,
                             completeHandler: ((_ clipedImage: UIImage?) -> Void)?) {
        
        guard let renderImage = drawToFixImageOrientation(),
              let cgImage = renderImage.cgImage else {
                  
                  if let handler = completeHandler {
                      
                      handler(nil)
                  }
                  
                  return
              }
        
        let imageViewBounds = CGRect(x: 0.0, y: 0.0, width: imageViewSize.width, height: imageViewSize.height)
        
        guard imageViewBounds.width > 0.0,
              imageViewBounds.height > 0.0 else {
                  
                  if let handler = completeHandler {
                      
                      handler(nil)
                  }
                  
                  return
              }
        
        let inImageCenter = CGPoint(x: inImageRect.midX, y: inImageRect.midY)
        
        var imageRect = CGRect.zero
        imageRect.size = editedImage.size
        
        let scaleX = imageRect.width / imageViewBounds.width
        let scaleY = imageRect.height / imageViewBounds.height
        
        let clipCenter = CGPoint(x: round(inImageCenter.x * scaleX), y: round(inImageCenter.y * scaleY))
        
        var clipWidth = round(inImageRect.width * scaleX)
        var clipHeight = round(inImageRect.height * scaleY)
        
        clipWidth = min(clipWidth, imageRect.width)
        clipHeight = min(clipHeight, imageRect.height)
        
        var clipX = (clipCenter.x - clipWidth * 0.5)
        var clipY = (clipCenter.y - clipHeight * 0.5)
        
        if isExport { // 导出时严格按照比例计算
            
            if clipX < 0.0 {
                
                clipWidth += (clipX * 2.0)
                
                clipX = 0.0
            }
            
            if clipY < 0.0 {
                
                clipHeight += (clipY * 2.0)
                
                clipY = 0.0
            }
            
            if configuration.isClipRatio  {
                
                let ratio = (configuration.clipRatio.x / configuration.clipRatio.y)
                
                if ratio == 1.0 {
                    
                    clipWidth = min(clipWidth, clipHeight)
                    clipHeight = clipWidth
                    
                } else {
                    
                    let previousHeight = clipHeight
                    
                    clipHeight = JKGetScaleHeight(currentWidth: clipWidth, scaleWidth: configuration.clipRatio.x, scaleHeight: configuration.clipRatio.y)
                    
                    if clipHeight > previousHeight {
                        
                        clipHeight = previousHeight
                        
                        clipWidth = JKGetScaleWidth(currentHeight: clipHeight, scaleWidth: configuration.clipRatio.x, scaleHeight: configuration.clipRatio.y)
                    }
                }
                
                clipX = (clipCenter.x - clipWidth * 0.5)
                clipY = (clipCenter.y - clipHeight * 0.5)
            }
        }
        
        let clipRect = CGRect(x: clipX, y: clipY, width: clipWidth, height: clipHeight)
        
        guard let croppedImage = cgImage.cropping(to: clipRect) else {
            
            if let handler = completeHandler {
                
                handler(nil)
            }
            
            return
        }
        
        let clipedImage = UIImage(cgImage: croppedImage)
        
        if configuration.isClipCircle {
            
            clipCircleImage(squareImage: clipedImage, contextScale: 1.0, completeHandler: completeHandler)
            
            return
        }
        
        if let handler = completeHandler {
            
            handler(clipedImage)
        }
    }
    
    private func rotateOrFlipClipImage(completeHandler: ((_ clipedImage: UIImage?) -> Void)?) {
        
        let isPng = editedImage.jk.isAlphaChannelImage
        
        let isOpaque = !isPng
        
        UIGraphicsBeginImageContextWithOptions(displayImageView.bounds.size, isOpaque, 1.0)
        
        guard let ctx = UIGraphicsGetCurrentContext() else {
            
            UIGraphicsEndImageContext()
            
            if let handler = completeHandler {
                
                handler(nil)
            }
            
            return
        }
        
        displayImageView.layer.render(in: ctx)
        
        guard let image = UIGraphicsGetImageFromCurrentImageContext(),
        let cgImage = image.cgImage else {
            
            UIGraphicsEndImageContext()
            
            if let handler = completeHandler {
                
                handler(nil)
            }
            
            return
        }
        
        UIGraphicsEndImageContext()
        
        var rect = convert(clipRectView.frame, to: displayImageView)
        
        rect.origin.x = rect.origin.x < 0.0 ? 0.0 : rect.origin.x * JKScreenScale;
        rect.origin.y = rect.origin.y < 0.0 ? 0.0 : rect.origin.y * JKScreenScale;
        rect.size.width = rect.size.width > self.displayImageView.frame.size.width ? self.displayImageView.frame.size.width * JKScreenScale : rect.size.width * JKScreenScale;
        rect.size.height = rect.size.height > self.displayImageView.frame.size.height ? self.displayImageView.frame.size.height * JKScreenScale : rect.size.height * JKScreenScale;
        
        guard let clipedImage = cgImage.cropping(to: rect) else {
            
            if let handler = completeHandler {
                
                handler(nil)
            }
            
            return
        }
        
        let editedImage = UIImage(cgImage: clipedImage)
        
        if configuration.isClipCircle {
            
            clipCircleImage(squareImage: editedImage, contextScale: 1.0, completeHandler: completeHandler)
            
            return
        }
        
        if let handler = completeHandler {
            
            handler(editedImage)
        }
    }
    
    private func clipCircleImage(squareImage: UIImage,
                                 contextScale: CGFloat,
                                 completeHandler: ((_ clipedImage: UIImage?) -> Void)?) {
        
        // NO代表透明
        UIGraphicsBeginImageContextWithOptions(squareImage.size, false, contextScale)
        
        // 获取上下文
        guard let ctx = UIGraphicsGetCurrentContext() else {
            
            UIGraphicsEndImageContext()
            
            if let handler = completeHandler {
                
                handler(nil)
            }
            
            return
        }
        
        // 添加一个圆
        var rect: CGRect = .zero
        rect.size = squareImage.size
        
        ctx.addEllipse(in: rect)
        
        ctx.clip()
        
        squareImage.draw(in: rect)
        
        guard let image = UIGraphicsGetImageFromCurrentImageContext() else {
            
            UIGraphicsEndImageContext()
            
            if let handler = completeHandler {
                
                handler(nil)
            }
            
            return
        }
        
        UIGraphicsEndImageContext()
        
        if let handler = completeHandler {
            
            handler(image)
        }
    }
    
    // MARK:
    // MARK: - Private Selector
    
    private var currentImageOriention: UIImage.Orientation = .up
    
    /// rotateButtonClick
    @objc private func rotateButtonClick(button: UIButton) {
        
        guard let cgImage = editedImage.cgImage else {
            
            return
        }
        
        isUserInteractionEnabled = false
        
        clipImage(isExport: false) { [weak self] clipedImage in
            
            guard let _ = self else { return }
            
            guard let _ = clipedImage else {
                
                self?.isUserInteractionEnabled = true
                
                return
            }
            
            if self!.configuration.isClipRatio &&
                !self!.configuration.isRatioReverseEnabled &&
                (self!.configuration.clipRatio.x / self!.configuration.clipRatio.y != 1) {
                
                self?.rotateRatioIrregularly(clipedImage: clipedImage!, cgImage: cgImage)
                
                return
            }
            
            self?.rotate(clipedImage: clipedImage!, cgImage: cgImage)
        }
    }
    
    /// 按比例裁剪 且 比例不为1时进行旋转
    private func rotateRatioIrregularly(clipedImage: UIImage, cgImage: CGImage) {
        
        let imageBounds = displayImageView.bounds
        
        guard imageBounds.width > 0.0,
              imageBounds.height > 0.0 else {
                  
                  resetUI(isOriginal: false, animated: true)
                  
                  return
              }
        
        let borderRect = currentClipBorderRect ?? initialClipBorderRect
        //let borderCenter = CGPoint(x: borderRect.midX, y: borderRect.midY)
        
        guard borderRect.width > 0.0 else {
            
            resetUI(isOriginal: false, animated: true)
            
            return
        }
        
        let rotatedBorderCenter = CGPoint(x: borderMaxRect.midX, y: borderMaxRect.midY)
        let rotatedBorderRect = CGRect(x: rotatedBorderCenter.x - borderRect.width * 0.5, y: rotatedBorderCenter.y - borderRect.height * 0.5, width: borderRect.width, height: borderRect.height)
        
        flipOrRotateImageView.frame = borderRect
        flipOrRotateImageView.image = clipedImage
        contentView.insertSubview(flipOrRotateImageView, belowSubview: mainScrollView)
        
        var zoomScale = mainScrollView.zoomScale
        
        let inImageRect = convert(clipRectView.frame, to: displayImageView)
        let inImageCenter = CGPoint(x: inImageRect.midX, y: inImageRect.midY)
        
        let imageSize = imageViewSize
        
        updateRotateOrFlipImage(cgImage: cgImage, isFlip: false)
        
        updateImageViewSize()
        
        if let _ = currentClipBorderRect {
            
            currentClipBorderRect = rotatedBorderRect
        }
        
        let rotatedImageSize = imageViewSize
        
        guard borderRect.width > 0.0,
              imageSize.height > 0.0 else {
                  
                  resetUI(isOriginal: false, animated: true)
                  
                  return
              }
        
        let rotateScale = (rotatedImageSize.height / imageSize.width)
        
        var rotatedInImageCenter = CGPoint(x: inImageCenter.y, y: imageBounds.width - inImageCenter.x)
        
        rotatedInImageCenter.x *= rotateScale
        rotatedInImageCenter.y *= rotateScale
        
        mainScrollView.setZoomScale(1.0, animated: false)
        
        /* TODO: - JKTODO <#注释#>
        let rotatedInImageSize = CGSize(width: inImageRect.height * rotateScale, height: inImageRect.width * rotateScale)
        let rotatedInImageRect = CGRect(x: rotatedInImageCenter.x - rotatedInImageSize.height * 0.5, y: rotatedInImageCenter.y - rotatedInImageSize.width * 0.5, width: rotatedInImageSize.height, height: rotatedInImageSize.width)
        let tempView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 10.0, height: 10.0))
        tempView.center = rotatedInImageCenter
        tempView.isUserInteractionEnabled = false
        tempView.layer.cornerRadius = 5.0
        tempView.layer.backgroundColor = UIColor.red.cgColor
        displayImageView.addSubview(tempView)
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            tempView.removeFromSuperview()
        }
        let tempView2 = UIView(frame: rotatedInImageRect)
        tempView2.isUserInteractionEnabled = false
        tempView2.layer.borderWidth = 2
        tempView2.layer.borderColor = UIColor.green.cgColor
        displayImageView.addSubview(tempView2)
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            tempView2.removeFromSuperview()
        } // */
        
        self.mainScrollView.alpha = 0.0
        
        var rotatedImageViewScale = rotatedImageSize.height / imageSize.width
        
        updateLayout()
        
        let previousZoomScale = zoomScale
        
        zoomScale = min(zoomScale, maxZoomScale)
        zoomScale = max(zoomScale, minZoomScale)
        
        guard previousZoomScale > 0.0 else {
            
            resetUI(isOriginal: false, animated: true)
            
            return
        }
        
        rotatedImageViewScale *= (zoomScale / previousZoomScale)
        
        let imageWidth = rotatedImageSize.width * zoomScale
        let imageHeight = rotatedImageSize.height * zoomScale
        
        let minOffsetX = -rotatedBorderRect.minX
        let maxOffsetX = imageWidth - rotatedBorderRect.maxX
        
        let minOffsetY = -rotatedBorderRect.minY
        let maxOffsetY = imageHeight - rotatedBorderRect.maxY
        
        var scrollToCenter = rotatedInImageCenter
        scrollToCenter.x *= zoomScale
        scrollToCenter.y *= zoomScale
        
        var offsetX = scrollToCenter.x - rotatedBorderRect.midX
        var offsetY = scrollToCenter.y - rotatedBorderRect.midY
        
        let offset = CGPoint(x: offsetX, y: offsetY)
        
        offsetX = max(offsetX, minOffsetX)
        offsetX = min(offsetX, maxOffsetX)
        
        offsetY = max(offsetY, minOffsetY)
        offsetY = min(offsetY, maxOffsetY)
        
        let correctedOffset = CGPoint(x: offsetX, y: offsetY)
        
        self.updateClipCoverShape()
        mainScrollView.minimumZoomScale = minZoomScale
        mainScrollView.maximumZoomScale = maxZoomScale
        mainScrollView.setZoomScale(zoomScale, animated: false)
        updateScrollViewContentInset()
        
        mainScrollView.setContentOffset(offset, animated: false)
        
        UIView.animate(withDuration: 0.25) {
            
            self.flipOrRotateImageView.center = rotatedBorderCenter
            self.flipOrRotateImageView.transform = CGAffineTransform(rotationAngle: -CGFloat.pi * 0.5 + 0.000001).scaledBy(x: rotatedImageViewScale, y: rotatedImageViewScale)
            
        } completion: { _ in
            
            UIView.animate(withDuration: 0.25) {
                
                self.mainScrollView.alpha = 1.0
                
            } completion: { _ in
                
                self.isUserInteractionEnabled = true
                
                self.mainScrollView.setContentOffset(correctedOffset, animated: true)
                
                self.flipOrRotateImageView.removeFromSuperview()
                self.flipOrRotateImageView.transform = .identity
            }
        }
    }
    
    private func rotate(clipedImage: UIImage, cgImage: CGImage) {
        
        let imageBounds = displayImageView.bounds
        
        guard imageBounds.width > 0.0,
              imageBounds.height > 0.0 else {
                  
                  resetUI(isOriginal: false, animated: true)
                  
                  return
              }
        
        configuration.reverseRatio()
        
        let borderRect = currentClipBorderRect ?? initialClipBorderRect
        let borderCenter = CGPoint(x: borderRect.midX, y: borderRect.midY)
        
        var rotatedBorderCenter = borderCenter
        var rotatedBorderRect = CGRect(x: borderCenter.x - borderRect.height * 0.5, y: borderCenter.y - borderRect.width * 0.5, width: borderRect.height, height: borderRect.width)
        
        if rotatedBorderRect.minX < borderMaxRect.minX ||
            rotatedBorderRect.minY < borderMaxRect.minY ||
            rotatedBorderRect.maxX > borderMaxRect.maxX ||
            rotatedBorderRect.maxY > borderMaxRect.maxY {
            
            rotatedBorderCenter = CGPoint(x: borderMaxRect.midX, y: borderMaxRect.midY)
            
            rotatedBorderRect = CGRect(x: rotatedBorderCenter.x - rotatedBorderRect.width * 0.5, y: rotatedBorderCenter.y - rotatedBorderRect.height * 0.5, width: rotatedBorderRect.width, height: rotatedBorderRect.height)
        }
        
        if rotatedBorderRect.width > borderMaxRect.width {
            
            rotatedBorderCenter = CGPoint(x: borderMaxRect.midX, y: borderMaxRect.midY)
            
            rotatedBorderRect.size.height = JKGetScaleHeight(currentWidth: borderMaxRect.width, scaleWidth: rotatedBorderRect.size.width, scaleHeight: rotatedBorderRect.size.height)
            rotatedBorderRect.size.width = borderMaxRect.width
            
            rotatedBorderRect.origin.x = rotatedBorderCenter.x - rotatedBorderRect.size.width * 0.5
            rotatedBorderRect.origin.y = rotatedBorderCenter.y - rotatedBorderRect.size.height * 0.5
        }
        
        if rotatedBorderRect.height > borderMaxRect.height {
            
            rotatedBorderCenter = CGPoint(x: borderMaxRect.midX, y: borderMaxRect.midY)
            
            rotatedBorderRect.size.width = JKGetScaleWidth(currentHeight: borderMaxRect.height, scaleWidth: rotatedBorderRect.size.width, scaleHeight: rotatedBorderRect.size.height)
            rotatedBorderRect.size.height = borderMaxRect.height
            
            rotatedBorderRect.origin.x = rotatedBorderCenter.x - rotatedBorderRect.size.width * 0.5
            rotatedBorderRect.origin.y = rotatedBorderCenter.y - rotatedBorderRect.size.height * 0.5
        }
        
        rotatedBorderRect.size.height = JKGetScaleHeight(currentWidth: borderMaxRect.width, scaleWidth: rotatedBorderRect.width, scaleHeight: rotatedBorderRect.height)
        rotatedBorderRect.size.width = borderMaxRect.width
        
        if rotatedBorderRect.size.height > borderMaxRect.height {
            
            rotatedBorderRect.size.width = JKGetScaleWidth(currentHeight: borderMaxRect.height, scaleWidth: rotatedBorderRect.width, scaleHeight: rotatedBorderRect.height)
            rotatedBorderRect.size.height = borderMaxRect.height
        }
        
        rotatedBorderCenter = CGPoint(x: borderMaxRect.midX, y: borderMaxRect.midY)
        
        rotatedBorderRect.origin.x = rotatedBorderCenter.x - rotatedBorderRect.size.width * 0.5
        rotatedBorderRect.origin.y = rotatedBorderCenter.y - rotatedBorderRect.size.height * 0.5
        
        /* TODO: - JKTODO <#注释#>
        let tempView2 = UIView(frame: rotatedBorderRect)
        tempView2.isUserInteractionEnabled = false
        tempView2.layer.borderWidth = 1
        tempView2.layer.borderColor = UIColor.purple.cgColor
        addSubview(tempView2)
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            tempView2.removeFromSuperview()
        } // */
        
        flipOrRotateImageView.frame = borderRect
        flipOrRotateImageView.image = clipedImage
        contentView.insertSubview(flipOrRotateImageView, belowSubview: mainScrollView)
        
        self.mainScrollView.alpha = 0.0
        self.clipRectView.alpha = 0.0
        
        for item in self.dragViewArray {
            
            item.alpha = 0.0
        }
        
        clipCoverShapeLayer.opacity = 0.0
        
        let inImageRect = convert(clipRectView.frame, to: displayImageView)
        let inImageCenter = CGPoint(x: inImageRect.midX, y: inImageRect.midY)
        
        let imageSize = imageViewSize
        
        updateClipBorderRect()
        
        updateRotateOrFlipImage(cgImage: cgImage, isFlip: false)
        
        updateClipBorderRect()
        
        updateImageViewSize()
        
        let rotatedImageSize = imageViewSize
        
        if let _ = currentClipBorderRect {
            
            currentClipBorderRect = rotatedBorderRect
            
        } else {
            
            rotatedBorderRect = initialClipBorderRect
        }
        
        guard borderRect.width > 0.0,
              imageSize.height > 0.0 else {
                  
                  resetUI(isOriginal: false, animated: true)
                  
                  return
              }
        
        var rotatedImageViewScale = rotatedBorderRect.height / borderRect.width
        
        let rotateScale = rotatedImageSize.width / imageSize.height
        
        var rotatedInImageCenter = CGPoint(x: inImageCenter.y, y: imageBounds.width - inImageCenter.x)
        rotatedInImageCenter.x *= rotateScale
        rotatedInImageCenter.y *= rotateScale
        
        let rotatedInImageSize = CGSize(width: inImageRect.height * rotateScale, height: inImageRect.width * rotateScale)
        let rotatedInImageRect = CGRect(x: rotatedInImageCenter.x - rotatedInImageSize.width * 0.5, y: rotatedInImageCenter.y - rotatedInImageSize.height * 0.5, width: rotatedInImageSize.width, height: rotatedInImageSize.height)
        
        mainScrollView.setZoomScale(1.0, animated: false)
        
        /* TODO: - JKTODO <#注释#>
        let tempView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 10.0, height: 10.0))
        tempView.center = rotatedInImageCenter
        tempView.isUserInteractionEnabled = false
        tempView.layer.cornerRadius = 5.0
        tempView.layer.backgroundColor = UIColor.red.cgColor
        displayImageView.addSubview(tempView)
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            tempView.removeFromSuperview()
        }
        let tempView1 = UIView(frame: rotatedInImageRect)
        tempView1.isUserInteractionEnabled = false
        tempView1.layer.borderWidth = 2
        tempView1.layer.borderColor = UIColor.green.cgColor
        displayImageView.addSubview(tempView1)
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            tempView1.removeFromSuperview()
        } // */
        
        guard rotatedInImageRect.height > 0.0 else {
            
            resetUI(isOriginal: false, animated: true)
            
            return
        }
        
        var zoomScale = rotatedBorderRect.height / rotatedInImageRect.height
        
        updateLayout()
        
        let previousZoomScale = zoomScale
        
        zoomScale = max(zoomScale, minZoomScale)
        zoomScale = min(zoomScale, maxZoomScale)
        
        guard previousZoomScale > 0.0 else {
            
            resetUI(isOriginal: false, animated: true)
            
            return
        }
        
        let scale = (zoomScale / previousZoomScale)
        
        rotatedImageViewScale *= scale
        
        if previousZoomScale != zoomScale {
            
            rotatedBorderRect.size.width *= scale
            rotatedBorderRect.size.height *= scale
            
            rotatedBorderRect.origin.x = rotatedBorderCenter.x - rotatedBorderRect.size.width * 0.5
            rotatedBorderRect.origin.y = rotatedBorderCenter.y - rotatedBorderRect.size.height * 0.5
            
            currentClipBorderRect = rotatedBorderRect
            
            updateLayout()
        }
        
        var scrollToCenter = rotatedInImageCenter
        scrollToCenter.x *= zoomScale
        scrollToCenter.y *= zoomScale
        
        let offsetX = scrollToCenter.x - rotatedBorderRect.midX
        let offsetY = scrollToCenter.y - rotatedBorderRect.midY
        
        let offset = CGPoint(x: offsetX, y: offsetY)
        
        mainScrollView.minimumZoomScale = minZoomScale
        mainScrollView.maximumZoomScale = maxZoomScale
        mainScrollView.setZoomScale(zoomScale, animated: false)
        updateScrollViewContentInset()
        
        mainScrollView.setContentOffset(offset, animated: false)
        
        UIView.animate(withDuration: 0.25) {
            
            self.flipOrRotateImageView.center = rotatedBorderCenter
            self.flipOrRotateImageView.transform = CGAffineTransform(rotationAngle: -CGFloat.pi * 0.5 + 0.000001).scaledBy(x: rotatedImageViewScale, y: rotatedImageViewScale)
            
        } completion: { _ in
            
            self.clipCoverShapeLayer.opacity = 1.0
            
            self.updateClipCoverShape()
            
            self.isUserInteractionEnabled = true
            
            UIView.animate(withDuration: 0.25) {
                
                self.mainScrollView.alpha = 1.0
                
                self.clipRectView.alpha = 1.0
                
                for item in self.dragViewArray {
                    
                    item.alpha = 1.0
                }
                
            } completion: { _ in
                
                self.flipOrRotateImageView.removeFromSuperview()
                self.flipOrRotateImageView.transform = .identity
            }
        }
    }
    
    private func updateRotateOrFlipImage(cgImage: CGImage, isFlip: Bool) {
        
        currentImageOriention = editedImage.imageOrientation
        
        switch currentImageOriention {
            
        case .up:
            
            currentImageOriention = isFlip ? .upMirrored : .left
            
        case .down:
            
            currentImageOriention = isFlip ? .downMirrored : .right
            
        case .left:
            currentImageOriention = isFlip ? .rightMirrored : .down
            
        case .right:
            
            currentImageOriention = isFlip ? .leftMirrored : .up
            
        case .upMirrored:
            
            currentImageOriention = isFlip ? .up : .leftMirrored
            
        case .downMirrored:
            
            currentImageOriention = isFlip ? .down : .rightMirrored
            
        case .leftMirrored:
            
            currentImageOriention = isFlip ? .right : .downMirrored
            
        case .rightMirrored:
            
            currentImageOriention = isFlip ? .left : .upMirrored
            
        default:
            break
        }
        
        _editedImage = UIImage(cgImage: cgImage, scale: originalImage.scale, orientation: currentImageOriention)
        
        _editedImage = drawToFixImageOrientation()
        
        displayImageView.image = editedImage
    }
    
    private lazy var flipOrRotateImageView: UIImageView = {
        
        let imageView = UIImageView()
        
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        
        return imageView
    }()
    
    /// flipButtonClick
    @objc private func flipButtonClick(button: UIButton) {
        
        guard let cgImage = editedImage.cgImage else {
            
            return
        }
        
        isUserInteractionEnabled = false
        
        clipImage(isExport: false) { [weak self] clipedImage in
            
            guard let _ = self else {
                
                return
            }
            
            guard let _ = clipedImage else {
                
                self?.isUserInteractionEnabled = true
                
                return
            }
            
            self?.flip(clipedImage: clipedImage!, cgImage: cgImage)
        }
    }
    
    private func flip(clipedImage: UIImage, cgImage: CGImage) {
        
        flipOrRotateImageView.frame = currentClipBorderRect ?? initialClipBorderRect
        flipOrRotateImageView.image = clipedImage
        contentView.insertSubview(flipOrRotateImageView, belowSubview: mainScrollView)
        
        var currentOffset = mainScrollView.contentOffset
        
        self.mainScrollView.alpha = 0.0
        self.clipRectView.alpha = 0.0
        for item in self.dragViewArray {
            
            item.alpha = 0.0
        }
        
        clipCoverShapeLayer.opacity = 0.0
        
        updateRotateOrFlipImage(cgImage: cgImage, isFlip: true)
        
        let convertRect = convert(clipRectView.frame, to: displayImageView)
        
        let convertCenter = CGPoint(x: convertRect.midX * mainScrollView.zoomScale, y: convertRect.midY * mainScrollView.zoomScale)
        
        let imageViewCenter = CGPoint(x: displayImageView.bounds.width * mainScrollView.zoomScale * 0.5, y: displayImageView.bounds.height * mainScrollView.zoomScale * 0.5)
        
        if (convertCenter.x != imageViewCenter.x) {
            
            let deltaX = (convertCenter.x - imageViewCenter.x) * 2.0
            
            currentOffset.x -= deltaX
            
            mainScrollView.setContentOffset(currentOffset, animated: false)
        }
        
        UIView.animate(withDuration: 0.25) {
            
            self.flipOrRotateImageView.layer.transform = CATransform3DMakeRotation(-CGFloat.pi, 0.0, 1.0, 0.0)
            
        } completion: { _ in
            
            self.clipCoverShapeLayer.opacity = 1.0
            
            self.isUserInteractionEnabled = true
            
            UIView.animate(withDuration: 0.25) {
                
                self.mainScrollView.alpha = 1.0
                self.clipRectView.alpha = 1.0
                
                for item in self.dragViewArray {
                    
                    item.alpha = 1.0
                }
                
            } completion: { _ in
                
                self.flipOrRotateImageView.removeFromSuperview()
                self.flipOrRotateImageView.layer.transform = CATransform3DIdentity
            }
        }
    }
    
    /// customRatioButtonClick
    @objc private func customRatioButtonClick(button: UIButton) {
        
        updateCustomRatioShowOrHidden()
    }
    
    private func updateCustomRatioShowOrHidden() {
        
        if customRatioContainerView.isHidden {
            
            rotateButton.isHidden = true
            flipButton.isHidden = true
            customRatioButton.isHidden = true
            
            customRatioContainerView.transform = CGAffineTransform(scaleX: 0.01, y: 1.0)
            
            customRatioContainerView.isHidden = false
            
            UIView.animate(withDuration: 0.25) {
                
                self.customRatioContainerView.transform = .identity
            }
            
            return
        }
        
        rotateButton.alpha = 0.0
        flipButton.alpha = 0.0
        customRatioButton.alpha = 0.0
        
        rotateButton.isHidden = false
        flipButton.isHidden = false
        customRatioButton.isHidden = false
        
        UIView.animate(withDuration: 0.25) {
            
            self.rotateButton.alpha = 1.0
            self.flipButton.alpha = 1.0
            self.customRatioButton.alpha = 1.0
            self.customRatioContainerView.transform = CGAffineTransform(scaleX: 0.01, y: 1.0)
            
        } completion: { _ in
            
            self.customRatioContainerView.isHidden = true
            self.customRatioContainerView.transform = .identity
        }
    }
    
    /// 当前选择的自定义比例按钮
    private var selectedCustomRatioItemButton: UIButton?
    
    /// 更新自定义比例按钮选中状态
    private func updateCustomRatioItemButtonStatus(_ button: UIButton, isSelected: Bool) {
        
        button.isSelected = isSelected
        button.layer.borderColor = (button.isSelected ? configuration.mainColor : UIColor.white).cgColor
    }
    
    /// 反转自定义比例
    @objc private func closeCustomRatioButtonClick(button: UIButton) {
        
        if customRatioContainerView.isHidden { return }
        
        updateCustomRatioShowOrHidden()
    }
    
    /// 点击某个自定义比例
    @objc private func customRatioItemButtonClick(button: UIButton) {
        
        guard let currentTitle = button.title(for: .normal) else { return }
        
        var targetRatio: CGPoint = .zero
        
        if currentTitle.contains(":") {
            
            let arr = currentTitle.components(separatedBy: ":")
            
            guard arr.count == 2,
                  let ratioX = Int(arr[0]),
                  let ratioY = Int(arr[1]) else {
                      
                      return
                  }
            
            targetRatio = CGPoint(x: CGFloat(ratioX), y: CGFloat(ratioY))
            
            if button.isSelected {
                
                let tempX = targetRatio.x
                targetRatio.x = targetRatio.y
                targetRatio.y = tempX
                
                button.setTitle("\(arr[1]):\(arr[0])", for: .normal)
            }
        }
        
        if let ratioButton = selectedCustomRatioItemButton {
            
            updateCustomRatioItemButtonStatus(ratioButton, isSelected: false)
            
            ratioButton.isSelected = false
        }
        
        selectedCustomRatioItemButton = button
        
        updateCustomRatioItemButtonStatus(button, isSelected: !button.isSelected)
        
        executeUpdateToCutomRatio(targetRatio)
    }
    
    private func executeUpdateToCutomRatio(_ targetRatio: CGPoint) {
        
        configuration.updateToCustomRatio(targetRatio)
        
        let previousImageSize = imageViewSize
        
        let previousBorderRect = currentClipBorderRect ?? initialClipBorderRect
        let prevoiousBorderCenter = CGPoint(x: previousBorderRect.midX, y: previousBorderRect.midY)
        
        updateMaxBorder()
        updateClipBorderRect()
        updateImageViewSize()
        
        currentClipBorderRect = nil
        
        let currentImageSize = imageViewSize
        
        let targetBorderRect = initialClipBorderRect
        
        let inImageCenter = convert(prevoiousBorderCenter, to: displayImageView)
        
        let imageSizeScale = currentImageSize.width / previousImageSize.width
        
        var scrollToCenter = inImageCenter
        
        scrollToCenter.x *= imageSizeScale
        scrollToCenter.y *= imageSizeScale
        
        let offsetX = scrollToCenter.x - targetBorderRect.midX
        let offsetY = scrollToCenter.y - targetBorderRect.midY
        
        var offset = CGPoint(x: offsetX, y: offsetY)
        
        let imageWidth = currentImageSize.width
        let imageHeight = currentImageSize.height
        
        let minOffsetX = -targetBorderRect.minX
        let maxOffsetX = imageWidth - targetBorderRect.maxX
        
        let minOffsetY = -targetBorderRect.minY
        let maxOffsetY = imageHeight - targetBorderRect.maxY
        
        offset.x = max(offset.x, minOffsetX)
        offset.x = min(offset.x, maxOffsetX)
        
        offset.y = max(offset.y, minOffsetY)
        offset.y = min(offset.y, maxOffsetY)
        
        resetUI(isOriginal: false, animated: true, animations: {
            
            self.mainScrollView.setContentOffset(offset, animated: false)
            
        }, completion: nil)
    }
    
    /// cancelButtonClick
    @objc private func cancelButtonClick(button: UIButton) {
        
        if let handler = configuration.cancelHandler {
            
            handler(configuration)
        }
    }
    
    /// resetButtonClick
    @objc private func resetButtonClick(button: UIButton) {
        
        resetUI(isOriginal: true, animated: true)
    }
    
    /// completeButtonClick
    @objc private func completeButtonClick(button: UIButton) {
        
        isUserInteractionEnabled = false
        
        clipImage(isExport: true) { [weak self] clipedImage in
            
            guard let _ = self else { return }
            
            self?.isUserInteractionEnabled = true
            
            let isAutoSave = self!.configuration.isAutoSaveTopPhotoLibrary
            
            if let handler = self?.configuration.editResultHandler {
                
                handler(self!.configuration, clipedImage)
            }
            
            if isAutoSave,
               let realImage = clipedImage {
                
                self?.checkSaveImageToPhotoLibrary(realImage)
            }
        }
    }
    
    @objc private func dragCornerPanGestureAction(gesture: UIPanGestureRecognizer) {
        
        switch gesture.state {
            
        case .began:
            
            guard let dragView = gesture.view,
                  let corner = DragCorner(rawValue: dragView.tag) else {
                      
                      gesture.state = .failed
                      
                      return
                  }
            
            prepareForDragCornerDidBegan(dragView: dragView)
            
            updateDragLimit(corner: corner)
            
            currentClipBorderRect = clipRectView.frame
            
            originalRect = clipRectView.frame
            
        case .changed:
            
            guard let dragView = gesture.view,
                  let corner = DragCorner(rawValue: dragView.tag) else {
                      
                      gesture.state = .failed
                      
                      return
                  }
            
            let translation = gesture.translation(in: self)
            
            updateDragChanged(corner: corner, translation: translation)
            
            gesture.setTranslation(.zero, in: gesture.view)
            
        default:
            
            /* TODO: - JKTODO <#注释#>
            if let borderRect = currentClipBorderRect,
               borderRect.width > editedImage.size.width,
               borderRect.height > editedImage.size.height {
                
                currentClipBorderRect = originalRect
                
                UIView.animate(withDuration: 0.25) {
                    
                    self.updateClipRectViewLayout()
                    self.updateScrollViewContentInset()
                    
                } completion: { _ in
                    
                    self.prepareForDragCornerDidEnd()
                }
                
                return
            } // */
            
            prepareForDragCornerDidEnd()
        }
    }
    
    /// 更新截图区域边框/中线等UI
    private func updateClipRectSubviewsLayout() {
        
        if clipCoverShapeLayer.opacity > 0.0 {
            
            updateClipCoverShape()
        }
        
        if configuration.isClipCircle {
            
            let circleWH = min(clipRectView.frame.width, clipRectView.frame.height)
            
            clipCircleView.frame = CGRect(x: (clipRectView.bounds.width - circleWH) * 0.5, y: (clipRectView.bounds.height - circleWH) * 0.5, width: circleWH, height: circleWH)
            
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            circleBorderShadowLayer.cornerRadius = circleWH * 0.5
            circleBorderShadowLayer.frame = clipCircleView.bounds
            circleBorderLayer.cornerRadius = circleWH * 0.5
            circleBorderLayer.frame = clipCircleView.bounds
            CATransaction.commit()
        }
        
        clipHorizontalLineView.frame = CGRect(x: 0.0, y: clipRectView.frame.height * 0.5, width: clipRectView.frame.width, height: Self.lineThickness)
        
        clipVerticalLineView.frame = CGRect(x: clipRectView.frame.width * 0.5, y: 0.0, width: Self.lineThickness, height: clipRectView.frame.height)
        
        clipTopLineView.frame = CGRect(x: 0.0, y: 0.0, width: clipRectView.frame.width, height: Self.lineThickness)
        
        clipBottomLineView.frame = CGRect(x: 0.0, y: clipRectView.frame.height - Self.lineThickness, width: clipRectView.frame.width, height: Self.lineThickness)
        
        clipLeftLineView.frame = CGRect(x: 0.0, y: 0.0, width: Self.lineThickness, height: clipRectView.frame.height)
        
        clipRightLineView.frame = CGRect(x: clipRectView.frame.width - Self.lineThickness, y: 0.0, width: Self.lineThickness, height: clipRectView.frame.height)
    }
    
    /// 单击状态栏位置
    @objc private func singleTapStatusBarLocationAction(gesture: UITapGestureRecognizer) {
        
        mainScrollView.setContentOffset(CGPoint(x: mainScrollView.contentOffset.x, y: -mainScrollView.contentInset.top), animated: true)
    }
    
    /// 双击
    @objc private func doubleTapAction(gesture: UITapGestureRecognizer) {
        
        let location: CGPoint = gesture.location(in: gesture.view)
        
        if bottomCoverView.frame.contains(location) { return }
        
        let point = displayImageView.convert(location, from: gesture.view)
        
        // 双击缩小
        if (mainScrollView.zoomScale > mainScrollView.minimumZoomScale) {
            
            var scale = mainScrollView.minimumZoomScale
            
            if let borderRect = currentClipBorderRect,
               imageViewSize.width > 0.0,
               imageViewSize.height > 0.0,
               (borderRect.width > imageViewSize.width ||
                borderRect.height > imageViewSize.height) {
                
                scale = max(borderRect.width / imageViewSize.width, borderRect.height / imageViewSize.height)
            }
            
            if scale != mainScrollView.zoomScale {
                
                mainScrollView.setZoomScale(scale, animated: true)
                
                return
            }
        }
        
        // 双击放大
        let maximumZoomScale = mainScrollView.maximumZoomScale
        
        let rect: CGRect = CGRect(x: point.x - 5.0, y: point.y - 5.0, width: 10.0, height: 10.0)
        
        var firstZoomScale: CGFloat = 2.0
        
        if mainScrollView.minimumZoomScale >= firstZoomScale &&
            mainScrollView.zoomScale >= mainScrollView.minimumZoomScale {
            
            firstZoomScale = maximumZoomScale
        }
        
        mainScrollView.maximumZoomScale = min(maximumZoomScale, firstZoomScale)
        
        mainScrollView.zoom(to: rect, animated: true)
        
        mainScrollView.maximumZoomScale = maximumZoomScale
    }
    
    // MARK:
    // MARK: - Initialization & Build UI
    
    /// 初始化自身属性 交给子类重写 super自动调用该方法
    open override func initializeProperty() {
        super.initializeProperty()
        
        
    }
    
    /// 构造函数初始化时调用 注意调用super
    open override func initialization() {
        super.initialization()
        
        contentView.addGestureRecognizer(doubleTapGesture)
    }
    
    /// 创建UI 交给子类重写 super自动调用该方法
    open override func createUI() {
        super.createUI()
        
        addSubview(bottomControlView)
        
        contentView.addSubview(mainScrollView)
        contentView.addSubview(statusBarCoverView)
        contentView.addSubview(clipCoverView)
        contentView.addSubview(tempMaxBorderView)
        contentView.addSubview(tempDefaultBorderView)
        contentView.addSubview(bottomCoverView)
        
        for item in dragViewArray {
            
            contentView.addSubview(item)
        }
        
        contentView.addSubview(clipRectView)
        contentView.addSubview(rotateButton)
        contentView.addSubview(flipButton)
        
        if !configuration.isClipRatio {
            
            contentView.addSubview(customRatioContainerView)
            contentView.addSubview(customRatioButton)
            
            customRatioContainerView.addSubview(closeCustomRatioButton)
            customRatioContainerView.addSubview(customRatioScrollView)
        }
        
        mainScrollView.addSubview(displayImageView)
        
        bottomControlView.contentView.addSubview(cancelButton)
        bottomControlView.contentView.addSubview(resetButton)
        bottomControlView.contentView.addSubview(completeButton)
        
        clipCoverView.layer.addSublayer(clipCoverShapeLayer)
        
        clipRectView.addSubview(clipCircleView)
        clipRectView.addSubview(clipVerticalLineView)
        clipRectView.addSubview(clipHorizontalLineView)
        clipRectView.addSubview(clipTopLineView)
        clipRectView.addSubview(clipBottomLineView)
        clipRectView.addSubview(clipLeftLineView)
        clipRectView.addSubview(clipRightLineView)
    }
    
    /// 布局UI 交给子类重写 super自动调用该方法
    open override func layoutUI() {
        super.layoutUI()
        
    }
    
    /// 初始化UI数据 交给子类重写 super自动调用该方法
    open override func initializeUIData() {
        super.initializeUIData()
        
        displayImageView.image = editedImage
        
        backgroundColor = .black
        
        // TODO: - JKTODO <#注释#>
        tempMaxBorderView.isHidden = true
        tempDefaultBorderView.isHidden = true
    }
    
    // MARK:
    // MARK: - Private Property
    
    /// 图片尺寸
    private var imageViewSize: CGSize = .zero
    
    private var borderInsets: UIEdgeInsets = .zero
    private var borderMaxSize: CGSize = .zero
    
    private var _editedImage: UIImage?
    
    private var editedImage: UIImage {
        
        _editedImage ?? originalImage
    }
    
    private var borderMaxRect: CGRect = .zero
    
    private var borderMinSize: CGSize = .zero
    
    private var dragLimit = DragLimit()
    
    private var originalRect: CGRect = .zero
    
    private var initialClipBorderRect: CGRect = .zero
    
    private var defaultClipBorderRect: CGRect = .zero
    
    private var currentClipBorderRect: CGRect? {
        
        didSet {
            
            minZoomScale = 1.0
            
            if let rect = currentClipBorderRect {
                
                minZoomScale = rect.width / imageViewSize.width
                minZoomScale = max(minZoomScale, rect.height / imageViewSize.height)
            }
            
            mainScrollView.minimumZoomScale = minZoomScale
        }
    }
    
    private var previousImageViewSize: CGSize = .zero
    
    private var previousFrame: CGRect = .zero
    
    private var firstZoomWidth: CGFloat = 0.0
    
    private var minZoomScale: CGFloat = 1.0
    
    private var maxZoomScale: CGFloat = 5.0
    
    /// doubleTapGesture
    private lazy var doubleTapGesture: UITapGestureRecognizer = {
        
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(doubleTapAction(gesture:)))
        
        doubleTapGesture.numberOfTouchesRequired = 1
        doubleTapGesture.numberOfTapsRequired = 2
        
        return doubleTapGesture
    }()
    
    /// mainScrollView
    private lazy var mainScrollView: UIScrollView = {
        
        let mainScrollView = UIScrollView(frame: self.bounds)
        
        mainScrollView.showsVerticalScrollIndicator = false
        mainScrollView.showsHorizontalScrollIndicator = false
        
        mainScrollView.alwaysBounceVertical = true
        mainScrollView.alwaysBounceHorizontal = true
        
        if #available(iOS 11.0, *) {
            
            mainScrollView.contentInsetAdjustmentBehavior = .never
        }
        
        if #available(iOS 13.0, *) {
            
            mainScrollView.automaticallyAdjustsScrollIndicatorInsets = false
        }
        
        mainScrollView.delegate = self
        
        return mainScrollView
    }()
    
    /// imageView
    private lazy var displayImageView: UIImageView = {
        
        let imageView = UIImageView()
        
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        //imageView.layer.borderColor = UIColor.white.withAlphaComponent(0.3).cgColor
        //imageView.layer.borderWidth = Self.lineThickness
        
        return imageView
    }()
    
    /// statusBarCoverView
    private lazy var statusBarCoverView: UIView = {
        
        let statusBarCoverView = UIView()
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(singleTapStatusBarLocationAction(gesture:)))
        
        statusBarCoverView.addGestureRecognizer(tapGesture)
        
        return statusBarCoverView
    }()
    
    /// bottomControlView
    private lazy var bottomControlView: JKPHPickerBarView = {
        
        let bottomControlView = JKPHPickerBarView()
        
        bottomControlView.isAtScreenBottom = true
        bottomControlView.backgroundEffectView.effect = UIBlurEffect(style: .dark)
        bottomControlView.topLineView.isHidden = false
        bottomControlView.topLineView.backgroundColor = JKLineDarkColor
        
        bottomControlView.didLayoutSubviewsHandler = { [weak self] _ in
            
            guard let _ = self else { return }
            
            self?.layoutBottomControlViewUI()
        }
        
        return bottomControlView
    }()
    
    /// completeButton
    private lazy var completeButton: UIButton = {
        
        let completeButton = UIButton(type: .custom)
        
        completeButton.setBackgroundImage(JKPHPickerResourceManager.image(named: "clip_done"), for: .normal)
        
        completeButton.addTarget(self, action: #selector(completeButtonClick(button:)), for: .touchUpInside)
        
        return completeButton
    }()
    
    /// cancelButton
    private lazy var cancelButton: UIButton = {
        
        let cancelButton = UIButton(type: .custom)
        
        cancelButton.setBackgroundImage(JKPHPickerResourceManager.image(named: "clip_close"), for: .normal)
        
        cancelButton.addTarget(self, action: #selector(cancelButtonClick(button:)), for: .touchUpInside)
        
        return cancelButton
    }()
    
    private lazy var resetButton: UIButton = {
        
        let resetButton = UIButton(type: .custom)
        
        resetButton.setBackgroundImage(JKPHPickerResourceManager.image(named: "clip_reset"), for: .normal)
        
        resetButton.addTarget(self, action: #selector(resetButtonClick(button:)), for: .touchUpInside)
        
        return resetButton
    }()
    
    private lazy var rotateButton: UIButton = {
        
        let rotateButton = UIButton(type: .custom)
        
        rotateButton.setBackgroundImage(JKPHPickerResourceManager.image(named: "clip_rotation"), for: .normal)
        
        rotateButton.addTarget(self, action: #selector(rotateButtonClick(button:)), for: .touchUpInside)
        
        return rotateButton
    }()
    
    private lazy var flipButton: UIButton = {
        
        let flipButton = UIButton(type: .custom)
        
        flipButton.setBackgroundImage(JKPHPickerResourceManager.image(named: "clip_flip_horizontal"), for: .normal)
        
        flipButton.addTarget(self, action: #selector(flipButtonClick(button:)), for: .touchUpInside)
        
        return flipButton
    }()
    
    private lazy var customRatioButton: UIButton = {
        
        let customRatioButton = UIButton(type: .custom)
        
        customRatioButton.setBackgroundImage(JKPHPickerResourceManager.image(named: "clip_custom_ratio"), for: .normal)
        
        customRatioButton.addTarget(self, action: #selector(customRatioButtonClick(button:)), for: .touchUpInside)
        
        return customRatioButton
    }()
    
    private lazy var customRatioContainerView: UIView = {
        
        let customRatioContainerView = UIView()
        
        customRatioContainerView.isHidden = true
        
        customRatioContainerView.layer.anchorPoint = CGPoint(x: 1.0, y: 0.5)
        
        return customRatioContainerView
    }()
    
    private lazy var closeCustomRatioButton: UIButton = {
        
        let closeCustomRatioButton = UIButton(type: .custom)
        
        closeCustomRatioButton.setImage(JKPHPickerResourceManager.image(named: "nav_go_white"), for: .normal)
        
        closeCustomRatioButton.addTarget(self, action: #selector(closeCustomRatioButtonClick(button:)), for: .touchUpInside)
        
        return closeCustomRatioButton
    }()
    
    /// customRatioScrollView
    private lazy var customRatioScrollView: UIScrollView = {
        
        let scrollView = UIScrollView()
        
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        
        if #available(iOS 11.0, *) {
            scrollView.contentInsetAdjustmentBehavior = .never
        }
        
        if #available(iOS 13.0, *) {
            scrollView.automaticallyAdjustsScrollIndicatorInsets = false
        }
        
        self.customRatioItemButtonArray.removeAll()
        
        for (index, ratioTitle) in self.customRatioItemTitleArray.enumerated() {
            
            let button = self.createCustomRatioItemButton(ratioTitle: ratioTitle)
            
            if index == 0 {
                
                self.selectedCustomRatioItemButton = button
                self.updateCustomRatioItemButtonStatus(button, isSelected: true)
            }
            
            button.addTarget(self, action: #selector(customRatioItemButtonClick(button:)), for: .touchUpInside)
            
            scrollView.addSubview(button)
            
            self.customRatioItemButtonArray.append(button)
        }
        
        return scrollView
    }()
    
    private lazy var customRatioItemButtonArray: [UIButton] = {
        
        var customRatioItemButtonArray = [UIButton]()
        
        return customRatioItemButtonArray
    }()
    
    private lazy var customRatioItemTitleArray: [String] = [
        "自由",
        "1:1",
        "16:9",
        "7:5",
        "5:4",
        "5:3",
        "4:3",
        "3:2"
    ]
    
    private lazy var customRatioItemTitleReversedArray: [String] = [
        "自由",
        "1:1",
        "9:16",
        "5:7",
        "4:5",
        "3:5",
        "3:4",
        "2:3"
    ]
    
    private lazy var customRatioItemButtonHeight: CGFloat = 20.0
    
    private func createCustomRatioItemButton(ratioTitle: String) -> UIButton {
        
        let button = UIButton(type: .custom)
        
        let normalTitleColor = UIColor.white
        let selectedTitleColor = configuration.mainColor
        
        button.titleLabel?.font = UIFont.systemFont(ofSize: 11.0)
        
        button.setTitleColor(normalTitleColor, for: .normal)
        button.setTitleColor(selectedTitleColor, for: .selected)
        
        button.setTitleColor(normalTitleColor.withAlphaComponent(0.5), for: [.normal, .highlighted])
        button.setTitleColor(selectedTitleColor.withAlphaComponent(0.5), for: [.selected, .highlighted])
        
        button.setTitle(ratioTitle, for: .normal)
        
        button.layer.cornerRadius = self.customRatioItemButtonHeight * 0.5
        button.layer.borderWidth = 0.5
        button.layer.borderColor = UIColor.white.cgColor
        
        return button
    }
    
    private lazy var tempMaxBorderView: UIView = {
        
        let borderView = UIView()
        
        borderView.isUserInteractionEnabled = false
        borderView.layer.borderColor = UIColor.red.cgColor
        borderView.layer.borderWidth = Self.lineThickness
        
        return borderView
    }()
    
    private lazy var tempDefaultBorderView: UIView = {
        
        let borderView = UIView()
        
        borderView.isUserInteractionEnabled = false
        borderView.layer.borderColor = UIColor.blue.cgColor
        borderView.layer.borderWidth = Self.lineThickness
        
        return borderView
    }()
    
    private lazy var clipCoverView: UIView = {
        
        let clipCoverView = UIView()
        
        clipCoverView.isUserInteractionEnabled = false
        
        return clipCoverView
    }()
    
    private lazy var bottomCoverView: UIView = {
        
        let bottomCoverView = UIView()
        
        //bottomCoverView.backgroundColor = self.coverColor
        
        return bottomCoverView
    }()
    
    private var clipCoverFullPath: UIBezierPath {
        
        UIBezierPath(rect: CGRect(x: 0.0, y: 0.0, width: contentView.bounds.width, height: contentView.bounds.height))
    }
    
    private var clipCoverPath: UIBezierPath {
        
        let fullPath = clipCoverFullPath
        
        var coverPath: UIBezierPath
        
        let clipRect = currentClipBorderRect ?? initialClipBorderRect
        
        if configuration.isClipCircle {
            
            coverPath = UIBezierPath(roundedRect: clipRect, cornerRadius: clipRect.width * 0.5)
            
        } else {
            
            coverPath = UIBezierPath(rect: clipRect)
        }
        
        fullPath.append(coverPath)
        fullPath.usesEvenOddFillRule = true
        
        return fullPath
    }
    
    private lazy var coverColor = UIColor.black.withAlphaComponent(0.6)
    
    private lazy var clipCoverShapeLayer: CAShapeLayer = {
        
        let clipCoverShapeLayer = CAShapeLayer()
        
        clipCoverShapeLayer.frame = self.bounds
        clipCoverShapeLayer.fillColor = self.coverColor.cgColor
        clipCoverShapeLayer.fillRule = .evenOdd
        clipCoverShapeLayer.strokeColor = UIColor.clear.cgColor
        
        return clipCoverShapeLayer
    }()
    
    private func updateClipCoverShape() {
        
        clipCoverShapeLayer.path = clipCoverPath.cgPath
    }
    
    private lazy var clipRectView: UIView = {
        
        let clipRectView = UIView()
        
        clipRectView.isUserInteractionEnabled = false
        
        return clipRectView
    }()
    
    private lazy var clipCircleView: UIView = {
        
        let clipCircleView = UIView()
        
        clipCircleView.isUserInteractionEnabled = false
        clipCircleView.layer.borderColor = UIColor.white.cgColor
        clipCircleView.layer.borderWidth = Self.lineThickness
        
        clipCircleView.layer.addSublayer(self.circleBorderShadowLayer)
        clipCircleView.layer.addSublayer(self.circleBorderLayer)
        
        clipCircleView.isHidden = !self.configuration.isClipCircle
        
        return clipCircleView
    }()
    
    private lazy var circleBorderShadowLayer: CAShapeLayer = {
        
        let circleBorderShapeLayer = CAShapeLayer()
        
        circleBorderShapeLayer.borderColor = UIColor.black.withAlphaComponent(0.1).cgColor
        circleBorderShapeLayer.borderWidth = 1.0
        
        return circleBorderShapeLayer
    }()
    
    private lazy var circleBorderLayer: CALayer = {
        
        let circleBorderLayer = CAShapeLayer()
        
        circleBorderLayer.borderColor = UIColor.white.cgColor
        circleBorderLayer.borderWidth = Self.lineThickness
        
        return circleBorderLayer
    }()
    
    private lazy var clipHorizontalLineView: UIView = {
        
        let clipHorizontalLineView = self.createClipLineView()
        
        return clipHorizontalLineView
    }()
    
    private lazy var clipVerticalLineView: UIView = {
        
        let clipVerticalLineView = self.createClipLineView()
        
        return clipVerticalLineView
    }()
    
    private lazy var clipTopLineView: UIView = {
        
        let clipTopLineView = self.createClipLineView()
        
        return clipTopLineView
    }()
    
    private lazy var clipBottomLineView: UIView = {
        
        let clipBottomLineView = self.createClipLineView()
        
        return clipBottomLineView
    }()
    
    private lazy var clipLeftLineView: UIView = {
        
        let clipLeftLineView = self.createClipLineView()
        
        return clipLeftLineView
    }()
    
    private lazy var clipRightLineView: UIView = {
        
        let clipRightLineView = self.createClipLineView()
        
        return clipRightLineView
    }()
    
    private func createClipLineView() -> UIView {
        
        let lineView = UIView()
        
        lineView.isUserInteractionEnabled = false
        lineView.layer.backgroundColor = UIColor.white.cgColor
        
        lineView.layer.borderColor = UIColor.black.withAlphaComponent(0.1).cgColor
        lineView.layer.borderWidth = 1.0
        
        return lineView
    }
    
    private let dragViewWH: CGFloat = 25.0
    private let cornerImageWH: CGFloat = 20.0
    private lazy var cornerImageThickness: CGFloat = 3.0 * (cornerImageWH / 20.0) - Self.lineThickness
    
    private lazy var dragViewArray: [UIView] = {
        
        var arr = [UIView]()
        
        var dragViewCenter: CGPoint = .zero
        
        let cornerShadowColor = UIColor.black.withAlphaComponent(0.1).cgColor
        
        let leftX = self.dragViewWH - self.cornerImageWH
        let rightX: CGFloat = 0.0
        let topY = self.dragViewWH - self.cornerImageWH
        let bottomY: CGFloat = 0.0
        
        for index in 0..<9 {
            
            let dragView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: self.dragViewWH, height: self.dragViewWH))
            dragView.tag = index
            arr.append(dragView)
            
            let panGusture = UIPanGestureRecognizer(target: self, action: #selector(dragCornerPanGestureAction(gesture:)))
            dragView.addGestureRecognizer(panGusture)
            
            dragViewCenter = CGPoint(x: dragView.bounds.width * 0.5, y: dragView.bounds.height * 0.5)
            
            if let corner = DragCorner(rawValue: index) {
                
                var cornerImageView: UIImageView?
                var cornerImage: UIImage?
                var shadowOffset: CGSize = .zero
                
                switch corner {
                case .topLeft:
                    cornerImageView = UIImageView(frame: CGRect(x: leftX, y: topY, width: self.cornerImageWH, height: self.cornerImageWH))
                    cornerImage = JKPHPickerResourceManager.image(named: "clip_corner_top_left")
                    shadowOffset = CGSize(width: -1.0, height: -1.0)
                case .topRight:
                    cornerImageView = UIImageView(frame: CGRect(x: rightX, y: topY, width: self.cornerImageWH, height: self.cornerImageWH))
                    cornerImage = JKPHPickerResourceManager.image(named: "clip_corner_top_right")
                    shadowOffset = CGSize(width: 1.0, height: -1.0)
                case .bottomLeft:
                    cornerImageView = UIImageView(frame: CGRect(x: leftX, y: bottomY, width: self.cornerImageWH, height: self.cornerImageWH))
                    cornerImage = JKPHPickerResourceManager.image(named: "clip_corner_bottom_left")
                    shadowOffset = CGSize(width: -1.0, height: 1.0)
                case .bottomRight:
                    cornerImageView = UIImageView(frame: CGRect(x: rightX, y: bottomY, width: self.cornerImageWH, height: self.cornerImageWH))
                    cornerImage = JKPHPickerResourceManager.image(named: "clip_corner_bottom_right")
                    shadowOffset = CGSize(width: 1.0, height: 1.0)
                default:
                    break
                }
                
                if let imageView = cornerImageView {
                    
                    imageView.image = cornerImage
                    dragView.addSubview(imageView)
                    
                    imageView.layer.shadowColor = cornerShadowColor
                    imageView.layer.shadowOffset = shadowOffset
                    imageView.layer.shadowOpacity = 1.0
                    imageView.layer.shadowRadius = Self.lineThickness
                }
            }
        }
        
        return arr
    }()
}

// MARK:
// MARK: - Auto Save To Photo Library

extension JKPHPickerEditView {
    
    private func checkSaveImageToPhotoLibrary(_ image: UIImage) {
        
        JKAuthorization.checkPhotoLibraryAuthorization(isAddOnly: true) { isNotDeterminedAtFirst, status in
            
            if status == .authorized || status == .limited {
                
                self.saveImageToPhotoLibrary(image)
            }
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
            
        } completionHandler: { isSuccess, error in
            
        }
    }
}

// MARK:
// MARK: - Control User Interaction

extension JKPHPickerEditView {
    
    /// 拖拽开始前的操作 禁用一些交互等
    private func prepareForDragCornerDidBegan(dragView: UIView) {
        
        let borderRect = currentClipBorderRect ?? initialClipBorderRect
        
        let imageWidth = imageViewSize.width * mainScrollView.zoomScale
        let imageHeight = imageViewSize.height * mainScrollView.zoomScale
        
        let minOffsetX = -borderRect.minX
        let maxOffsetX = imageWidth - borderRect.maxX
        
        let minOffsetY = -borderRect.minY
        let maxOffsetY = imageHeight - borderRect.maxY
        
        var offset = mainScrollView.contentOffset
        
        offset.x = max(offset.x, minOffsetX)
        offset.y = max(offset.y, minOffsetY)
        offset.x = min(offset.x, maxOffsetX)
        offset.y = min(offset.y, maxOffsetY)
        
        mainScrollView.setContentOffset(offset, animated: false)
        
        bottomControlView.isUserInteractionEnabled = false
        mainScrollView.isUserInteractionEnabled = false
        rotateButton.isUserInteractionEnabled = false
        flipButton.isUserInteractionEnabled = false
        customRatioButton.isUserInteractionEnabled = false
        customRatioContainerView.isUserInteractionEnabled = false
        
        clipCoverShapeLayer.opacity = 0.0
        
        for item in dragViewArray {
            
            if item == dragView {
                
                continue
            }
            
            item.isUserInteractionEnabled = false
        }
    }
    
    /// 拖拽结束后的操作 开启交互等
    private func prepareForDragCornerDidEnd() {
        
        bottomControlView.isUserInteractionEnabled = true
        mainScrollView.isUserInteractionEnabled = true
        rotateButton.isUserInteractionEnabled = true
        flipButton.isUserInteractionEnabled = true
        customRatioButton.isUserInteractionEnabled = true
        customRatioContainerView.isUserInteractionEnabled = true
        
        for item in dragViewArray {
            
            item.isUserInteractionEnabled = true
        }
        
        clipCoverShapeLayer.opacity = 1.0
        
        updateClipCoverShape()
    }
    
    /// scrollView将开始拖动或缩放时 禁用一些交互等
    private func prepareForscrollViewWillBeginDraggingOrZooming() {
        
        bottomControlView.isUserInteractionEnabled = false
        rotateButton.isUserInteractionEnabled = false
        flipButton.isUserInteractionEnabled = false
        customRatioButton.isUserInteractionEnabled = false
        customRatioContainerView.isUserInteractionEnabled = false
        
        clipCoverShapeLayer.opacity = 0.0
    }
    
    /// scrollView结束拖动或缩放时 开启交互
    private func prepareForscrollViewDidEndDraggingOrZooming() {
        
        bottomControlView.isUserInteractionEnabled = true
        rotateButton.isUserInteractionEnabled = true
        flipButton.isUserInteractionEnabled = true
        customRatioButton.isUserInteractionEnabled = true
        customRatioContainerView.isUserInteractionEnabled = true
        
        clipCoverShapeLayer.opacity = 1.0
    }
}

// MARK:
// MARK: - Drag Limit

extension JKPHPickerEditView {
    
    /// 更新拖拽的限制
    private func updateDragLimit(corner: DragCorner) {
        
        let convertRet = mainScrollView.convert(displayImageView.frame, to: contentView)
        
        var maxRect: CGRect = .zero
        
        maxRect.origin.x = max(borderMaxRect.minX, convertRet.minX)
        maxRect.origin.y = max(borderMaxRect.minY, convertRet.minY)
        
        maxRect.size.width = min(borderMaxRect.maxX, convertRet.maxX) - maxRect.minX
        maxRect.size.height = min(borderMaxRect.maxY, convertRet.maxY) - maxRect.minY
        
        let clipRect = currentClipBorderRect ?? initialClipBorderRect
        
        dragLimit.minWidth = borderMinSize.width
        dragLimit.minHeight = borderMinSize.height
        
        guard configuration.isClipRatio else { // 不按比例裁剪
            
            switch corner {
                
            case .topLeft:
                
                dragLimit.minX = max(maxRect.minX, clipRect.maxX - defaultClipBorderRect.width)
                dragLimit.minY = max(maxRect.minY, clipRect.maxY - defaultClipBorderRect.height)
                dragLimit.maxX = clipRect.maxX - borderMinSize.width
                dragLimit.maxY = clipRect.maxY - borderMinSize.height
                dragLimit.maxWidth = min(clipRect.maxX - maxRect.minX, defaultClipBorderRect.width)
                dragLimit.maxHeight = min(clipRect.maxY - maxRect.minY, defaultClipBorderRect.height)
                
            case .topRight:
                
                dragLimit.minX = clipRect.minX
                dragLimit.minY = max(maxRect.minY, clipRect.maxY - defaultClipBorderRect.height)
                dragLimit.maxX = clipRect.minX
                dragLimit.maxY = clipRect.maxY - borderMinSize.height
                dragLimit.maxWidth = min(maxRect.maxX - clipRect.minX, defaultClipBorderRect.width)
                dragLimit.maxHeight = min(clipRect.maxY - maxRect.minY, defaultClipBorderRect.height)
                
            case .bottomLeft:
                
                dragLimit.minX = max(maxRect.minX, clipRect.maxX - defaultClipBorderRect.width)
                dragLimit.minY = clipRect.minY
                dragLimit.maxX = clipRect.maxX - borderMinSize.width
                dragLimit.maxY = clipRect.minY
                dragLimit.maxWidth = min(clipRect.maxX - maxRect.minX, defaultClipBorderRect.width)
                dragLimit.maxHeight = min(maxRect.maxY - clipRect.minY, defaultClipBorderRect.height)
                
            case .bottomRight:
                
                dragLimit.minX = clipRect.minX
                dragLimit.minY = clipRect.minY
                dragLimit.maxX = clipRect.minX
                dragLimit.maxY = clipRect.maxY
                dragLimit.maxWidth = min(maxRect.maxX - clipRect.minX, defaultClipBorderRect.width)
                dragLimit.maxHeight = min(maxRect.maxY - clipRect.minY, defaultClipBorderRect.height)
                
            case .topCenter:
                
                dragLimit.minX = clipRect.minX
                dragLimit.minY = max(maxRect.minY, clipRect.maxY - defaultClipBorderRect.height)
                dragLimit.maxX = clipRect.minX
                dragLimit.maxY = clipRect.maxY - borderMinSize.height
                dragLimit.maxWidth = clipRect.width
                dragLimit.maxHeight = min(clipRect.maxY - maxRect.minY, defaultClipBorderRect.height)
                
            case .bottomCenter:
                
                dragLimit.minX = clipRect.minX
                dragLimit.minY = clipRect.minY
                dragLimit.maxX = clipRect.minX
                dragLimit.maxY = clipRect.minY
                dragLimit.maxWidth = clipRect.width
                dragLimit.maxHeight = min(maxRect.maxY - clipRect.minY, defaultClipBorderRect.height)
                
            case .leftCenter:
                
                dragLimit.minX = max(maxRect.minX, clipRect.maxX - defaultClipBorderRect.width)
                dragLimit.minY = clipRect.minY
                dragLimit.maxX = clipRect.maxX - borderMinSize.width
                dragLimit.maxY = clipRect.minY
                dragLimit.maxWidth = min(clipRect.maxX - maxRect.minX, defaultClipBorderRect.width)
                dragLimit.maxHeight = clipRect.height
                
            case .rightCenter:
                
                dragLimit.minX = clipRect.minX
                dragLimit.minY = clipRect.minY
                dragLimit.maxX = clipRect.minX
                dragLimit.maxY = clipRect.minY
                dragLimit.maxWidth = min(maxRect.maxX - clipRect.minX, defaultClipBorderRect.width)
                dragLimit.maxHeight = clipRect.height
                
            default:
                
                dragLimit.minX = maxRect.minX
                dragLimit.minY = maxRect.minY
                dragLimit.maxX = maxRect.maxX - clipRect.width
                dragLimit.maxY = maxRect.maxY - clipRect.height
                dragLimit.maxWidth = clipRect.width
                dragLimit.maxHeight = clipRect.height
            }
            
            return
        }
        
        // 按比例裁剪
        
        switch corner {
            
        case .topLeft:
            
            dragLimit.minX = max(maxRect.minX, clipRect.maxX - defaultClipBorderRect.width)
            dragLimit.minY = max(maxRect.minY, clipRect.maxY - defaultClipBorderRect.height)
            dragLimit.maxX = clipRect.maxX - borderMinSize.width
            dragLimit.maxY = clipRect.maxY - borderMinSize.height
            
            dragLimit.maxWidth = min(clipRect.maxX - maxRect.minX, defaultClipBorderRect.width)
            
            let maxHeight = min(clipRect.maxY - maxRect.minY, defaultClipBorderRect.height)
            
            dragLimit.maxHeight = JKGetScaleHeight(currentWidth: dragLimit.maxWidth, scaleWidth: configuration.clipRatio.x, scaleHeight: configuration.clipRatio.y)
            
            if dragLimit.maxHeight > maxHeight {
                
                dragLimit.maxHeight = maxHeight
                
                dragLimit.maxWidth = JKGetScaleWidth(currentHeight: dragLimit.maxHeight, scaleWidth: configuration.clipRatio.x, scaleHeight: configuration.clipRatio.y)
            }
            
        case .topRight:
            
            dragLimit.minX = clipRect.minX
            dragLimit.minY = max(maxRect.minY, clipRect.maxY - defaultClipBorderRect.height)
            dragLimit.maxX = clipRect.minX
            dragLimit.maxY = clipRect.maxY - borderMinSize.height
            
            dragLimit.maxWidth = min(maxRect.maxX - clipRect.minX, defaultClipBorderRect.width)
            
            let maxHeight = min(clipRect.maxY - maxRect.minY, defaultClipBorderRect.height)
            
            dragLimit.maxHeight = JKGetScaleHeight(currentWidth: dragLimit.maxWidth, scaleWidth: configuration.clipRatio.x, scaleHeight: configuration.clipRatio.y)
            
            if dragLimit.maxHeight > maxHeight {
                
                dragLimit.maxHeight = maxHeight
                
                dragLimit.maxWidth = JKGetScaleWidth(currentHeight: dragLimit.maxHeight, scaleWidth: configuration.clipRatio.x, scaleHeight: configuration.clipRatio.y)
            }
            
        case .bottomLeft:
            
            dragLimit.minX = max(maxRect.minX, clipRect.maxX - defaultClipBorderRect.width)
            dragLimit.minY = clipRect.minY
            dragLimit.maxX = clipRect.maxX - borderMinSize.width
            dragLimit.maxY = clipRect.minY
            
            dragLimit.maxWidth = min(clipRect.maxX - maxRect.minX, defaultClipBorderRect.width)
            
            let maxHeight = min(maxRect.maxY - clipRect.minY, defaultClipBorderRect.height)
            
            dragLimit.maxHeight = JKGetScaleHeight(currentWidth: dragLimit.maxWidth, scaleWidth: configuration.clipRatio.x, scaleHeight: configuration.clipRatio.y)
            
            if dragLimit.maxHeight > maxHeight {
                
                dragLimit.maxHeight = maxHeight
                
                dragLimit.maxWidth = JKGetScaleWidth(currentHeight: dragLimit.maxHeight, scaleWidth: configuration.clipRatio.x, scaleHeight: configuration.clipRatio.y)
            }
            
        case .bottomRight:
            
            dragLimit.minX = clipRect.minX
            dragLimit.minY = clipRect.minY
            dragLimit.maxX = clipRect.minX
            dragLimit.maxY = clipRect.maxY
            
            dragLimit.maxWidth = min(maxRect.maxX - clipRect.minX, defaultClipBorderRect.width)
            
            let maxHeight = min(maxRect.maxY - clipRect.minY, defaultClipBorderRect.height)
            
            dragLimit.maxHeight = JKGetScaleHeight(currentWidth: dragLimit.maxWidth, scaleWidth: configuration.clipRatio.x, scaleHeight: configuration.clipRatio.y)
            
            if dragLimit.maxHeight > maxHeight {
                
                dragLimit.maxHeight = maxHeight
                
                dragLimit.maxWidth = JKGetScaleWidth(currentHeight: dragLimit.maxHeight, scaleWidth: configuration.clipRatio.x, scaleHeight: configuration.clipRatio.y)
            }
            
        case .topCenter:
            
            dragLimit.minX = max(clipRect.midX - defaultClipBorderRect.width, maxRect.minX)
            dragLimit.minY = max(maxRect.minY, clipRect.maxY - defaultClipBorderRect.height)
            dragLimit.maxX = clipRect.midX - borderMinSize.width * 0.5
            dragLimit.maxY = clipRect.maxY - borderMinSize.height
            
            var maxHalfWidth = min(clipRect.midX - maxRect.minX, maxRect.maxX - clipRect.midX)
            maxHalfWidth = min(maxHalfWidth, defaultClipBorderRect.width * 0.5)
            dragLimit.maxWidth = min(maxHalfWidth * 2.0, defaultClipBorderRect.width)
            
            let maxHeight = min(clipRect.maxY - maxRect.minY, defaultClipBorderRect.height)
            dragLimit.maxHeight = JKGetScaleHeight(currentWidth: dragLimit.maxWidth, scaleWidth: configuration.clipRatio.x, scaleHeight: configuration.clipRatio.y)
            
            if dragLimit.maxHeight > maxHeight {
                
                dragLimit.maxHeight = maxHeight
                
                dragLimit.maxWidth = JKGetScaleWidth(currentHeight: dragLimit.maxHeight, scaleWidth: configuration.clipRatio.x, scaleHeight: configuration.clipRatio.y)
            }
            
        case .bottomCenter:
            
            dragLimit.minX = max(clipRect.midX - defaultClipBorderRect.width, maxRect.minX)
            dragLimit.minY = clipRect.minY
            dragLimit.maxX = clipRect.midX - borderMinSize.width * 0.5
            dragLimit.maxY = clipRect.minY
            
            var maxHalfWidth = min(clipRect.midX - maxRect.minX, maxRect.maxX - clipRect.midX)
            maxHalfWidth = min(maxHalfWidth, defaultClipBorderRect.width * 0.5)
            dragLimit.maxWidth = min(maxHalfWidth * 2.0, defaultClipBorderRect.width)
            
            let maxHeight = min(maxRect.maxY - clipRect.minY, defaultClipBorderRect.height)
            dragLimit.maxHeight = JKGetScaleHeight(currentWidth: dragLimit.maxWidth, scaleWidth: configuration.clipRatio.x, scaleHeight: configuration.clipRatio.y)
            
            if dragLimit.maxHeight > maxHeight {
                
                dragLimit.maxHeight = maxHeight
                
                dragLimit.maxWidth = JKGetScaleWidth(currentHeight: dragLimit.maxHeight, scaleWidth: configuration.clipRatio.x, scaleHeight: configuration.clipRatio.y)
            }
            
        case .leftCenter:
            
            dragLimit.minX = max(maxRect.minX, clipRect.maxX - defaultClipBorderRect.width)
            dragLimit.minY = max(clipRect.midY - defaultClipBorderRect.height, maxRect.minY)
            dragLimit.maxX = clipRect.maxX - borderMinSize.width
            dragLimit.maxY = clipRect.midY - borderMinSize.height * 0.5
            
            var maxHalfHeight = min(clipRect.midY - maxRect.minY, maxRect.maxY - clipRect.midY)
            maxHalfHeight = min(maxHalfHeight, defaultClipBorderRect.height * 0.5)
            dragLimit.maxHeight = min(maxHalfHeight * 2.0, defaultClipBorderRect.height)
            
            let maxWdith = min(clipRect.maxX - maxRect.minX, defaultClipBorderRect.width)
            dragLimit.maxWidth = JKGetScaleWidth(currentHeight: dragLimit.maxHeight, scaleWidth: configuration.clipRatio.x, scaleHeight: configuration.clipRatio.y)
            
            if dragLimit.maxWidth > maxWdith {
                
                dragLimit.maxWidth = maxWdith
                
                dragLimit.maxHeight = JKGetScaleHeight(currentWidth: dragLimit.maxWidth, scaleWidth: configuration.clipRatio.x, scaleHeight: configuration.clipRatio.y)
            }
            
        case .rightCenter:
            
            dragLimit.minX = clipRect.minX
            dragLimit.minY = max(clipRect.midY - defaultClipBorderRect.height, maxRect.minY)
            dragLimit.maxX = clipRect.minX
            dragLimit.maxY = clipRect.midY - borderMinSize.height * 0.5
            
            var maxHalfHeight = min(clipRect.midY - maxRect.minY, maxRect.maxY - clipRect.midY)
            maxHalfHeight = min(maxHalfHeight, defaultClipBorderRect.height * 0.5)
            dragLimit.maxHeight = min(maxHalfHeight * 2.0, defaultClipBorderRect.height)
            
            let maxWidth = min(maxRect.maxX - clipRect.minX, defaultClipBorderRect.width)
            dragLimit.maxWidth = JKGetScaleWidth(currentHeight: dragLimit.maxHeight, scaleWidth: configuration.clipRatio.x, scaleHeight: configuration.clipRatio.y)
            
            if dragLimit.maxWidth > maxWidth {
                
                dragLimit.maxWidth = maxWidth
                
                dragLimit.maxHeight = JKGetScaleHeight(currentWidth: dragLimit.maxWidth, scaleWidth: configuration.clipRatio.x, scaleHeight: configuration.clipRatio.y)
            }
            
        default:
            
            dragLimit.minX = maxRect.minX
            dragLimit.minY = maxRect.minY
            dragLimit.maxX = maxRect.maxX - clipRect.width
            dragLimit.maxY = maxRect.maxY - clipRect.height
            dragLimit.maxWidth = clipRect.width
            dragLimit.maxHeight = clipRect.height
        }
    }
}

// MARK:
// MARK: - Drag Changed

extension JKPHPickerEditView {
    
    /// 更新拖拽区域改变
    private func updateDragChanged(corner: DragCorner, translation: CGPoint) {
        
        var rect = clipRectView.frame
        
        if configuration.isClipRatio { // 按比例裁剪
            
            let isUsedWidth = abs(translation.x) > abs(translation.y)
            
            switch corner {
                
            case .topLeft:
                
                if isUsedWidth {
                    
                    rect.size.width -= translation.x
                    rect.size.width = min(rect.size.width, dragLimit.maxWidth)
                    
                    rect.size.height = JKGetScaleHeight(currentWidth: rect.size.width, scaleWidth: configuration.clipRatio.x, scaleHeight: configuration.clipRatio.y)
                    
                } else {
                    
                    rect.size.height -= translation.y
                    rect.size.height = min(rect.size.height, dragLimit.maxHeight)
                    
                    rect.size.width = JKGetScaleWidth(currentHeight: rect.size.height, scaleWidth: configuration.clipRatio.x, scaleHeight: configuration.clipRatio.y)
                }
                
                rect.origin.x = originalRect.maxX - rect.size.width
                rect.origin.y = originalRect.maxY - rect.size.height
                
            case .topRight:
                
                if isUsedWidth {
                    
                    rect.size.width += translation.x
                    rect.size.width = min(rect.size.width, dragLimit.maxWidth)
                    
                    rect.size.height = JKGetScaleHeight(currentWidth: rect.size.width, scaleWidth: configuration.clipRatio.x, scaleHeight: configuration.clipRatio.y)
                    
                } else {
                    
                    rect.size.height -= translation.y
                    rect.size.height = min(rect.size.height, dragLimit.maxHeight)
                    
                    rect.size.width = JKGetScaleWidth(currentHeight: rect.size.height, scaleWidth: configuration.clipRatio.x, scaleHeight: configuration.clipRatio.y)
                }
                
                rect.origin.y = originalRect.maxY - rect.size.height
                
            case .bottomLeft:
                
                if isUsedWidth {
                    
                    rect.size.width -= translation.x
                    rect.size.width = min(rect.size.width, dragLimit.maxWidth)
                    
                    rect.size.height = JKGetScaleHeight(currentWidth: rect.size.width, scaleWidth: configuration.clipRatio.x, scaleHeight: configuration.clipRatio.y)
                    
                } else {
                    
                    rect.size.height += translation.y
                    rect.size.height = min(rect.size.height, dragLimit.maxHeight)
                    
                    rect.size.width = JKGetScaleWidth(currentHeight: rect.size.height, scaleWidth: configuration.clipRatio.x, scaleHeight: configuration.clipRatio.y)
                }
                
                rect.origin.x = originalRect.maxX - rect.size.width
                
            case .bottomRight:
                
                if isUsedWidth {
                    
                    rect.size.width += translation.x
                    rect.size.width = min(rect.size.width, dragLimit.maxWidth)
                    
                    rect.size.height = JKGetScaleHeight(currentWidth: rect.size.width, scaleWidth: configuration.clipRatio.x, scaleHeight: configuration.clipRatio.y)
                    
                } else {
                    
                    rect.size.height += translation.y
                    rect.size.height = min(rect.size.height, dragLimit.maxHeight)
                    
                    rect.size.width = JKGetScaleWidth(currentHeight: rect.size.height, scaleWidth: configuration.clipRatio.x, scaleHeight: configuration.clipRatio.y)
                }
                
            case .topCenter:
                
                rect.size.height -= translation.y
                rect.size.height = min(rect.size.height, dragLimit.maxHeight)
                rect.size.width = JKGetScaleWidth(currentHeight: rect.size.height, scaleWidth: configuration.clipRatio.x, scaleHeight: configuration.clipRatio.y)
                
                rect.origin.x = originalRect.midX - rect.size.width * 0.5
                rect.origin.y = originalRect.maxY - rect.size.height
                
            case .bottomCenter:
                
                rect.size.height += translation.y
                rect.size.height = min(rect.size.height, dragLimit.maxHeight)
                rect.size.width = JKGetScaleWidth(currentHeight: rect.size.height, scaleWidth: configuration.clipRatio.x, scaleHeight: configuration.clipRatio.y)
                
                rect.origin.x = originalRect.midX - rect.size.width * 0.5
                rect.origin.y = originalRect.maxY - rect.size.height
                
            case .leftCenter:
                
                rect.size.width -= translation.x
                rect.size.width = min(rect.size.width, dragLimit.maxWidth)
                
                rect.size.height = JKGetScaleHeight(currentWidth: rect.size.width, scaleWidth: configuration.clipRatio.x, scaleHeight: configuration.clipRatio.y)
                
                rect.origin.x = originalRect.maxX - rect.size.width
                rect.origin.y = originalRect.midY - rect.size.height * 0.5
                
            case .rightCenter:
                
                rect.size.width += translation.x
                rect.size.width = min(rect.size.width, dragLimit.maxWidth)
                
                rect.size.height = JKGetScaleHeight(currentWidth: rect.size.width, scaleWidth: configuration.clipRatio.x, scaleHeight: configuration.clipRatio.y)
                
                rect.origin.x = originalRect.maxX - rect.size.width
                rect.origin.y = originalRect.midY - rect.size.height * 0.5
                
            default:
                
                rect.origin.x += translation.x
                rect.origin.y += translation.y
            }
            
        } else { // 不按比例裁剪
            
            switch corner {
                
            case .topLeft:
                
                rect.origin.x += translation.x
                rect.origin.y += translation.y
                rect.size.width -= translation.x
                rect.size.height -= translation.y
                
            case .topRight:
                
                rect.origin.y += translation.y
                rect.size.width += translation.x
                rect.size.height -= translation.y
                
            case .bottomLeft:
                
                rect.origin.x += translation.x
                rect.size.width -= translation.x
                rect.size.height += translation.y
                
            case .bottomRight:
                
                rect.size.width += translation.x
                rect.size.height += translation.y
                
            case .topCenter:
                
                rect.origin.y += translation.y
                rect.size.height -= translation.y
                
            case .bottomCenter:
                
                rect.size.height += translation.y
                
            case .leftCenter:
                
                rect.origin.x += translation.x
                rect.size.width -= translation.x
                
            case .rightCenter:
                
                rect.size.width += translation.x
                
            default:
                
                rect.origin.x += translation.x
                rect.origin.y += translation.y
            }
        }
        
        correctClipRect(rect)
        
        updateDragViewLayout()
        
        updateScrollViewContentInset()
    }
    
    /// 校正截图区域
    private func correctClipRect(_ clipRect: CGRect) {
        
        var rect = clipRect
        
        rect.origin.x = max(rect.origin.x, dragLimit.minX)
        rect.origin.x = min(rect.origin.x, dragLimit.maxX)
        
        rect.origin.y = max(rect.origin.y, dragLimit.minY)
        rect.origin.y = min(rect.origin.y, dragLimit.maxY)
        
        rect.size.width = min(rect.size.width, dragLimit.maxWidth)
        rect.size.width = max(rect.size.width, dragLimit.minWidth)

        rect.size.height = min(rect.size.height, dragLimit.maxHeight)
        rect.size.height = max(rect.size.height, dragLimit.minHeight)
        
        currentClipBorderRect = rect
        
        clipRectView.frame = rect
        
        updateClipRectSubviewsLayout()
    }
}

// MARK:
// MARK: - UIScrollViewDelegate

extension JKPHPickerEditView: UIScrollViewDelegate {
    
    open func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        
        prepareForscrollViewWillBeginDraggingOrZooming()
    }
    
    open func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        
        if decelerate { return }
        
        prepareForscrollViewDidEndDraggingOrZooming()
    }
    
    open func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        
        prepareForscrollViewDidEndDraggingOrZooming()
    }
    
    open func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        
        prepareForscrollViewDidEndDraggingOrZooming()
    }
    
    open func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        
        prepareForscrollViewWillBeginDraggingOrZooming()
    }
    
    open func scrollViewDidZoom(_ scrollView: UIScrollView) {
        
    }
    
    open func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        
        self.prepareForscrollViewDidEndDraggingOrZooming()
    }
    
    open func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        
        return displayImageView
    }
}
