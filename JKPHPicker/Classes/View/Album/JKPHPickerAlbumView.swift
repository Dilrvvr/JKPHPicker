//
//  JKPHPickerAlbumView.swift
//  JKSwiftPhotoPicker
//
//  Created by AlbertCC on 2021/5/4.
//

import UIKit
import Photos

public protocol JKPHPickerAlbumViewDelegate: NSObjectProtocol {
    
    /// 选中相册
    func albumView(_ albumView: JKPHPickerAlbumView, didSelect album: JKPHPickerAlbumItem)
    
    /// 相册列表即将展示
    func albumViewWillShow(_ albumView: JKPHPickerAlbumView)
    
    /// 相册列表即将退出
    func albumViewWillDismiss(_ albumView: JKPHPickerAlbumView)
}

open class JKPHPickerAlbumView: JKPHPickerUIView {
    
    private static let rowHeight: CGFloat = 66.0
    
    // MARK:
    // MARK: - Public Property
    
    open private(set) var configuration: JKPHPickerConfiguration
    
    /// 相册列表代理
    open weak var delegate: JKPHPickerAlbumViewDelegate?
    
    // MARK:
    // MARK: - Public Methods
    
    open func updateAlbumDataArray(_ albumItemArray: [JKPHPickerAlbumItem]) {
        
        albumDataArray = albumItemArray
        
        tableView.reloadData()
    }
    
    /// show
    open func show() {
        
        if isAnimating { return }
        
        isAnimating = true
        
        if let _ = delegate {
            
            delegate!.albumViewWillShow(self)
        }
        
        backgroundView.alpha = 0.0
        contentView.frame.origin.y = -contentView.bounds.height
        isHidden = false
        
        UIView.animate(withDuration: 0.25) {
            
            self.backgroundView.alpha = 1.0
            self.contentView.frame.origin.y = 0.0
            self.tableView.frame.origin.y = 15.0
            
        } completion: { _ in
            
            UIView.animate(withDuration: 0.25) {
                
                self.tableView.frame.origin.y = 0.0
                
            } completion: { _ in
                
                self.isAnimating = false
            }
        }
    }
    
    /// dismiss
    open func dismiss() {
        
        if isAnimating { return }
        
        isAnimating = true
        
        UIView.animate(withDuration: 0.25) {
            
            self.tableView.frame.origin.y = 15.0
            
        } completion: { _ in
            
            if let _ = self.delegate {
                
                self.delegate!.albumViewWillDismiss(self)
            }
            
            UIView.animate(withDuration: 0.25) {
                
                self.backgroundView.alpha = 0.0
                self.tableView.frame.origin.y = 0.0
                self.contentView.frame.origin.y = -self.contentView.bounds.height
                
            } completion: { _ in
                
                self.isHidden = true
                self.isAnimating = false
            }
        }
    }
    
    // MARK:
    // MARK: - Override
    
    public init(frame: CGRect, configuration: JKPHPickerConfiguration) {
        
        self.configuration = configuration
        
        super.init(frame: frame)
    }
    
    public required init?(coder: NSCoder) {
        
        self.configuration = JKPHPickerConfiguration()
        
        super.init(coder: coder)
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        
        dismissButton.frame = bounds
        
        contentView.frame = CGRect(x: 0.0, y: 0.0, width: bounds.width, height: bounds.height * 0.618)
        
        tableView.frame = contentView.bounds
    }
    
    // MARK:
    // MARK: - Private Methods
    
    
    
    // MARK:
    // MARK: - Private Selector
    
    /// dismissButtonClick
    @objc private func dismissButtonClick(button: UIButton) {
        
        dismiss()
    }
    
    // MARK:
    // MARK: - Custom Delegates
    
    
    
    // MARK:
    // MARK: - Initialization & Build UI
    
    /// 初始化自身属性 交给子类重写 super自动调用该方法
    open override func initializeProperty() {
        super.initializeProperty()
        
    }
    
    /// 构造函数初始化时调用 注意调用super
    open override func initialization() {
        super.initialization()
        
    }
    
    /// 创建UI 交给子类重写 super自动调用该方法
    open override func createUI() {
        super.createUI()
        
        insertSubview(dismissButton, aboveSubview: backgroundView)
        
        contentView.addSubview(tableView)
    }
    
    /// 布局UI 交给子类重写 super自动调用该方法
    open override func layoutUI() {
        super.layoutUI()
        
    }
    
    /// 初始化UI数据 交给子类重写 super自动调用该方法
    open override func initializeUIData() {
        super.initializeUIData()
        
        clipsToBounds = true
        
        backgroundView.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        contentView.backgroundColor = JKPHPickerUtility.darkBackgroundColor
        tableView.backgroundColor = contentView.backgroundColor
    }
    
    // MARK:
    // MARK: - Private Property
    
    private var isAnimating = false
    
    private var albumDataArray = [JKPHPickerAlbumItem]()
    
    /// dismissButton
    private lazy var dismissButton: UIButton = {
        
        let dismissButton = UIButton(type: .custom)
        
        dismissButton.addTarget(self, action: #selector(dismissButtonClick(button:)), for: .touchUpInside)
        
        return dismissButton
    }()
    
    /// tableView
    private lazy var tableView: UITableView = {
        
        let tableView = UITableView(frame: .zero, style: .plain)
        
        tableView.backgroundColor = .clear
        tableView.backgroundView = nil
        
        tableView.separatorStyle = .none
        
        tableView.rowHeight = Self.rowHeight
        
        tableView.register(JKPHPickerAlbumCell.self, forCellReuseIdentifier: String(describing: JKPHPickerAlbumCell.self))
        
        tableView.dataSource = self
        tableView.delegate = self
        
        return tableView
    }()
}

// MARK:
// MARK: - UITableViewDataSource & UITableViewDelegate

extension JKPHPickerAlbumView: UITableViewDataSource, UITableViewDelegate {
    
    open func numberOfSections(in tableView: UITableView) -> Int {
        
        return 1
    }
    
    open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return albumDataArray.count
    }
    
    open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: JKPHPickerAlbumCell.self), for: indexPath)
        
        guard cell is JKPHPickerAlbumCell else { return cell }
        
        if indexPath.row >= albumDataArray.count { return cell }
        
        let realCell = cell as! JKPHPickerAlbumCell
        
        realCell.configuration = configuration
        
        realCell.model = albumDataArray[indexPath.row]
        
        return realCell
    }
    
    open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if albumDataArray.count <= indexPath.row { return }
        
        let model = albumDataArray[indexPath.row]
        
        dismiss()
        
        guard let _ = delegate else { return }
        
        delegate?.albumView(self, didSelect: model)
    }
}
