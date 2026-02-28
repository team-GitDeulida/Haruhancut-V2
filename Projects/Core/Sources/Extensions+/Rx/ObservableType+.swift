//
//  ObservableType+.swift
//  Core
//
//  Created by 김동현 on 2/4/26.
//

import RxSwift

/*
 [before]
 public func updateUser(user: Domain.User) -> Observable<Result<Domain.User, LoginError>> {
     let path = "users/\(user.uid)"
     let dto = user.toDTO()
     
     return updateValue(path: path, value: dto)
         .map { .success(user) }
         .catch { _ in .just(.failure(.updateUserError)) }
 }
 
 [after]
 public func updateUser(user: Domain.User) -> Observable<Result<Domain.User, LoginError>> {
     let path = "users/\(user.uid)"
     let dto = user.toDTO()
     
     return updateValue(path: path, value: dto)
         .asResult(
             success: user,
             failure: .updateUserError
         )
 */
//public extension ObservableType {
//    func asResult<T, E: Error>(success value: T, failure error: E) -> Observable<Result<T, E>> {
//        self
//            .map { _ in .success(value) }
//            .catch { _ in .just(.failure(error)) }
//    }
//    
//    func mapTo<R>(_ value: R) -> Observable<R> {
//        map { _ in value }
//    }
//    
//    func asResult<E: Error>(
//        failure error: E
//    ) -> Observable<Result<Element, E>> {
//        self
//            .map { .success($0) }
//            .catch { _ in .just(.failure(error)) }
//    }
//}

public extension ObservableType {
    /// Observable이 방출하는 각 `Result` 값을
    /// 성공 값은 `Void`로 변환하고, 실패는 그대로 유지한 형태로 변환합니다.
    ///
    /// 이 메서드는 `Observable<Result<Success, Failure>>` 형태의 스트림에서
    /// 성공 값의 실제 데이터는 필요 없고,
    /// 성공/실패 결과만 필요한 경우에 사용합니다.
    ///
    /// 이 연산자는 Observable의 `error` 채널에는 영향을 주지 않으며,
    /// 방출되는 `Result` 값만 변환합니다.
    ///
    /// 내부적으로 `Result.mapToVoid()`를 사용하여
    /// 각 방출 값을 안전하게 변환합니다.
    ///
    /// ### 사용 예시
    /// ```swift
    /// groupUsecase.joinGroup(inviteCode)
    ///     .mapResultToVoid()
    ///     // Observable<Result<Void, GroupError>>
    /// ```
    ///
    /// - 반환값: `Result<Void, Failure>`를 방출하는 Observable
//    func mapToVoid<Success, Failure>() -> Observable<Result<Void, Failure>>
//    where Element == Result<Success, Failure> {
//        self.map { $0.mapToVoid() }
//    }
}

public extension ObservableType {
    func mapTo<T>(_ value: T) -> Observable<T> {
        map { _ in value }
    }
    
    func mapToVoid() -> Observable<Void> {
        map { _ in () }
    }
}

public extension PrimitiveSequence where Trait == SingleTrait {
    func mapTo<T>(_ value: T) -> Single<T> {
        map { _ in value }
    }
    
    func mapToVoid() -> Single<Void> {
        map { _ in () }
    }
}
