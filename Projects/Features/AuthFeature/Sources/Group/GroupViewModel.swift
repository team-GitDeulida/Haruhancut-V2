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

final class GroupViewModel: GroupViewModelType {
    
    // MARK: - Properties
    let disposeBag = DisposeBag()
    private let signInUsecase: SignInUsecaseProtocol
    
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
        let endEditingTrigger: Signal<Void> // UI 상태가 아니라 단순 트리거(event)라서 Observable
        
        let hostResult: Driver<Result<String, GroupError>>
        let hostGroupNameValid: Driver<Bool>
        
        let joinResult: Driver<Result<String, GroupError>>
        let joinInviteCodeValid: Driver<Bool>
    }
    
    // MARK: - Init
    public init(signInUsecase: SignInUsecaseProtocol) {
        self.signInUsecase = signInUsecase
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
        let completed = Observable.merge(
            input.hostEndTapped,
            input.enterEndTapped
        )
        
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
        let hostResult = input.hostButtonTapped
            .withLatestFrom(input.invideCodeText)
            .withUnretained(self)
//            .flatMapLatest { inviteCode -> Observable<Result<Void, GroupError>> in
//                return self.signInUsecase
//            }
        
        // 코디네이터 트리거
        completed.subscribe(onNext: { [weak self] in
            self?.onGroupMakeOrJoinSuccess?()
        })
        .disposed(by: disposeBag)
        
        return Output(step: step,
                      endEditingTrigger: endEditingTrigger,
                      hostResult: .just(.success("")),
                      hostGroupNameValid: isHostGroupNameValid,
                      joinResult: .just(.success("")),
                      joinInviteCodeValid: isJoinInviteCodeValid)
    }
}
