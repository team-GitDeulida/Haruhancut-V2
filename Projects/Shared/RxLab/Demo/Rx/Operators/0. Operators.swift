//
//  Operators.swift
//  RxLabDemo
//
//  Created by 김동현 on 2/3/26.
//

import RxSwift
import Foundation

/*
 MARK: Operators (연산자)
 ─────────────────────────────────────
 연산자는 Observable이 흘려보내는 값을
 "변환 / 조합 / 제어"하는 함수들이다.

 핵심 개념
 - Observable을 다른 Observable로 바꾼다
 - 원본은 건드리지 않는다 (불변)
 - 연산자 체인은 "데이터 파이프라인"이다
 */

/*
 map
 ─────────────────────────────────────
 역할
 - 방출된 값을 다른 값으로 변환

 특징
 - 1 : 1 변환
 - 가장 기본적인 연산자

 언제 사용하는가
 - 모델 → 뷰모델
 - 타입 변환
 - 값 가공

 한 줄 요약
 - ❝ 값을 다른 값으로 바꾼다 ❞
 */
func map() {
    runner(description: "map") {
        let disposeBag = DisposeBag()
        Observable.of(1, 2, 3)
            .map { $0 * 2 }
            .subscribe(onNext: { print($0) })
            .disposed(by: disposeBag)
        // 2, 4, 6
    }
}

/*
 filter
 ─────────────────────────────────────
 역할
 - 조건에 맞는 값만 통과

 특징
 - true → 통과
 - false → 버림

 언제 사용하는가
 - 유효성 검사
 - 조건부 처리

 한 줄 요약
 - ❝ 필요한 값만 흘려보낸다 ❞
 */
func filter() {
    runner(description: "filter") {
        let disposeBag = DisposeBag()
        Observable.of(1, 2, 3, 4)
            .filter { $0.isMultiple(of: 2) }
            .subscribe(onNext: { print($0) })
            .disposed(by: disposeBag)
        // 2, 4
    }
}

/*
 flatMap
 ─────────────────────────────────────
 역할
 - 값 → Observable로 변환 후 병합

 특징
 - 비동기 작업 연결
 - 여러 스트림이 동시에 살아 있음

 언제 사용하는가
 - API 체이닝
 - Observable 안에서 Observable 반환

 한 줄 요약
 - ❝ Observable을 펼쳐서 하나로 만든다 ❞
 */
func flatMap() {
    runner(description: "flatMap") {
        let disposeBag = DisposeBag()
        Observable.of(1, 2)
            .flatMap { value in
                Observable.of(value * 10)
            }
            .subscribe(onNext: { print($0) })
            .disposed(by: disposeBag)
        // 10, 20
    }
}

/*
 flatMapLatest
 ─────────────────────────────────────
 역할
 - 가장 최신 Observable만 유지

 특징
 - 이전 작업은 자동 취소
 - UI 입력 처리의 핵심

 언제 사용하는가
 - 검색
 - 버튼 연타 방지

 한 줄 요약
 - ❝ 최신 것만 살아남는다 ❞
 
 searchText
     .flatMapLatest { query in
         api.search(query)
     }
 */
func flatMapLatest() {
    runner(description: "flatMapLatest") {
        let disposeBag = DisposeBag()
        let subject = PublishSubject<Int>()

        subject
            .flatMapLatest { value in
                Observable<Int>.just(value)
            }
            .subscribe(onNext: { print($0) })
            .disposed(by: disposeBag)

        subject.onNext(1)
        subject.onNext(2)
        subject.onNext(3)
    }
}

/*
 merge
 ─────────────────────────────────────
 역할
 - 여러 Observable을 하나로 합침

 특징
 - 순서 보장 ❌
 - 먼저 오는 대로 방출

 언제 사용하는가
 - 여러 이벤트 소스 통합

 한 줄 요약
 - ❝ 여러 파이프를 하나로 ❞
 */
func merge() {
    runner(description: "merge") {
        let a = Observable<Int>.just(1)
        let b = Observable<Int>.just(2)
        let disposeBag = DisposeBag()
        Observable.merge(a, b)
            .subscribe(onNext: { print($0) })
            .disposed(by: disposeBag)
        
        // 1, 2
    }
}

/*
 combineLatest
 ─────────────────────────────────────
 역할
 - 최신 값들을 조합

 특징
 - 모든 Observable이 한 번 이상 값 방출해야 동작

 언제 사용하는가
 - 입력 폼 검증
 - 상태 조합

 한 줄 요약
 - ❝ 최신 상태들을 묶는다 ❞
 
 Observable.combineLatest(id, password)
     .map { !$0.isEmpty && !$1.isEmpty }
 */
