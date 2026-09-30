---
title: RxSwift Input/Output 바인딩 패턴
description: ReactorKit으로 전환하기 전까지 유지하는 Input/Output 화면에서 이벤트를 ViewModel Input으로 넘기고 Driver·Signal Output을 표시하는 방법과 자주 쓰는 연산자를 정리해요.
---

# Haruhancut RxSwift Input/Output 바인딩 패턴

> **기존 화면 유지보수용 문서예요.** 새 화면은 ReactorKit으로 작성해요. ([View·Reactor·ViewModel 계약](view-viewmodel-protocols.md#reactorkit-화면-구조)) 이 문서는 아직 `ViewModelType`을 쓰는 화면(Auth, Image, ProfileFeatureV2, MemberFeatureV2, Admin, HomeFeatureV2 상세 화면)을 고칠 때 참고해요. 예시는 실제 코드를 줄인 것이에요. 연산자 사용법(`flatMapLatest`, `materialize`, `share`)은 Reactor의 `mutate`에도 그대로 적용해요.

## 화면 바인딩의 순서

```text
ViewController.viewDidLoad
  → bindViewModel()
    1. 이벤트 소스를 Observable로 모아 ViewModel.Input 생성
    2. viewModel.transform(input:) 호출
    3. Output의 Driver는 drive(with:), Signal은 emit(with:)으로 표시
```

| 단계 | 기준 |
| --- | --- |
| Input 생성 | `XxxViewModel.Input(...)`의 memberwise init에 `Observable`을 넘겨요. Input 안에 Relay를 만들지 않아요. |
| transform | `viewDidLoad`에서 한 번만 호출해요. |
| Output 표시 | 상태는 `Driver`, 한 번 처리할 이벤트는 `Signal`이에요. ViewController의 `disposeBag`에 담아요. |

## Input·Output 계약

```swift
// AdminFeature/Sources/Admin/AdminViewModel.swift (요약)
struct AdminScreenState: Equatable { ... }

final class AdminViewModel: AdminViewModelType {
    struct Input {
        let reload: Observable<Void>
        let groupTapped: Observable<AdminGroupSummary>
        let sortOption: Observable<AdminGroupSortOption>
    }

    struct Output {
        let screenState: Driver<AdminScreenState>
        let loadFailed: Signal<Void>
    }
}
```

| 구분 | 타입 | 이력에서 확인한 사용 |
| --- | --- | --- |
| Input 필드 | `Observable<T>` | 24개 Input의 82개 필드가 모두 `Observable` |
| 상태 Output | `Driver<T>` | 50개. 화면 전체 상태는 `Equatable` `XxxScreenState`로 묶어요. (`MemberScreenState`, `AdminScreenState`) |
| 이벤트 Output | `Signal<T>` | 14개. 실패 알림, 공유 시트 표시처럼 재구독 시 다시 받으면 안 되는 값 |
| Relay·Subject Output | 사용하지 않아요. | 0개 |

## ViewController에서 Input을 만들어요

### RxCocoa 이벤트는 바로 넘겨요

```swift
// AuthFeature/Sources/SignIn/SignInViewController.swift (요약)
let input = SignInViewModel.Input(
    kakaoLoginButtonTapped: customView.kakaoLoginButton.rx.tap.asObservable(),
    appleLoginButtonTapped: customView.appleLoginButton.rx.tap.asObservable()
)
```

`rx.tap`처럼 RxCocoa가 제공하는 이벤트를 Relay로 한 번 더 감싸지 않아요.

### 클로저 이벤트는 VC의 PublishRelay로 받아요

CollectionViewAdapter의 `onTouch`·`onToggle`, `UIAlertAction`, `@objc` 메서드는 Rx 이벤트가 아니에요. ViewController가 `private let` Relay로 받아 `asObservable()`로 넘겨요.

```swift
// MemberFeatureV2/Sources/Member/MemberViewController.swift (요약)
private let inviteTappedRelay = PublishRelay<Void>()
private let memberTappedRelay = PublishRelay<User>()

// render(_:) 안의 CollectionViewAdapter 구성
MemberRowComponent.invite
    .onTouch { [weak self] in
        self?.inviteTappedRelay.accept(())
    }

// bindViewModel()
let input = MemberViewModel.Input(
    inviteCellTapped: inviteTappedRelay.asObservable(),
    memberCellTapped: memberTappedRelay.asObservable(),
    birthdaySettingsChanged: birthdaySettingsRelay.asObservable()
)
```

- Relay는 ViewController 안에 `private`으로 두고, Input에는 `Observable`만 넘겨요.
- 클로저 안에서는 `[weak self]`로 ViewController를 참조해요.

### DSKit 컴포넌트의 클로저는 `Observable.create`로 감싸요

DSKit 컴포넌트는 Rx 대신 클로저(`ProfileImageView.onProfileTapped` 등)를 공개해요. 한 번만 연결하면 되는 경우 `Observable.create`로 감싸 Input에 넘겨요. (예: `ProfileFeatureV2/Sources/Profile/ProfileViewController.swift`)

### 화면 생명 주기 이벤트

```swift
// ProfileFeatureV2/Sources/Profile/ProfileViewController.swift (요약)
let viewWillAppear = rx
    .methodInvoked(#selector(UIViewController.viewWillAppear(_:)))
    .map { _ in }
```

Core의 `Rx+.swift`에 `rx.didLoad`, `rx.willAppear`, `rx.didAppear` 같은 확장이 있지만 Feature에서는 쓰지 않아요. 새 코드에서 쓰려면 기존 화면과 함께 맞출지 먼저 정해요. (확인 필요: 팀 합의)

### 자주 쓰는 입력 조합

| 목적 | 사용 예 |
| --- | --- |
| 첫 로드 + 새로고침 | `input.reload.startWith(())` |
| 여러 이벤트를 하나로 | `Observable.merge(toBack, toHost, toEnter)` (`GroupViewModel`) |
| 이벤트 시점에 최신 상태 읽기 | `.withLatestFrom(input.groupNameText)` (`GroupViewModel`) |
| Void 변환 | Core의 `mapToVoid()`, 값 고정은 `mapTo(_:)` |

`debounce`, `throttle`, `flatMapFirst`는 현재 코드에서 쓰지 않아요. 중복 요청은 `flatMapLatest`가 이전 요청을 취소하는 방식으로 처리해요.

## ViewModel에서 Output을 조립해요

### 요청은 `withUnretained(self)` + `flatMapLatest`

```swift
// AdminFeature/Sources/Admin/AdminViewModel.swift (요약)
let loadEvent = input.reload
    .startWith(())
    .withUnretained(self)
    .flatMapLatest { owner, _ in
        owner.adminUsecase
            .fetchGroupSummaries()
            .asObservable()
            .materialize()
    }
    .share()
```

- `self`는 `withUnretained(self)`로 약하게 잡고, 클로저 인자 이름은 `owner`로 써요. `withUnretained`를 쓸 수 없는 클로저에서는 `[weak self]` + `guard let self = self else { return }`을 사용해요.
- Usecase의 `Single`은 `.asObservable()`로 바꿔 연결해요.

### 실패를 화면에 알려야 하면 `materialize()`

```swift
let loadFailed = loadEvent
    .compactMap { $0.error == nil ? nil : () }
    .asSignal(onErrorJustReturn: ())
```

`materialize()`로 오류를 이벤트로 바꾸고 `share()`로 한 요청을 성공·실패 스트림이 나눠 써요. 실패는 `Signal<Void>`로 내보내요. (예: `MemberViewModel`의 `birthdaySettingsUpdateFailed`, `AdminViewModel`의 `loadFailed`)

### 실패를 무시해도 되면 `catch`

화면에 알릴 필요가 없는 보조 요청은 `flatMapLatest` 안에서 `.catch { _ in .empty() }`나 `.catchAndReturn(nil)`로 스트림 종료를 막아요. 바깥 스트림에서 오류를 받으면 Input 구독 전체가 끝나기 때문이에요.

### 공유가 필요한 결과는 `share(replay: 1)`

같은 요청 결과를 여러 Output에 쓰면 `share(replay: 1)`로 한 번만 요청해요. (예: `MemberViewModel`의 `members`, `ProfileViewModel`의 게시물 목록)

### 화면 이동은 ViewModel 내부 구독으로 연결해요

```swift
input.memberCellTapped
    .compactMap(\.profileImageURL)
    .bind(with: self) { owner, imageURL in
        owner.onCellImageTapped?(imageURL)
    }
    .disposed(by: disposeBag)   // ViewModel의 disposeBag
```

RouteTrigger 호출은 Output으로 내보내지 않고 ViewModel 안에서 `bind(with:)`로 호출해요. 호출 전에 Usecase 결과를 기다려 화면을 이동한다면 `observe(on: MainScheduler.instance)`를 붙여요. (예: `NicknameEditViewModel`, `SettingViewModel`)

### Driver·Signal로 바꾸는 방법

| 변환 | 사용 시점 |
| --- | --- |
| `asDriver(onErrorJustReturn: 기본값)` | 오류 시 보여 줄 기본 상태가 있어요. (예: 빈 `MemberScreenState`) |
| `asDriver(onErrorDriveWith: .empty())` | 오류 시 아무것도 표시하지 않아요. ReactorKit State 구독에서 주로 써요. |
| `relay.asDriver()` | `BehaviorRelay`로 보관한 상태를 내보내요. |
| `asSignal(onErrorJustReturn:)` | 이벤트 Output을 만들어요. |

## ViewController에서 Output을 표시해요

```swift
output.screenState
    .drive(with: self) { owner, state in
        owner.render(state)
    }
    .disposed(by: disposeBag)

output.birthdaySettingsUpdateFailed
    .emit(with: self) { owner, _ in
        owner.showBirthdaySettingsFailure()
    }
    .disposed(by: disposeBag)
```

- 새 코드는 `drive(with: self)`·`emit(with: self)`를 사용해요. V1 화면의 `.drive(onNext: { [weak self] ... })`는 수정할 때 바꿔요.
- `render(_:)`는 ViewController의 `private` 메서드로 두고, 목록은 CollectionViewAdapter의 `adapter.bind(SectionModels { ... })`로 갱신해요. 이 `bind`는 Rx의 `bind(to:)`가 아니에요.
- 단순한 속성은 `.drive(button.rx.isEnabled)`처럼 RxCocoa Binder에 바로 연결할 수 있어요. (V1 화면에서 주로 사용)

## 바인딩 전 확인할 것

- [ ] Input 필드가 모두 `Observable`이고, Relay는 ViewController 안에만 있어요.
- [ ] 상태 Output은 `Driver`, 이벤트 Output은 `Signal`이에요.
- [ ] Usecase 호출은 `flatMapLatest` 안에 두고, 오류가 바깥 스트림을 끝내지 않아요.
- [ ] 같은 요청을 여러 Output이 쓰면 `share(replay: 1)` 또는 `materialize()` + `share()`를 사용해요.
- [ ] RouteTrigger 호출은 ViewModel의 `disposeBag`에, Output 표시는 ViewController의 `disposeBag`에 담아요.
- [ ] `transform(input:)`은 `viewDidLoad`에서 한 번만 호출해요.

## 관련 문서

- [RxSwift 사용 기준](rxswift.md): 타입·연산자와 하루한컷에서 쓰는 범위
- [RxSwift 바인딩 정책](rxswift-binding-policy.md): 구독 수명, 메모리, 스레드 규칙
- [View·Reactor·ViewModel 계약](view-viewmodel-protocols.md): ReactorKit 기본 규칙과 Input/Output → ReactorKit 전환 절차
