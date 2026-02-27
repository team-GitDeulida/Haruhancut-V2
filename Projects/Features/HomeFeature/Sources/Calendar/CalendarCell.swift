//
//  CalendarCell.swift
//  HomeFeature
//
//  Created by 김동현 on 2/9/26.
//

import Foundation
import FSCalendar

final class CalendarCell: FSCalendarCell {
    
    private var currentImageURL: String?
    
    // 현재 월 여부를 selection 처리 시 사용하기 위한 내부 플래그
    private var currentMonthFlag: Bool = false
    
    // 날짜에 표시될 이미지 뷰
    private let cellImageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        return view
    }()
    
    // 선택 시 반투명 오버레이를 표시하기 위한 뷰
    private let selectedOverlay: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = false
        return view
    }()

    // 셀 생성 시 UI 초기 세팅
    override init!(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    // 스토리보드 미사용으로 fatal 처리
    required init!(coder: NSCoder!) {
        fatalError("init(coder:) has not been implemented")
    }

    // 서브뷰를 contentView에 추가
    private func setupUI() {
        contentView.insertSubview(cellImageView, at: 0)
        contentView.insertSubview(selectedOverlay, aboveSubview: cellImageView)
    }

    // 셀 내부 레이아웃 계산 및 중앙 정렬 처리
    override func layoutSubviews() {
        super.layoutSubviews()
        // 1. cellImageView와 selectedOverlay 똑같이 배치 (정중앙 정사각형)
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
        
        // 2. 숫자(타이틀) 완전 정중앙!
        let labelSize = titleLabel.intrinsicContentSize
        titleLabel.frame = CGRect(
            x: (contentView.bounds.width - labelSize.width) / 2,
            y: (contentView.bounds.height - labelSize.height) / 2,
            width: labelSize.width,
            height: labelSize.height
        )
    }

    /*
    // 기본 UIImage를 직접 설정
    func setImage(image: UIImage?) {
        self.cellImageView.image = image
    }
    
    // URL 기반 이미지 로드 (Kingfisher 사용)
    func setImage(url: String) {
        guard let url = URL(string: url) else { return }
        cellImageView.kf.setImage(with: url)
    }
     */
    
    /*
    // 이미지가 없을 때 기본 회색 박스 표시
    func setGrayBox() {
        cellImageView.image = nil
        cellImageView.backgroundColor = .gray500
    }
    
    // 다크 회색 박스 표시 (현재는 동일 색상)
    func setDarkGrayBox() {
        cellImageView.image = nil
        cellImageView.backgroundColor = .gray500
    }
     */
    
    // 날짜, 현재월 여부, 이미지 정보를 기반으로 셀 UI 구성
    /*
    public func configure(date: Date, isCurrentMonth: Bool, imageURL: String?) {
        let calendar = Calendar.current
        let isToday = calendar.isDateInToday(date)
        currentMonthFlag = isCurrentMonth
        
        // 이미지 세팅
        if let imageURL, let url = URL(string: imageURL) {
            cellImageView.kf.setImage(
                with: url,
                options: [
                    .backgroundDecode,      // 디코딩 백그라운드 스레드
                    .cacheOriginalImage,    // 원본 이미지 캐시 저장
                    .transition(.fade(0.15))// 이미지 교체 페이드 애니메이션
                ]
            )
            cellImageView.backgroundColor = .clear
        } else {
            cellImageView.image = nil
            cellImageView.backgroundColor = .gray500
        }
        
        // 오늘 테두리 표시
        if isToday && isCurrentMonth {
            cellImageView.layer.borderWidth = 3
            cellImageView.layer.borderColor = UIColor.hcColor.cgColor
        } else {
            cellImageView.layer.borderWidth = 0
        }
        
        // 셀 재사용으로 데이터 변경 시 호출
        updateSelectionUI()
    }
     */
    
    public func configure(date: Date, isCurrentMonth: Bool, imageURL: String?) {
        let calendar = Calendar.current
        let isToday = calendar.isDateInToday(date)
        currentMonthFlag = isCurrentMonth

        // 🔥 1️⃣ 이미지 처리
        if let imageURL,
           let url = URL(string: imageURL) {
            
            // 같은 URL이면 다시 로딩하지 않음
            if currentImageURL != imageURL {
                currentImageURL = imageURL
                
                cellImageView.kf.setImage(
                    with: url,
                    placeholder: cellImageView.image,
                    options: [
                        .backgroundDecode,
                        .cacheOriginalImage
                    ]
                )
            }
            
            // 이미지가 있는 날은 배경 투명
            cellImageView.backgroundColor = .clear
            
        } else {
            // 🔥 이미지 없는 날짜 처리 (항상 실행)
            currentImageURL = nil
            cellImageView.kf.cancelDownloadTask()
            cellImageView.image = nil
            cellImageView.backgroundColor = .gray500
        }

        // 🔥 2️⃣ 오늘 테두리 처리
        if isToday && isCurrentMonth {
            cellImageView.layer.borderWidth = 3
            cellImageView.layer.borderColor = UIColor.hcColor.cgColor
        } else {
            cellImageView.layer.borderWidth = 0
        }

        // 🔥 3️⃣ 선택 상태 업데이트
        updateSelectionUI()
    }
    
    // selection 상태 변경 시 오버레이 UI 업데이트
    override var isSelected: Bool {
        didSet {
            updateSelectionUI()
        }
    }
    
    // 현재월 && 선택 상태일 때만 반투명 오버레이 적용
    private func updateSelectionUI() {
        // 현재월 && 선택시 오버레이만 반투명 하늘색, 아니면 투명
        selectedOverlay.backgroundColor = isSelected && currentMonthFlag
            ? UIColor.hcColor.withAlphaComponent(0.4)
            : .clear
    }
    
    // 셀 재사용 전 이전 상태 초기화
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
