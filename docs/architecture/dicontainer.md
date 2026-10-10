---
title: iOS DI Container 패턴
description: Core의 DIContainer와 @Dependency, AppDelegate의 등록 순서, Feature Builder의 주입 방식, Demo·테스트에서 의존성을 바꾸는 방법을 설명해요.
---

# Haruhancut iOS DI Container 패턴

> 하루한컷은 `Core` 모듈의 `DIContainer.shared`에 구현체를 **타입 키로 등록**하고, `@Dependency` 프로퍼티 래퍼로 꺼내 쓰는 서비스 로케이터 방식을 사용해요. 앱 시작 시 `AppDelegate.registerDependencies()`가 한 번 등록하고, Feature Builder가 꺼내서 생성자로 넘겨요.

## DIContainer 구현

`Projects/Core/Sources/DIContainer/DIContainer.swift`

```swift
public final class DIContainer {
    public static let shared = DIContainer()
    private init() {}

    private var dependencies: [String: Any] = [:]

    public func register<T>(_ type: T.Type, dependency: T) {
        let key = String(describing: type)
        dependencies[key] = dependency
    }

    public func resolve<T>(_ type: T.Type) -> T {
        let key = String(describing: type)
        guard let dependency = dependencies[key] as? T else {
            preconditionFailure("⚠️ \(key)는 register되지 않았습니다. resolve호출 전에 register 해주세요.")
        }
        return dependency
    }
}

@propertyWrapper
public class Dependency<T> {
    public var wrappedValue: T
    public init() {
        self.wrappedValue = DIContainer.shared.resolve(T.self)
    }
}
```

| 특징 | 동작 | 사용할 때 주의할 점 |
| --- | --- | --- |
| 키 | `String(describing: type)`. 등록할 때 넘긴 타입 이름이에요. | 구현 타입이 아니라 `AuthUsecaseProtocol.self`처럼 **프로토콜 타입**으로 등록하고 꺼내요. |
| 생명 주기 | 인스턴스를 그대로 저장해요. 팩토리나 스코프가 없어요. | 등록한 객체는 앱 전체에서 공유하는 싱글턴이에요. 화면마다 새로 만들어야 하는 객체(ViewModel, Reactor)는 등록하지 않아요. |
| 재등록 | 같은 키로 다시 등록하면 덮어써요. | Demo 앱이 이 동작으로 가짜 구현을 넣어요. 앱 코드에서는 한 번만 등록해요. |
| 미등록 resolve | `preconditionFailure`로 앱이 종료돼요. | 새 Usecase를 추가하면 앱과 해당 Feature Demo 모두에 등록해요. |
| `@Dependency` 해석 시점 | 프로퍼티를 가진 객체가 초기화될 때 즉시 resolve해요. 지연 해석이 아니에요. | 등록 전에 `@Dependency`를 가진 객체를 만들지 않아요. |
| 스레드 안전성 | 잠금이 없어요. | 등록은 `didFinishLaunching`의 메인 스레드에서 끝내요. |

## 등록: `AppDelegate.registerDependencies()`

`Projects/App/Sources/AppDelegate/AppDelegate+Dependency.swift`에서 모든 구현체를 만들어요. `AppDelegate.didFinishLaunching`이 `FirebaseApp.configure()`보다 먼저 호출해요.

| 순서 | 만드는 객체 | 등록 여부 |
| --- | --- | --- |
| 1. session | `UserDefaultsStorage`, `UserSession(storageKey: "session.user")`, `GroupSession(storageKey: "session.group")`, `FCMTokenStore` | `UserSession`, `GroupSession`, `FCMTokenStore` 등록 |
| 2. manager | `KakaoLoginManager`, `AppleLoginManager`, `FirebaseAuthManager`, `FirebaseStorageManager` | 등록하지 않고 Repository 생성자로 넘겨요. |
| 3. repository | `AuthRepositoryImpl`, `GroupRepositoryImpl`, `AdminRepositoryImpl`, `WidgetRepositoryImpl`(WidgetSupport) | 등록하지 않고 Usecase 생성자로 넘겨요. |
| 4. usecase | `AuthUsecaseImpl`, `GroupUsecaseImpl`, `AdminUsecaseImpl`, `WidgetUsecaseImpl` | `AuthUsecaseProtocol`, `GroupUsecaseProtocol`, `AdminUsecaseProtocol`, `WidgetUsecaseProtocol`로 등록 |

