//
//  3. Traits.swift
//  RxLabDemo
//
//  Created by 김동현 on 2/3/26.
//

import Foundation
import RxCocoa

/*
 MARK: Traits
 ─────────────────────────────────────
 Trait은 Observable에 "성질(의도)"을 부여한 타입이다.

 Observable은 너무 자유롭다.
 → 스레드?
 → 에러?
 → 몇 번 방출?
 → UI에 써도 되나?

 Trait은 이런 질문을 타입 레벨에서 끝내준다.

 핵심
 - Trait = Observable + 규칙 세트
 - 규칙을 어기면 생성 자체가 불가능
 */

/*
 Driver
 MARK: 이 스트림은 UI 상태용이며, 메인 스레드에서 에러 없이 안전하게 전달되어야 한다
 ─────────────────────────────────────
 역할
 - ViewModel Output → View(UI) 바인딩
 - UI 상태를 표현하는 스트림

 특징
 - MainScheduler 보장 ⭕️
 - 에러 방출 ❌
 - replay(1) ⭕️ (항상 최신 값 유지)
 - 여러 구독자 공유 ⭕️

 스레드
 - ⭕️ 항상 MainScheduler
 - observe(on:) 필요 없음

 에러
 - ❌ 허용되지 않음
 - Driver로 만들 때 반드시 에러 제거 필요
   (onErrorJustReturn / onErrorDriveWith)

 언제 사용하는가
 - UILabel.text
 - 버튼 enable 상태
 - 화면에 항상 보여야 하는 상태값

 한 줄 요약
 - ❝ UI 상태는 메인 스레드에서, 에러 없이, 항상 최신 값으로 ❞
 
 let titleDriver: Driver<String> =
     titleRelay.asDriver(onErrorJustReturn: "")

 titleDriver
     .drive(label.rx.text)
     .disposed(by: bag)
 */

/*
 Signal
 MARK: 이 스트림은 UI 이벤트용이며, 메인 스레드에서 에러 없이 전달되지만 재생되지 않는다
 ─────────────────────────────────────
 역할
 - UI 이벤트 전달
 - “한 번 발생하면 끝”인 액션

 특징
 - MainScheduler 보장 ⭕️
 - 에러 ❌
 - replay ❌
 - 구독 시 과거 이벤트 재방출 ❌

 스레드
 - ⭕️ MainScheduler

 에러
 - ❌ 허용되지 않음

 언제 사용하는가
 - 버튼 탭
 - 토스트 표시
 - 화면 이동 이벤트

 한 줄 요약
 - ❝ UI 이벤트는 흘러가고, 다시 재생되지 않는다 ❞
 
 let toastSignal: Signal<String> =
     toastRelay.asSignal()

 toastSignal
     .emit(onNext: { message in
         print("Toast:", message)
     })
     .disposed(by: bag)
 */

/*
 Single
 MARK: 이 스트림은 단 한 번 성공 또는 실패만 한다
 ─────────────────────────────────────
 역할
 - 비동기 작업 결과 표현
 - API 요청

 특징
 - success(value) 또는 failure(error)
 - onCompleted ❌
 - 값은 정확히 1번

 스레드
 - 보장 없음
 - 필요 시 observe(on:) 지정

 에러
 - ⭕️ 허용 (실패 개념 포함)

 언제 사용하는가
 - 네트워크 요청
 - DB fetch

 한 줄 요약
 - ❝ 성공 또는 실패, 단 한 번 ❞
 
 func fetchUser() -> Single<User> {
     return Single.create { single in
         single(.success(User()))
         return Disposables.create()
     }
 }
 */

/*
 Completable
 MARK: 이 스트림은 값 없이 완료 또는 실패만 표현한다
 ─────────────────────────────────────
 역할
 - 저장, 삭제, 로그아웃 등 결과만 중요한 작업

 특징
 - 값 방출 ❌
 - completed 또는 error

 언제 사용하는가
 - 로그아웃
 - 캐시 삭제

 한 줄 요약
 - ❝ 결과는 필요 없고, 성공 여부만 중요 ❞
 */

/*
 Maybe
 MARK: 이 스트림은 값이 있을 수도, 없을 수도 있다
 ─────────────────────────────────────
 역할
 - optional 결과 표현

 특징
 - success(value)
 - completed (값 없음)
 - error

 언제 사용하는가
 - 캐시 조회
 - 조건부 결과

 한 줄 요약
 - ❝ 값이 있을 수도, 없을 수도 ❞
 */
