//
//  MemberViewController.swift
//  MemberFeature
//
//  Created by 김동현 on 3/4/26.
//

import UIKit
import RxSwift
import RxCocoa
import Core
import Domain
import DSKit

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
        
        let itemSelected = customView.collectionView.rx
            .modelSelected(MemberItem.self)
            .share()
        
        let inviteCellTapped = itemSelected
            .compactMap { item -> Void? in
                guard case .invite = item else { return nil }
            }.mapToVoid()
        
        let memberCellTapped = itemSelected
            .compactMap { item -> User? in
                guard case .member(let user) = item else { return nil }
                return user
            }
        
        let input = MemberViewModel.Input(inviteCellTapped: inviteCellTapped,
                                          memberCellTapped: memberCellTapped)
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
        
        // 공유하기
        output.inviteCode
            .drive(with: self, onNext: { owner, inviteCode in
                owner.shareInvitation(inviteCode: inviteCode)
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

extension MemberViewController {
    // MARK: - 초대 함수
    private func shareInvitation(inviteCode: String) {
        // 1) 초대 메시지
        let inviteURL = Constants.Notion.notionURL
        let message = String(
            format: "member.invite.share.message".localized(),
            inviteCode,
            inviteURL,
            Constants.Appstore.appstoreURL
        )
        // 2) UIActivityViewController 생성
        let items: [Any] = [message]
        let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)
        
        // 3) iPad 대응(팝오버 위치)
        if let pop = activityVC.popoverPresentationController {
            pop.sourceView = self.view
            pop.sourceRect = CGRect(x: view.bounds.midX,
                                    y: view.bounds.midY,
                                    width: 0, height: 0)
            pop.permittedArrowDirections = []
        }
        
        // 4) 공유 시트 표시
        present(activityVC, animated: true)
    }
}
