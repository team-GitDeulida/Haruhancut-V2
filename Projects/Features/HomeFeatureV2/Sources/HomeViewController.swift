//
//  HomeViewController.swift
//  HomeFeatureV2Interface
//
//  Created by 김동현 on 4/19/26.
//

import UIKit
import ReactorKit
import CarbonListKit
import DSKit

final class HomeViewController: UIViewController, View {

    var disposeBag = DisposeBag()
    typealias Reactor = HomeReactor
    
    private let collectionView = UICollectionView(
        frame: .zero,
        collectionViewLayout: UICollectionViewLayout()
    )
    private lazy var adapter = ListAdapter(collectionView: collectionView)
    
    private let segmentedBar: CustomSegmentedBarView = {
        let segment = CustomSegmentedBarView(items: [LocalizationKey.homeSegmentFeed.localized, LocalizationKey.homeSegmentCalendar.localized])
        return segment
    }()
    
    init(reactor: HomeReactor) {
        super.init(nibName: nil, bundle: nil)
        self.reactor = reactor
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigation()
        setupCollectionView()
    }
    
    private func setupNavigation() {
        /// 뷰 배경 색상
        view.backgroundColor = .background
        
        /// 네비게이션 버튼 색상
        self.navigationController?.navigationBar.tintColor = .mainWhite
        
        /// 네비게이션 제목
        segmentedBar.sizeToFit() // 글자 길이에 맞게 label 크기 조정
        self.navigationItem.titleView = segmentedBar
        
        /// 좌측 네비게이션 버튼
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "list.bullet"),
            style: .plain,
            target: nil,
            action: nil)
        
        /// 우측 네비게이션 버튼
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "person.fill"),
            style: .plain,
            target: nil,
            action: nil)
        
        /// 자식 화면에서 뒤로가기
        let backItem = UIBarButtonItem()
        backItem.title = LocalizationKey.homeNavigationBack.localized
        navigationItem.backBarButtonItem = backItem
    }
    
    private func setupCollectionView() {
        collectionView.backgroundColor = .clear
        collectionView.alwaysBounceVertical = true
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func render(components: [SimpleTextComponent]) {
        adapter.apply(updateStrategy: .animated) {
            Section(id: "section-1") {
                for component in components {
                    Cell(id: component.id, component: component)
                        .onSelect { context in
                            print(context.rowID)
                        }
                }
            }
            .layout(.vertical(spacing: 10))
            .contentInsets(.init(top: 20, leading: 16, bottom: 0, trailing: 16))
        }
    }
    
    func bind(reactor: HomeReactor) {
        reactor.state
            .map(\.components)
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .bind(with: self) { owner, components in
                owner.render(components: components)
            }
            .disposed(by: disposeBag)
    }
}

#Preview {
    let vc = HomeViewController(reactor: HomeReactor())
    UINavigationController(rootViewController: vc)
    
}
