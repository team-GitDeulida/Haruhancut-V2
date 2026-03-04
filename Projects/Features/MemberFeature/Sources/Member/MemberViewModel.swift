//
//  MemberViewModel.swift
//  MemberFeature
//
//  Created by 김동현 on 3/4/26.
//

import MemberFeatureInterface
import Domain
import RxCocoa
import Core
import RxSwift

final class MemberViewModel: MemberViewModelType {
    
    // MARK: - Coordinator Trigger
    var onCellImageTapped: ((String) -> Void)?
    
    let disposeBag = DisposeBag()
    private let userSession: UserSession
    private let groupSession: GroupSession
    private let authUsecase: AuthUsecaseProtocol
    private let groupUsecase: GroupUsecaseProtocol
    
    struct Input {
        let inviteCellTapped: Observable<Void>
        let memberCellTapped: Observable<User>
    }
    
    struct Output {
        let sortedMembers: Driver<[User]>
        let inviteCode: Driver<String>
    }
    
    init(userSession: UserSession,
         groupSession: GroupSession,
         authUsecase: AuthUsecaseProtocol,
         groupUsecase: GroupUsecaseProtocol
    ) {
        self.userSession = userSession
        self.groupSession = groupSession
        self.authUsecase = authUsecase
        self.groupUsecase = groupUsecase
    }
    
    func transform(input: Input) -> Output {
        let memberUIDs: [String] = Array(groupSession.members.keys)
        let members = Observable
            .from(memberUIDs) /// 배열타입의 각 요소를 하나씩 방출
            .withUnretained(self)
            .flatMap { owner, uid -> Observable<User> in
                return owner.authUsecase
                    .fetchUser(uid: uid)
                    .asObservable()
                    .compactMap { $0 }
            }
            .toArray()
            .asObservable()
            .share(replay: 1)
        
        let sortedMembers = members
            .withUnretained(self)
            .map { owner, users -> [User] in
                let myUID = owner.userSession.userId
                let me = users.first { $0.uid == myUID }
                let others = users
                    .filter { $0.uid != myUID }
                    .sorted { $0.registerDate < $1.registerDate }
                return ([me].compactMap { $0 }) + others
            }
            .asDriver(onErrorJustReturn: [])
        
        let inviteCode = input.inviteCellTapped
                .map { [weak self] _ in self?.groupSession.inviteCode ?? "" }
                .asDriver(onErrorJustReturn: "")
        
        // MARK: - Coordinator
        input.memberCellTapped
            .compactMap(\.profileImageURL)
            .bind(with: self, onNext: { owner, imageURL in
                owner.onCellImageTapped?(imageURL)
            })
            .disposed(by: disposeBag)
        
        return Output(sortedMembers: sortedMembers,
                      inviteCode: inviteCode)
    }
}
