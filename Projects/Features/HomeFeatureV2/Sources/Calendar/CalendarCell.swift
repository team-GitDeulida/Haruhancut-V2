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
    private static let calendar = Calendar.current
    private static let selectedOverlayColor = UIColor.hcColor.withAlphaComponent(0.4)
    private static let todayBorderColor = UIColor.hcColor.cgColor

    private var currentImageURL: String?
    private var currentMonthFlag: Bool = false
    private var lastLayoutBounds: CGRect = .zero
    private var lastTitleText: String?

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

        let bounds = contentView.bounds
        let titleText = titleLabel.text
        guard bounds != lastLayoutBounds || titleText != lastTitleText else { return }

        lastLayoutBounds = bounds
        lastTitleText = titleText

        let minSide = min(bounds.width, bounds.height) - 6
        let frame = CGRect(
            x: (bounds.width - minSide) / 2,
            y: (bounds.height - minSide) / 2,
            width: minSide,
            height: minSide
        )

        cellImageView.frame = frame
        cellImageView.layer.cornerRadius = minSide / 4

        selectedOverlay.frame = frame
        selectedOverlay.layer.cornerRadius = minSide / 4

        let labelSize = titleLabel.intrinsicContentSize
        titleLabel.frame = CGRect(
            x: (bounds.width - labelSize.width) / 2,
            y: (bounds.height - labelSize.height) / 2,
            width: labelSize.width,
            height: labelSize.height
        )
    }

    public func configure(date: Date, isCurrentMonth: Bool, imageURL: String?) {
        let isToday = Self.calendar.isDateInToday(date)
        currentMonthFlag = isCurrentMonth

        let fallbackBackgroundColor: UIColor = currentMonthFlag ? .gray500 : .gray700
        if cellImageView.backgroundColor != fallbackBackgroundColor {
            cellImageView.backgroundColor = fallbackBackgroundColor
        }

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

            if cellImageView.backgroundColor != .clear {
                cellImageView.backgroundColor = .clear
            }
        } else {
            currentImageURL = nil
            cellImageView.kf.cancelDownloadTask()
            if cellImageView.image != nil {
                cellImageView.image = nil
            }
        }

        if isToday && isCurrentMonth {
            if cellImageView.layer.borderWidth != 3 {
                cellImageView.layer.borderWidth = 3
            }
            if cellImageView.layer.borderColor !== Self.todayBorderColor {
                cellImageView.layer.borderColor = Self.todayBorderColor
            }
        } else {
            if cellImageView.layer.borderWidth != 0 {
                cellImageView.layer.borderWidth = 0
            }
        }

        updateSelectionUI()
    }

    override var isSelected: Bool {
        didSet {
            updateSelectionUI()
        }
    }

    private func updateSelectionUI() {
        let targetColor = isSelected && currentMonthFlag ? Self.selectedOverlayColor : .clear
        if selectedOverlay.backgroundColor != targetColor {
            selectedOverlay.backgroundColor = targetColor
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        cellImageView.kf.cancelDownloadTask()
        if cellImageView.image != nil {
            cellImageView.image = nil
        }
        if cellImageView.backgroundColor != .clear {
            cellImageView.backgroundColor = .clear
        }
        if cellImageView.layer.borderWidth != 0 {
            cellImageView.layer.borderWidth = 0
        }
        if selectedOverlay.backgroundColor != .clear {
            selectedOverlay.backgroundColor = .clear
        }
        currentMonthFlag = false
        currentImageURL = nil
        lastTitleText = nil
    }
}
