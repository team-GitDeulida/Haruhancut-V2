//
//  1. Chaining.swift
//  RxLabDemo
//
//  Created by 김동현 on 2/3/26.
//

import RxSwift
import Foundation

func chaining_example_1() {
    runner(description: "Tap -> Text -> Filter -> Map -> Print") {
        let disposeBag = DisposeBag()

        let tap = PublishSubject<Void>()
        let text = PublishSubject<String>()

        tap
            // tap
            // -> 최신 text
            .withLatestFrom(text)

            // String
            // -> 공백 제거된 String
            .map { value in
                value.trimmingCharacters(in: .whitespaces)
            }

            // String
            // -> 비어있지 않은 것만 통과
            .filter { value in
                !value.isEmpty
            }

            // String
            // -> 메시지 가공
            .map { value in
                "입력값: \(value)"
            }

            // 최종 소비
            .subscribe(onNext: { message in
                print(message)
            })
            .disposed(by: disposeBag)

        // 실행
        text.onNext("   ")
        tap.onNext(())
        text.onNext("RxSwift")
        tap.onNext(())
    }
}

func chaining_example_2() {
    runner(description: "Number Stream Pipeline") {
        let disposeBag = DisposeBag()

        Observable.of(1, 2, 3, 4, 5)
            // Int
            // -> 짝수만
            .filter { number in
                number.isMultiple(of: 2)
            }

            // Int
            // -> 중간 확인
            .do(onNext: { number in
                print("중간 통과:", number)
            })

            // Int
            // -> String
            .map { number in
                "짝수 변환: \(number)"
            }

            .subscribe(onNext: { result in
                print("최종:", result)
            })
            .disposed(by: disposeBag)
    }
}

func chaining_example_3() {
    runner(description: "Search Pipeline") {
        let disposeBag = DisposeBag()
        let searchText = PublishSubject<String>()

        searchText
            // String 입력
            // -> 잠깐 기다림
            .debounce(.milliseconds(300), scheduler: MainScheduler.instance)

            // String
            // -> 이전과 다른 값만
            .distinctUntilChanged()

            // String
            // -> 빈 문자열 제거
            .filter { text in
                !text.isEmpty
            }

            // String
            // -> 출력
            .subscribe(onNext: { text in
                print("검색:", text)
            })
            .disposed(by: disposeBag)

        // 실행
        searchText.onNext("R")
        searchText.onNext("Rx")
        searchText.onNext("Rx")
        searchText.onNext("RxS")

        RunLoop.main.run(until: Date(timeIntervalSinceNow: 1))
    }
}

func chaining_example_4() {
    runner(description: "Result Pipeline") {
        let disposeBag = DisposeBag()

        Observable.of("ok", "fail", "ok")
            // String
            // -> Result<String, Error>
            .map { value -> Result<String, Error> in
                if value == "fail" {
                    return .failure(NetworkError.fail)
                } else {
                    return .success(value)
                }
            }

            // Result
            // -> 처리
            .subscribe(onNext: { result in
                switch result {
                case .success(let value):
                    print("성공:", value)
                case .failure(let error):
                    print("실패:", error)
                }
            })
            .disposed(by: disposeBag)
    }
}

func chaining_type_change_1() {
    runner(description: "String -> Int -> Bool -> String") {
        let disposeBag = DisposeBag()

        Observable.of("1", "2", "x", "3")
            // String
            // -> Int?
            .map { text -> Int? in
                Int(text)
            }

            // Int?
            // -> Int (nil 제거)
            .compactMap { number in
                number
            }

            // Int
            // -> Bool
            .map { number -> Bool in
                number >= 2
            }

            // Bool
            // -> String
            .map { isValid -> String in
                isValid ? "통과" : "탈락"
            }

            .subscribe(onNext: { result in
                print(result)
            })
            .disposed(by: disposeBag)
    }
}

func chaining_type_change_2() {
    runner(description: "Int -> Observable<String> -> String") {
        let disposeBag = DisposeBag()

        Observable.of(1, 2, 3)
            // Int
            // -> Observable<String>
            .flatMap { number -> Observable<String> in
                Observable.just("값은 \(number)")
            }

            // String
            .subscribe(onNext: { text in
                print(text)
            })
            .disposed(by: disposeBag)
    }
}

func chaining_type_change_3() {
    runner(description: "Void -> String -> Int") {
        let disposeBag = DisposeBag()

        let tap = PublishSubject<Void>()
        let text = PublishSubject<String>()

        tap
            // Void (버튼 탭)
            // -> 최신 String
            .withLatestFrom(text)

            // String
            // -> 글자 수(Int)
            .map { value -> Int in
                value.count
            }

            .subscribe(onNext: { length in
                print("글자 수:", length)
            })
            .disposed(by: disposeBag)

        // 실행
        text.onNext("RxSwift")
        tap.onNext(())
    }
}

func chaining_type_change_4() {
    runner(description: "String -> Result -> String") {
        let disposeBag = DisposeBag()

        Observable.of("10", "x", "3")
            // String
            // -> Result<Int, Error>
            .map { text -> Result<Int, Error> in
                if let number = Int(text) {
                    return .success(number)
                } else {
                    return .failure(NetworkError.fail)
                }
            }

            // Result
            // -> String
            .map { result -> String in
                switch result {
                case .success(let number):
                    return "성공: \(number)"
                case .failure:
                    return "실패"
                }
            }

            .subscribe(onNext: { message in
                print(message)
            })
            .disposed(by: disposeBag)
    }
}
