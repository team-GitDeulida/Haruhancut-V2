//  GroupViewModel.swift
//  AuthFeature
//
//  Created by 김동현 on 2/3/26.
//

import UIKit
import RxSwift
import AuthFeatureInterface
import RxCocoa
import Core

final class GroupViewModel: GroupViewModelType {
    
    let disposeBag = DisposeBag()
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
        let hostEndTapped: Observable<Void>
        
        // Enter
        let invideCodeText: Observable<String>
        let enterEndTapped: Observable<Void>
    }
    
    struct Output {
        let hostResult: Driver<Result<String, GroupError>>
        let joinResult: Driver<Result<String, GroupError>>
        let step: Driver<Step>
    }
    
    func transform(input: Input) -> Output {
        // 화면 이동
        let toBack = input.backTapped.map { Step.select }
        let toHost = input.hostButtonTapped.map { Step.host }
        let toEnter = input.enterButtonTapped.map { Step.enter }
    
        // 각 분기 뷰에서 완료 버튼 누를 때
        let completed = Observable.merge(
            input.hostEndTapped,
            input.enterEndTapped
        )
        
        completed.subscribe(onNext: { [weak self] in
            self?.onGroupMakeOrJoinSuccess?()
        })
        .disposed(by: disposeBag)
        
        
        let step = Observable.merge(toBack, toHost, toEnter)
            .startWith(.select)
            .asDriver(onErrorJustReturn: .select)
        
        return Output(hostResult: .just(.success("")),
                      joinResult: .just(.success("")),
                      step: step)
    }
    
}
