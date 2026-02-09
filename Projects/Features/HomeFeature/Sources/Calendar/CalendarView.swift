//
//  CalendarView.swift
//  HomeFeature
//
//  Created by 김동현 on 2/9/26.
//

import UIKit
import FSCalendar
import Kingfisher

final class CalendarView: UIView {
    
    var calendarViewHeightConstraint: NSLayoutConstraint!
    
    // MARK: - UI Component
    lazy var calendarView: FSCalendar = {
        let calendar = FSCalendar()
        
        // 셀등록
        calendar.register(CalendarCell.self, forCellReuseIdentifier: CalendarCell.reuseIdentifier)
        
        // 첫 열을 월요일로 설정
        calendar.firstWeekday = 2
        
        // week 또는 month 가능
        calendar.scope = .month
        calendar.scrollEnabled = true
        calendar.locale = Locale(identifier: "ko_KR")
        
        // 헤더뷰 설정
        calendar.headerHeight = 55
        calendar.appearance.headerDateFormat = "MM월"
        calendar.appearance.headerTitleColor = .mainWhite
        
        // 요일 UI 설정
        calendar.appearance.weekdayFont = UIFont.hcFont(.regular, size: 12.scaled)
        calendar.appearance.weekdayTextColor = .mainWhite
        
        // 날짜별 UI 설정
        calendar.appearance.titleDefaultColor = .mainWhite
        calendar.appearance.titleTodayColor = .mainWhite
        calendar.appearance.titleFont = UIFont.hcFont(.bold, size: 18.scaled)
        calendar.appearance.subtitleFont = UIFont.hcFont(.medium, size: 10.scaled)
        calendar.appearance.subtitleTodayColor = .kakao
        calendar.appearance.todayColor = .clear
        
        // 선택 배경 사라지게
        calendar.appearance.selectionColor = .clear
        return calendar
    }()

    // MARK: - Initializer
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UI Setup
    private func setupUI() {
        backgroundColor = .background

        self.addSubview(calendarView)
        calendarView.translatesAutoresizingMaskIntoConstraints = false
    }

    // MARK: - Constraints
    private func setupConstraints() {
        calendarViewHeightConstraint = calendarView.heightAnchor.constraint(equalToConstant: 500)
        NSLayoutConstraint.activate([
            calendarView.topAnchor.constraint(equalTo: self.safeAreaLayoutGuide.topAnchor, constant: 0),
            calendarView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 20),
            calendarView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -20),
            calendarViewHeightConstraint
        ])
    }
}

//#Preview {
//    CalendarViewController(homeViewModel: StubHomeViewModel())
//}
