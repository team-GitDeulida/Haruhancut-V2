import Core
import Domain
import HomeFeatureV2Interface
import RxSwift

/// Home과 하위 상세 화면이 표시 모드에 맞게 그룹을 조회하고 구독하는 방법입니다.
struct HomeGroupLoader {
    /// 그룹을 조회하고 조회 단계를 보냅니다. `force`가 `true`면 최근에 받은 그룹이 있어도 서버에 묻습니다.
    let fetch: (_ force: Bool) -> Observable<FetchResult<HCGroup>>

    /// 저장된 그룹이 바뀔 때마다 보냅니다. 저장하지 않는 그룹(관리자 미리보기)은 보내지 않습니다.
    let changes: () -> Observable<HCGroup>
}

extension HomeGroupLoader {
    /// 표시 모드에 맞는 로더를 만듭니다.
    ///
    /// - `.currentGroup`: 내 그룹을 Fetcher로 조회하고, 저장된 그룹의 변화를 구독합니다.
    /// - `.adminPreview`: 다른 그룹을 한 번 조회합니다. 저장하지 않으므로 변화는 없습니다.
    static func make(
        mode:
            HomePresentationMode,
        groupUsecase:
            GroupUsecaseProtocol
    ) -> HomeGroupLoader {
        switch mode {
        case .currentGroup:
            return HomeGroupLoader(
                fetch: { force in
                    force
                        ? groupUsecase.refreshGroupResult()
                        : groupUsecase.fetchGroupResult()
                },
                changes: {
                    groupUsecase.observeGroup()
                }
            )
        case let .adminPreview(
            groupID
        ):
            @Dependency
            var adminUsecase:
                AdminUsecaseProtocol
            return HomeGroupLoader(
                fetch: { _ in
                    adminUsecase
                        .fetchGroup(
                            groupId: groupID
                        )
                        .asObservable()
                        .map { FetchResult(status: .success, value: $0) }
                        .startWith(FetchResult(status: .loading, value: nil))
                        .catch { error in
                            .just(FetchResult(status: .failure(error), value: nil))
                        }
                },
                changes: {
                    .empty()
                }
            )
        }
    }

    /// 조회한 그룹 값만 보냅니다. 실패하면 조용히 끝납니다.
    ///
    /// 상세 화면처럼 조회 단계가 필요 없는 곳에서 씁니다.
    func values() -> Observable<HCGroup> {
        fetch(false)
            .fetchedValues()
            .catch { _ in .empty() }
    }
}
