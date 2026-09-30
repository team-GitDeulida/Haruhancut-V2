# Haruhancut 테스트 안내

> 테스트 타깃, CI 검증 범위, 로컬 실행 명령을 정리했어요. "로컬 확인" 열의 명령은 2026-09-30에 `docs/#98` 브랜치에서 실행해 성공을 확인했어요.

## 요약

| 항목 | 값 | 근거 |
| --- | --- | --- |
| 테스트 프레임워크 | XCTest (`@testable import`). RxTest·RxBlocking·Swift Testing은 사용하지 않아요. | 각 `Tests/` 소스 |
| CI 필수 체크 | `Test / App`, `Test / Core`, `Test / Data` | `main` 브랜치 보호 규칙 |
| CI 환경 | `macos-15`, Xcode 26.3, iPhone 16 / iOS 26.2 | `.github/workflows/build-and-test.yml` |
| Tuist 버전 | 4.115.0 | `mise.toml` |
| 배포 대상 | iOS 17.0 | 각 `Project.swift` |

## 테스트 타깃

| 스킴 | 테스트 타깃 | 대상 | 외부 의존 | CI 실행 |
| --- | --- | --- | --- | --- |
| `Core` | `CoreTests` | `SessionContext`, `UserDefaultsStorage` | 없음 | 실행 |
| `Data` | `DataTests` | Firebase Manager, DTO 변환, 통합 테스트 | **실제 Firebase** (App을 test host로 사용) | 실행 |
| `App` | `AppTests`, `AppUITests` | FCM 토큰 동기화, 홈 업로드·삭제 UI 흐름 | **실제 Firebase** | 실행 |
| `HomeFeatureV2` | `HomeFeatureV2Tests` | 오늘 업로드 상태, Feed 레이어, 상세 새로고침 | 없음 | 실행하지 않음 |
| `MemberFeatureV2` | `MemberFeatureV2Tests` | 멤버 화면 ViewModel | 없음 | 실행하지 않음 |
| `ProfileFeatureV2` | `ProfileFeatureV2Tests` | 프로필 화면 | 없음 | 실행하지 않음 |
| `AdminFeature` | `AdminFeatureTests` | 관리자 Usecase·ViewModel | 없음 | 실행하지 않음 |
| `CollectionViewAdapter` | `CollectionViewAdapterTests` | 섹션·컴포넌트·diff 적용 | 없음 | 실행하지 않음 |

- Domain, WidgetSupport, V1 Feature(Auth, Home, Image, Member, Onboarding, Profile)의 테스트 타깃은 `Project.swift`에서 주석 처리돼 있어요. `Tests/Sources/Empty.swift`만 있어요.
- `DSKitTests`, `RxLabTests`는 타깃만 있고 테스트가 없어요.
- **Feature와 CollectionViewAdapter 테스트는 CI에서 실행하지 않아요.** 해당 모듈을 바꿨다면 로컬에서 실행하고 결과를 PR의 `🔥 추가 설명`에 적어요.

## 로컬에서 실행해요

### 1. 준비

```bash
mise exec -- tuist install
mise exec -- tuist generate --no-open
```

- 비대화형 셸이나 에이전트 환경에서는 PATH의 다른 Tuist 버전이 실행될 수 있어요. `mise exec -- tuist version`이 `4.115.0`인지 확인해요.
- `Projects/Shared/Configs/Shared.xcconfig`가 있어야 빌드돼요. `.gitignore` 대상이며 CI는 `SHARED_XCCONFIG` secret으로 만들어요. 로컬 파일이 없으면 팀에 요청해요.

### 2. 시뮬레이터 ID를 확인해요

```bash
xcrun simctl list devices available
```

CI와 같은 방식으로 찾으려면 `scripts/resolve_simulator_udid.sh`를 사용해요. 이 스크립트는 `SIMULATOR_NAME`, `SIMULATOR_OS`, `GITHUB_ENV` 환경 변수가 필요해요. 로컬 사용법은 스크립트 상단 주석에 있어요.

### 3. 외부 의존이 없는 스킴을 테스트해요

```bash
xcodebuild test \
  -workspace Haruhancut.xcworkspace \
  -scheme HomeFeatureV2 \
  -configuration Debug \
  -destination "id=<SIMULATOR_UDID>" \
  -derivedDataPath DerivedData
```

