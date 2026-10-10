# Haruhancut Swift 스타일 가이드

> Git이 추적하는 `Projects/**/*.swift` 385개(테스트 제외)를 분석해 정리한 스타일이에요. SwiftLint·SwiftFormat 설정과 빌드 스크립트는 없으므로 리뷰에서 확인해요. 코드에 두 가지 스타일이 함께 있어, 모든 코드가 따르는 규칙과 스타일별 규칙을 나눠 적었어요.

## 목차

- [두 가지 스타일](#두-가지-스타일)
- [모든 코드가 따르는 규칙](#모든-코드가-따르는-규칙)
- [파일 헤더와 파일 이름](#파일-헤더와-파일-이름)
- [import](#import)
- [줄 바꿈과 중괄호](#줄-바꿈과-중괄호)
- [네이밍](#네이밍)
- [접근 제어와 extension](#접근-제어와-extension)
- [UI 코드](#ui-코드)
- [MARK와 주석](#mark와-주석)
- [로깅과 디버그 코드](#로깅과-디버그-코드)

---

## 두 가지 스타일

| 구분 | 스타일 A: 기존 코드 | 스타일 B: 최근 코드 |
| --- | --- | --- |
| 적용 범위 | V1 Feature, AuthFeature, OnboardingFeature, ImageFeature, HomeFeatureV2 대부분, Core, Data, Domain, DSKit | AdminFeature, MemberFeatureV2, ProfileFeatureV2, Domain·Data의 `Admin*`, CollectionViewAdapter |
| 파일 헤더 | Xcode 기본 헤더 | 없음 (CollectionViewAdapter는 일부만 있음) |
| import | `UIKit` 먼저, 나머지는 정렬하지 않음 | 모두 알파벳순, 빈 줄 없음 |
| 줄 길이 | 한 줄에 길게 작성 | `:`·`=` 뒤에서 거의 항상 줄 바꿈 |
| 긴 선언의 여는 중괄호 | 같은 줄 (1TBS) | 줄을 바꾼 선언 뒤에는 `{`를 다음 줄에 둠 |
| 구역 표시 | `// MARK: -` | MARK가 거의 없고 `///` 문서 주석 사용 |
| View 설정 메서드 | `setupUI()`, `setupConstraints()` | `configureView()`, `configureLayout()` |

**기존 파일을 수정할 때는 그 파일의 스타일을 유지해요.** 한 파일 안에서 두 스타일을 섞지 않아요.

새 파일에 어떤 스타일을 쓸지는 팀 합의가 없어요. (확인 필요: 새 파일 기준 스타일. 최근 작성된 V2·Admin 모듈은 스타일 B를 사용해요.) 같은 모듈의 파일이 이미 있으면 그 모듈의 스타일을 따라요.

스타일 B의 줄 바꿈 예시예요.

```swift
// ProfileFeatureV2/Sources/Profile/ProfileViewController.swift
final class ProfileViewController:
    UIViewController,
    RefreshableViewController
{
    private let disposeBag =
        DisposeBag()
```

---

## 모든 코드가 따르는 규칙

| 규칙 | 예시 |
| --- | --- |
| 들여쓰기는 공백 4칸이에요. 탭은 쓰지 않아요. | |
| 콜론은 오른쪽에만 공백을 둬요. 삼항 연산자, `->`, 이항 연산자는 양옆에 공백을 둬요. | `let dict: [String: Int]`, `func load() -> Single<User>` |
| 한 줄 클로저는 중괄호 안쪽에 공백을 둬요. | `users.filter { $0.uid != myUID }` |
| 배열·딕셔너리는 축약형으로 써요. | `[String]`, `[String: URL]` (`Array<`는 0곳) |
| 상속하지 않는 클래스는 `final`이에요. | `final class FeedReactor` (예외: `AppDelegate`, `SceneDelegate`, 상속용 `BaseView`·`BasicCell`, `Dependency<T>`) |
| 타입을 추론할 수 있으면 생략해요. | `backgroundColor = .background` |
| 튜플 반환값에는 이름을 붙여요. | `Single<(groupId: String, inviteCode: String)>` |
| 조건이 여러 개인 `guard`는 조건마다 줄을 바꾸고 `else {`를 따로 둬요. | 아래 예시 |
| 레이아웃은 코드로 작성해요. SnapKit·Then은 의존성에 없어요. | `NSLayoutConstraint.activate([...])` |

```swift
guard
    let userId = userSession.userId,
    let groupId = userSession.groupId
else {
    return .error(DomainError.missingDomainSession)
}
```

---

## 파일 헤더와 파일 이름

### 파일 헤더 (스타일 A)

Xcode와 Tuist 템플릿이 만드는 헤더를 사용해요. Copyright 줄은 없어요.

```swift
//
//  FeedReactor.swift
//  HomeFeatureV2
//
//  Created by 김동현 on 4/21/26.
//

import UIKit
```

- 두 번째 줄은 파일 이름, 세 번째 줄은 **모듈 이름**이에요. (`Domain`, `HomeFeatureV2`)
- 날짜는 `m/d/yy` 형식이에요. Tuist 템플릿(`Tuist/Templates/**`)으로 만든 파일은 날짜가 비어 있을 수 있어요.
- 파일을 복사하거나 이름을 바꾸면 헤더의 파일 이름도 고쳐요. 현재 49개 파일은 헤더의 파일 이름이 실제와 달라요. (예: `KakaoLoginManager.swift`의 헤더가 `Empty.swift`)
- 스타일 B 파일은 헤더 없이 `import`로 시작해요.

### 파일 이름

| 종류 | 규칙 | 예시 |
| --- | --- | --- |
| 타입 파일 | 주요 타입 하나당 한 파일, 타입 이름과 같게 | `MemberViewModel.swift` |
| extension 파일 | `<타입>+<주제>.swift` 또는 `<타입>+.swift` | `AppDelegate+FCM.swift`, `SceneDelegate+UITests.swift`, `Date+.swift` |
| CollectionViewAdapter | 읽는 순서를 번호로 붙여요. | `5. Component.swift`, `18. CollectionViewAdapter.swift` |
| 사용하지 않는 이전 구현 | `Legacy` 접미사 | `UserSessionLegacy2.swift`, `CalendarCellLegacy.swift` |
| DTO | 파일은 `Dto`, 타입은 `DTO` | `UserDto.swift` 안의 `UserDTO` |

---

## import

| 스타일 | 규칙 |
| --- | --- |
| A | 한 블록에 나열하고 빈 줄로 나누지 않아요. 정렬 규칙은 없어요. |
| B | 시스템·외부·사내 모듈을 구분하지 않고 알파벳순으로 정렬해요. |

```swift
// 스타일 B: MemberFeatureV2/Sources/Member/MemberViewController.swift
import CollectionViewAdapter
import Core
import Domain
import DSKit
import Kingfisher
import RxRelay
import RxSwift
import UIKit
```

`ThirdPartyLibs`는 `@_exported import`를 하지 않으므로 파일에서 쓰는 외부 모듈(`RxSwift`, `RxCocoa`, `ReactorKit`, `Kingfisher` 등)을 직접 import해요.

---

## 줄 바꿈과 중괄호

### 함수 선언과 호출

- 스타일 B는 매개변수가 두 개 이상이면 매개변수마다 줄을 바꿔요. 라벨 뒤에서 한 번 더 줄을 바꾸기도 해요.
- 스타일 A는 한 줄에 쓰거나 Xcode 자동 정렬(첫 매개변수 위치에 맞춤)을 사용해요.

```swift
// 스타일 A: AppDelegate+Dependency.swift
let authUseCase = AuthUsecaseImpl(authRepository: authRepository,
                                  userSession: userSession,
                                  groupSession: groupSession,
                                  fcmTokenStore: fcmTokenStore)

// 스타일 B: AdminFeatureBuilder.swift
public func makeAdmin(
    adminUsecase:
        AdminUsecaseProtocol
) -> AdminPresentable {
```

### 클로저

- 클로저 인자가 하나면 trailing closure를 사용해요. (`.drive(with: self) { owner, state in ... }`)
- 클로저 인자가 둘 이상이면 라벨을 모두 쓰고 소괄호를 세로로 열고 닫아요.

```swift
UIView.animate(
    withDuration: 0.3,
    animations: { ... },
    completion: { _ in ... }
)
```

### 여는 중괄호

- 기본은 선언과 같은 줄에 여는 1TBS예요.
- 스타일 B는 여러 줄로 나눈 타입 선언·반환 타입 뒤의 `{`를 다음 줄에 둬요. 한 줄 선언은 1TBS를 유지해요.

### 불필요한 소괄호

`if`·`switch` 조건에 소괄호를 쓰지 않아요. (예외: `AppDelegate.swift`의 `if (AuthApi.isKakaoTalkLoginUrl(url))`)

---

## 네이밍

### 표기법

타입과 프로토콜은 UpperCamelCase, 변수·함수·enum case는 lowerCamelCase를 사용해요.

### 타입과 프로토콜

| 종류 | 규칙 | 예시 |
| --- | --- | --- |
| Usecase | `Usecase`(소문자 c)로 써요. 변수 이름은 `authUseCase`처럼 섞여 있어요. | `AuthUsecaseProtocol`, `AuthUsecaseImpl` |
| 구현체 | `Impl` 접미사 | `GroupUsecaseImpl`, `GroupRepositoryImpl` |
| Domain·Data 계약 | `Protocol` 접미사 | `AuthRepositoryProtocol`, `FirebaseAuthManagerProtocol` |
| 공통 역할 계약 | `Type` 접미사 | `ViewModelType`, `SessionType`, `StorageType` |
| Feature Builder | `<X>FeatureBuildable` + `<X>FeatureBuilder` | `MemberFeatureBuildable`, `MemberFeatureBuilder` |
| 화면 이동 계약 | `<X>RouteTrigger` | `SignInRouteTrigger`, `HomeRouteTrigger` |
| Builder 반환 타입 | `<X>Presentable`, `<X>ViewModelType` | `MemberPresentable` |
| 기능(capability) | `-able` | `Pressable`, `Touchable`, `LongPressable`, `ReuseIdentifiable` |
| Reactor | `<X>Reactor` + 중첩 `Action`·`Mutation`·`State` | `FeedReactor`, `CalendarReactor` |
| 화면 상태 (기존 Input/Output) | `<X>ScreenState` | `MemberScreenState`, `AdminScreenState` |
| Domain 이름 충돌 회피 | `HC` 접두사 | `HCGroup` |

### 이벤트와 메서드

| 종류 | 규칙 | 예시 |
| --- | --- | --- |
| Reactor Action | 사용자 의도나 생명 주기 | `viewDidLoad`, `refresh`, `deleteConfirmed(Post)` |
| Reactor Mutation | `set<상태>` | `setLoading(Bool)`, `setFeed(components:didTodayUpload:)` |
| ViewModel Input (기존) | `<대상>Tapped`, `<대상>Changed` | `cameraButtonTapped`, `memberCellTapped`, `birthdaySettingsChanged` |
| RouteTrigger 클로저 | `on<사건>` | `onSignInSuccess`, `onCellImageTapped` |
| `@objc` 핸들러 | `didTap<대상>`, `didRequest<동작>` | `didTapNext`, `didRequestRefresh` |
| 데이터 조회·변경 | 동작을 드러내는 동사. HTTP 메서드 접두사(`get`/`post`)는 쓰지 않아요. | `fetchUser`, `fetchGroup`, `createGroup`, `updateUser`, `uploadImage`, `deleteValue`, `observe*` |

### 약어

- `URL`, `DTO`, `UI`는 대문자로 써요. (`imageURL`, `profileImageURL`, `UserDTO`)
- `Id`는 Domain·Data 전반에서 `groupId`, `userId`, `postId`로 써요. CollectionViewAdapter와 ProfileFeatureV2는 `itemID`처럼 `ID`를 써요. 같은 모듈 안에서는 기존 표기를 따라요.

---

## 접근 제어와 extension

- `internal`은 적지 않아요.
- 프레임워크 모듈(Core, Domain, Data, DSKit, CollectionViewAdapter, Interface)은 다른 모듈이 쓰는 타입·멤버를 `public`으로 선언해요.
- V2 Feature는 Builder와 Builder 계약만 `public`으로 두고, ViewModel·ViewController는 internal이에요. V1 Feature는 ViewModel도 `public`이에요.
- 내부 구현은 `private`을 사용해요. `fileprivate`은 거의 쓰지 않아요.
- 읽기만 공개할 값은 `private(set)`을 사용해요. (`public private(set) weak var collectionView`)
- `private extension`과 `public extension`을 모두 사용해요. (`Session.swift`, `FeedReactor.swift`, `HomeV2Coordinator.swift`)
- 스타일 A는 프로토콜 채택을 `extension`으로 분리하는 경우가 많고(`extension AuthUsecaseImpl`), 스타일 B는 타입 선언에 함께 적어요.

### `self` 사용

- 생성자의 프로퍼티 대입, `[weak self]` 없이 `self`를 캡처하는 escaping 클로저에서는 `self.`를 써요.
- 일반 멤버 접근에는 `self.`를 생략해요. (`customView.cameraBtn.isHidden`, `repository.fetchUser(uid:)`)
- `self` 참조가 필요한 Rx 연산자 체인에서는 `withUnretained(self)`를 사용해요. `withUnretained`를 쓸 수 없는 클로저(`[weak self]`로 잡는 CollectionViewAdapter·`UIAlertAction`·GCD 클로저, `Observable.create` 등)에서는 `guard let self = self else { return }`로 풀어요. 축약형 `guard let self else`는 새 코드에서 쓰지 않아요. 스타일 A·B 모두 같은 규칙을 적용해요. 기존 코드의 `guard let self else`(22곳)는 파일을 수정할 때 바꿔요.

```swift
// Rx 연산자 체인: withUnretained
input.reload
    .withUnretained(self)
    .flatMapLatest { owner, _ in owner.adminUsecase.fetchGroupSummaries().asObservable() }

// 그 밖의 클로저: guard let self = self
alert.addAction(UIAlertAction(title: title, style: .destructive) { [weak self] _ in
    guard let self = self else { return }
    self.reactor?.action.onNext(.deleteConfirmed(post))
})
```

### `switch`

- 여러 패턴을 한 case에 적을 수 있어요. (`case .ended, .cancelled:`)
- case 사이에 빈 줄을 두지 않는 코드가 대부분이에요.
- 새 case를 추가할 때 누락을 알 수 있도록 우리 코드의 enum에는 `default`를 쓰지 않는 편을 권장해요. 외부 enum(UIKit 등)은 `default`나 `@unknown default`를 사용해요.

---

## UI 코드

### 뷰 구성

- 목록·반복 UI는 CollectionViewAdapter의 Component로 그려요. ([화면 그리기](../architecture/view-rendering.md))
- 루트 View는 `final class XxxView: UIView`로 분리하고 ViewController의 `loadView`에서 `view = customView`로 설치해요. 자세한 내용은 [View·Reactor·ViewModel 계약](../architecture/view-viewmodel-protocols.md)을 확인해요.
- 서브뷰는 클로저 초기화로 만들어요. 다른 프로퍼티를 참조하면 `lazy var`, 아니면 `let`을 사용해요.

```swift
let collectionView: UICollectionView = {
    let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
    collectionView.backgroundColor = .clear
    return collectionView
}()
```

- 레이아웃은 `translatesAutoresizingMaskIntoConstraints = false` + `NSLayoutConstraint.activate([...])`로 작성해요.
- 크기와 여백은 ScaleKit의 `.scaled`를, 폰트는 DSKit의 `UIFont.hcFont(_:size:)`를, 색상은 DSKit 색상 자산(`.background` 등)을 사용해요.
- 새 View의 `required init?(coder:)`는 `@available(*, unavailable)`을 붙이고 `fatalError`를 호출해요.
- 미리보기는 `#Preview`를 사용해요.

### 문자열 현지화

- 화면 문자열은 DSKit의 `LocalizationKey`에 키를 추가하고 `LocalizationKey.xxx.localized`로 사용해요.
- 문자열 파일은 `Projects/Shared/DSKit/Resources/Localizing/{ko,en,ja}.lproj/Localizable.strings`에 있어요. 세 언어에 모두 추가해요.
- 인자가 있으면 `String(format: LocalizationKey.xxx.localized, value)`를 사용해요.
- Feature 소스에 한국어 문자열 리터럴이 약 34개 남아 있어요. (예: `"새로고침 중..."`) 새 코드에서는 리터럴을 추가하지 않아요.

---

## MARK와 주석

### MARK

스타일 A에서 주로 쓰는 섹션 이름이에요. MARK 다음 줄에 바로 코드를 쓰는 경우가 대부분이에요.

| 섹션명 | 용도 |
| --- | --- |
| `UI Component` | 서브뷰 프로퍼티 |
| `Initializer` | `init`, `required init?(coder:)` |
| `LifeCycle` | `viewDidLoad` 등 |
| `UI Setup` | `setupUI()` |
| `Constraints` | `setupConstraints()` |
| `Bindings` | `bindViewModel()` |
| `Coordinator Trigger` | RouteTrigger 클로저 프로퍼티 |
| `Properties` | 그 밖의 프로퍼티 |
| `UICollectionViewDelegate` 등 | 프로토콜 채택 extension |

스타일 B는 MARK 대신 `///` 문서 주석으로 타입과 공개 메서드를 설명해요.

### 주석

- 공개 API와 Builder·RouteTrigger에는 `///` 문서 주석을 달아요. (`/// Member 화면에서 Coordinator로 전달하는 이동 이벤트입니다.`)
- 문서 주석은 합쇼체로 써요.
- 사용하지 않는 코드를 주석으로 남긴 곳이 많아요. 새 코드에서는 주석 처리 대신 삭제하고 Git 이력으로 추적해요.

---

## 로깅과 디버그 코드

- 로그는 Core의 `Logger.d`, `Logger.i`, `Logger.w`, `Logger.e`를 사용해요. `print`가 35개 파일에 130곳 남아 있지만 새 코드에는 추가하지 않아요.
- UI 테스트나 디버그에서만 쓰는 코드는 `#if DEBUG`로 감싸요. (`AuthUsecaseProtocol.bootstrapUserSession(uid:)`, `GroupUsecaseImpl.resetPostsForUITests()`, `SceneDelegate+UITests.swift`)
- UI 테스트 접근성 ID는 Core의 `UITestID`에 모아요.

---

## 관련 문서

- [아키텍처](../architecture/architecture.md)
- [DI Container](../architecture/dicontainer.md)
- [View·Reactor·ViewModel 계약](../architecture/view-viewmodel-protocols.md)
- [RxSwift 바인딩 정책](../architecture/rxswift-binding-policy.md)
- [테스트](testing.md)
