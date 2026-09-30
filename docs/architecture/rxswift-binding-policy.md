---
title: RxSwift 바인딩 정책
description: 하루한컷 UIKit 화면에서 ReactorKit(기본)과 기존 Input/Output 화면의 Rx 구독 수명, 메모리 참조, UI 스레드, 상태·이벤트 전달 기준을 정리해요.
---

# Haruhancut RxSwift 바인딩 정책

> 새 화면은 ReactorKit으로 작성하고, 기존 Input/Output 화면은 유지하다가 순차적으로 전환해요. ([View·Reactor·ViewModel 계약](view-viewmodel-protocols.md)) 아래 규칙은 현재 코드(Feature 소스 grep)에서 확인한 방식을 바탕으로 정했어요. **(새 규칙)**은 기존 코드에 아직 없는 규칙이에요. 린터가 강제하지 않으므로 리뷰에서 확인해요.

## 규칙 요약

| 항목 | ReactorKit 화면 (기본) | 기존 Input/Output 화면 |
| --- | --- | --- |
| 입력 | `Reactor.Action`. 생명 주기·`@objc`·클로저 이벤트는 `reactor?.action.onNext(...)`, RxCocoa 이벤트는 `bind(to: reactor.action)` **(새 규칙)** | `Input`의 `Observable<T>` 필드 |
| 상태 | `Reactor.State`를 조각별로 `map`·`distinctUntilChanged`·`asDriver(onErrorDriveWith: .empty())`·`drive(with:)` | `Driver` Output |
| 일회성 이벤트 | State의 `@Pulse` + `reactor.pulse(\.$x)` **(새 규칙)** | `Signal` Output |
| 구독 소유 | ReactorKit View의 `var disposeBag` | ViewController와 ViewModel 각자의 `private let disposeBag` |
| 화면 이동 | ViewController가 `weak var routeTrigger`를 호출 | ViewModel이 RouteTrigger 클로저를 호출 |
| `self` 참조 | 구독은 `drive(with:)`·`emit(with:)`·`bind(with:)`, 연산자 체인은 `withUnretained(self)`, 쓸 수 없는 곳은 `[weak self]` + `guard let self = self else { return }` | 같음 |
| UI 스레드 | State를 `Driver`로 바꿔 메인 스레드에서 표시해요. | `Driver`·`Signal`. 이동 전에만 `observe(on: MainScheduler.instance)` |
| 중복 요청 | `mutate`에서 요청을 이어 붙일 때 `flatMapLatest`를 사용해요. | `flatMapLatest` |

## 구독의 수명

| 구독 | 담는 곳 | 해제 시점 |
| --- | --- | --- |
| Reactor State·Action 바인딩 (`bind(reactor:)`) | ReactorKit View의 `disposeBag` | `reactor` 재설정 또는 View 해제 |
| `mutate`가 반환한 스트림 | ReactorKit 내부 | Reactor 해제 |
| 컨테이너의 자식 이벤트 구독 | 컨테이너의 `disposeBag` | 컨테이너 해제 |
| Input/Output 화면의 Output 표시 | ViewController의 `disposeBag` | ViewController 해제 |
| Input/Output 화면의 RouteTrigger 호출 | ViewModel의 `disposeBag` | ViewModel 해제 |

- `bind(reactor:)`와 `transform(input:)`은 한 번만 호출돼야 해요. `viewWillAppear`처럼 여러 번 불리는 곳에서 구독을 만들지 않아요.
- ReactorKit View가 `init`에서 `self.reactor`를 설정하면 ReactorKit이 `bind(reactor:)`를 `viewDidLoad` 뒤로 미뤄요. `bind(reactor:)`를 직접 호출하지 않아요.
- Reactor 안에서 `subscribe`하지 않아요. 모든 작업은 `mutate`가 반환하는 `Observable<Mutation>`에 담아요.
- `subscribe()`만 호출하고 bag에 담지 않는 코드(`SignInViewModel`, ProfileFeatureV2 `SettingViewModel`)는 기존 코드예요. 새 코드에서는 쓰지 않아요.

