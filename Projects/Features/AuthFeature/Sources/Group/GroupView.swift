//  GroupViewView.swift
//  AuthFeature
//
//  Created by 김동현 on 2/3/26.
//

import UIKit
//
//final class GroupView: UIView {
//    
//    // MARK: - UI Component
//    let scrollView: UIScrollView={
//        let view = UIScrollView()
//        view.isPagingEnabled = true
//        view.isScrollEnabled = false
//        view.contentInsetAdjustmentBehavior = .never
//        return view
//    }()
//    let contentView = UIView()
//    
//    // MARK: - View
//    let groupSelectView = GroupSelectView()
//    let groupHostView = GroupHostView()
//    let groupEnterView = GroupEnterView()
//
//    // MARK: - Initializer
//    override init(frame: CGRect) {
//        super.init(frame: frame)
//        setupUI()
//        setupConstraints()
//    }
//
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//
//    // MARK: - UI Setup
//    private func setupUI() {
//        backgroundColor = .background
//        
//        addSubview(scrollView)
//        scrollView.addSubview(contentView)
//        scrollView.translatesAutoresizingMaskIntoConstraints = false
//        contentView.translatesAutoresizingMaskIntoConstraints = false
//        
//        [groupSelectView, groupHostView, groupEnterView].forEach {
//            contentView.addSubview($0)
//            $0.translatesAutoresizingMaskIntoConstraints = false
//        }
//    }
//
//    // MARK: - Constraints
//    private func setupConstraints() {
//        NSLayoutConstraint.activate([
//            // MARK: - ScrollView
//            scrollView.topAnchor.constraint(equalTo: topAnchor, constant: 0),
//            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
//            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
//            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
//            
//            // MARK: - ContentView
//            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
//            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
//            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
//            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
//            
//            // 세로는 고정, 가로만 늘림
//            contentView.heightAnchor.constraint(equalTo: scrollView.frameLayoutGuide.heightAnchor),
//            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, multiplier: 3),
//            
//            // MARK: - Page 1 (Nickname)
//            groupSelectView.topAnchor.constraint(equalTo: contentView.topAnchor),
//            groupSelectView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
//            groupSelectView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
//            groupSelectView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
//            
//            // MARK: - Page 2
//            groupHostView.topAnchor.constraint(equalTo: contentView.topAnchor),
//            groupHostView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
//            groupHostView.leadingAnchor.constraint(equalTo: groupSelectView.trailingAnchor),
//            groupHostView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
//            
//            // MARK: - Page 3
//            groupEnterView.topAnchor.constraint(equalTo: contentView.topAnchor),
//            groupEnterView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
//            groupEnterView.leadingAnchor.constraint(equalTo: groupHostView.trailingAnchor),
//            groupEnterView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
//        ])
//    }
//    
//    // MARK: - Page Control
//    func move(to index: Int, animated: Bool = true) {
//        let x = scrollView.frame.width * CGFloat(index)
//        scrollView.setContentOffset(CGPoint(x: x, y: 0), animated: animated)
//    }
//}
//
//#Preview {
//    GroupView()
//}

enum TransitionDirection {
    case forward
    case backward
}

final class GroupView: UIView {
    
    // MARK: - UI Component
    private let containerView = UIView()
    private var currentView: UIView?
    
    // MARK: - View
    let groupSelectView = GroupSelectView()
    let groupHostView = GroupHostView()
    let groupEnterView = GroupEnterView()

    // MARK: - Initializer
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UI Setup
    private func setupUI() {
        backgroundColor = .background
        
        addSubview(containerView)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
    }
    
    // MARK: - Show
    func show(
        _ nextView: UIView,
        direction: TransitionDirection,
        animated: Bool = true
    ) {
        // 같은 뷰면 아무 것도 안 함
        guard currentView !== nextView else { return }
        
        // 최초 진입
        guard let current = currentView else {
            attach(nextView)
            currentView = nextView
            return
        }
        
        let width = bounds.width
        let offset = direction == .forward ? width : -width

        nextView.frame = bounds.offsetBy(dx: offset, dy: 0)
        nextView.translatesAutoresizingMaskIntoConstraints = true
        containerView.addSubview(nextView)

        /*
        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseOut]) {
            current.frame = current.frame.offsetBy(dx: -offset, dy: 0)
            nextView.frame = self.bounds
        } completion: { _ in
            current.removeFromSuperview()
            self.currentView = nextView
        }
         */
        
        UIView.animate(
            withDuration: 0.65,             // 시간 늘리기
            delay: 0,
            usingSpringWithDamping: 0.92,   // 살짝 탄성
            initialSpringVelocity: 0.6,     // 시작 속도 낮추기
            options: [.allowUserInteraction, .curveEaseOut],
            animations: {
                current.frame = current.frame.offsetBy(dx: -offset, dy: 0)
                nextView.frame = self.bounds
            },
            completion: { _ in
                current.removeFromSuperview()
                self.currentView = nextView
            }
        )
    }

    private func attach(_ view: UIView) {
        containerView.addSubview(view)
        view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: containerView.topAnchor),
            view.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            view.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
        ])
    }
}

#Preview {
    GroupView()
}
