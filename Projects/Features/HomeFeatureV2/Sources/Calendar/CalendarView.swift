//
//  CalendarView.swift
//  HomeFeatureV2
//
//  Created by 김동현 on 4/21/26.
//

import UIKit
import FSCalendar

final class CalendarView: UIView {

    var calendarViewHeightConstraint: NSLayoutConstraint!

    lazy var calendarView: FSCalendar = {
        let calendar = FSCalendar()
        let currentLocale = Locale.current

        calendar.register(CalendarCell.self, forCellReuseIdentifier: CalendarCell.reuseIdentifier)
        calendar.firstWeekday = 2
        calendar.scope = .month
        calendar.scrollEnabled = true
        calendar.locale = currentLocale

        calendar.headerHeight = 55
        calendar.appearance.headerDateFormat = DateFormatter.dateFormat(fromTemplate: "MMMM", options: 0, locale: currentLocale) ?? "MMMM"
        calendar.appearance.headerTitleColor = .mainWhite

        calendar.appearance.weekdayFont = UIFont.hcFont(.regular, size: 12.scaled)
        calendar.appearance.weekdayTextColor = .mainWhite

        calendar.appearance.titleDefaultColor = .mainWhite
        calendar.appearance.titleTodayColor = .mainWhite
        calendar.appearance.titleFont = UIFont.hcFont(.bold, size: 18.scaled)
        calendar.appearance.subtitleFont = UIFont.hcFont(.medium, size: 10.scaled)
        calendar.appearance.subtitleTodayColor = .kakao
        calendar.appearance.todayColor = .clear

        calendar.appearance.selectionColor = .clear
        return calendar
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .background
        addSubview(calendarView)
        calendarView.translatesAutoresizingMaskIntoConstraints = false
    }

    private func setupConstraints() {
        calendarViewHeightConstraint = calendarView.heightAnchor.constraint(equalToConstant: 500)
        NSLayoutConstraint.activate([
            calendarView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            calendarView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            calendarView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            calendarViewHeightConstraint
        ])
    }
}
