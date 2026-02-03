//
//  2. Relay.swift
//  RxLabDemo
//
//  Created by 김동현 on 2/3/26.
//

import RxSwift
import RxCocoa


/*
 Relay
 MARK: Relay는 “절대 종료되지 않는 Subject”이다.
 MARK: UI와 상태 스트림에서 안전하게 쓰기 위한 Subject의 실무용 대체제

 - Subject에서 onError / onCompleted를 제거한 형태
 - 오직 값 전달(onNext)만 가능
 - 스트림이 절대 종료되지 않음

 Observable + Observer 역할을 동시에 수행
 ─────────────────────────────────────
 차이 요약
 - Subject : 이벤트 + 에러 + 완료 → 스트림 종료 위험
 - Relay   : 이벤트만 전달 → 절대 죽지 않음

 스레드
 - ❌ 스레드 보장 없음
 - accept를 호출한 스레드에서 그대로 방출
 - UI 연결 시 Driver로 변환 권장

 에러
 - ❌ 에러 개념 자체가 없음
 - onError / onCompleted 존재하지 않음
 - UI 스트림에 최적화된 설계

 언제 사용하는가
 - ViewModel Input
 - ViewModel 내부 상태
 - UI에 전달되는 모든 스트림

 한 줄 요약
 - ❝ UI에서 써도 절대 죽지 않는 Subject ❞
 */


/*
 PublishRelay
 ─────────────────────────────────────
 특징
 - 구독 이후에 발생한 값만 전달
 - 이전 값은 저장하지 않음
 - accept(_:)로 값 전달

 Subject 대응
 - PublishSubject의 안전한 대체제

 스레드
 - ❌ 스레드 보장 없음

 에러
 - ❌ 에러 불가 (설계상 존재하지 않음)

 언제 사용하는가
 - 버튼 탭
 - 단발성 이벤트
 - 트리거

 한 줄 요약
 - ❝ 지금 발생한 이벤트만 안전하게 흘려보낸다 ❞
 */
func relay_publish() {
    runner(description: "PublishRelay") {
        let disposeBag = DisposeBag()
        let relay = PublishRelay<String>()

        // 구독자 1
        relay
            .subscribe(onNext: {
                print("구독자1:", $0)
            })
            .disposed(by: disposeBag)

        relay.accept("A")
        relay.accept("B")

        // 구독자 2 (늦게 구독)
        relay
            .subscribe(onNext: {
                print("구독자2:", $0)
            })
            .disposed(by: disposeBag)

        relay.accept("C")
    }
}


/*
 BehaviorRelay
 ─────────────────────────────────────
 특징
 - 항상 최신 값 1개를 저장
 - 새 구독자는 즉시 최신 값 수신
 - 초기값 필수
 - value로 현재 값 접근 가능

 Subject 대응
 - BehaviorSubject의 안전한 대체제

 스레드
 - ❌ 스레드 보장 없음

 에러
 - ❌ 에러 불가

 언제 사용하는가
 - 현재 상태 표현
 - UI 상태 (로딩, 선택값, 토글)
 - ViewModel Output

 한 줄 요약
 - ❝ 항상 최신 상태를 안전하게 들고 있는 스트림 ❞
 */
func relay_behavior() {
    runner(description: "BehaviorRelay") {
        let disposeBag = DisposeBag()
        let relay = BehaviorRelay(value: "초기값")

        // 구독자 1
        relay
            .subscribe(onNext: {
                print("구독자1:", $0)
            })
            .disposed(by: disposeBag)

        relay.accept("A")

        // 구독자 2 (늦게 구독)
        relay
            .subscribe(onNext: {
                print("구독자2:", $0)
            })
            .disposed(by: disposeBag)

        relay.accept("B")
    }
}


/*
 Relay 사용 패턴 (MVVM)
 ─────────────────────────────────────

 ViewModel Input
 - PublishRelay 사용
 - 외부 이벤트 전달

 ViewModel Output
 - BehaviorRelay 사용
 - 현재 상태 전달

 View
 - Output을 Driver로 변환 후 UI 바인딩
 */
func relay_mvvm_pattern() {
    runner(description: "Relay MVVM Pattern") {
        let disposeBag = DisposeBag()

        let tapRelay = PublishRelay<Void>()
        let titleRelay = BehaviorRelay<String>(value: "")

        tapRelay
            .map { "버튼 눌림" }
            .bind(to: titleRelay)
            .disposed(by: disposeBag)

        titleRelay
            .asDriver()
            .drive(onNext: {
                print("UI:", $0)
            })
            .disposed(by: disposeBag)

        // View 이벤트
        tapRelay.accept(())
    }
}
