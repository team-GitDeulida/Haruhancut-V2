//
//  Result.swift
//  Core
//
//  Created by 김동현 on 2/3/26.
//

import Foundation

/*
 [기존 방식]
 .map { result in
     switch result {
     case .success(let group):
         //
         return .success(())
     case .failure(let error):
         return .failure(error)
     }
 }
 
 [단순화]
 .mapToVoid()
 */
public extension Result {
    /// 성공 값을 `Void`로 변환하고, 실패는 그대로 유지한 새로운 `Result`를 반환합니다.
    ///
    /// 이 메서드는 성공 시 전달되는 실제 값이 더 이상 필요 없고,
    /// 성공/실패 여부만 의미가 있을 때 사용합니다.
    ///
    /// - `.success`인 경우:
    ///   성공 값을 버리고 `.success(())`를 반환합니다.
    ///
    /// - `.failure`인 경우:
    ///   실패 값(`Failure`)을 변경하지 않고 그대로 반환합니다.
    ///
    /// 이 변환은 성공 값에만 적용되며,
    /// 실패 로직에는 전혀 영향을 주지 않습니다.
    ///
    /// ### 사용 예시
    /// ```swift
    /// let result: Result<User, LoginError> = .success(user)
    /// let voidResult = result.mapToVoid()
    /// // 결과: .success(())
    /// ```
    ///
    /// ```swift
    /// let result: Result<User, LoginError> = .failure(.network)
    /// let voidResult = result.mapToVoid()
    /// // 결과: .failure(.network)
    /// ```
    ///
    /// - 반환값: 성공 값이 `Void`로 변환된 `Result<Void, Failure>`
    func mapToVoid() -> Result<Void, Failure> {
        self.map { _ in () }
    }
}

/*
 
 [기존]
 // 코디네이터 이동(성공 이벤트만 흘리고 실패는 버린다)
 result
     .compactMap { result in
         if case .success = result { return () }
         return nil
     }
     .withUnretained(self)
     .bind(onNext: { vm, _ in
         vm.onGroupMakeOrJoinSuccess?()
     })
     .disposed(by: disposeBag)
 
 // 에러 알림
 result
     .compactMap { result in
         if case .failure(let error) = result { return error }
         return nil
     }
     .bind(to: errorRepay)
     .disposed(by: disposeBag)
 
 [변경]
 result
     .compactMap(\.successVoid)
     .withUnretained(self)
     .bind(onNext: { vm, _ in vm.onGroupMakeOrJoinSuccess?() })

 result
     .compactMap(\.failureError)
     .bind(to: errorRelay)

 */
public extension Result {
    var successVoid: Void? {
        if case .success = self { return () }
        return nil
    }
    
    var failureError: Failure? {
        if case .failure(let error) = self { return error }
        return nil
    }
}
