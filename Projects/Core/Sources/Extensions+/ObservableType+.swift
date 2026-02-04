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
public extension ObservableType {
    func asResult<T, E: Error>(success value: T, failure error: E) -> Observable<Result<T, E>> {
        self
            .map { _ in .success(value) }
            .catch { _ in .just(.failure(error)) }
    }
    
    func mapTo<R>(_ value: R) -> Observable<R> {
        map { _ in value }
    }
    
    func asResult<E: Error>(
        failure error: E
    ) -> Observable<Result<Element, E>> {
        self
            .map { .success($0) }
            .catch { _ in .just(.failure(error)) }
    }
}
