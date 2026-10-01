---
title: CollectionViewAdapter로 화면 그리기
description: 하루한컷 화면에서 루트 View와 CollectionViewAdapter로 목록을 그리는 방법, Component 작성 규칙, ReactorKit State 연결, 이벤트·이미지·prefetch 처리를 설명해요.
---

# Haruhancut CollectionViewAdapter로 화면 그리기

> 목록이나 반복되는 UI는 사내 모듈 `CollectionViewAdapter`로 그려요. 화면 상태(ReactorKit State)를 `SectionModels`로 선언하면 Adapter가 Diffable snapshot, Cell 등록과 재사용, Compositional Layout을 처리해요. API 전체 설명은 [CollectionViewAdapter README](../../Projects/Shared/CollectionViewAdapter/README.md)를 확인하고, 이 문서는 하루한컷 Feature 화면에서 쓰는 방법만 다뤄요.

## 목차

- [어떤 방식으로 그릴지 정해요](#어떤-방식으로-그릴지-정해요)
- [전체 구조](#전체-구조)
- [Component를 만들어요](#component를-만들어요)
- [ViewController에서 Section을 선언해요](#viewcontroller에서-section을-선언해요)
- [이벤트를 연결해요](#이벤트를-연결해요)
- [Section layout을 골라요](#section-layout을-골라요)
- [이미지와 prefetch](#이미지와-prefetch)
- [체크리스트](#체크리스트)

## 어떤 방식으로 그릴지 정해요

| 화면 | 그리는 방법 | 예시 |
| --- | --- | --- |
| 목록, 그리드, 반복되는 행, 섹션이 여러 개인 화면 | 루트 View의 `UICollectionView` + `CollectionViewAdapter` | 피드(`FeedViewController`), 멤버(`MemberViewController`), 프로필 게시물(`ProfileViewController`), 설정(`SettingViewController`), 관리자(`AdminViewController`) |
| 입력 폼, 고정된 배치, 단일 콘텐츠 화면 | 루트 View에서 Auto Layout으로 직접 배치 | 닉네임 수정, 로그인, 온보딩 |
| 날짜 그리드 | FSCalendar | 캘린더(`CalendarViewController`) |

- 새 목록 화면에는 `UITableView`, RxDataSources, 직접 만든 `UICollectionViewCell` 서브클래스를 쓰지 않아요. RxDataSources는 V1 `ProfileFeature` 설정 화면에만 남아 있어요.
- `Project.swift`에 `CollectionViewAdapter` 의존성이 있는지 확인해요. V2 Feature와 AdminFeature에는 이미 있어요.

## 전체 구조

```text
Reactor.State (도메인 모델·표시 값)
      │  bind(reactor:) : map → distinctUntilChanged → drive
      ▼
ViewController.render(...)
      │  SectionModels { LazySection { For(of:) { XxxComponent(...) } } }
      ▼
CollectionViewAdapter.bind(_:animatingDifferences:)
      │  Diffable snapshot · ContainerCell<Component> · Compositional Layout
      ▼
루트 View의 UICollectionView
```

| 파일 | 역할 |
| --- | --- |
| `XxxView.swift` | 루트 View. `collectionView`와 빈 상태 라벨, 고정 버튼 같은 목록 밖 UI를 배치해요. |
| `XxxViewController.swift` | Adapter를 소유하고, State를 `SectionModels`로 바꿔 `bind`해요. Component 이벤트를 Action으로 보내요. |
| `Component/XxxComponent.swift` 또는 `XxxRowComponent.swift` | `XxxComponent`(Component)와 `XxxContentView`(표시할 `UIView`)를 한 파일에 둬요. |

## Component를 만들어요

`MemberFeatureV2/Sources/Member/MemberRowComponent.swift`가 기준 예시예요.

```swift
// Component: Item과 ContentView를 연결해요
struct MemberRowComponent: Component {
    typealias Item = MemberRowContentView.Item

    let item: Item

    init(user: User, birthdayText: String? = nil) {
        item = Item(
            id: .member(user.uid),
            content: .member(
                nickname: user.nickname,
                profileImageURL: user.profileImageURL,
                birthdayText: birthdayText
            )
        )
    }

    var estimatedHeight: CGFloat { 60 }

    func createContent() -> MemberRowContentView {
        MemberRowContentView()
    }

    func render(context _: ComponentContext, content: MemberRowContentView) {
        content.item = item
    }
}

// ContentView: 실제로 그리는 UIView
final class MemberRowContentView: UIView, Touchable {
    struct Item: Identifiable, Equatable {
        let id: MemberRowIdentifier
        let content: Content
    }

    var item: Item? {
        didSet {
            guard item != oldValue else { return }
            applyItem()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureView()
        configureLayout()
    }
}
```

### Item

| 규칙 | 이유 |
| --- | --- |
| `Identifiable & Equatable`인 값 타입으로 ContentView 안에 중첩해요. (`MemberRowContentView.Item`) | Adapter가 `id`로 snapshot identity를, `==`로 같은 행의 변경 여부를 판단해요. |
| `id`는 모델의 안정적인 식별자를 써요. (`post.postId`, `user.uid`) 배열 index나 새 `UUID()`는 쓰지 않아요. | id가 바뀌면 갱신이 아니라 삭제·삽입으로 처리돼 깜빡이거나 스크롤 위치가 흔들려요. |
| 한 Section에 종류가 다른 행이 섞이면 id를 enum으로 만들어요. (`MemberRowIdentifier.invite`, `.member(String)`) | 같은 Section 안에서 id가 겹치지 않아야 해요. 중복이면 precondition이 발생해요. |
| 화면에 표시하는 값만 담고, 표시용으로 가공해서 넣어요. (`relativeTimeText`, `birthdayText`) | 표시 값이 `==` 비교에 들어가야 값이 바뀔 때 다시 그려져요. |
| 도메인 모델 전체를 Item에 넣지 않아요. 이벤트에 원본 모델이 필요하면 Component 프로퍼티로 따로 들고 있어요. (`FeedComponent.post`) | 표시와 무관한 필드 변경으로 불필요한 갱신이 생기지 않게 해요. |

### Component

- `struct XxxComponent: Component`로 만들고 `let item: Item`만 저장해요. 이벤트에 필요한 원본 값은 추가 프로퍼티로 둘 수 있어요.
- 모델을 받는 `init`에서 Item을 만들어요. 고정 행은 `static var invite: Self`처럼 정적 프로퍼티로 제공해요.
- `estimatedHeight`는 초기 추정값이에요. 실제 높이는 ContentView의 Auto Layout으로 정해져요.
- `render`는 `content.item = item` 한 줄로 끝내요. 그리기 로직은 ContentView에 둬요.
- 재사용 시 취소해야 하는 작업(직접 만든 observation 등)만 `context.cancellationBag`에 저장해요.

### ContentView

- `final class XxxContentView: UIView`로 만들고 지원하는 상호작용 capability만 채택해요. (`Touchable`, `Pressable`, `LongPressable`, `ContainsButton`, `ContainsSwitch`)
- `var item: Item? { didSet { guard item != oldValue else { return }; applyItem() } }`로 같은 값이면 다시 그리지 않아요.
- `applyItem()`은 이전 상태를 먼저 지운 뒤 새 값을 적용해요. `item`이 `nil`이면 라벨·이미지·접근성 값을 비워요. (재사용 셀에 이전 값이 남지 않게)
- 위에서 아래까지 이어지는 Auto Layout 제약을 걸어요. 제약이 끊기면 self-sizing 높이가 맞지 않아요.
- 서브뷰 생성과 배치는 [Swift 스타일의 UI 코드](../development/swiftstyle.md#ui-코드) 규칙을 따라요. 새 파일은 `configureView()`·`configureLayout()`을 사용해요.
- 내부 버튼·스위치는 `ContainsButton`·`ContainsSwitch`를 채택하고 `buttonTapEvent.send(())`, `switchToggleEvent.send(toggle.isOn)`으로 이벤트를 보내요.
- `#Preview { XxxContentView() }`로 미리보기를 둘 수 있어요.

## ViewController에서 Section을 선언해요

### Adapter 소유

```swift
// FeedViewController (요약)
private lazy var collectionViewAdapter = CollectionViewAdapter(
    collectionView: customView.collectionView
)
```

- Adapter는 ViewController가 `private lazy var`로 한 개만 소유해요. 기본 initializer가 Collection View의 layout을 Compositional Layout으로 교체하므로, 루트 View의 `collectionView`는 `UICollectionViewFlowLayout()`으로 만들어 두면 돼요.
- Section 사이 간격이 필요하면 `CollectionViewAdapter(collectionView:interSectionSpacing:)`을 사용해요.

### State를 SectionModels로 바꿔요 (ReactorKit)

```swift
func bind(reactor: FeedReactor) {
    reactor.state
        .map(\.components)
        .distinctUntilChanged()
        .asDriver(onErrorDriveWith: .empty())
        .drive(with: self) { owner, components in
            owner.renderFeed(components: components)
        }
        .disposed(by: disposeBag)
}

private func renderFeed(components: [FeedComponent]) {
    let shouldAnimate = !currentComponents.isEmpty
    currentComponents = components

    collectionViewAdapter.bind(
        SectionModels {
            LazySection(identifier: "feed") {
                For(of: components) { component in
                    self.makeInteractiveComponent(component)
                }
            }
            .withSectionLayout(
                .grid(columns: 2, estimatedRowHeight: 240, interItemSpacing: 20, lineSpacing: 20,
                      contentInsets: NSDirectionalEdgeInsets(top: 20, leading: 16, bottom: 0, trailing: 16))
            )
        },
        animatingDifferences: shouldAnimate
    )
    customView.emptyLabel.isHidden = !components.isEmpty   // 실제 코드는 읽기 전용 모드 문구도 함께 바꿔요
}
```

- 목록에 쓰는 State 조각을 `distinctUntilChanged()`로 걸러 `render...` 메서드 하나로 넘겨요. 매번 전체 `SectionModels`를 새로 만들어 `bind`하면 Adapter가 차이만 반영해요.
- `render...`는 `private` 메서드로 두고, 목록 밖 UI(빈 상태 라벨, 버튼 상태)도 같은 곳에서 갱신해요.
- 첫 표시에는 `animatingDifferences: false`, 이후 갱신에는 `true`를 써요. (`shouldAnimate`)
- Section `identifier`는 화면 안에서 고유한 문자열로 정하고, 반복 사용하면 `private enum Constant`에 둬요. (`Constant.memberSectionIdentifier`)
- 한 화면에 Section이 여러 개면 `SectionModels { ... }` 안에 `LazySection`을 나열해요.

### Reactor State에는 무엇을 두나요

| 방식 | 사용 |
| --- | --- |
| State에 도메인 모델·표시 값(`[Post]`, `[User]`, `birthdaySettings`)을 두고, ViewController의 `render...`에서 Component를 만들어요. | **새 화면의 기준** |
| State에 Component 배열(`[FeedComponent]`)을 둬요. | `FeedReactor`의 기존 방식이에요. Reactor가 `UIKit`·`CollectionViewAdapter`에 의존하게 되므로 새 Reactor에서는 쓰지 않아요. |

Component는 UIKit 표시 타입이에요. Reactor는 화면에 무엇을 보여 줄지(State)만 정하고, 어떻게 그릴지(Component)는 ViewController가 정해요.

## 이벤트를 연결해요

### Component modifier

```swift
// ReactorKit 화면 예시 (Action 이름은 화면에 맞게 정해요)
MemberRowComponent(user: member, birthdayText: text)
    .onTouch { [weak self] in
        self?.reactor?.action.onNext(.memberSelected(member.uid))
    }
```

| modifier | ContentView가 채택할 capability | 하루한컷 사용 예 |
| --- | --- | --- |
| `.onTouch { }` | `Touchable` | 피드 이미지·멤버 행 선택 |
| `.pressedEffect(scale:)` | `Pressable` | 피드 카드 눌림 효과 |
| `.onLongPress(minimumDuration:) { }` | `LongPressable` | 피드 게시물 삭제 (`minimumDuration: 0.4`) |
| `.onButtonTap { }` | `ContainsButton` | 멤버 헤더의 생일 설정 버튼 |
| `.onToggle { isOn in }` | `ContainsSwitch` | 설정 화면 알림 토글 |

- ReactorKit 화면은 modifier 클로저에서 `[weak self]`로 잡고 `self?.reactor?.action.onNext(...)`로 Action을 보내요.
- 컨테이너의 자식 화면이면 `PublishRelay`에 넣고 `Driver`로 부모에 공개해요. (`FeedViewController.imageTappedRelay` → `imageTapped`)
- 기존 Input/Output 화면은 `PublishRelay`에 넣어 Input으로 넘겨요. (`MemberViewController.memberTappedRelay`)
- 조건에 따라 modifier를 다르게 붙이면 반환 타입이 달라지므로 `AnyComponent`로 감싸요.

```swift
// FeedViewController (요약): 읽기 전용 모드에서는 길게 누르기를 붙이지 않아요
private func makeInteractiveComponent(_ component: FeedComponent) -> AnyComponent {
    let interactive = component
        .pressedEffect()
        .onTouch { [weak self] in
            self?.imageTappedRelay.accept(component.post)
        }

    guard !isReadOnly else { return AnyComponent(interactive) }

    return AnyComponent(
        interactive.onLongPress(minimumDuration: 0.4) { [weak self] in
            self?.longPressedRelay.accept(component.post)
        }
    )
}
```

Modifier의 observation은 `ComponentContext.cancellationBag`에 연결돼, Cell이 재사용되거나 다시 render될 때 자동으로 정리돼요.

### Header와 Footer

```swift
LazySection(identifier: Constant.memberSectionIdentifier) { ... }
    .withHeader(
        MemberHeaderComponent(memberCount: state.members.count, showsBirthdaySettingsButton: state.canEditBirthdaySettings)
            .onButtonTap { [weak self] in
                self?.showBirthdaySettings()
            },
        zIndex: 1
    )
    .withSectionLayout(
        CollectionSectionLayout
            .verticalList(estimatedRowHeight: Constant.rowHeight, spacing: Constant.rowSpacing)
            .withHeaderPinToVisibleBounds(true)
    )
```

- Header·Footer도 일반 Component로 만들어요.
- 스크롤 중 고정하려면 layout에 `.withHeaderPinToVisibleBounds(true)`를 붙이고, 셀 위에 보이도록 `zIndex: 1`을 줘요.

## Section layout을 골라요

| layout | 하루한컷 사용 예 | 주요 인자 |
| --- | --- | --- |
| `.verticalList` | 멤버, 설정, 관리자 목록 | `estimatedRowHeight`, `spacing`, `contentInsets` |
| `.grid` | 피드(2열) | `columns`, `estimatedRowHeight`, `interItemSpacing`, `lineSpacing`, `contentInsets` |
| `.horizontalCarousel` | 아직 사용하지 않아요. (Demo에만 있음) | `itemWidth`, `estimatedHeight`, `spacing`, `behavior` |
| `CollectionSectionLayout { _ in ... }` 직접 생성 | 프로필 게시물 그리드 (`ProfileViewController.makeProfilePostGridLayout(targetWidth:)`) | 기본 layout으로 표현할 수 없을 때 `NSCollectionLayoutSection`을 직접 만들어요. |

- 좌우 여백은 layout의 `contentInsets`로 줘요. 루트 View에서 `collectionView` 자체에 여백을 주는 방식(`MemberView`의 `constant: 20`)도 있지만, 새 화면은 `contentInsets`를 사용해요.
- 전체 목록 끝 도달은 `adapter.reachedEnd`, 가로 Section 끝은 `.onReachedEnd`를 사용해요. 현재 Feature에서는 쓰지 않아요.

## 이미지와 prefetch

### ContentView에서 이미지를 불러와요

```swift
// FeedRowView (요약)
private func applyItem() {
    imageView.kf.cancelDownloadTask()
    imageView.image = nil

    guard let item else { return }
    imageView.kf.setImage(with: URL(string: item.imageURL))
}
```

- 이미지는 Kingfisher로 불러와요. 새 값을 적용하기 전에 `kf.cancelDownloadTask()`로 이전 요청을 취소하고 이미지를 비워요.
- 작은 썸네일은 `DownsamplingImageProcessor`로 표시 크기만큼 줄여요. 옵션은 Component 파일에 `enum XxxImageRequest`로 모아요. (`MemberProfileImageRequest.options`)
- 이미지가 로드된 뒤 높이가 바뀌는 셀이면 `context.invalidateLayout()`을 호출해요. 정사각형처럼 비율을 제약으로 고정하면 필요 없어요. (`FeedRowView`의 `heightAnchor == widthAnchor`)

### 목록이 길면 prefetch해요

```swift
// MemberViewController (요약)
private lazy var adapter: CollectionViewAdapter = {
    let adapter = CollectionViewAdapter(collectionView: customView.collectionView)
    adapter.prefetchItems = { [weak self] items in
        self?.prefetchImages(for: items)
    }
    adapter.cancelPrefetchingItems = { [weak self] items in
        self?.cancelImagePrefetching(for: items)
    }
    return adapter
}()
```

- `prefetchItems`는 `[CollectionViewPrefetchItem]`(`indexPath`, `sectionIdentifier`, `itemIdentifier`)을 전달해요. `itemIdentifier`를 Item의 id 타입으로 바꿔 URL을 찾아요.
- `render...`에서 id → URL 조회표(`imageURLsByMemberID`)를 갱신하고, Kingfisher `ImagePrefetcher`에 화면 표시와 **같은 옵션**을 넘겨요. 옵션이 다르면 캐시 키가 달라 prefetch한 이미지를 쓰지 못해요.
- 진행 중인 prefetcher는 id별로 보관해 중복 요청을 막고, `cancelPrefetchingItems`와 `deinit`에서 `stop()`해요.

## 체크리스트

- [ ] 목록·반복 UI는 CollectionViewAdapter로, 고정 배치는 루트 View의 Auto Layout으로 그렸어요.
- [ ] Item id가 모델의 안정적인 식별자이고, Section 안에서 겹치지 않아요.
- [ ] 화면에 표시하는 값이 모두 Item의 `Equatable` 비교에 들어가요.
- [ ] ContentView의 `item` `didSet`에서 같은 값이면 다시 그리지 않고, 새 값 적용 전에 이전 이미지·요청을 지워요.
- [ ] Reactor State에는 모델·표시 값을 두고, Component는 ViewController의 `render...`에서 만들어요.
- [ ] Component 이벤트는 `[weak self]`로 잡고 Action(또는 Relay)으로 보내요.
- [ ] prefetch를 쓰면 화면 표시와 같은 Kingfisher 옵션을 쓰고, 취소와 `deinit` 정리를 넣었어요.
- [ ] 문제가 생기면 [README의 트러블슈팅](../../Projects/Shared/CollectionViewAdapter/README.md#트러블슈팅)을 확인해요. (중복 id, 갱신 누락, self-sizing, Header 고정)

## 관련 문서

- [CollectionViewAdapter README](../../Projects/Shared/CollectionViewAdapter/README.md): API와 내부 구조
- [View·Reactor·ViewModel 계약](view-viewmodel-protocols.md): Reactor·View·RouteTrigger 구조
- [RxSwift 바인딩 정책](rxswift-binding-policy.md): State 구독과 메모리 참조
- [Swift 스타일](../development/swiftstyle.md): UI 코드 작성 규칙
