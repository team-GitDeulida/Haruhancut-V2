import Core
import Domain
import ProfileFeatureV2Interface

public protocol ProfileFeatureBuildable {
    func makeProfile() -> ProfilePresentable
    func makeSetting() -> SettingPresentable
    func makeNicknameEdit()
        -> NicknameEditPresentable
    func makeBirthdayEdit()
        -> BirthdayEditPresentable
}

public final class ProfileFeatureBuilder {
    public init() {}
}

extension ProfileFeatureBuilder:
    ProfileFeatureBuildable
{
    public func makeProfile()
        -> ProfilePresentable
    {
        @Dependency
        var userSession: UserSession
        @Dependency
        var authUsecase:
            AuthUsecaseProtocol
        @Dependency
        var groupUsecase:
            GroupUsecaseProtocol

        let viewModel = ProfileViewModel(
            userSession: userSession,
            authUsecase: authUsecase,
            groupUsecase: groupUsecase
        )
        let viewController =
            ProfileViewController(
                viewModel: viewModel
            )
        return (
            viewController,
            viewModel
        )
    }

    public func makeSetting()
        -> SettingPresentable
    {
        @Dependency
        var authUsecase:
            AuthUsecaseProtocol

        let viewModel = SettingViewModel(
            authUsecase: authUsecase
        )
        let viewController =
            SettingViewController(
                viewModel: viewModel
            )
        return (
            viewController,
            viewModel
        )
    }

    public func makeNicknameEdit()
        -> NicknameEditPresentable
    {
        @Dependency
        var authUsecase:
            AuthUsecaseProtocol

        let viewModel =
            NicknameEditViewModel(
                authUsecase: authUsecase
            )
        let viewController =
            NicknameEditViewController(
                viewModel: viewModel
            )
        return (
            viewController,
            viewModel
        )
    }

    public func makeBirthdayEdit()
        -> BirthdayEditPresentable
    {
        @Dependency
        var userSession: UserSession
        @Dependency
        var authUsecase:
            AuthUsecaseProtocol

        let viewModel =
            BirthdayEditViewModel(
                userSession: userSession,
                authUsecase: authUsecase
            )
        let viewController =
            BirthdayEditViewController(
                viewModel: viewModel
            )
        return (
            viewController,
            viewModel
        )
    }
}
