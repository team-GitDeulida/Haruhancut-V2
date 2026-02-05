//  GroupViewModel.swift
//  AuthFeature
//
//  Created by 김동현 on 2/3/26.
//

import RxSwift
import AuthFeatureInterface
import Domain
import Core
import RxCocoa

// UILabel / UIButton 상태 반영 -> Driver
// push / pop / endEditing / alert등 VM이 판단한 UI 트리거라면 Signal
// 그룹 생성
// → 성공한 그룹만 추출
//   → 유저 업데이트
//     → 성공이면 이동
//     → 실패면 에러


final class GroupViewModel: GroupViewModelType {
    
    // MARK: - Properties
    let disposeBag = DisposeBag()
    private let groupUsecase: GroupUsecaseProtocol
    private var groupName = BehaviorRelay<String>(value: "")
    let errorRelay = PublishRelay<GroupError>()
    
    // MARK: - Coordinate Trigger
    var onGroupMakeOrJoinSuccess: (() -> Void)?
    
    enum Step {
        case select
        case host
        case enter
    }
    
    struct Input {
        // Navigation
        let backTapped: Observable<Void>
        
        // Select
        let enterButtonTapped: Observable<Void>
        let hostButtonTapped: Observable<Void>
        
        // Host
        let groupNameText: Observable<String>
        let hostReturnTapped: Observable<Void>
        let hostEndTapped: Observable<Void>
        
        // Enter
        let invideCodeText: Observable<String>
        let enterReturnTapped: Observable<Void>
        let enterEndTapped: Observable<Void>
    }
    
    struct Output {
        let step: Driver<Step>
        let hostGroupNameValid: Driver<Bool>
        let joinInviteCodeValid: Driver<Bool>
        
        let endEditingTrigger: Signal<Void> // UI 상태가 아니라 단순 트리거(event)라서 Observable
        let error: Signal<GroupError>
    }
    
    // MARK: - Init
    public init(groupUsecase: GroupUsecaseProtocol) {
        self.groupUsecase = groupUsecase
    }
    
    func transform(input: Input) -> Output {
        // 화면 이동
        let toBack = input.backTapped.map { Step.select }
        let toHost = input.hostButtonTapped.map { Step.host }
        let toEnter = input.enterButtonTapped.map { Step.enter }
        
        // 화면 이동
        let step = Observable.merge(toBack, toHost, toEnter)
            .startWith(.select)
            .asDriver(onErrorJustReturn: .select)
        
        // 각 분기 뷰에서 키보드 엔터 누를 때
        let endEditingTrigger = Observable.merge(
            input.hostReturnTapped,
            input.enterReturnTapped,
            input.hostEndTapped,
            input.enterEndTapped
        ).asSignal(onErrorSignalWith: .empty())
        
        // 각 분기 뷰에서 완료 버튼 누를 때
        /*
        let completed = Observable.merge(
            input.hostEndTapped,
            input.enterEndTapped
        )
         */
        
        // 그룹 이름 유효성
        let isHostGroupNameValid = input.groupNameText
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).count >= 2 }
            .distinctUntilChanged()                 // 중복된 값은 무시하고 변경될 때만 아래로 전달
            .asDriver(onErrorJustReturn: false)     // 에러 발생 시에도 false를 대신 방출
        
        // 초대 코드 유효성
        let isJoinInviteCodeValid = input.invideCodeText
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false }
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: false)
        
        // 그룹 생성 유효성
        let createGroupValid = input.hostEndTapped
            .withLatestFrom(input.groupNameText)
            .withUnretained(self)
            // 그룹 만들기
            .flatMapLatest { vm, groupName -> Observable<Result<Void, GroupError>> in
                return self.groupUsecase
                    .createGroup(groupName: groupName)
                    .mapToVoid()
            }
        
        // 그룹 참가 유효성
        let joinGroupValid = input.enterEndTapped
            .withLatestFrom(input.invideCodeText)
            .withUnretained(self)
            .flatMapLatest { vm, inviteCode -> Observable<Result<Void, GroupError>> in
                return self.groupUsecase
                    .joinGroup(inviteCode: inviteCode) // Observable<Result<HCGroup, GroupError>>
                    // .mapToVoid()                       // Observable<Result<Void, GroupError>>
                    .flatMapLatest { result -> Observable<Result<Void, GroupError>> in
                        switch result {
                        case .success(let group):
                            return vm.groupUsecase
                                .updateUserGroupId(groupId: group.groupId)
                                .map { updateResult in
                                    switch updateResult {
                                    case .success:
                                        // vm.updateLocalUser(group: group)
                                        return .success(())
                                    case .failure:
                                        return .failure(.updateUserGroupIdError)
                                    }
                                }
                            
                        case .failure(let error):
                            return .just(.failure(error))
                        }
                    }
            }
        
        // 유효성 결과
        let result = Observable                        // Observable<Result<Void, GroupError>>
            .merge(createGroupValid, joinGroupValid)
            .share()
        
        // 코디네이터 이동(성공 이벤트만 흘리고 실패는 버린다)
        result
            .compactMap(\.successVoid)
            .withUnretained(self)
            .bind(onNext: { vm, _ in
                vm.onGroupMakeOrJoinSuccess?()
            })
            .disposed(by: disposeBag)
        
        // 에러 알림
        result
            .compactMap(\.failureError)
            .bind(to: errorRelay)
            .disposed(by: disposeBag)
        

        return Output(step: step,
                      hostGroupNameValid: isHostGroupNameValid,
                      joinInviteCodeValid: isJoinInviteCodeValid,
                      endEditingTrigger: endEditingTrigger,
                      error: errorRelay.asSignal())
    }
}

