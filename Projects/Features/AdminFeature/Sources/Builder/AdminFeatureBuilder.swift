import AdminFeatureInterface
import Core
import Domain

/// AdminFeature 화면 생성 계약입니다.
public protocol AdminFeatureBuildable {
    func makeAdmin() -> AdminPresentable
}

/// 관리자 화면의 의존성을 조립합니다.
public final class AdminFeatureBuilder {
    public init() {}

    /// Demo와 테스트에서 명시적인 Usecase를 전달해 화면을 만듭니다.
    public func makeAdmin(
        adminUsecase:
            AdminUsecaseProtocol
    ) -> AdminPresentable {
        let viewModel =
            AdminViewModel(
                adminUsecase:
                    adminUsecase
            )
        let viewController =
            AdminViewController(
                viewModel: viewModel
            )
        return (
            viewController,
            viewModel
        )
    }
}

extension AdminFeatureBuilder:
    AdminFeatureBuildable
{
    public func makeAdmin()
        -> AdminPresentable
    {
        @Dependency
        var adminUsecase:
            AdminUsecaseProtocol

        return makeAdmin(
            adminUsecase:
                adminUsecase
        )
    }
}
