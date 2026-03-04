//
//  MemberViewController.swift
//  MemberFeature
//
//  Created by 김동현 on 3/4/26.
//

import UIKit
import RxSwift
import RxCocoa
import Domain

enum MemberItem {
    case invite
    case member(User)
}

final class MemberViewController: UIViewController {
    
    let disposeBag = DisposeBag()
    private let viewModel: MemberViewModel
    private let customView = MemberView()
    
    init(viewModel: MemberViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - LifeCycle
    override func loadView() {
        self.view = customView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setDelegate()
        bindViewModel()
    }
    
    private func setDelegate() {
        customView.collectionView.rx
            .setDelegate(self)
            .disposed(by: disposeBag)
    }
    
    private func bindViewModel() {
        
        // 맴버 클릭
        let memberPreview = customView.collectionView.rx
            .modelSelected(MemberCell.self)
            .asObservable()
        
        
        let input = MemberViewModel.Input()
        let output = viewModel.transform(input: input)
        
        // 인원 수
        output.sortedMembers
            .map { "\($0.count)명" }
            .drive(customView.peopleLabel.rx.text)
            .disposed(by: disposeBag)
        
        // invite버튼 + 멤버 리스트
        let items = output.sortedMembers
            .map { members -> [MemberItem] in
                [.invite] + members.map { MemberItem.member($0) }
            }
        
        // invite버튼 + 멤버 리스트
        items
            .drive(
                customView.collectionView.rx
                    .items(cellIdentifier: MemberCell.reuseIdentifier,
                           cellType: MemberCell.self
                  )
            ) { _, memberItem, cell in
                switch memberItem {
                case .invite:
                    cell.configureInvite()
                case .member(let user):
                    cell.configure(user: user)
                }
            }
            .disposed(by: disposeBag)
        
        // 셀 선택 이벤트
        customView.collectionView.rx
            .modelSelected(MemberItem.self)
            .bind(with: self, onNext: { owner, item in
                switch item {
                case .invite:
                    print("초대 버튼")
                case .member(let user):
                    print("멤버 버튼")
                }
            })
            .disposed(by: disposeBag)
    }
}

extension MemberViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {

        return CGSize(
            width: collectionView.frame.width,
            height: 60
        )
    }
}
