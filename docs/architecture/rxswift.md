---
title: RxSwift와 RxCocoa 타입 및 연산자 가이드
description: 하루한컷에서 쓰는 RxSwift·RxCocoa·ReactorKit의 범위와, 스트림 타입·연산자의 차이를 UIKit 화면 연결 기준으로 정리한 가이드예요.
---

# RxSwift와 RxCocoa 타입 및 연산자 가이드

Rx 코드는 값을 시간 순서대로 전달하는 스트림을 만들고, 연산자로 가공한 뒤, 구독자에게 연결하는 구조예요. 이름이 비슷해 보여도 각 타입과 메서드는 담당하는 역할이 달라요.

이 문서에서는 `Observable`, Subject, Relay, Trait와 `subscribe`, `bind`, `drive`, `emit`의 차이를 설명해요. 먼저 [하루한컷에서 쓰는 범위](#하루한컷에서-쓰는-범위)로 실제 사용 현황을 확인하고, 뒤의 라이브러리 설명은 필요할 때 찾아봐요. 타입 설명 절의 `currentLocationTapped`, `Coordinate` 같은 이름은 라이브러리 동작을 보여 주기 위한 예시예요.

## 하루한컷에서 쓰는 범위

Feature 소스(`Projects/Features/*/Sources`)의 grep 결과예요. 버전은 `Tuist/Package.swift` 기준 RxSwift 6.10.2, ReactorKit 3.2.0, RxDataSources 5.0.0 이상이에요.

| 영역 | 사용하는 것 | 사용하지 않는 것 |
| --- | --- | --- |
| Domain·Data 반환 타입 | `Single`(대부분), `Observable`(캐시 후 서버처럼 여러 번 방출), `Completable`(1곳) | `Maybe`, `Infallible` |
| ViewModel Input | `Observable<T>` | Input 안의 Relay, `ControlEvent` 필드 |
| ViewModel Output | `Driver`(상태), `Signal`(일회성 이벤트) | Relay·`Observable` Output |
| ViewModel 내부 상태 | `BehaviorRelay`, `PublishRelay` | `BehaviorSubject`, `ReplaySubject`, `ReplayRelay` |
| ViewController 이벤트 | `rx.tap`, `rx.methodInvoked`, 클로저 이벤트용 `private` `PublishRelay` | `PublishSubject`(V1 `SettingViewController`에만 2곳) |
| 연결 메서드 | `drive(with:)`, `emit(with:)`, ViewModel 안의 `bind(with:)` | `[unowned self]` |
| 연산자 | `flatMapLatest`, `withUnretained`, `share(replay: 1)`, `distinctUntilChanged`, `materialize`, `catch`, `withLatestFrom`, `merge`, `startWith` | `debounce`, `throttle`, `flatMapFirst`, `subscribe(on:)` |
| 상태 관리 | **ReactorKit이 새 화면의 기본 규칙**이에요. 현재 `HomeFeatureV2`의 Feed·Calendar에서 사용해요. 저장된 그룹 구독은 `transform(mutation:)`, 피드 실패 안내는 `@Pulse`로 보내요. 나머지 화면은 Input/Output을 유지하다가 순차 전환해요. | |
| 기타 | RxDataSources(V1 `ProfileFeature` Setting), Core의 `UIView.rx.tap`·`mapToVoid()` | RxGesture, RxTest·RxBlocking(선언만 있고 테스트에서 사용하지 않아요) |

팀 규칙은 [바인딩 정책](rxswift-binding-policy.md)에, ReactorKit 화면 구조는 [View·Reactor·ViewModel 계약](view-viewmodel-protocols.md)에, 기존 화면 연결 예시는 [Input/Output 패턴](rxswift-input-output.md)에 있어요. Rx 학습용 예제는 `Projects/Shared/RxLab/Demo`에 있어요.

## Rx 문서 읽는 순서

| 순서 | 문서 | 확인할 내용 |
| --- | --- | --- |
| 1 | 이 문서 | RxSwift·RxCocoa 타입과 연산자의 동작을 찾아봐요. |
| 2 | [바인딩 정책](rxswift-binding-policy.md) | 구독 수명, 메모리 참조, 스레드, `Driver`·`Signal` 사용 기준을 확인해요. |
| 3 | [View·Reactor·ViewModel 계약](view-viewmodel-protocols.md) | ReactorKit 화면의 Reactor·View·RouteTrigger 구조를 확인해요. |
| 4 | [Input/Output 패턴](rxswift-input-output.md) | 기존 Input/Output 화면을 고칠 때 바인딩 예시를 확인해요. |

타입 설명은 라이브러리의 기능을, 바인딩 정책은 하루한컷 코드에서 확인한 규칙을 다뤄요.

## 어떤 모듈에서 제공하나요

| 모듈 | 주요 기능 |
| --- | --- |
| `RxSwift` | `Observable`, Subject, `Single`, `Completable`, `Maybe`, 연산자, `Disposable` |
| `RxRelay` | `PublishRelay`, `BehaviorRelay`, `ReplayRelay` |
| `RxCocoa` | `ControlEvent`, `ControlProperty`, `Driver`, `Signal`, `Binder`, UIKit의 `rx` 확장 |
| `ReactorKit` | `Reactor`(Action·Mutation·State), `View`(`bind(reactor:)`) |
| `RxDataSources` | 섹션 기반 테이블·컬렉션 데이터 소스 |
| `RxTest`, `RxBlocking` | `TestScheduler`, `toBlocking()` 기반 테스트 도구 |

하루한컷은 외부 패키지를 `Projects/Shared/ThirdPartyLibs`에서 링크하고, 각 파일에서 필요한 모듈을 직접 import해요.

## Rx 흐름을 먼저 이해해요

Rx 코드는 보통 아래 순서로 동작해요.

```text
이벤트 발생
  -> Observable 또는 Relay
  -> map, filter, flatMapLatest 같은 연산자
  -> Driver 또는 Signal 같은 UI 출력
  -> bind, drive, emit으로 화면에 연결
```

스트림은 세 종류의 이벤트를 전달할 수 있어요.

| 이벤트 | 의미 |
| --- | --- |
| `.next(value)` | 새로운 값을 전달해요. 여러 번 전달할 수 있어요. |
| `.error(error)` | 오류와 함께 스트림을 종료해요. 이후에는 어떤 이벤트도 전달하지 않아요. |
| `.completed` | 정상적으로 스트림을 종료해요. 이후에는 어떤 이벤트도 전달하지 않아요. |

`Relay`, `Driver`, `Signal`, `ControlEvent`는 오류를 전달하지 않아요. UI 이벤트나 화면 상태처럼 오류 때문에 스트림 자체가 끝나면 곤란한 곳에서 사용해요.

## Observable은 값의 흐름이에요

`Observable<Element>`은 여러 값을 시간 순서대로 전달할 수 있는 가장 기본적인 타입이에요. 값이 없을 수도 있고, 여러 개일 수도 있어요. 정상 완료하거나 오류로 끝날 수도 있어요.

```swift
let numbers = Observable.from([1, 2, 3])

numbers
    .map { $0 * 2 }
    .subscribe(onNext: { number in
        print(number)
    })
    .disposed(by: disposeBag)
```

`Observable`이라는 이름만으로 Hot과 Cold를 판단할 수는 없어요. 이벤트를 어디서 만드는지에 따라 달라져요.

| 구분 | 동작 | 대표 예시 |
| --- | --- | --- |
| Cold Observable | 구독할 때마다 작업을 새로 시작해요. | 일반적인 네트워크 요청, `Observable.create`, `Observable.deferred` |
| Hot Observable | 구독 여부와 관계없이 이미 발생하는 이벤트를 관찰해요. | 버튼 탭, Subject, Relay |

## Observer는 값을 받는 쪽이에요

`Observable`이 값을 보내는 쪽이라면 `Observer`는 값을 받는 쪽이에요. `Subject`와 `Relay`는 값을 받을 수도 있고 다른 구독자에게 다시 전달할 수도 있어요.

```text
Observable -> Observer
```

`subscribe`는 Observable과 Observer를 연결해요.

## Disposable은 구독을 종료해요

`subscribe`, `bind`, `drive`, `emit`은 대부분 `Disposable`을 반환해요. 구독이 더 이상 필요 없을 때 `dispose()`를 호출하면 이벤트 전달을 중단해요.

`DisposeBag`은 여러 Disposable을 한 번에 관리해요. `DisposeBag`이 해제되면 내부 구독도 함께 종료돼요.

```swift
observable
    .subscribe(onNext: { value in
        print(value)
    })
    .disposed(by: disposeBag)
```

ViewController가 가진 `DisposeBag`은 ViewController의 수명과 UI 구독의 수명을 맞추는 데 사용해요.

## Subject는 값을 받고 다시 전달해요

Subject는 `Observable`이면서 `Observer`예요. 외부 콜백을 Rx 스트림으로 바꾸거나 테스트에서 원하는 이벤트를 직접 발생시킬 때 사용할 수 있어요.

Subject는 `.error`와 `.completed`를 받을 수 있어요. 한 번 종료되면 다시 값을 전달할 수 없어요.

| 타입 | 초기값 | 새 구독자에게 과거 값 전달 | 주 용도 |
| --- | --- | --- | --- |
| `PublishSubject` | 없음 | 전달하지 않음 | 지금부터 발생하는 이벤트 |
| `BehaviorSubject` | 필요 | 최신 값 1개 | 현재 상태와 종료 이벤트가 모두 필요한 경우 |
| `ReplaySubject` | 설정에 따라 다름 | 지정한 개수만큼 전달 | 과거 이벤트 재생 |
| `AsyncSubject` | 없음 | 완료할 때 마지막 값 1개 | 완료 시점의 마지막 결과 |

### PublishSubject

구독 이후에 발생한 값만 전달해요.

```swift
let tapped = PublishSubject<Void>()

tapped.onNext(())
```

### BehaviorSubject

초기값이 필요하고 새 구독자에게 최신 값을 전달해요.

```swift
let state = BehaviorSubject<String>(value: "idle")

state.onNext("loading")
```

### ReplaySubject

지정한 개수의 이전 값을 새 구독자에게 다시 전달해요.

```swift
let messages = ReplaySubject<String>.create(bufferSize: 2)
```

### AsyncSubject

스트림이 완료될 때 마지막 값만 전달해요.

```swift
let result = AsyncSubject<Int>()

result.onNext(1)
result.onNext(2)
result.onCompleted() // 구독자는 2를 받아요.
```

## Relay는 종료되지 않는 값 통로예요

Relay는 Subject를 감싸지만 `.error`와 `.completed`를 받지 않아요. 값은 `onNext` 대신 `accept`로 전달해요.

UI 상태와 사용자 입력처럼 앱이 살아 있는 동안 계속 사용할 스트림에는 Subject보다 Relay가 안전해요.

| 타입 | 초기값 | 새 구독자에게 과거 값 전달 | 주 용도 |
| --- | --- | --- | --- |
| `PublishRelay` | 없음 | 전달하지 않음 | 일회성 입력과 명령 |
| `BehaviorRelay` | 필요 | 최신 값 1개 | 현재 화면 상태 |
| `ReplayRelay` | 설정에 따라 다름 | 지정한 개수만큼 전달 | 종료 없는 이벤트 재생 |

### PublishRelay

현재부터 발생하는 이벤트만 전달해요.

```swift
let alertRelay = PublishRelay<String>()

alertRelay.accept("위치 요청 실패")
```

### BehaviorRelay

현재 값을 보관하며 `.value`로 최신 값을 읽을 수 있어요.

```swift
let stateRelay = BehaviorRelay<String>(value: "idle")

stateRelay.accept("loading")
print(stateRelay.value)
```

### ReplayRelay

지정한 개수의 이전 이벤트를 다시 전달해요.

```swift
let recentSearches = ReplayRelay<String>.create(bufferSize: 3)
```

Relay는 메인 스레드를 자동으로 보장하지 않아요. 여러 스레드에서 값을 넣는다면 스케줄러와 동시 접근을 따로 관리해야 해요.

## 한 번의 비동기 작업에는 PrimitiveSequence를 사용해요

네트워크 요청이나 저장 작업처럼 결과 개수가 정해진 작업에는 일반 `Observable`보다 의도가 분명한 타입을 사용할 수 있어요.

| 타입 | 성공 결과 | 실패 가능 | 주 용도 |
| --- | --- | --- | --- |
| `Single<Element>` | 값 1개 | 가능 | API 요청, 위치 한 번 조회 |
| `Completable` | 값 없이 완료 | 가능 | 저장, 삭제, 로그아웃 |
| `Maybe<Element>` | 값 0개 또는 1개 | 가능 | 값이 없을 수 있는 단일 조회 |
| `Infallible<Element>` | 값 0개 이상 | 불가능 | 실패하지 않는 일반 스트림 |

하루한컷의 Usecase·Repository는 대부분 `Single`을 반환하고, ViewModel에서 `.asObservable()`로 바꿔 `flatMapLatest`에 연결해요. `GroupUsecase.loadAndFetchGroup()`처럼 캐시 값과 서버 값을 차례로 방출하는 API는 `Observable`이고, Core의 `Fetcher`로 만들어요. 서버 값만 필요하면 호출부에서 `takeLast(1)`을 붙이지 말고 Usecase에서 `Fetcher.refresh()`를 써요. ([Fetcher로 캐시 우선 조회하기](#fetcher로-캐시-우선-조회하기))

```swift
let coordinate: Single<Coordinate> = provider.requestLocation()
let save: Completable = Completable.empty()
let cachedValue: Maybe<String> = Maybe.empty()
let safeValues: Infallible<Int> = Infallible.just(1)
```

## Fetcher로 캐시 우선 조회하기

Core의 `Fetcher`(`Core/Sources/Fetcher/`)는 Session에 저장된 값을 먼저 보내고 서버 값으로 갱신해요. 저장된 값의 변화 구독과 "먼저 바꾸고, 실패하면 되돌리는" 쓰기도 맡아요. Usecase마다 `concat(cached, remote)`나 되돌리기 코드를 다시 짜지 않아요.

서버 응답은 세 가지로 나눠요.

| 서버 응답 | Fetcher 동작 | 보내는 결과 |
| --- | --- | --- |
| 값 | `updateLocal`로 저장해요. | `(.success, 서버 값)` |
| 없음 (`nil`) | `removeLocal`로 캐시를 지우고, `cleanUpNotFound`가 있으면 끝날 때까지 기다려요. | `(.notFound, nil)` |
| 실패 (에러) | 캐시를 그대로 둬요. | `(.failure(에러), 캐시)` |

### Fetcher 만들기

Fetcher에는 캐시와 서버를 다루는 방법만 알려 주면 돼요. 순서와 실패 처리는 Fetcher가 맡아요.

```swift
// GroupUsecase.swift
private let groupRequests = FetchRequests<HCGroup>(maxAge: 10)  // Usecase가 하나만 가져요

func groupFetcher(groupId: String) -> Fetcher<HCGroup> {
    Fetcher(
        // 1. 캐시는 어디 있나요? → GroupSession
        local: { groupSession.entity },
        // 2. 캐시가 바뀌면 어떻게 알 수 있나요? → GroupSession 구독
        observeLocal: { groupSession.asObservable().map { $0?.toEntity() } },
        // 3. 서버에는 어떻게 묻나요? → 그룹이 없으면 nil, 읽지 못하면 에러
        remote: { groupRepository.fetchGroup(groupId: groupId) },
        // 4. 서버 값을 받으면? → GroupSession에 저장
        updateLocal: { group in groupSession.update(group.toSession()) },
        // 5. 서버에 그룹이 없으면? → GroupSession을 비우고, 서버·세션의 groupId도 지움
        removeLocal: { groupSession.clear() },
        cleanUpNotFound: { self.leaveMissingGroup(groupId: groupId) },
        // 6. 응답이 왔을 때 아직 이 그룹인가요? → 아니면 응답을 버림 (생략하면 항상 반영)
        isCurrent: { userSession.groupId == groupId }
    )
    .timeout(.seconds(15))                   // 15초 안에 응답이 없으면 실패
    .sharing(groupRequests, key: groupId)    // 같은 요청 합치기, 10초 안에 받은 그룹이면 서버 생략
    .logging("Group")                        // Debug 빌드에서 단계별 로그
}
```

다른 데이터도 이 항목만 바꿔 끼우면 돼요. 내 유저 정보는 `userSession`과 `repository.fetchUser(uid:)`를 넣어 만들어요(`AuthUsecaseImpl.userFetcher`). `SessionContext.asObservable()`은 지금 값을 먼저 보내고 값이 바뀔 때마다 보내는 스트림이에요.

### 연산자

아래 예시는 모두 같은 상황이에요.

- 휴대폰 캐시: 어제 받아 둔 그룹 (게시물 2개)
- 서버: 오늘 게시물이 하나 더 올라온 그룹 (게시물 3개)

#### `fetch()`: 캐시를 먼저 보여 주고 서버 값으로 바꿔요

화면에 들어올 때 써요. 사용자는 서버를 기다리지 않고 저장된 피드를 먼저 보고, 서버 응답이 오면 새 게시물이 붙어요. (`fetchGroupResult`, `loadAndFetchUser`, `loadAndFetchGroup`)

| 순서 | 받는 결과 | 화면 |
| --- | --- | --- |
| 1. 구독하자마자 | `(.loading, 게시물 2개 그룹)` | 저장된 피드를 바로 보여 줘요. |
| 2. 서버 응답 | `(.success, 게시물 3개 그룹)` | 새 게시물까지 보여 줘요. 캐시도 3개로 바뀌어요. |

서버 응답에 따라 2번이 달라져요.

| 서버 응답 | 2번에 받는 결과 | 화면 |
| --- | --- | --- |
| 확인 실패 (네트워크 오류, 15초 초과) | `(.failure(에러), 게시물 2개 그룹)` | 저장된 피드를 그대로 두고 실패를 안내해요. |
| 그룹 없음 | `(.notFound, nil)` | `cleanUpNotFound`가 서버·세션의 `groupId`를 지운 뒤에 보내요. AppCoordinator가 그룹 화면으로 보내요. |
| 10초 안에 이미 받음 | `(.success, 게시물 2개 그룹)` (캐시) | 서버에 묻지 않아요. |

캐시가 비어 있으면(앱 첫 실행) 1번은 `(.loading, nil)`이고, 피드는 가운데에 로딩을 보여 줘요.

#### `refresh()`: 캐시는 건너뛰고 서버 값만 받아요

당겨서 새로고침할 때와 서버에 쓴 직후 써요. 10초 안에 받은 값이 있어도 서버에 다시 물어요. (`refreshGroupResult`, `updateNicknameAndReloadSession`)

| 받는 결과 | 화면 |
| --- | --- |
| `(.success, 게시물 3개 그룹)` 하나 | 서버의 최신 그룹을 보여 줘요. |

#### `observe()`: 저장된 값이 바뀔 때마다 받아요

화면이 서로 새로고침을 알려 주지 않아도 되게 해요. 저장된 그룹을 먼저 보내고, 다른 화면이 서버 값이나 쓰기 결과를 저장하면 바로 다시 보내요. 서버에는 묻지 않고, 같은 값을 다시 저장하면 보내지 않아요. 끝나지 않는 스트림이라 화면이 사라질 때 구독을 해제해요. (`observeGroup`, `observeUser`)

| 일어난 일 | `observe()`로 받는 것 |
| --- | --- |
| 구독하자마자 | 게시물 2개 그룹 |
| 피드 화면이 서버에서 3개 그룹을 받아 저장 | 게시물 3개 그룹 |
| 댓글 시트에서 댓글 작성 | 댓글이 붙은 그룹 |

피드·캘린더·상세·댓글·프로필 화면이 `observeGroup()`을 구독해요. 그래서 댓글 시트를 닫을 때 Coordinator가 상세 화면에 `refresh()`를 알리던 코드를 지웠고, 위젯도 피드가 구독하는 그룹 변화로 맞춰요. 프로필 화면은 `observeUser()`도 구독해서 닉네임·프로필 사진·생일을 바꾸면 다시 읽지 않고 바로 그려요. 화면에 들어올 때 서버에 묻는 일(`loadAndFetchUser()`, `fetchGroupResult()`)은 따로 하고, 받은 값은 Session에 저장돼 구독으로 와요.

#### `update(_:remote:)`: 먼저 바꾸고, 실패하면 되돌려요

쓰기에 써요. 저장된 값을 먼저 바꾸고 서버에 써요. 서버 쓰기가 실패하면 원래 값으로 되돌려요. 화면은 `observe()`로 바뀐 값과 되돌린 값을 그대로 따라가요. (`updatePushEnabled`, `updateNicknameAndReloadSession`, `updateProfileImageAndReloadSession`, `updateBirthday`, `updateBirthdaySettings`, `addComment`, `deleteComment`, `deletePostAndReload`, `uploadImageAndUploadPost`)

```swift
// AuthUsecase.updatePushEnabled
userFetcher(userId: userId)
    .update({ user in user.isPushEnabled = false },
            remote: { user in repository.updateUser(user: user).map { _ in () } })
```

| 순서 | 저장된 값 | 화면 |
| --- | --- | --- |
| 1. 호출하자마자 | 알림 꺼짐 | 스위치가 바로 꺼져요. |
| 2-a. 서버 저장 성공 | 알림 꺼짐 | 그대로예요. |
| 2-b. 서버 저장 실패 | 알림 켜짐 (되돌림) | 스위치가 다시 켜지고 에러로 끝나요. |

실패했을 때 저장된 값이 바꾼 값 그대로면 원래 값으로 되돌려요. 그사이 다른 쓰기나 서버 값이 저장됐다면 그 변경까지 지우지 않도록 원래 값으로 덮어쓰지 않고, 서버 값을 다시 받아 저장해요. 다른 쓰기가 아직 진행 중이면 그 쓰기가 끝난 뒤에 다시 받아요. 쓰는 동안 받은 응답은 버려지기 때문이에요. 다시 받기가 실패해도 다음 `fetch()`는 최근 값 여부와 상관없이 서버에 물어요. 이 비교 때문에 `update`는 `Equatable` 값에서만 쓸 수 있어요. `sharing(_:key:)`을 붙였다면 쓰는 동안이나 쓰기 전에 시작된 서버 응답은 예전 값일 수 있어 저장하지 않고 버려요. 그래서 피드가 그룹을 읽는 중에 게시물을 지워도, 뒤늦게 온 예전 응답이 지운 게시물을 되살리지 않아요. 프로필 화면이 유저를 읽는 중에 닉네임을 바꿔도 마찬가지예요. 저장 뒤에 서버 값을 다시 읽지 않으므로, 푸시 설정 저장이 진행 중이어도 닉네임 저장은 서버 저장 결과대로 끝나요. 바꿀 캐시가 없으면 `FetchError.missingLocal`로 끝나고, 그사이 대상이 바뀌었으면(`isCurrent`가 `false`) 아무것도 바꾸지 않아요. 서버 쓰기는 보낸 뒤 취소되지 않으므로, 결과를 기다리던 구독이 먼저 해제돼도(댓글을 보내자마자 시트를 닫거나 `flatMapLatest`로 다음 저장을 시작함) 서버 응답까지 기다렸다가 되돌리기와 다시 받기를 마쳐요. 다만 해제된 구독은 실패를 받지 못하니, 실패를 알려야 하는 화면은 저장을 `flatMapLatest`로 취소하지 말고 `flatMap`으로 이어요(`MemberViewModel`의 생일 설정).

| 순서 (댓글 A·B를 연달아 작성) | 저장된 값 | 화면 |
| --- | --- | --- |
| 1. A·B 호출 | 댓글 A·B | 두 댓글이 바로 보여요. |
| 2. A 서버 저장 실패, B는 진행 중 | 댓글 A·B | 지금 다시 받으면 B와 겹쳐 버려지므로 B를 기다려요. |
| 3. B 서버 저장 성공 → 서버 값을 다시 받음 | 댓글 B | 실패한 A만 사라져요. |

#### `writeThenRefresh(_:)`: 먼저 바꿀 수 없으면 서버에 쓰고 다시 받아요

저장된 값을 먼저 바꿀 수 없을 때 써요. 서버에 쓰고, 쓰기가 끝나면 서버 값을 새 요청으로 받아 저장해요. 쓰기 전이나 쓰는 동안 시작된 요청에 합류하지 않아서, 다시 받은 값에는 방금 쓴 내용이 들어 있어요. 다른 쓰기가 진행 중이면 그 쓰기가 끝난 뒤에 받아요. 서버 쓰기가 실패하면 다시 받지 않고 그 에러로 끝나요. (`writeGroup`)

```swift
// GroupUsecaseImpl.writeGroup: 저장된 그룹이 없거나 댓글을 달 게시물이 없을 때
groupFetcher(groupId: groupId)
    .writeThenRefresh { groupRepository.addComment(path: path, value: newComment) }
    .ignoreElements()   // 다시 받은 그룹은 저장돼 observeGroup()으로 화면에 가요
```

| 상황 | `writeThenRefresh` 없이 서버에만 쓰기 | `writeThenRefresh` |
| --- | --- | --- |
| 앱을 처음 열어 저장된 그룹이 없을 때 댓글 작성 | 저장된 그룹이 없어 댓글 화면이 바뀌지 않아요. | 서버 그룹을 받아 저장하고, 그룹을 구독하는 댓글 화면에 댓글이 보여요. |
| 저장된 그룹에 아직 없는 게시물에 댓글 작성 | 바꿀 게시물이 없어 아무것도 바뀌지 않아요. | 서버 그룹을 받아 게시물과 댓글이 함께 보여요. |
| 피드가 그룹을 읽는 중에 위 댓글 작성 | 쓰기 전에 시작된 읽기가 댓글 없는 그룹을 저장할 수 있어요. | 그 읽기에 합류하지 않고 쓰기가 끝난 뒤 새로 받아요. 늦게 온 예전 응답은 버려요. |

`GroupUsecaseImpl.writeGroup`은 저장된 그룹이 없거나, 쓰려는 그룹과 다르거나(그룹 참여 직후), 바꿔도 달라지지 않으면(게시물이 없음) `writeThenRefresh`로, 아니면 `update`로 써요. 다시 받기가 실패해도 서버 쓰기는 끝났으므로 성공으로 끝내요.

#### `fetchedValues()`: 상태를 떼고 값만 꺼내요

`Observable<HCGroup>`처럼 값만 받는 화면에 연결할 때 써요. `Equatable`인 값은 바로 앞과 같은 값을 다시 보내지 않아요.

```swift
groupFetcher(groupId: groupId).fetch().fetchedValues()  // Observable<HCGroup>
```

| `fetch()`가 보낸 결과 | `fetchedValues()`가 보내는 것 |
| --- | --- |
| `(.loading, 게시물 2개 그룹)` | 게시물 2개 그룹 |
| `(.success, 게시물 3개 그룹)` | 게시물 3개 그룹 |
| `(.success, 게시물 2개 그룹)` (캐시와 같음) | 보내지 않아요. |
| `(.loading, nil)` (캐시 없음) | 건너뛰어요. |
| `(.failure(에러), 캐시)` | 그 에러로 끝나요. |
| `(.notFound, nil)` | `FetchError.notFound`로 끝나요. |

#### `timeout(_:)`, `sharing(_:key:)`, `logging(_:)`: Fetcher를 꾸며요

| 꾸미기 | 하는 일 | 예 |
| --- | --- | --- |
| `timeout(.seconds(15))` | 서버가 응답하지 않으면 `FetchError.timeout`으로 실패해요. 오프라인에서 로딩이 끝나지 않는 일을 막아요. | 지하철에서 앱을 열면 15초 뒤 "최신 정보를 불러오지 못했어요"를 보여 줘요. |
| `sharing(requests, key:)` | 같은 key의 요청이 진행 중이면 결과를 함께 받아요. `FetchRequests(maxAge:)` 안에 받은 값이면 `fetch()`가 서버를 건너뛰어요. | 홈에 들어가 피드와 캘린더가 동시에 그룹을 요청해도 서버 요청은 한 번이에요. 탭을 오가도 10초 안에는 다시 받지 않아요. |
| `logging("Group")` | 단계마다 로그를 남겨요. Debug 빌드에서만 남기고 값의 내용 대신 있음·없음만 남겨요. | 아래 로그 |

```
// 정상
[Group] 캐시 읽기: 있음
[Group] 서버 요청
[Group] 서버 응답: 값
[Group] 캐시 저장

// 최근에 받은 그룹
[Group] 캐시 읽기: 있음
[Group] 최근에 받은 값이라 서버 요청 생략

// 서버 확인 실패
[Group] 캐시 읽기: 있음
[Group] 서버 요청
[Group] 서버 응답: 실패 (timeout)       ← 🟡 경고
[Group] 캐시 읽기: 있음                ← 실패 결과에 담을 캐시를 다시 읽어요

// 그룹 없음
[Group] 서버 응답: 없음
[Group] 캐시 삭제
[Group] 없음 뒷정리 시작
[Group] 없음 뒷정리 완료
```

실제 로그에는 앞에 `[🟢] [GroupUsecase:409] Fetcher —`처럼 `.logging`을 붙인 위치가 찍혀요.

### 지킬 점

- Repository는 서버에 데이터가 없을 때만 `nil`을 돌려주고, 읽거나 변환하지 못하면 에러를 보내요. `nil`과 에러를 섞지 않아야 Fetcher가 캐시를 잘못 지우지 않아요.
- `isCurrent`에 요청한 대상(유저 ID·그룹 ID)이 지금 세션과 같은지 확인하는 조건을 넘겨요. 응답이 왔을 때 `false`면 Fetcher가 응답을 버려요. 캐시를 덮어쓰거나 지우지 않고, 예전 대상의 값을 화면에 보내지도 않아요.
- 없는 데이터를 가리키는 서버 값이 있으면 `cleanUpNotFound`에서 정리해요. 그룹이 없을 때 세션의 `groupId`만 지우면, 다음 유저 조회가 서버의 예전 `groupId`를 다시 저장해요. 정리가 실패하면 `.failure`로 끝나고 세션의 `groupId`는 남아 다음 조회에서 다시 정리해요.
- `FetchRequests`는 Usecase처럼 오래 사는 객체가 하나만 가져요. Fetcher를 만들 때마다 새로 만들면 요청을 합치지 못해요.
- 서버에 쓸 때는 `update(_:remote:)`로 저장된 값을 같이 바꾸거나 `writeThenRefresh(_:)`로 다시 받아요. Repository로 직접 쓰고 `refresh()`를 부르면 쓰기 전에 시작된 요청에 합류해 예전 값을 저장할 수 있어요. 저장된 값을 바꾸지 않고 서버에만 쓰면, 10초 안의 `fetch()`가 예전 캐시를 보여 줄 수도 있어요.
- 바꿀 캐시가 없으면 `update`는 `FetchError.missingLocal`로 끝나요. `GroupUsecaseImpl.writeGroup`처럼 저장된 값을 먼저 바꿀 수 없을 때는 `writeThenRefresh(_:)`로 나눠요.
- `observe()`는 끝나지 않아요. Reactor는 `transform(mutation:)`에서 한 번만 구독하고, `mutate`에서는 끝나는 `fetch()`·`refresh()`를 써요.
- 네트워크가 끊겨 있으면 Data가 쓰기를 시작하지 않고 `FirebaseError.offline`으로 바로 끝내요(`NetworkReachability`). `update(_:remote:)`는 이 실패로 먼저 바꾼 값을 되돌리므로, 화면은 다른 저장 실패와 같은 방식으로 처리하면 돼요.

## RxCocoa 타입은 UI에 필요한 규칙을 보장해요

`Observable`은 실행 스레드, 오류, 이벤트 공유 방법을 직접 결정해야 해요. RxCocoa의 Trait와 `Binder`는 UI에서 자주 필요한 규칙을 타입으로 표현해요.

| 타입 | 최신 값 재전달 | 메인 스레드 | 오류 | 주 용도 |
| --- | --- | --- | --- | --- |
| `ControlEvent` | 없음 | 보장 | 전달하지 않음 | 버튼 탭과 화면 생명주기 |
| `ControlProperty` | 현재 값 전달 | 보장 | 전달하지 않음 | 텍스트와 선택 상태 같은 UI 속성 |
| `Driver` | 연결 중 최신 값 1개 | 보장 | 전달하지 않음 | 화면이 계속 표시할 상태 |
| `Signal` | 없음 | 보장 | 전달하지 않음 | 알림과 화면 이동 같은 일회성 명령 |
| `Binder` | 해당 없음 | 기본적으로 보장 | 받지 않음 | 값을 UI 속성에 쓰는 목적지 |

### ControlEvent

UIKit에서 발생한 사용자 입력을 표현해요. 초기값이나 과거 이벤트를 전달하지 않아요.

```swift
let tapped: ControlEvent<Void> = locationButton.rx.tap
```

화면 생명주기를 Rx 이벤트로 감싼 확장이 있다면 `ControlEvent<Void>`로 표현할 수 있어요. 이 확장은 모든 프로젝트에 기본으로 제공되지는 않아요.

### ControlProperty

UI가 가진 현재 값과 이후 변경을 함께 표현해요. 읽기와 쓰기가 모두 가능한 속성에 주로 사용해요.

```swift
let text: ControlProperty<String?> = textField.rx.text
```

### Driver

화면이 계속 표시해야 하는 현재 상태에 사용해요. 메인 스레드 전달, 오류 없음, 구독 간 작업 공유, 연결 중 최신 값 재전달을 보장해요.

```swift
let state: Driver<State> = stateRelay.asDriver()

state
    .drive(onNext: { state in
        print(state)
    })
    .disposed(by: disposeBag)
```

### Signal

한 번 발생하고 지나가는 UI 명령에 사용해요. 메인 스레드에서 전달하고 오류가 없지만 이전 값을 재전달하지 않아요.

```swift
let alert: Signal<String> = alertRelay.asSignal()

alert
    .emit(onNext: { alert in
        print(alert)
    })
    .disposed(by: disposeBag)
```

### Binder

값을 받기만 하는 UI 목적지예요. 직접 만들 수도 있지만 `label.rx.text`, `button.rx.isEnabled`처럼 RxCocoa가 제공하는 Binder를 주로 사용해요.

```swift
viewModel.title
    .bind(to: titleLabel.rx.text)
    .disposed(by: disposeBag)
```

## 같은 버튼을 RxSwift와 RxCocoa로 연결해요

UIKit 버튼 탭을 ViewModel의 `currentLocationTapped` Input으로 전달한다고 가정해요. RxCocoa를 사용하지 않아도 구현할 수 있지만, UIKit 콜백을 Rx 이벤트로 바꾸는 코드를 직접 작성해야 해요.

### RxCocoa 없이 PublishSubject로 연결하기

RxSwift만 사용하면 `UIButton`의 Target-Action을 `PublishSubject<Void>`로 전달해요.

```swift
import RxSwift
import UIKit

final class LocationViewController: UIViewController {
    private let locationButton = UIButton(type: .system)
    private let currentLocationTapped = PublishSubject<Void>()

    override func viewDidLoad() {
        super.viewDidLoad()

        locationButton.addTarget(
            self,
            action: #selector(didTapCurrentLocation),
            for: .touchUpInside
        )

        let input = LocationViewModel.Input(
            currentLocationTapped: currentLocationTapped.asObservable()
        )
    }

    /// UIKit 버튼 탭을 RxSwift 이벤트로 변환합니다.
    @objc private func didTapCurrentLocation() {
        currentLocationTapped.onNext(())
    }
}
```

이 방식의 흐름은 아래와 같아요.

```text
UIButton 터치
  -> addTarget
  -> @objc 메서드
  -> PublishSubject.onNext(())
  -> ViewModel Input
```

`PublishSubject`는 UIKit 콜백과 RxSwift 사이의 수동 연결 통로예요. RxCocoa를 사용할 수 없거나 Rx로 제공되지 않는 외부 SDK 콜백을 연결할 때 같은 방식이 필요할 수 있어요.

### RxCocoa의 ControlEvent로 연결하기

RxCocoa는 `UIButton`의 탭을 `ControlEvent<Void>`로 제공해요. 별도의 Subject, Target-Action, `@objc` 메서드가 필요하지 않아요.

```swift
import RxCocoa
import RxSwift
import UIKit

final class LocationViewController: UIViewController {
    private let locationButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()

        let input = LocationViewModel.Input(
            currentLocationTapped: locationButton.rx.tap.asObservable()
        )
    }
}
```

이 방식의 흐름은 아래와 같아요.

```text
UIButton 터치
  -> button.rx.tap
  -> ViewModel Input
```

버튼을 눌렀을 때 ViewModel Input 전달 외에 직접 실행할 코드가 있다면 `bind(onNext:)`를 사용할 수 있어요.

```swift
locationButton.rx.tap
    .bind(onNext: {
        print("위치 버튼 탭")
    })
    .disposed(by: disposeBag)
```

### 두 방식을 비교해요

| 비교 항목 | UIKit + RxSwift | RxCocoa |
| --- | --- | --- |
| 버튼 이벤트 시작점 | `addTarget` | `button.rx.tap` |
| Rx 이벤트 변환 | `PublishSubject.onNext(())`를 직접 호출 | `ControlEvent<Void>`가 자동 제공 |
| 필요한 중간 객체 | `PublishSubject<Void>` | 없음 |
| Objective-C 메서드 | `@objc` 메서드 필요 | 필요 없음 |
| 메인 스레드와 오류 규칙 | 직접 관리 | `ControlEvent`가 메인 스레드와 오류 없음 보장 |
| 적합한 상황 | RxCocoa가 없거나 지원되지 않는 콜백 | UIKit 컨트롤을 일반적으로 연결할 때 |

두 방식 모두 같은 ViewModel Input을 만들 수 있어요. 하루한컷은 RxCocoa를 사용하므로 중간 Subject를 만들지 않고 `rx.tap`을 직접 전달해요. RxCocoa가 지원하지 않는 콜백(CollectionViewAdapter의 `onTouch`, `UIAlertAction`, `UIRefreshControl`의 `@objc` 메서드)만 ViewController의 `private` `PublishRelay`로 감싸요. ReactorKit 화면에서는 `@objc` 메서드에서 `reactor?.action.onNext(.refresh)`를 호출해요. (예: `FeedViewController`)

실제 Input 구성은 [Input/Output 패턴](rxswift-input-output.md)에서 확인해요.

## subscribe, bind, drive, emit을 구분해요

이 메서드들은 스트림을 최종 소비자에게 연결해요. 반환된 `Disposable`을 보관해야 실제 화면 수명과 구독 수명을 맞출 수 있어요.

### subscribe

가장 기본적인 구독 방법이에요. `.next`, `.error`, `.completed`를 모두 처리할 수 있어요. UI 전용 규칙은 보장하지 않아요.

```swift
observable
    .subscribe(
        onNext: { value in
            print(value)
        },
        onError: { error in
            print(error)
        },
        onCompleted: {
            print("완료")
        }
    )
    .disposed(by: disposeBag)
```

일반 비동기 흐름, 데이터 계층, 디버깅처럼 오류와 완료를 직접 처리해야 할 때 사용해요.

### bind(to:)

값을 다른 Observer, Relay, Subject, Binder에 그대로 전달해요. 중간에 별도 동작이 필요하지 않을 때 사용해요.

```swift
textField.rx.text.orEmpty
    .bind(to: queryRelay)
    .disposed(by: disposeBag)
```

```swift
viewModel.title
    .bind(to: titleLabel.rx.text)
    .disposed(by: disposeBag)
```

### bind(onNext:)

값을 받을 때 메서드 호출이나 여러 동작을 직접 실행해야 할 때 사용해요.

```swift
locationButton.rx.tap
    .bind(onNext: {
        print("위치 버튼 탭")
    })
    .disposed(by: disposeBag)
```

`bind`는 UI 바인딩처럼 오류가 없어야 하는 흐름에 사용해요. 오류가 발생할 수 있는 Observable이라면 먼저 `catch` 등으로 오류 정책을 정해야 해요.

### drive

`Driver`를 UI나 클로저에 연결해요. `Driver`의 메인 스레드, 오류 없음, 최신 상태 공유 규칙을 유지해요.

```swift
output.state
    .drive(onNext: { [weak self] state in
        self?.renderState(state)
    })
    .disposed(by: disposeBag)
```

### emit

`Signal`을 UI나 클로저에 연결해요. 과거 이벤트를 재실행하지 않는 일회성 흐름에 사용해요.

```swift
output.alert
    .emit(onNext: { [weak self] alert in
        self?.renderAlert(alert)
    })
    .disposed(by: disposeBag)
```

## 자주 쓰는 생성 연산자

| 연산자 | 설명 | 간단한 예시 |
| --- | --- | --- |
| `just` | 값 하나를 전달해요. | `Observable.just(1)` |
| `from` | 배열 등의 각 요소를 순서대로 전달해요. | `Observable.from([1, 2, 3])` |
| `of` | 전달한 인자를 각각 이벤트로 만들어요. | `Observable.of(1, 2, 3)` |
| `create` | 이벤트 발생 규칙을 직접 만들어요. | `Observable<Int>.create { observer in ... }` |
| `deferred` | 구독할 때 Observable을 새로 만들어요. | `Observable.deferred { makeRequest() }` |
| `empty` | 값 없이 바로 완료해요. | `Observable<Int>.empty()` |
| `never` | 값도 종료도 전달하지 않아요. | `Observable<Int>.never()` |

## 값을 바꾸고 걸러내는 연산자

| 연산자 | 설명 | 간단한 예시 |
| --- | --- | --- |
| `map` | 각 값을 다른 값으로 바꿔요. | `.map { $0.name }` |
| `compactMap` | `nil`을 제거하면서 값을 바꿔요. | `.compactMap { Int($0) }` |
| `filter` | 조건을 만족하는 값만 통과시켜요. | `.filter { $0.isValid }` |
| `distinctUntilChanged` | 직전 값과 같은 연속 값을 제거해요. | `.distinctUntilChanged()` |
| `scan` | 이전 누적값으로 새 값을 만들어요. | `.scan(0, accumulator: +)` |
| `startWith` | 구독 직후 지정한 값을 먼저 전달해요. | `.startWith(.idle)` |
| `skip` | 앞에서 지정한 개수만큼 건너뛰어요. | `.skip(1)` |
| `take` | 앞에서 지정한 개수만 받아요. | `.take(1)` |

## 비동기 작업을 연결하는 연산자

| 연산자 | 새 입력이 오면 기존 작업을 어떻게 하나요 | 적합한 상황 |
| --- | --- | --- |
| `flatMap` | 기존 작업과 새 작업을 모두 유지해요. | 여러 요청을 동시에 처리할 때 |
| `flatMapLatest` | 이전 내부 구독을 해제하고 최신 결과만 전달해요. 실제 작업 취소 여부는 원본 구현에 달려 있어요. | 검색어 자동 완성 |
| `flatMapFirst` | 기존 작업이 끝날 때까지 새 입력을 무시해요. | 중복 로그인이나 위치 요청 방지 |
| `concatMap` | 앞 작업이 끝날 때까지 새 작업을 대기시켜요. | 요청 순서를 반드시 지킬 때 |

```swift
query
    .flatMapLatest { keyword in
        repository.search(keyword)
    }
```

위치 요청 중 연속 탭을 무시하려면 `flatMapFirst`를 선택할 수 있어요.

## 여러 스트림을 합치는 연산자

| 연산자 | 동작 | 적합한 상황 |
| --- | --- | --- |
| `merge` | 같은 타입의 여러 스트림 이벤트를 하나로 합쳐요. | 자동 요청과 버튼 요청 합치기 |
| `combineLatest` | 각 스트림의 최신 값을 조합해요. | 이메일과 비밀번호 유효성 조합 |
| `zip` | 각 스트림의 같은 순번 값을 한 쌍으로 묶어요. | 순서가 맞는 결과 조합 |
| `withLatestFrom` | 기준 이벤트가 발생할 때 다른 스트림의 최신 값을 가져와요. | 버튼 탭 시 최신 입력값 사용 |

```swift
loginButton.rx.tap
    .withLatestFrom(credentials)
```

## 시간과 중복 입력을 다루는 연산자

| 연산자 | 동작 | 적합한 상황 |
| --- | --- | --- |
| `debounce` | 일정 시간 새 이벤트가 없을 때 마지막 값을 전달해요. | 검색어 입력 (하루한컷에서는 아직 사용하지 않아요.) |
| `throttle` | 일정 시간 동안 이벤트 전달 횟수를 제한해요. | 연속 버튼 탭 방지 (하루한컷에서는 아직 사용하지 않아요.) |
| `delay` | 이벤트 전달을 늦춰요. | 표시 타이밍 조정과 테스트 |
| `timeout` | 제한 시간 안에 이벤트가 없으면 오류를 발생시켜요. | 위치 조회와 네트워크 제한 시간 |

## 오류를 다루는 연산자

| 연산자 | 동작 | 간단한 예시 |
| --- | --- | --- |
| `catch` | 오류를 다른 Observable로 바꿔요. | `.catch { _ in .just([]) }` |
| `catchAndReturn` | 오류가 발생하면 지정한 값을 전달해요. | `.catchAndReturn([])` |
| `retry` | 오류가 발생하면 다시 구독해요. | `.retry(2)` |
| `materialize` | 이벤트를 값으로 바꿔 오류도 일반 값처럼 다뤄요. | `.materialize()` |

오류를 무조건 빈 값으로 바꾸면 원인을 잃을 수 있어요. 사용자에게 보여줄 오류, 재시도할 오류, 기록만 할 오류를 먼저 구분한 뒤 연산자를 선택해요. 하루한컷에서 사용자에게 실패를 알려야 하는 흐름은 `materialize()` + `share()`로 오류를 분리해 `Signal<Void>`로 내보내고(`MemberViewModel`, `AdminViewModel`), 무시해도 되는 보조 요청은 `flatMapLatest` 안에서 `.catch { _ in .empty() }`를 사용해요. Reactor는 `Logger.e`로 기록한 뒤 빈 스트림을 반환하거나 낙관적 갱신을 되돌려요.

## 스레드를 정하는 연산자

| 연산자 | 바꾸는 위치 | 적합한 상황 |
| --- | --- | --- |
| `subscribe(on:)` | 구독과 원본 작업이 시작되는 스케줄러 | 파일 읽기, 무거운 계산 시작 |
| `observe(on:)` | 이후 이벤트를 받는 스케줄러 | 결과를 메인 스레드에서 UI에 반영 |

```swift
repository.load()
    .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .userInitiated))
    .observe(on: MainScheduler.instance)
```

`Driver`, `Signal`, `ControlEvent`, `ControlProperty`는 메인 스레드 전달을 보장하므로 UI 연결 직전에 `observe(on: MainScheduler.instance)`를 반복할 필요가 없어요.

## 부수 효과와 공유를 다루는 연산자

| 연산자 | 동작 | 적합한 상황 |
| --- | --- | --- |
| `do` | 값은 바꾸지 않고 로그나 상태 기록을 실행해요. | 세션 요청 횟수 기록 |
| `share` | 여러 구독자가 하나의 원본 작업을 공유해요. | 네트워크 요청 중복 방지 |
| `take(until:)` | 다른 스트림이 이벤트를 내면 현재 구독을 끝내요. | 화면이 사라질 때 요청 취소 |

```swift
let sharedRequest = repository.load()
    .share(replay: 1, scope: .whileConnected)
```

`share` 없이 Cold Observable을 여러 번 구독하면 네트워크 요청이나 계산도 여러 번 실행될 수 있어요.

## Subject와 Relay를 남용하지 않아요

기존 UIKit 콜백을 Rx로 바꿔야 할 때 Subject나 Relay가 필요할 수 있어요. 하지만 RxCocoa가 이미 제공하는 이벤트를 다시 Subject로 전달할 필요는 없어요.

```swift
// 불필요한 중간 통로
button.rx.tap
    .bind(to: buttonTappedRelay)

// Input에서 직접 사용
let buttonTapped = button.rx.tap.asObservable()
```

다른 스트림 안에서 `subscribe`를 다시 호출하는 중첩 구독도 피해야 해요. `flatMap`, `flatMapLatest`, `flatMapFirst` 중 동시 실행 정책에 맞는 연산자를 사용해요. 하루한컷은 요청 연결에 주로 `flatMapLatest`를 사용해요. ProfileFeatureV2 `ProfileViewModel`의 프로필 이미지 변경 흐름에는 중첩 구독이 남아 있어요. 변경 뒤 유저를 다시 읽던 구독은 `observeUser()` 구독으로 바꿔 지웠어요.

## 피드 화면(ReactorKit)에서는 이렇게 사용해요

`HomeFeatureV2`의 피드 탭에서 쓰는 타입이에요.

| 위치 | 타입 | 이유 |
| --- | --- | --- |
| `reactor?.action.onNext(.viewDidLoad)` | `ActionSubject<FeedReactor.Action>` | 생명 주기와 `@objc` 새로고침을 Action으로 보내요. |
| `FeedReactor.mutate(action:)` | `Observable<Mutation>` | 로딩 시작·결과·로딩 끝을 `concat`으로 이어요. |
| `authUsecase.loadAndFetchUser()` | `Observable<User>` → `Mutation.setUser` | 캐시와 서버 값을 차례로 반영해요. |
| `reactor.state.map(\.components)` | `Observable<[FeedComponent]>` → `Driver` | `distinctUntilChanged` 후 메인 스레드에서 그려요. |
| `imageTappedRelay` (VC) | `PublishRelay<Post>` → `Driver<Post>` | CollectionViewAdapter의 `onTouch` 클로저를 부모 컨테이너 이벤트로 올려요. |
| `routeTrigger?.onImageTapped?(post)` (컨테이너) | 클로저 | Coordinator가 상세 화면으로 이동해요. |

## 멤버 화면(기존 Input/Output)에서는 이렇게 사용해요

`MemberFeatureV2`의 멤버 목록 화면에서 쓰는 타입이에요. ReactorKit으로 전환하기 전까지 이 구조를 유지해요.

| 위치 | 타입 | 이유 |
| --- | --- | --- |
| `MemberRowComponent.invite.onTouch { ... }` | 클로저 | CollectionViewAdapter 컴포넌트는 Rx가 아닌 클로저로 이벤트를 전달해요. |
| `inviteTappedRelay`, `memberTappedRelay` (ViewController) | `PublishRelay<Void>`, `PublishRelay<User>` | 클로저 이벤트를 Rx 스트림으로 바꿔요. |
| `MemberViewModel.Input.memberCellTapped` | `Observable<User>` | UI와 테스트가 같은 방식으로 입력을 넣을 수 있어요. |
| `authUsecase.fetchUser(uid:)` | `Single<User?>` | 사용자 한 명을 한 번 조회해요. |
| 조회한 멤버 목록 | `Observable<[User]>` + `share(replay: 1)` | 화면 상태와 다른 계산이 같은 결과를 공유해요. |
| `Output.screenState` | `Driver<MemberScreenState>` | 화면이 최신 상태를 메인 스레드에서 받아요. |
| `Output.inviteCode` | `Driver<String>` | 초대 코드를 공유 시트로 표시해요. |
| `Output.birthdaySettingsUpdateFailed` | `Signal<Void>` | 실패 알림을 다시 표시하지 않아요. |
| `onCellImageTapped` 호출 | ViewModel 안의 `bind(with:)` | 화면 이동은 RouteTrigger 클로저로 Coordinator에 알려요. |

## 최종 선택표

이 표는 RxSwift·RxCocoa에서 가능한 타입 선택을 정리한 참고표예요. 하루한컷은 화면 Output에 `Driver`·`Signal`을 사용해요. 표와 [바인딩 정책](rxswift-binding-policy.md)이 다르면 바인딩 정책을 따라요.

| 상황 | 만들 타입 | 연결 방법 |
| --- | --- | --- |
| 일반적인 여러 값과 오류를 처리해요. | `Observable` | `subscribe` |
| API가 값 하나 또는 오류를 반환해요. | `Single` | `subscribe` |
| 값 없이 성공 또는 오류만 필요해요. | `Completable` | `subscribe` |
| 값이 없을 수도 있는 단일 결과가 필요해요. | `Maybe` | `subscribe` |
| 버튼 탭이나 화면 생명주기를 받아요. | `ControlEvent` | `bind` 또는 Input에 직접 전달 |
| 텍스트 필드의 현재 값과 변경을 받아요. | `ControlProperty` | `bind` |
| ViewModel 내부에서 현재 상태를 보관해요. | `BehaviorRelay` | `accept` |
| ViewModel 내부에서 일회성 이벤트를 발생시켜요. | `PublishRelay` | `accept` |
| 화면이 계속 표시할 최신 상태를 출력해요. | `Driver` | `drive` |
| 알림, 화면 이동, 카메라 이동을 한 번 실행해요. | `Signal` | `emit` |
| 값을 Relay나 UI 속성에 그대로 전달해요. | `Observable` 또는 `ControlProperty` | `bind(to:)` |
| 값을 받을 때 직접 여러 동작을 실행해요. | `Observable` 또는 `ControlEvent` | `bind(onNext:)` |
| 오류와 완료를 직접 처리해야 해요. | `Observable` | `subscribe` |

가장 짧게 기억하면 아래와 같아요.

```text
일반 스트림은 Observable
UI 입력은 ControlEvent
내부 상태는 BehaviorRelay
내부 사건은 PublishRelay
화면 상태 출력은 Driver
일회성 UI 출력은 Signal
오류까지 처리하면 subscribe
그대로 연결하면 bind(to:)
직접 동작하면 bind(onNext:)
Driver는 drive
Signal은 emit
```