```swift
// usecase
let authUseCase = AuthUsecaseImpl(authRepository: authRepository,
                                  userSession: userSession,
                                  groupSession: groupSession,
                                  fcmTokenStore: fcmTokenStore)
DIContainer.shared.register(AuthUsecaseProtocol.self, dependency: authUseCase)
```

- Manager와 Repository는 컨테이너에 넣지 않고 생성자 주입으로만 연결해요. Feature가 Repository를 직접 꺼낼 수 없게 하려는 구조예요.
- 새 의존성은 같은 파일에서 `// session`, `// repository`, `// usecase` 구역 순서를 지켜 추가해요.
- 등록 키는 위 7개(`UserSession`, `GroupSession`, `FCMTokenStore`, `AuthUsecaseProtocol`, `GroupUsecaseProtocol`, `AdminUsecaseProtocol`, `WidgetUsecaseProtocol`)예요. 늘어나면 이 표를 갱신해요.

## 사용: 어디서 resolve하나요

### Feature Builder에서 꺼내 생성자로 넘겨요 (기본)

Builder의 `make...()` 메서드 안에서 지역 `@Dependency`로 꺼내고, Reactor(기존 화면은 ViewModel)와 ViewController는 생성자로 받아요. 호출할 때마다 새 화면 객체를 만들어요.

```swift
// HomeFeatureV2/Sources/Home/HomeFeatureBuilder.swift (요약, ReactorKit 화면)
public func makeHome(mode: HomePresentationMode, routeTrigger: HomeRouteTrigger? = nil) -> HomePresentable {
    @Dependency var groupUsecase: GroupUsecaseProtocol
    @Dependency var widgetUsecase: WidgetUsecaseProtocol

    let loadGroup = HomeGroupLoaderFactory.make(mode: mode, groupUsecase: groupUsecase)
    let feedReactor = FeedReactor(
        loadGroup: loadGroup,
        groupUsecase: mode.isReadOnly ? nil : groupUsecase,
        widgetUsecase: mode.isReadOnly ? nil : widgetUsecase
    )
    let calendarReactor = CalendarReactor(loadGroup: loadGroup)
    let vc = HomeViewController(feedReactor: feedReactor, calendarReactor: calendarReactor, mode: mode)
    vc.routeTrigger = routeTrigger
    return vc
}
```

기존 Input/Output 화면의 Builder는 ViewModel을 만들어 `(vc, vm)`을 반환해요.

```swift
// AuthFeature/Sources/Factory/AuthFeatureBuilder.swift
public func makeSignIn() -> SignInPresentable {
    @Dependency var authUsecase: AuthUsecaseProtocol
    let vm = SignInViewModel(authUsecase: authUsecase)
    let vc = SignInViewController(signInViewModel: vm)
    return (vc, vm)
}
```

테스트나 Demo에서 컨테이너 없이 주입해야 하면 `AdminFeatureBuilder`처럼 의존성을 받는 오버로드를 함께 둬요.

```swift
// AdminFeature/Sources/Builder/AdminFeatureBuilder.swift
public func makeAdmin(adminUsecase: AdminUsecaseProtocol) -> AdminPresentable {
    let viewModel = AdminViewModel(adminUsecase: adminUsecase)
    let viewController = AdminViewController(viewModel: viewModel)
    return (viewController, viewModel)
}

public func makeAdmin() -> AdminPresentable {
    @Dependency var adminUsecase: AdminUsecaseProtocol
    return makeAdmin(adminUsecase: adminUsecase)
}
```

### 프로퍼티 주입을 쓰는 곳

| 위치 | 예시 |
| --- | --- |
| Reactor·ViewModel | `FeedReactor`의 `@Dependency private var userSession`, `groupSession`, `authUsecase`, `ImageUploadViewModel`의 `groupUsecase`, `SettingViewModel` |
| Coordinator | `AppCoordinator`의 `userSession`·`groupSession`, `HomeV2Coordinator`의 `userSession` |
| App | `AppDelegate+FCM.swift`의 `DIContainer.shared.resolve(AuthUsecaseProtocol.self)`, `SceneDelegate+UITests.swift` |

