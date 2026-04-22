//
//  CalendarCell.swift
//  HomeFeatureV2
//
//  Created by 김동현 on 4/21/26.
//

import UIKit
import Foundation
import FSCalendar
import Kingfisher
import DSKit

final class CalendarCell: FSCalendarCell {

    private var currentImageURL: String?
    private var currentMonthFlag: Bool = false

    private let cellImageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        return view
    }()

    private let selectedOverlay: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = false
        return view
    }()

    override init!(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init!(coder: NSCoder!) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        contentView.insertSubview(cellImageView, at: 0)
        contentView.insertSubview(selectedOverlay, aboveSubview: cellImageView)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let minSide = min(contentView.bounds.width, contentView.bounds.height) - 6
        let frame = CGRect(
            x: (contentView.bounds.width - minSide) / 2,
            y: (contentView.bounds.height - minSide) / 2,
            width: minSide,
            height: minSide
        )

        cellImageView.frame = frame
        cellImageView.layer.cornerRadius = minSide / 4

        selectedOverlay.frame = frame
        selectedOverlay.layer.cornerRadius = minSide / 4

        let labelSize = titleLabel.intrinsicContentSize
        titleLabel.frame = CGRect(
            x: (contentView.bounds.width - labelSize.width) / 2,
            y: (contentView.bounds.height - labelSize.height) / 2,
            width: labelSize.width,
            height: labelSize.height
        )
    }

    public func configure(date: Date, isCurrentMonth: Bool, imageURL: String?) {
        let calendar = Calendar.current
        let isToday = calendar.isDateInToday(date)
        currentMonthFlag = isCurrentMonth

        cellImageView.backgroundColor = currentMonthFlag ? .gray500 : .gray700

        if let imageURL, let url = URL(string: imageURL) {
            if currentImageURL != imageURL {
                currentImageURL = imageURL

                let targetSize = contentView.bounds.size
                guard targetSize != .zero else { return }

                let processor = DownsamplingImageProcessor(size: targetSize)
                cellImageView.kf.setImage(
                    with: url,
                    placeholder: cellImageView.image,
                    options: [
                        .processor(processor),
                        .backgroundDecode,
                        .scaleFactor(UIScreen.main.scale),
                        .cacheOriginalImage
                    ]
                )
            }

            cellImageView.backgroundColor = .clear
        } else {
            currentImageURL = nil
            cellImageView.kf.cancelDownloadTask()
            cellImageView.image = nil
        }

        if isToday && isCurrentMonth {
            cellImageView.layer.borderWidth = 3
            cellImageView.layer.borderColor = UIColor.hcColor.cgColor
        } else {
            cellImageView.layer.borderWidth = 0
        }

        updateSelectionUI()
    }

    override var isSelected: Bool {
        didSet {
            updateSelectionUI()
        }
    }

    private func updateSelectionUI() {
        selectedOverlay.backgroundColor = isSelected && currentMonthFlag
            ? UIColor.hcColor.withAlphaComponent(0.4)
            : .clear
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        cellImageView.kf.cancelDownloadTask()
        cellImageView.image = nil
        cellImageView.backgroundColor = .clear
        cellImageView.layer.borderWidth = 0
        selectedOverlay.backgroundColor = .clear
        currentMonthFlag = false
        currentImageURL = nil
    }
}