| 스킴 | 로컬 확인 (2026-09-30, Xcode 26.4, iPhone 16 Pro Max / iOS 26.0) |
| --- | --- |
| `Core` | 8개 테스트 통과 |
| `HomeFeatureV2` | 9개 테스트 통과 |
| `CollectionViewAdapter` | 40개 테스트 통과 |
| `MemberFeatureV2` | 9개 테스트 통과 |
| `ProfileFeatureV2` | 3개 테스트 통과 |
| `AdminFeature` | 5개 테스트 통과 |

과거 PR에서는 같은 스킴을 `tuist test <스킴>`으로도 실행했어요. (예: PR #80의 `tuist test HomeFeatureV2`, PR #76의 `tuist test CollectionViewAdapter`) 이 경우에도 `mise exec -- tuist test <스킴>`으로 버전을 맞춰요.

### 4. App·Data 테스트는 실행 전에 확인해요

`App`과 `Data` 스킴은 실제 Firebase 프로젝트에 연결해요. 특히 `AppUITests`는 테스트 사용자(`UITestID.User.userId`) 그룹의 게시물과 Storage 이미지를 **삭제**한 뒤 시작해요.

- AI 에이전트는 사용자 확인 없이 로컬에서 `App`·`Data` 스킴 테스트를 실행하지 않아요. PR CI의 `Test / App`, `Test / Data` 결과로 확인해요.
- 앱 빌드만 확인하려면 테스트 없이 빌드해요. PR #80에서 사용한 명령이에요.

```bash
xcodebuild build \
  -workspace Haruhancut.xcworkspace \
  -scheme App \
  -configuration Debug \
  -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO
```

### 5. 스크립트 테스트

의존성 업데이트 스크립트(`scripts/update_ios_dependencies.py`)를 바꿨다면 실행해요.

```bash
python3 -m unittest scripts/tests/test_update_ios_dependencies.py
```

로컬 확인: 9개 테스트 통과 (2026-09-30)

### 사용하지 않는 실행 방법

| 명령 | 사용하지 않는 이유 |
| --- | --- |
| `make test` | Xcode·Simulator를 종료하고 `sudo rm`, 이전 경로에 `sudo chown`을 실행해요. 마지막 `tuist test CoreTests`는 스킴이 아니라 타깃 이름이에요. |
| `scripts/run-tests.sh` | 시뮬레이터 이름(`iphone 16 Pro Max`)과 iOS 18.5 조건이 현재 환경과 맞지 않아요. CI에서도 쓰지 않아요. |
| `local-build.sh` | `sudo xcode-select`, `xcpretty`가 필요하고 iOS 18.5를 가정해요. `tuist test App`에 UI 테스트가 포함돼 실제 Firebase 데이터를 지워요. |

## CI에서 검증해요

### `build-and-test.yml`

| 항목 | 내용 |
| --- | --- |
| 실행 조건 | `main` 대상 PR, 매일 07:00 KST(`0 22 * * *`), 수동 실행, PR 댓글 명령 |
| 동시 실행 | 같은 PR의 이전 실행을 취소해요. |
| 매트릭스 | `module: [Core, Data, App]`, `fail-fast: false` |
| 단계 | `Shared.xcconfig` 생성 → Xcode 26.3 선택 → SwiftPM·Tuist·DerivedData 캐시 복원 → `tuist install` → `tuist generate --no-open` → `scripts/resolve_simulator_udid.sh` → `xcodebuild build-for-testing` → `xcodebuild test-without-building` |
| 캐시 키 | `Tuist/Package.swift`, `Tuist/Package.resolved`, `Projects/**/Project.swift` 등의 해시. 의존성이 바뀌면 캐시를 새로 만들어요. |
| 결과 알림 | PR 댓글과 메일 |

CI의 테스트 명령은 모듈마다 다음과 같아요.

```bash
xcodebuild build-for-testing -workspace Haruhancut.xcworkspace -scheme <Core|Data|App> -configuration Debug -destination "id=$SIM_UDID" -derivedDataPath DerivedData
xcodebuild test-without-building -workspace Haruhancut.xcworkspace -scheme <Core|Data|App> -configuration Debug -destination "id=$SIM_UDID" -derivedDataPath DerivedData
```

### PR 댓글로 다시 실행해요

PR에 `/하루한컷 빌드하고 테스트` 댓글을 달면 `pr-command.yml`이 PR 브랜치에서 `build-and-test.yml`을 다시 실행해요. 확인 댓글에 표시되는 기기 정보(iOS 18.5 iPhone 16 Pro Max)는 실제 CI 환경(iPhone 16 / iOS 26.2)과 달라요.

## UI 테스트

`AppUITests.test_home_upload_and_delete_flow`가 홈 화면의 사진 업로드와 삭제 흐름을 검증해요.

| 항목 | 내용 |
| --- | --- |
| launch argument | `-UITest`, `-AppleLanguages (ko)`, `-AppleLocale ko_KR` |
| launch environment | `TEST_USER_UID = UITestID.User.userId` |
| 앱 준비 | `SceneDelegate+UITests.swift`(DEBUG 전용)가 세션을 비우고 `bootstrapUserSession(uid:)`로 테스트 사용자를 불러온 뒤 `resetPostsForUITests()`로 게시물을 지워요. 준비가 끝나야 `AppCoordinator`를 시작해요. |
| 데이터 초기화 | Realtime Database의 `groups/{groupId}/postsByDate`와 Storage의 `groups/{groupId}/images/{postId}.jpg`를 삭제해요. |
| `-UITest` 분기 | 온보딩과 Firebase 로그인 확인을 건너뛰고(`AppCoordinator`), 사진 선택 대신 테스트 이미지를 넣어요(`HomeV2Coordinator`). |
| 접근성 ID | `Projects/Core/Sources/UITestID.swift` |
| 시스템 알림 | `UIInterruptionMonitor`가 허용·확인 버튼을 눌러요. |

Firebase 에뮬레이터는 사용하지 않아요.

## 테스트를 작성해요

- 테스트 대상은 생성자에 Stub을 넣어 직접 만들어요. `DIContainer`에 등록하지 않아요. 자세한 내용은 [DI Container](../architecture/dicontainer.md#교체-demo와-테스트)를 확인해요.
- Session은 `UserDefaultsStorageProtocol`을 따르는 메모리 저장소로 만들어요. (예: `Core/Tests/Sources/Mocks/FakeUserDefaultsStorage.swift`)
- 테스트 대역은 테스트 파일 안에 `private` 타입으로 두는 경우가 많아요. 이름은 `Fake*`, `*Stub`, `Test*`, `Dummy*`가 섞여 있어요.
- 테스트 대상 생성은 `makeSUT(...)` 헬퍼로 모아요. (예: `FCMTokenSyncTests`)
- `Single`은 `async throws` 테스트에서 `try await single.value`로 기다려요. `Observable` 출력은 `XCTestExpectation`과 `DisposeBag`으로 확인해요.
- 테스트 메서드 이름은 `testCamelCase`가 많고, Core와 UI 테스트는 `test_snake_case`를 사용해요. 같은 파일 안에서는 한 가지로 맞춰요.
- 기존 Input/Output 화면은 `transform(input:)`에 테스트용 `Observable`을 넣고 Output을 `XCTestExpectation`으로 확인해요.

### Reactor 테스트

ReactorKit이 새 화면의 기본 규칙이므로 Reactor 테스트를 기본으로 작성해요.

- 계산 로직은 `static func`으로 분리해 순수 함수로 테스트해요. 현재 `FeedUploadStateTests`가 `FeedReactor.didTodayUpload`, `makeComponents`를 이 방식으로 테스트해요.
- 상태 흐름은 Stub Usecase를 생성자로 넣은 Reactor에 `reactor.action.onNext(...)`를 보내고 `reactor.currentState`를 확인해요. **(새 규칙)** Stub이 `.just(...)`처럼 동기적으로 끝나면 바로 확인할 수 있고, 비동기라면 `reactor.state`를 `XCTestExpectation`으로 기다려요.
- 낙관적 갱신은 실패 Stub으로 이전 상태로 돌아오는지 확인해요. (예: `FeedReactor.deletePost`)
- ViewController 표시만 확인하려면 `reactor.isStubEnabled = true`로 두고 `reactor.stub.state.accept(State(...))`로 상태를 넣어요. **(새 규칙)**
- `@Dependency` 프로퍼티를 가진 Reactor(`FeedReactor`)는 생성 전에 `DIContainer.shared` 등록이 필요해요. 새 Reactor는 생성자 주입으로 만들어 이 준비를 없애요.

## 변경 후 확인

- 수정한 모듈의 테스트를 실행하고 명령과 결과(테스트 수)를 PR에 적어요.
- CI 필수 체크(`Test / App`, `Test / Core`, `Test / Data`)가 모두 통과했는지 확인해요.
- 자동 테스트로 확인하기 어려운 동작은 Demo 앱(`<X>FeatureDemo`)이나 실기기에서 재현 단계와 결과를 적어요.
- 실행하지 못한 테스트는 통과했다고 적지 않고, 이유와 남은 검증을 표시해요.