프로퍼티 주입은 테스트에서 값을 바꾸기 어렵고 생성 시점에 등록 여부에 의존해요. 새 Reactor는 Builder에서 꺼내 **생성자로 받는 방식**을 사용해요. Reactor 테스트에서 Stub을 넣으려면 생성자 주입이 필요해요. `FeedReactor`처럼 생성자로 받은 값(`loadGroup`, `groupUsecase`)과 `@Dependency`(`userSession`, `groupSession`, `authUsecase`)가 섞인 코드는 수정할 때 생성자 주입으로 옮기는 것을 검토해요.

## 교체: Demo와 테스트

### Demo 앱은 같은 컨테이너에 가짜 구현을 등록해요

```swift
// HomeFeatureV2/Demo/Sources/DemoDependencies.swift (요약)
DIContainer.shared.register(UserSession.self, dependency: userSession)   // DemoMemoryStorage 사용
DIContainer.shared.register(GroupSession.self, dependency: groupSession)
DIContainer.shared.register(AuthUsecaseProtocol.self, dependency: DemoAuthUsecase())
DIContainer.shared.register(GroupUsecaseProtocol.self, dependency: DemoGroupUsecase())
DIContainer.shared.register(WidgetUsecaseProtocol.self, dependency: DemoWidgetUsecase()) // 아무것도 하지 않음
```

- Demo의 `AppDelegate`가 화면을 만들기 전에 등록 함수를 호출해요.
- Demo에서 쓰는 Builder가 resolve하는 타입은 모두 등록해요. HomeFeatureV2 Demo는 `AdminUsecaseProtocol`을 등록하지 않으므로 `.adminPreview` 모드를 실행하지 않아요.
- AdminFeatureDemo는 컨테이너 대신 `makeAdmin(adminUsecase: DemoAdminUsecase())`로 직접 주입해요.

### 단위 테스트는 컨테이너를 쓰지 않아요

테스트 대상은 생성자로 Stub을 넣어 직접 만들어요. `DIContainer`를 쓰는 테스트는 `HomeFeatureV2/Tests/Sources/FeedReactorWidgetTests.swift` 하나예요. `FeedReactor`가 세션과 `AuthUsecaseProtocol`을 `@Dependency`로 생성 시점에 꺼내서, 테스트마다 메모리 세션과 Stub을 등록해요.

```swift
// App/Tests/Sources/FCMTokenSyncTests.swift (요약)
let storage = FCMTokenSyncTestStorage()
let userSession = UserSession(storage: storage, storageKey: "fcm-test-user")
let groupSession = GroupSession(storage: storage, storageKey: "fcm-test-group")

let sut = AuthUsecaseImpl(
    authRepository: repository,        // FCMAuthRepositoryStub
    userSession: userSession,
    groupSession: groupSession,
    fcmTokenStore: FCMTokenStore()
)
```

- Session은 공통 저장소 계약 `StorageProtocol`을 따르는 메모리 저장소(`FakeUserDefaultsStorage`, `FCMTokenSyncTestStorage`)로 만들어요. 임시 폴더의 `FileStorage`도 넣을 수 있어요.
- `@Dependency` 프로퍼티를 가진 타입을 테스트하려면 먼저 `DIContainer.shared`에 등록해야 하므로, 테스트할 타입은 생성자 주입으로 만들어요.

## 새 의존성을 추가하는 순서

1. Domain에 프로토콜(`<X>UsecaseProtocol`, `<X>RepositoryProtocol`)을 정의해요.
2. Data에 Repository 구현을, Domain에 Usecase 구현을 추가해요.
3. `registerDependencies()`에서 Manager → Repository → Usecase 순서로 만들고 Usecase 프로토콜로 등록해요.
4. Feature Builder에서 `@Dependency`로 꺼내 Reactor 생성자로 넘겨요.
5. 해당 Feature Demo의 등록 함수에 Demo 구현을 추가해요.
6. 이 문서의 등록 키 표를 갱신해요.

## 관련 문서

- [전체 아키텍처 개요](architecture.md): 모듈과 의존성 방향
- [View·Reactor·ViewModel 계약](view-viewmodel-protocols.md): Builder가 반환하는 Presentable과 RouteTrigger
- [테스트](../development/testing.md): Stub 주입 테스트 실행 방법