func combineLatest() {
    runner(description: "combineLatest") {
        let disposeBag = DisposeBag()
        let id = PublishSubject<String>()
        let pw = PublishSubject<String>()

        Observable.combineLatest(id, pw)
            .subscribe(onNext: { print("id:", $0, "pw:", $1) })
            .disposed(by: disposeBag)

        id.onNext("user")
        pw.onNext("1234")
        pw.onNext("5678")
    }
}


/*
 withLatestFrom
 ─────────────────────────────────────
 역할
 - 트리거 시점에 다른 스트림의 최신 값 사용

 특징
 - 기준 스트림이 명확

 언제 사용하는가
 - 버튼 탭 + 현재 입력값

 한 줄 요약
 - ❝ 누를 때 최신 값을 가져온다 ❞
 
 submitTap
     .withLatestFrom(formData)
 */
func withLatestFrom() {
    runner(description: "withLatestFrom") {
        let disposeBag = DisposeBag()
        let tap = PublishSubject<Void>()
        let text = PublishSubject<String>()

        tap
            .withLatestFrom(text)
            .subscribe(onNext: { print("전송:", $0) })
            .disposed(by: disposeBag)

        text.onNext("Hello")
        tap.onNext(())
        text.onNext("RxSwift")
        tap.onNext(())
    }
}

/*
 debounce
 ─────────────────────────────────────
 역할
 - 일정 시간 동안 입력이 멈췄을 때만 방출

 언제 사용하는가
 - 검색창

 한 줄 요약
 - ❝ 잠깐 기다렸다가 한 번 ❞
 
 searchText
     .debounce(.milliseconds(300), scheduler: MainScheduler.instance)
 */
func debounce() {
    runner(description: "debounce") {
        let disposeBag = DisposeBag()
        let subject = PublishSubject<String>()

        subject
            .debounce(.milliseconds(300), scheduler: MainScheduler.instance)
            .subscribe(onNext: { print($0) })
            .disposed(by: disposeBag)

        subject.onNext("H")
        subject.onNext("He")
        subject.onNext("Hel")
        subject.onNext("Hell")
        subject.onNext("Hello")

        RunLoop.main.run(until: Date(timeIntervalSinceNow: 1))
    }
}

/*
 throttle
 ─────────────────────────────────────
 역할
 - 일정 시간 동안 한 번만 허용

 언제 사용하는가
 - 버튼 연타 방지

 한 줄 요약
 - ❝ 너무 자주 오면 막는다 ❞
 */
func throttle() {
    runner(description: "throttle") {
        let disposeBag = DisposeBag()
        let subject = PublishSubject<String>()

        subject
            .throttle(.milliseconds(300), scheduler: MainScheduler.instance)
            .subscribe(onNext: { print($0) })
            .disposed(by: disposeBag)

        subject.onNext("A")
        subject.onNext("B")
        subject.onNext("C")

        RunLoop.main.run(until: Date(timeIntervalSinceNow: 1))
    }
}


/*
 distinctUntilChanged
 ─────────────────────────────────────
 역할
 - 이전 값과 같으면 방출하지 않음

 언제 사용하는가
 - 중복 UI 업데이트 방지

 한 줄 요약
 - ❝ 같은 값이면 무시 ❞
 */
func distinctUntilChanged() {
    runner(description: "distinctUntilChanged") {
        let disposeBag = DisposeBag()

        Observable.of(1, 1, 2, 2, 3, 3)
            .distinctUntilChanged()
            .subscribe(onNext: { print($0) })
            .disposed(by: disposeBag)
    }
}

/*
 take / skip
 ─────────────────────────────────────
 역할
 - take(n): 앞에서 n개만
 - skip(n): 앞에서 n개 버림

 한 줄 요약
 - ❝ 일부만 선택 ❞
 */
func take_skip() {
    runner(description: "take / skip") {
        let disposeBag = DisposeBag()

        Observable.of(1, 2, 3, 4, 5)
            .skip(2)
            .take(2)
            .subscribe(onNext: { print($0) })
            .disposed(by: disposeBag)
    }
}

