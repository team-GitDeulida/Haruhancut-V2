import Core
import Domain
import HomeFeatureV2Interface
import RxSwift

/// Home과 하위 상세 화면이 표시 모드에 맞는 그룹을 조회하도록 로더를 만듭니다.
enum HomeGroupLoaderFactory {
    static func make(
        mode:
            HomePresentationMode,
        groupUsecase:
            GroupUsecaseProtocol
    ) -> () -> Observable<HCGroup> {
        switch mode {
        case .currentGroup:
            return {
                groupUsecase
                    .loadAndFetchGroup()
            }
        case let .adminPreview(
            groupID
        ):
            @Dependency
            var adminUsecase:
                AdminUsecaseProtocol
            return {
                adminUsecase
                    .fetchGroup(
                        groupId: groupID
                    )
                    .asObservable()
            }
        }
    }
}