## ReactorKit 바인딩

### State 표시

```swift
func bind(reactor: FeedReactor) {
    reactor.state
        .map(\.isLoading)
        .distinctUntilChanged()
        .asDriver(onErrorDriveWith: .empty())
        .drive(with: self) { owner, isLoading in
            owner.updateRefreshingState(isLoading: isLoading)
        }
        .disposed(by: disposeBag)
}
```

- State 전체를 한 번에 구독하지 않고, 화면 요소별로 필요한 값만 `map`해요.
- `distinctUntilChanged()`를 붙여 같은 값으로 다시 그리지 않게 해요. 값 타입은 `Equatable`이어야 해요. (`FeedComponent` 배열 등) 프로필 이미지 깜빡임을 `distinctUntilChanged`로 고친 이력이 있어요. (`d335f4a`)

### Action 전달

```swift
// 생명 주기·@objc·클로저: 직접 보내요 (기존 코드)
override func viewDidLoad() {
    super.viewDidLoad()
    reactor?.action.onNext(.viewDidLoad)
}

@objc
private func didRequestRefresh() {
    reactor?.action.onNext(.refresh)
}

// RxCocoa 이벤트: bind(reactor:) 안에서 연결해요 (새 규칙)
customView.retryButton.rx.tap
    .map { Reactor.Action.refresh }
    .bind(to: reactor.action)
    .disposed(by: disposeBag)
```

### 일회성 이벤트 (새 규칙)

```swift
// Reactor
struct State {
    @Pulse var deleteFailed: Void?
}

// View
reactor.pulse(\.$deleteFailed)
    .compactMap { $0 }
    .asSignal(onErrorSignalWith: .empty())
    .emit(with: self) { owner, _ in
        owner.showDeleteFailure()
    }
    .disposed(by: disposeBag)
```

알림·토스트·이동처럼 다시 구독할 때 반복되면 안 되는 값은 일반 State 대신 `@Pulse`를 사용해요. `FeedReactor`는 삭제 실패 시 이전 목록으로 되돌리기만 하고 알림은 띄우지 않아요.

### Reactor 안의 비동기 작업

- 로딩 표시는 `Observable.concat([.just(.setLoading(true)), 작업, .just(.setLoading(false))])`로 감싸요.
- 오류는 작업 스트림 안에서 `.catch`로 처리해요. `mutate` 스트림에서 오류가 나면 해당 Action의 처리가 끝나요.
- 캐시 후 서버 순서로 여러 번 방출하는 `loadAndFetchGroup()` 같은 API에서 최종 값만 필요하면 `takeLast(1)`을 붙여요.
- 연산자 체인에서 Reactor를 참조하면 `withUnretained(self)`를 사용해요. `withUnretained`를 쓸 수 없으면 `[weak self]`로 잡고 `guard let self = self else { return .empty() }`로 풀어요. (`FeedReactor.deletePost`의 `guard let self else`는 수정할 때 바꿔요.)

## 메모리 참조

```swift
// Rx 구독: with: self
reactor.state.map(\.components)
    .asDriver(onErrorDriveWith: .empty())
    .drive(with: self) { owner, components in owner.renderFeed(components: components) }
    .disposed(by: disposeBag)

// 연산자 체인: withUnretained(self)
input.reload
    .withUnretained(self)
    .flatMapLatest { owner, _ in owner.adminUsecase.fetchGroupSummaries().asObservable() }

// Rx 밖의 클로저: [weak self]
component.onTouch { [weak self] in
    self?.reactor?.action.onNext(.itemSelected(id))
}
```

- 클로저 인자 이름은 `owner`로 통일해요.
- `[unowned self]`는 사용하지 않아요.
- `routeTrigger`는 `weak`로 보관해요.
- `self` 참조가 필요한 Rx 연산자 체인에서는 `withUnretained(self)`를 사용해요. `withUnretained`를 쓸 수 없는 클로저(`[weak self]`로 잡는 CollectionViewAdapter·`UIAlertAction`·GCD 클로저, `Observable.create` 등)에서는 `guard let self = self else { return }`로 풀어요. 축약형 `guard let self else`는 새 코드에서 쓰지 않아요. 기존 코드에는 `guard let self else`(22곳, 주로 V2·Admin)가 섞여 있는데, 파일을 수정할 때 바꿔요.