/*
 do
 ─────────────────────────────────────
 역할
 - 스트림을 변경하지 않고 "중간에서 엿보기"만 한다
 - 사이드 이펙트(side-effect) 전용 연산자

 특징
 - 값은 그대로 흘려보냄 (map 아님)
 - 디버깅, 로깅, 상태 추적에 사용
 - 데이터 흐름에 영향 ❌

 언제 사용하는가
 - 네트워크 요청 로그
 - 값 흐름 디버깅
 - subscribe 전에 상태 확인

 주의
 - 로직을 넣으면 안 됨
 - 값 변환 ❌
 - 상태 변경 ❌ (원칙적으로)

 한 줄 요약
 - ❝ 건드리지 말고 보기만 한다 ❞
 */
func `do`() {
    runner(description: "do") {
        let disposeBag = DisposeBag()

        Observable.of(1, 2, 3)
            .do(onNext: { value in
                print("👉 중간 확인:", value)
            })
            .do(onSubscribe: { print("요청 시작") })
            .do(onError: { print("에러 발생:", $0) })
            .do(onCompleted: { print("완료") })
            .map { $0 * 2 }
            .subscribe(onNext: { print("✅ 최종:", $0) })
            .disposed(by: disposeBag)
    }
}

/*
 enum Result<Success, Failure: Error> {
     case success(Success)
     case failure(Failure)
 }

 Rx에서 Result쓰는이유
 - onNext
 - onError
 이게 있는데 왜 굳이 Result를쓰는가?
 => 스트림을 “죽이지 않고” 성공/실패를 값으로 흘리고 싶을 때
 
 ex) Result를 안 쓰면 생기는 문제 (Rx 기본 방식)
 - Result를 안 쓰면 생기는 문제 (Rx 기본 방식)
 - onError 발생 → 스트림 종료
 - 이후 재시도 / UI 업데이트 불가
 func fetchUser() -> Observable<User> {
     Observable.create { observer in
         observer.onError(NetworkError.fail)
         return Disposables.create()
     }
 }
 
 ex) Result를 쓰는 기본 패턴 (스트림 유지)
 장점
 - 스트림 안 죽음
 - 성공/실패를 값으로 처리
 - UI에서 분기 가능
 func fetchUser() -> Observable<Result<User, Error>> {
     Observable.create { observer in
         observer.onNext(.failure(NetworkError.fail))
         return Disposables.create()
     }
 }
 */


/*
 Result
 ─────────────────────────────────────
 역할
 - 성공 / 실패를 "에러 이벤트"가 아닌 "값"으로 표현

 Rx에서 Result를 쓰는 이유
 - onError를 쓰면 스트림이 종료됨
 - UI에서는 "실패도 하나의 상태"로 다뤄야 함
 - 스트림을 죽이지 않고 상태 분기 처리 가능

 핵심 포인트
 - 실패해도 onNext로 흘러감
 - subscribe가 계속 살아 있음
 - UI / 상태 머신 / MVVM Output에 적합

 한 줄 요약
 - ❝ 에러를 터뜨리지 말고 상태로 흘려보낸다 ❞
 */

enum NetworkError: Error {
    case fail
}

struct User {
    let name: String
}

func result_operator() {
    runner(description: "Result as Value") {
        let disposeBag = DisposeBag()

        // 성공 / 실패를 값으로 방출하는 Observable
        let fetchUser = Observable<Result<User, Error>>.create { observer in
            observer.onNext(.success(User(name: "동현")))
            observer.onNext(.failure(NetworkError.fail))
            observer.onNext(.success(User(name: "RxSwift")))
            return Disposables.create()
        }

        fetchUser
            .subscribe(onNext: { result -> () in
                switch result {
                case .success(let user):
                    print("✅ 성공:", user.name)
                case .failure(let error):
                    print("❌ 실패:", error)
                }
            })
            .disposed(by: disposeBag)
    }
}

/*
 compactMap
 ─────────────────────────────────────
 역할
 - 값을 변환하면서 nil은 자동으로 제거

 특징
 - map + filter(nil 제거)의 조합
 - Optional을 반환해야 함
 - nil이 나오면 해당 이벤트는 버려짐

 언제 사용하는가
 - String → Int 변환
 - Optional 값 안전하게 언래핑
 - 실패한 변환 무시

 한 줄 요약
 - ❝ 변환하다가 실패한 건 조용히 버린다 ❞
 */
func compactMap() {
    runner(description: "compactMap") {
        let disposeBag = DisposeBag()

        Observable.of("1", "2", "A", "3", "B")
            .compactMap { value -> Int? in
                Int(value)   // 변환 실패 시 nil
            }
            .subscribe(onNext: { print($0) })
            .disposed(by: disposeBag)

        /*
         출력
         1
         2
         3
         */
    }
}
