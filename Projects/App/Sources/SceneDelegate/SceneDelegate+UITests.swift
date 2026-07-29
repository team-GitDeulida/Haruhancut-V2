//
//  SceneDelegate+UITests.swift
//  App
//
//  Created by 김동현 on 2/24/26.
//

import UIKit
import Core
import Domain
import RxSwift

#if DEBUG
extension SceneDelegate {
    @discardableResult
    func configureForUITests(
        completion: @escaping () -> Void
    ) -> Bool {
        guard
            ProcessInfo.processInfo.arguments.contains("-UITest")
        else {
            return false
        }

        let environment = ProcessInfo.processInfo.environment
        guard let uid = environment["TEST_USER_UID"] else {
            Logger.e("UI 테스트 사용자 UID가 설정되지 않음")
            assertionFailure("TEST_USER_UID가 필요합니다.")
            return true
        }
        
        let authUsecase = DIContainer.shared.resolve(AuthUsecaseProtocol.self)
        let groupUsecase = DIContainer.shared.resolve(GroupUsecaseProtocol.self)
        let userSession = DIContainer.shared.resolve(UserSession.self)
        let groupSession = DIContainer.shared.resolve(GroupSession.self)
        
        // 1. 테스트 시작 시 세션 초기화
        userSession.clear()
        groupSession.clear()
        Logger.d("테스트 시작: 기존 세션 초기화")
        
        // 2. 테스트 유저 주입 후 기존 게시글 정리
        authUsecase
            .bootstrapUserSession(uid: uid)
            .flatMap { user in
                groupUsecase
                    .resetPostsForUITests()
                    .map { removedPostCount in
                        (
                            user: user,
                            removedPostCount: removedPostCount
                        )
                    }
            }
            .subscribe(
                onSuccess: { result in
                    Logger.d(
                        "UI 테스트 준비 완료: \(result.user.uid), 게시글 \(result.removedPostCount)개 정리"
                    )
                    DispatchQueue.main.async(execute: completion)
                },
                onFailure: { error in
                    Logger.e("UI 테스트 초기 데이터 정리 실패: \(error)")
                    assertionFailure(
                        "UI 테스트 초기 데이터 정리에 실패했습니다: \(error)"
                    )
                }
            )
            .disposed(by: disposeBag)

        return true
    }
}
#endif