## 컨테이너 화면

`HomeViewController`처럼 자식 ReactorKit 화면을 묶는 컨테이너는 다음을 지켜요.

- 자식 이벤트는 자식 VC가 공개한 `Driver`로 받아요. (`feedVC.imageTapped`)
- 자식 Reactor의 `currentState`를 읽거나 `action`에 직접 보내는 코드는 새로 추가하지 않아요. 지금 `HomeViewController.presentDeleteAlert`에 이 방식이 남아 있어요.

## 기존 Input/Output 화면

- Input은 `Observable`만 넘기고, `let input = XxxViewModel.Input()` 뒤에 `bind(to: input.x)`로 채우는 방식은 쓰지 않아요.
- RxCocoa 이벤트(`rx.tap`, `rx.text`)는 Relay로 감싸지 않고 바로 `asObservable()`로 넘겨요.
- Output에는 Relay를 공개하지 않아요.
- 화면 이동은 Output으로 내보내지 않고, ViewModel이 RouteTrigger 클로저를 호출해요.
- 실패 알림은 `materialize()` + `share()`로 분리해 `Signal`로 내보내요.
- `bind(with:)`·`subscribe` 클로저 안에서 다시 구독하지 않아요. ProfileFeatureV2 `ProfileViewModel`의 프로필 이미지 변경 흐름에 중첩 구독이 남아 있어요. ReactorKit으로 전환하면서 `mutate`로 옮겨요.

자세한 예시는 [Input/Output 패턴](rxswift-input-output.md)을 확인해요.

## 프로젝트 전용 확장

| 확장 | 위치 | 사용 현황 |
| --- | --- | --- |
| `UIView.rx.tap: ControlEvent<Void>` | `Core/Sources/Extensions+/Rx/Rx+.swift` | 사용 중 (`customView.imageView.rx.tap`) |
| `rx.didLoad`, `rx.willAppear`, `rx.didAppear`, `rx.willDisappear`, `rx.didDisappear` | `Core/Sources/Extensions+/Rx/Rx+.swift` | Feature에서 사용하지 않아요. ReactorKit 화면은 생명 주기 메서드에서 Action을 보내요. |
| `mapToVoid()`, `mapTo(_:)` | `Core/Sources/Extensions+/Rx/ObservableType+.swift` | 사용 중 |
| `UIImageView.rx.imageURL: Binder<String?>` | `Core/Sources/Extensions+/Rx/RX+UIImageView+.swift` | Feature에서 사용하지 않아요. |

`throttle`·`debounce`·`flatMapFirst`는 쓰지 않아요. 연속 탭으로 중복 동작이 문제가 되면 해당 화면에서 적용하고 이 문서에 기록해요.

## 적용 전 체크리스트

- [ ] 새 화면이 ReactorKit(`Reactor` + `View`)으로 작성됐어요.
- [ ] State는 조각별로 `distinctUntilChanged()` 후 `Driver`로 표시해요.
- [ ] 일회성 이벤트는 `@Pulse`, 화면 이동은 ViewController의 `routeTrigger`로 처리해요.
- [ ] Reactor 안에서 `subscribe`하지 않고, 오류는 작업 스트림 안에서 `.catch`로 처리해요.
- [ ] Rx 구독은 `with: self`, 연산자 체인은 `withUnretained(self)`, 그 밖의 클로저는 `[weak self]` + `guard let self = self else { return }`을 사용해요.
- [ ] 기존 Input/Output 화면을 수정했다면 그 화면의 구조를 유지했거나, 전환 절차를 따랐어요.

## 관련 문서

- [RxSwift 사용 기준](rxswift.md)
- [View·Reactor·ViewModel 계약](view-viewmodel-protocols.md)
- [RxSwift Input/Output 패턴](rxswift-input-output.md)
