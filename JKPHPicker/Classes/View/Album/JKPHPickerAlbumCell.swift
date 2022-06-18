//
//  JKPHPickerAlbumCell.swift
//  JKSwiftPhotoPicker
//
//  Created by AlbertCC on 2021/5/4.
//

import UIKit
import Photos
import JKSwiftLibrary

open class JKPHPickerAlbumCell: UITableViewCell {
    
    private static let thumbnailImageWH: CGFloat = 50.0

    // MARK:
    // MARK: - Public Property
    
    open var configuration: JKPHPickerConfiguration?
    
    /// model
    open var model: JKPHPickerAlbumItem? {
        
        didSet {
            
            albumTitleLabel.text = model?.albumTitle
            photoCountLabel.text = "\(model?.photoCount ?? 0)"
            thumbnailImageView.image = nil
            
            let selected = model?.isSelected ?? false
            
            accessoryType = selected ? .checkmark : .none
            
            guard let item = model,
                  let thumbnailPhotoItem = item.thumbnailPhotoItem else {
                      
                      return
                  }
            
            item.updateSelectStatusHandler = { [weak self] (albumItem) in
                
                guard let _ = self else { return }
                
                self?.updateSelectedStatus(albumItem: albumItem)
            }
            
            item.updatePhotoCountHandler = { [weak self] (albumItem) in
                
                guard let _ = self else { return }
                
                self?.updatePhotoCount(albumItem: albumItem)
            }
            
            thumbnailImageView.setPhotoPickerImage(with: thumbnailPhotoItem, configuration: configuration, imageCache: nil, requestType: .thumbnail)
        }
    }
    
    // MARK:
    // MARK: - Public Methods
    
    
    
    // MARK:
    // MARK: - Override
    
    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        initialization()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        initialization()
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        
        thumbnailImageView.frame = CGRect(x: 15.0, y: (contentView.bounds.height - Self.thumbnailImageWH) * 0.5, width: Self.thumbnailImageWH, height: Self.thumbnailImageWH)
        
        albumTitleLabel.frame = CGRect(x: thumbnailImageView.frame.maxX + 15.0, y: thumbnailImageView.frame.minY, width: contentView.bounds.width - 30.0 - thumbnailImageView.frame.maxX, height: Self.thumbnailImageWH * 0.5)
        
        photoCountLabel.frame = CGRect(x: albumTitleLabel.frame.minX, y: albumTitleLabel.frame.maxY, width: albumTitleLabel.frame.width, height: Self.thumbnailImageWH * 0.5)
        
        bottomLineView.frame = CGRect(x: 15.0, y: bounds.height - JKLineThickness, width: bounds.width - 15.0, height: JKLineThickness)
    }
    
    open override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        
        contentView.alpha = highlighted ? 0.5 : 1.0
        
        bottomLineView.layer.backgroundColor = JKLineDarkColor.cgColor
    }
    
    // MARK:
    // MARK: - Private Methods
    
    private func updatePhotoCount(albumItem : JKPHPickerAlbumItem) {
        
        guard let item = model, item == albumItem else { return }
        
        photoCountLabel.text = "\(albumItem.photoCount)"
    }
    
    private func updateSelectedStatus(albumItem : JKPHPickerAlbumItem) {
        
        guard let item = model, item == albumItem else { return }
        
        accessoryType = albumItem.isSelected ? .checkmark : .none
    }
    
    // MARK:
    // MARK: - Private Selector
    
    
    
    // MARK:
    // MARK: - Custom Delegates
    
    
    
    // MARK:
    // MARK: - Initialization & Build UI
    
    /// 初始化自身属性 交给子类重写 super自动调用该方法
    open func initializeProperty() {
        
    }
    
    /// 构造函数初始化时调用 注意调用super
    open func initialization() {
        
        initializeProperty()
        createUI()
        layoutUI()
        initializeUIData()
    }
    
    /// 创建UI 交给子类重写 super自动调用该方法
    open func createUI() {
        
        contentView.addSubview(thumbnailImageView)
        contentView.addSubview(albumTitleLabel)
        contentView.addSubview(photoCountLabel)
        
        addSubview(bottomLineView)
    }
    
    /// 布局UI 交给子类重写 super自动调用该方法
    open func layoutUI() {
        
    }
    
    /// 初始化UI数据 交给子类重写 super自动调用该方法
    open func initializeUIData() {
        
        backgroundColor = JKPHPickerUtility.darkBackgroundColor
        contentView.backgroundColor = backgroundColor
        
        backgroundView = nil
        selectedBackgroundView = UIView()
    }
    
    // MARK:
    // MARK: - Private Property
    
    /// 预览图
    private lazy var thumbnailImageView: JKPHPickerUIImageView = {
        
        let imageView = JKPHPickerUIImageView()
        
        imageView.layer.borderWidth = 0.5
        imageView.layer.borderColor = UIColor.lightGray.withAlphaComponent(0.5).cgColor
        imageView.layer.cornerRadius = 5.0
        imageView.layer.masksToBounds = true
        imageView.contentMode = .scaleAspectFill
        
        return imageView
    }()
    
    /// 相册标题
    private lazy var albumTitleLabel: UILabel = {
        
        let label = UILabel()
        
        label.font = UIFont.systemFont(ofSize: 16.0)
        label.textColor = .white
        label.textAlignment = .left
        
        return label
    }()
    
    /// 照片数量
    private lazy var photoCountLabel: UILabel = {
        
        let label = UILabel()
        
        label.font = UIFont.systemFont(ofSize: 13.0)
        label.textColor = .lightGray
        label.textAlignment = .left
        
        return label
    }()
    
    /// bottomLineView
    private lazy var bottomLineView: UIView = {
        
        let bottomLineView = UIView()
        
        bottomLineView.isUserInteractionEnabled = false
        
        bottomLineView.layer.backgroundColor = JKLineDarkColor.cgColor
        
        return bottomLineView
    }()
}
