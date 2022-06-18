//
//  JKPHPickerToastView.swift
//  JKSwiftPhotoPicker
//
//  Created by albert on 2021/12/3.
//

import UIKit
import JKSwiftLibrary

open class JKPHPickerToastView: JKPHPickerUIView {
    
    private static let maxWidth = min(JKScreenWidth, JKScreenHeight) * 0.618
    
    private static let edgeInses = UIEdgeInsets(top: 10.0, left: 15.0, bottom: 10.0, right: 15.0)
    
    // MARK:
    // MARK: - Public Property
    
    open var message: String? {
        
        willSet {
            
            titleLabel.text = nil
            titleLabel.attributedText = nil
        }
        
        didSet {
            
            guard let _ = message else { return }
            
            let para = NSMutableParagraphStyle()
            para.alignment = .center
            para.lineSpacing = 5.0
            
            var attributes = [NSAttributedString.Key : Any]()
            attributes[.foregroundColor] = titleLabel.textColor
            attributes[.font] = titleLabel.font
            attributes[.paragraphStyle] = para
            
            let attr = NSAttributedString(string: message!, attributes: attributes)
            
            titleLabel.attributedText = attr
        }
    }
    
    // MARK:
    // MARK: - Public Methods
    
    public static func show(in superView: UIView?,
                            message: String?,
                            dismissInterval: TimeInterval = 1.0) {
        
        guard let _ = superView,
              let toast = message,
              toast.count > 0,
              dismissInterval > 0.0 else {
                  
                  return
              }
        
        let toastView = JKPHPickerToastView()
        toastView.alpha = 0.0
        toastView.message = message
        superView?.addSubview(toastView)
        
        toastView.updateLayout()
        
        UIView.animate(withDuration: 0.25) {
            
            toastView.alpha = 1.0
            
        } completion: { _ in
            
            DispatchQueue.main.asyncAfter(deadline: .now() + dismissInterval) {
                
                UIView.animate(withDuration: 0.25) {
                    
                    toastView.alpha = 0.0
                    
                } completion: { _ in
                    
                    toastView.removeFromSuperview()
                }
            }
        }
    }
    
    // MARK:
    // MARK: - Override
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        
        updateLayout()
    }
    
    // MARK:
    // MARK: - Private Methods
    
    private func updateLayout() {
        
        guard let superView = superview else { return }
        
        let titleMaxWidth = Self.maxWidth - Self.edgeInses.left - Self.edgeInses.right
        
        let titleSize = titleLabel.sizeThatFits(CGSize(width: titleMaxWidth, height: CGFloat.infinity))
        
        let height = titleSize.height + Self.edgeInses.top + Self.edgeInses.bottom
        
        frame = CGRect(x: 0.0, y: 0.0, width: titleMaxWidth + Self.edgeInses.left + Self.edgeInses.right, height: height)
        
        center = CGPoint(x: superView.bounds.width * 0.5, y: superView.bounds.height * 0.5)
        
        titleLabel.frame = CGRect(x: 0.0, y: 0.0, width: titleSize.width, height: height)
        
        titleLabel.center = CGPoint(x: bounds.width * 0.5, y: bounds.height * 0.5)
    }
    
    // MARK:
    // MARK: - Private Selector
    
    
    
    // MARK:
    // MARK: - Initialization & Build UI
    
    /// 初始化自身属性 交给子类重写 super自动调用该方法 注意调用super
    open override func initializeProperty() {
        super.initializeProperty()
        
    }
    
    /// 构造函数初始化时调用 注意调用super
    open override func initialization() {
        super.initialization()
        
    }
    
    /// 创建UI 交给子类重写 super自动调用该方法 注意调用super
    open override func createUI() {
        super.createUI()
        
        addSubview(titleLabel)
    }
    
    /// 布局UI 交给子类重写 super自动调用该方法 注意调用super
    open override func layoutUI() {
        super.layoutUI()
        
    }
    
    /// 初始化UI数据 交给子类重写 super自动调用该方法 注意调用super
    open override func initializeUIData() {
        super.initializeUIData()
        
        layer.backgroundColor = UIColor.black.cgColor
        layer.cornerRadius = 5.0
        
        contentView.isHidden = true
        backgroundView.isHidden = true
    }
    
    // MARK:
    // MARK: - Private Property
    
    /// titleLabel
    private lazy var titleLabel: UILabel = {
        
        let label = UILabel()
        
        label.font = UIFont.systemFont(ofSize: 15.0)
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 0
        
        return label
    }()
}
