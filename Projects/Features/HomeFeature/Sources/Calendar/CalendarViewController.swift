//
//  CalendarViewController.swift
//  HomeFeature
//
//  Created by 김동현 on 2/9/26.
//

import UIKit
import RxSwift
import FSCalendar
import Domain

final class CalendarViewController: UIViewController {
    
    private let disposeBag = DisposeBag()
    private let homeViewModel: HomeViewModel
    private let customView = CalendarView()
    private var output: HomeViewModel.Output?
    private var postsByDate: [String: [Post]] = [:]
    
    // MARK: - Initializer
    init(homeViewModel: HomeViewModel) {
        self.homeViewModel = homeViewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - LifeCycle
    override func loadView() {
        self.view = customView
        setDeleagte()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // MARK: - Bindings
    func setOutput(_ output: HomeViewModel.Output) {
        self.output = output
        bindViewModel()
    }
    
    private func setDeleagte() {
        customView.calendarView.delegate = self
        customView.calendarView.dataSource = self
    }
    
    private func bindViewModel() {
        guard let output else { return }
        
        // 새로운 그룹 정보를 방출할 때 마다 새로고침
        output.group
            .asDriver()
            .drive(with: self, onNext: { owner, _ in
                owner.customView.calendarView.reloadData()
            })
            .disposed(by: disposeBag)
        
        // 데이터 바인딩
        output.postsByDate
            .drive(with: self, onNext: { owner, map in
                owner.postsByDate = map
                owner.customView.calendarView.reloadData()
            })
            .disposed(by: disposeBag)
    }
}

// 행동(이벤트)을 처리하는 역할
extension CalendarViewController: FSCalendarDelegate {
    // 달력 뷰 높이 등 크기 변화 감지(UI 동적 레이아웃 맞출 때 활용)
    func calendar(_ calendar: FSCalendar, boundingRectWillChange bounds: CGRect, animated: Bool) {
        customView.calendarViewHeightConstraint.constant = bounds.height
        view.layoutIfNeeded()
    }
    
    // 셀 터치 감지
    func calendar(_ calendar: FSCalendar, didSelect date: Date, at monthPosition: FSCalendarMonthPosition) {
        // 현재 월이 아니면 return
        guard monthPosition == .current else { return }
        let dateString = date.toDateKey()
        
        // 터치한 날짜에 게시글이 없으면 조기 리턴
        guard let posts = postsByDate[dateString],
              !posts.isEmpty else { return }
        
        // print("게시글 존재하는 셀 클릭됨: \(posts)")
        homeViewModel.onCalendarImageTapped?(posts, date)
    }
}

// 데이터를 제공하는 역할 (FSCalendar에 셀 구성 데이터 전달)
extension CalendarViewController: FSCalendarDataSource {
    // 각 날짜에 해당하는 셀을 생성하고 구성
    func calendar(_ calendar: FSCalendar, cellFor date: Date, at position: FSCalendarMonthPosition) -> FSCalendarCell {
        
        // 재사용 큐에서 커스텀 CalendarCell 가져오기
        let cell = calendar.dequeueReusableCell(withIdentifier: CalendarCell.reuseIdentifier,
                                                for: date,
                                                at: position) as! CalendarCell
        
        // 날짜 -> String(key) 변환
        let dateString = date.toDateKey()
        
        // 셀에 표시할 이미지 URL (없으면 nil → 회색 박스 처리)
        let imageURL: String?

        // // 현재 월이면서 해당 날짜에 게시글이 존재하는 경우
        if position == .current,
           let posts = postsByDate[dateString],
           let first = posts.first {
            // // 첫 번째 게시글의 이미지 URL을 사용
            imageURL = first.imageURL
        } else {
            // 게시글이 없거나 현재 월이 아닌 경우 이미지 없음
            imageURL = nil
        }
        
        // 날짜, 현재월 여부, 이미지 정보를 기반으로 셀 UI 구성
        cell.configure(date: date,
                       isCurrentMonth: position == .current,
                       imageURL: imageURL)
        return cell
    }
}


