import Core
import Domain
import MemberFeatureV2Interface

/// MemberFeatureV2 화면 생성 계약입니다.
public protocol MemberFeatureBuildable {
    /// Member 목록 화면을 만듭니다.
    func makeMember() -> MemberPresentable
}

/// MemberFeatureV2의 의존성을 조립합니다.
public final class MemberFeatureBuilder {
    public init() {}
}

extension MemberFeatureBuilder:
    MemberFeatureBuildable
{
    public func makeMember()
        -> MemberPresentable
    {
        @Dependency
        var userSession: UserSession
        @Dependency
        var groupSession: GroupSession
        @Dependency
        var authUsecase:
            AuthUsecaseProtocol

        let viewModel = MemberViewModel(
            userSession: userSession,
            groupSession: groupSession,
            authUsecase: authUsecase
        )
        let viewController =
            MemberViewController(
                viewModel: viewModel
            )
        return (
            viewController,
            viewModel
        )
    }
}
