//
//  CalendarViewController.swift
//  HomeFeatureV2
//
//  Created by 김동현 on 4/21/26.
//

import UIKit
import RxSwift
import RxRelay
import RxCocoa
import ReactorKit
import FSCalendar
import Domain

// 캘린더 영역만 막고 나머지 페이지는 이동하기 위한 로직 1
// MARK: - 캘린더 에서 PageGesture를 제어하는 커스텀 Delegate
protocol GestureDelegate: AnyObject {
    func calendarDidStartGesture()
    func calendarDidEndGesture()
}

final class CalendarViewController: UIViewController, View {
    
    weak var gestureDelegate: GestureDelegate?
    var disposeBag = DisposeBag()
    private let customView = CalendarView()
    private let calendarImageTappedRelay = PublishRelay<([Post], Date)>()
    private var postsByDate: [String: [Post]] = [:]

    var calendarImageTapped: Driver<([Post], Date)> {
        calendarImageTappedRelay.asDriver(onErrorDriveWith: .empty())
    }

    init(reactor: CalendarReactor) {
        super.init(nibName: nil, bundle: nil)
        self.reactor = reactor
        
        // 캘린더 영역만 막고 나머지 페이지는 이동하기 위한 로직 3
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handleGesture))
        customView.calendarView.addGestureRecognizer(pan)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // 캘린더 영역만 막고 나머지 페이지는 이동하기 위한 로직 2
    @objc private func handleGesture(_ gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .began:
            gestureDelegate?.calendarDidStartGesture() // 페이지 제스처 막기
        case .ended, .cancelled:
            gestureDelegate?.calendarDidEndGesture()   // 페이지 제스처 허용
        default:
            break
        }
    }

    override func loadView() {
        view = customView
        customView.calendarView.delegate = self
        customView.calendarView.dataSource = self
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        reactor?.action.onNext(.viewDidAppear)
    }

    func bind(reactor: CalendarReactor) {
        reactor.state
            .map(\.postsByDate)
            .asDriver(onErrorDriveWith: .empty())
            .drive(with: self) { owner, postsByDate in
                owner.postsByDate = postsByDate
                owner.customView.calendarView.reloadData()
            }
            .disposed(by: disposeBag)
    }
}

extension CalendarViewController: FSCalendarDelegate {
    func calendar(_ calendar: FSCalendar, boundingRectWillChange bounds: CGRect, animated: Bool) {
        customView.calendarViewHeightConstraint.constant = bounds.height
        view.layoutIfNeeded()
    }

    func calendar(_ calendar: FSCalendar, didSelect date: Date, at monthPosition: FSCalendarMonthPosition) {
        guard monthPosition == .current else { return }
        let dateString = date.toDateKey()

        guard let posts = postsByDate[dateString], !posts.isEmpty else { return }

        calendarImageTappedRelay.accept((posts, date))
    }
}

extension CalendarViewController: FSCalendarDataSource {
    func calendar(_ calendar: FSCalendar, cellFor date: Date, at position: FSCalendarMonthPosition) -> FSCalendarCell {
        let cell = calendar.dequeueReusableCell(
            withIdentifier: CalendarCell.reuseIdentifier,
            for: date,
            at: position
        ) as! CalendarCell

        let dateString = date.toDateKey()
        let imageURL: String?

        if position == .current,
           let posts = postsByDate[dateString],
           let first = posts.first {
            imageURL = first.imageURL
        } else {
            imageURL = nil
        }

        cell.configure(
            date: date,
            isCurrentMonth: position == .current,
            imageURL: imageURL
        )
        return cell
    }
}
