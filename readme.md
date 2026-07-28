<div align=center>

## 하루한컷

### **하루의 순간을 사진으로 담아 가족에게 전해보세요**

하루한컷은 가족과 하루에 한 장씩 사진을 공유하며  
서로의 하루를 기록하는 사진 기록 앱입니다.

</div>

<!--![haruhancut-ezgif com-video-to-gif-converter](https://github.com/user-attachments/assets/3f0cebad-14d3-4e97-bff8-806bcc449dcb)
-->

![1](https://github.com/user-attachments/assets/096330e8-4836-41d3-9eac-97b1c70e15ea)
<br/>
<br/>

# 주요 화면 소개

| ![0](https://github.com/user-attachments/assets/38e83972-f0e2-4b44-94c8-fdc3075fa7b9) | ![1](https://github.com/user-attachments/assets/6eb4b901-fe7e-4575-a8bc-563b5fa21979) | ![2](https://github.com/user-attachments/assets/2cf2e03b-3843-45e3-bac3-05f31d95d5b3) | ![3](https://github.com/user-attachments/assets/2fd851ff-9099-4f52-a4ea-17cf58d6eeff) | ![4](https://github.com/user-attachments/assets/280285e1-f14a-4112-85d2-7dceb162e349) | ![5](https://github.com/user-attachments/assets/2cb6dc19-f8b2-4523-9fbc-9f3efb74246e) |
| :-----------------------------------------------------------------------------------: | :-----------------------------------------------------------------------------------: | :-----------------------------------------------------------------------------------: | :-----------------------------------------------------------------------------------: | :-----------------------------------------------------------------------------------: | :-----------------------------------------------------------------------------------: |
|                                      로그인 화면                                      |                                        홈 화면                                        |                                      포스팅 화면                                      |                                       댓글 화면                                       |                                      캘린더 화면                                      |                                      프로필 화면                                      |

</br><br/>

<!-- https://github.com/user-attachments/assets/55cffead-89ec-4126-9e74-c6af316c31e5 -->

<!--1. 하루에 한 장 사진 업로드-->
<!--2. 캘린더 기반 사진 아카이브-->
<!--3. 사진에 댓글로 하루의 이야기 공유-->
<!--4. 우리 가족만의 프라이빗 공간-->

# 1. 기능 소개

1. 하루에 단 한 장 사진 업로드 📸
2. 캘린더로 날짜별 사진 아카이브 확인 🗓️
3. 사진에 댓글을 남겨 하루의 이야기 공유 💬
4. 가족·연인·지인과만 소통하는 프라이빗 그룹 👨‍👩‍👧‍👦

</br><br/>

# 2. 기술 스택

|     library     |                           description                           |
| :-------------: | :-------------------------------------------------------------: |
| **FirebaseSDK** |    FCM을 이용한 푸쉬 알림 및 사용자 인증/데이터 관리를 위함     |
|   **RxSwift**   | 비동기 흐름을 선언적으로 관리하고 이벤트 기반 로직 처리를 위함  |
|  **WidgetKit**  | 앱을 열지 않아도 위젯으로 오늘 업로드된 사진을 확인할 수 있도록 구현 |
|  **KakaoSDK**   |                 카카오 소셜 로그인 구현을 위함                  |
|  **GoogleSDK**  |                  구글 소셜 로그인 구현을 위함                   |
| **Kingfisher**  |             이미지 캐싱 처리 및 UI 성능 개선을 위함             |

</br><br/>

# 3. 핵심 성과

### **1. 제네릭 기반 Firebase CRUD + 실시간 Observe 추상화**

> **문제**  
> Firebase Realtime Database를 사용할 때 엔티티마다
> JSON 직렬화/역직렬화, 단건 조회, 부분 수정, 삭제, 실시간 구독 로직이 반복되어
> Repository 계층이 쉽게 비대해지는 문제가 있었습니다.
>
> **해결**  
> `Encodable / Decodable` 기반 제네릭 CRUD 메서드와
> `observeValueStream(path:type:)` 실시간 구독 인터페이스를 공통화해
> 모든 엔티티가 같은 방식으로 Firebase에 접근하도록 정리했습니다.
>
> **성과**  
> 🔸 단건 조회 / 저장 / 수정 / 삭제 / 실시간 감지를 하나의 패턴으로 통일  
> 🔸 신규 DTO 추가 시 Firebase 접근 코드를 거의 복붙 없이 확장 가능  
> 🔸 Feature / Repository 레이어가 비즈니스 로직에 집중할 수 있는 구조 확보

```swift
// 공통 Firebase 인터페이스
func setValue<T: Encodable>(path: String, value: T) -> Single<Void>
func readValue<T: Decodable>(path: String, type: T.Type) -> Single<T>
func updateValue<T: Encodable>(path: String, value: T) -> Single<Void>
func deleteValue(path: String) -> Single<Void>
func observeValueStream<T: Decodable>(path: String, type: T.Type) -> Observable<T>

// Usecase / Repository 에서는 경로와 타입만 정의하면 재사용 가능
func observeValueStream<T: Decodable>(path: String, type: T.Type) -> Observable<T> {
    return groupRepository.observeValueStream(path: path, type: type)
}
```

---

### **2. WidgetKit + App Group + FileManager 기반 위젯 동기화 구조 설계**

> **문제**  
> 위젯은 앱과 다른 프로세스/샌드박스에서 실행되기 때문에
> 앱 메모리나 일반 로컬 상태를 직접 참조할 수 없습니다.
> 특히 "가족 그룹의 오늘 최신 사진 1장"을 홈 화면 위젯에 안정적으로 노출하려면
> 앱과 위젯이 공통으로 읽을 수 있는 데이터 전달 경로가 필요했습니다.
>
> **해결**  
> `App Group + FileManager` 기반 공유 컨테이너 구조를 설계했습니다.
>
> 1. 앱에서 현재 유저 세션을 `Session/user.json`으로 저장
> 2. 오늘 최신 게시글 이미지를 `Photos/<groupId>/<yyyy-MM-dd>/<timestamp>-<postId>.jpg` 형식으로 저장
> 3. 저장 전에 다운샘플링 + 리사이즈 + JPEG 압축을 적용해 위젯 메모리 사용량을 절감
> 4. 위젯 Provider는 `user.json`에서 groupId를 읽고, 오늘 폴더의 파일 중 가장 최신 1장만 로드
> 5. 홈 실시간 데이터가 바뀌면 `WidgetCenter.reloadTimelines`로 즉시 위젯 갱신
> 6. 게시글 삭제 시 동일 `postId`를 가진 파일도 함께 정리
>
> **성과**  
> 🔸 앱과 위젯의 프로세스 분리 문제를 App Group 공유 파일 시스템으로 해결  
> 🔸 위젯 전용 경량 이미지 파이프라인으로 메모리 부담과 로딩 실패 가능성 완화  
> 🔸 앱을 열지 않아도 홈 화면에서 "우리 그룹의 오늘 사진"을 바로 확인 가능

```swift
public enum WidgetSessionStore {
    private static func sessionFile() -> URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: WidgetPaths.appGroupId)?
            .appendingPathComponent("Session", isDirectory: true)
            .appendingPathComponent("user.json")
    }
}

public static func photosFolder(groupId: String, dateKey: String) -> URL? {
    FileManager.default
        .containerURL(forSecurityApplicationGroupIdentifier: appGroupId)?
        .appendingPathComponent("Photos", isDirectory: true)
        .appendingPathComponent(groupId, isDirectory: true)
        .appendingPathComponent(dateKey, isDirectory: true)
}

guard let latest = files.sorted(by: {
    $0.lastPathComponent > $1.lastPathComponent
}).first else { return nil }
```

---

### **3. Tuist 기반 멀티 모듈 구조로 앱/위젯/공용 코드 경계 분리**

> **문제**  
> 기능이 늘어날수록 앱 타깃 하나에 인증, 홈, 프로필, 위젯, 공용 유틸이 함께 섞이면
> 의존성 경계가 흐려지고 빌드 구성 관리와 책임 분리가 어려워집니다.
>
> **해결**  
> `Tuist` 워크스페이스를 기준으로
> `App / Coordinator / Features / Core / Domain / Shared / Widget` 모듈을 분리하고,
> 위젯 전용 공유 로직은 `WidgetSupport` 모듈로 별도 관리했습니다.
>
> **성과**  
> 🔸 앱 본체와 위젯이 필요한 코드만 선택적으로 의존하는 구조 확보  
> 🔸 기능 추가 시 수정 범위를 모듈 단위로 제한해 변경 영향도 파악이 쉬워짐  
> 🔸 공용 코드와 기능 코드를 분리해 프로젝트 구조를 더 명확하게 정리

```swift
let workspace = Workspace(
    name: "Haruhancut",
    projects: [
        "Projects/App",
        "Projects/Widget/*",
        "Projects/Coordinator",
        "Projects/Features/*",
        "Projects/Domain",
        "Projects/Core",
        "Projects/Shared/*"
    ]
)

dependencies: [
    .project(target: "Coordinator", path: "../Coordinator"),
    .project(target: "Data", path: "../Data"),
    .project(target: "WidgetSupport", path: "../Shared/WidgetSupport"),
    .project(target: "HaruhancutWidget", path: "../Widget/HaruhancutWidget")
]
```

---

### **4. Component + Section DSL 기반 Collection View 화면 구성 표준화**

> **문제**
>
> UIKit으로 Collection View 화면을 만들 때마다 Cell과 Header/Footer 등록,
> Data Source 타입 분기, Section별 Layout 구성이 반복됐습니다.
> Diffable Snapshot 갱신과 이벤트 연결까지 ViewController가 맡으면서
> 화면이 복잡해질수록 구체적인 Cell 타입과 상태 갱신 로직이 ViewController에 모였습니다.
> Section을 추가하거나 같은 UI를 다른 화면에서 재사용할 때 수정 범위도 커졌습니다.
>
> **해결**
>
> 반복되는 Collection View 구성 책임을 `CollectionViewAdapter` 공용 모듈로 옮겼습니다.
>
> - `Component`는 `Identifiable & Equatable` Item과 `UIView`의 생성·렌더링 규칙을 연결합니다.
> - `SectionModels`는 Header/Footer와 세로 목록, Grid, 가로 Carousel을 선언합니다.
> - `CollectionViewAdapter`는 generic container 등록, Compositional Layout,
>   stable identity 기반 Snapshot, 재사용 생명주기, Prefetch/Pagination을 관리합니다.
>
> Content는 `Touchable`, `Pressable`, `LongPressable`, `ContainsButton`,
> `ContainsSwitch` 중 필요한 capability만 채택하고, 각 상호작용은 modifier로 연결합니다.
> Component가 SwiftUI `View`도 채택하면 같은 UI를 SwiftUI에서 바로 재사용할 수 있습니다.
>
> **성과**
>
> 🔸 ViewController에서 반복되던 Cell 등록과 Data Source 타입 분기 제거<br>
> 🔸 세로 목록, Grid, 가로 Carousel을 같은 Section DSL로 선언<br>
> 🔸 Snapshot 갱신, 재사용, 이벤트, Prefetch, Pagination을 Adapter에서 관리<br>
> 🔸 같은 Component를 UIKit과 SwiftUI에서 재사용

#### CollectionViewAdapter 사용 예제

Demo 앱의 `ReadmeCapture` Section은 주요 사용 방식을 비교하는 네 가지
예제로 구성됩니다. 앞의 세 화면은 `LazySection`과
`CollectionViewAdapter`로 서로 다른 Section layout을 구성하고, 마지막
화면은 `View`를 채택한 Component를 SwiftUI에서 직접 사용합니다.

##### Vertical

가장 단순한 단일 Section 세로 목록입니다. 각 모델을
`AccountRowComponent`로 변환하고 `.verticalList`로 위에서 아래로
배치합니다.

<table>
<tr><th>Source</th><th>Result</th></tr>
<tr>
<td width="65%">

```swift
import CollectionViewAdapter
import UIKit

let sections = SectionModels {
    LazySection(identifier: "accounts") {
        For(of: accounts) { account in
            AccountRowComponent(item: account)
        }
    }
    .withSectionLayout(
        .verticalList(spacing: 10)
    )
}

adapter.bind(sections)
```

</td>
<td width="35%" align="center">

<img width="280" alt="CollectionViewAdapter vertical example" src="Projects/Shared/CollectionViewAdapter/docs/images/readme/vertical.png">

</td>
</tr>
</table>

##### Grid

카드 Component를 별도의 Cell subclass 없이 2열 Grid로 배치합니다.
열 수, Item 간격, 행 간격과 바깥 여백은 Section layout이 담당합니다.

<table>
<tr><th>Source</th><th>Result</th></tr>
<tr>
<td width="65%">

```swift
let sections = SectionModels {
    LazySection(identifier: "cards") {
        For(of: cards) { item in
            PhotoCardComponent(item: item)
        }
    }
    .withSectionLayout(
        .grid(
            columns: 2,
            estimatedRowHeight: 178,
            interItemSpacing: 12,
            lineSpacing: 12,
            contentInsets: .init(
                top: 20,
                leading: 20,
                bottom: 24,
                trailing: 20
            )
        )
    )
}

adapter.bind(sections)
```

</td>
<td width="35%" align="center">

<img width="280" alt="CollectionViewAdapter grid example" src="Projects/Shared/CollectionViewAdapter/docs/images/readme/grid.png">

</td>
</tr>
</table>

##### Horizontal + Vertical

한 Collection View 안에서 Section마다 서로 다른 스크롤 방향을 선언할 수
있습니다. 첫 번째 Section은 가로 Carousel로 움직이고, 두 번째 Section은
일반 세로 목록으로 이어집니다.

<table>
<tr><th>Source</th><th>Result</th></tr>
<tr>
<td width="65%">

```swift
let sections = SectionModels {
    LazySection(identifier: "featured") {
        For(of: featured) { item in
            PhotoCardComponent(item: item)
        }
    }
    .withHeader(
        TitleComponent(title: "Horizontal")
    )
    .withSectionLayout(
        .horizontalCarousel(
            itemWidth: 0.72,
            estimatedHeight: 178,
            spacing: 12,
            behavior: .continuousGroupLeadingBoundary,
            contentInsets: .init(
                top: 8,
                leading: 20,
                bottom: 24,
                trailing: 20
            )
        )
    )

    LazySection(identifier: "accounts") {
        For(of: accounts) { account in
            AccountRowComponent(item: account)
        }
    }
    .withHeader(
        TitleComponent(title: "Vertical")
    )
    .withSectionLayout(
        .verticalList(
            spacing: 10,
            contentInsets: .init(
                top: 8,
                leading: 20,
                bottom: 24,
                trailing: 20
            )
        )
    )
}

adapter.bind(sections)
```

</td>
<td width="35%" align="center">

<img width="280" alt="CollectionViewAdapter horizontal and vertical sections example" src="Projects/Shared/CollectionViewAdapter/docs/images/readme/mixed-sections.png">

</td>
</tr>
</table>

Section마다 독립적인 `CollectionSectionLayout`을 가지므로 가로 Section의
orthogonal scrolling과 화면 전체의 세로 스크롤을 한 Adapter에서 함께
처리할 수 있습니다.

##### Component를 SwiftUI에서 바로 사용하기

`Component`가 SwiftUI `View`도 함께 채택하면 Component 자체를 SwiftUI
View hierarchy에 바로 배치할 수 있습니다. 모듈이 기본 `body`를 제공하므로
별도의 `ComponentView` wrapper를 호출할 필요가 없습니다.

<table>
<tr><th>Source</th><th>Result</th></tr>
<tr>
<td width="65%">

```swift
import CollectionViewAdapter
import SwiftUI

struct AccountRowComponent: Component, View {
    let item: Account

    func createContent() -> AccountContentView {
        AccountContentView()
    }

    func render(
        context: ComponentContext,
        content: AccountContentView
    ) {
        content.configure(with: item)
    }
}

struct AccountStack: View {
    let accounts: [Account]

    var body: some View {
        VStack(spacing: 10) {
            ForEach(accounts) { account in
                AccountRowComponent(item: account)
                    .frame(height: 84)
            }
        }
    }
}
```

</td>
<td width="35%" align="center">

<img width="280" alt="Component used directly as a SwiftUI View" src="Projects/Shared/CollectionViewAdapter/docs/images/readme/swiftui-component.png">

</td>
</tr>
</table>

Collection View에서 사용할 때는 같은 Component를 `LazySection`에 넣고,
SwiftUI에서는 `VStack`, `ForEach` 같은 View 구성 안에 직접 넣습니다.
두 환경 모두 같은 `createContent`와 `render` 계약을 사용합니다.

[CollectionViewAdapter의 구조와 예제 자세히 보기](Projects/Shared/CollectionViewAdapter/README.md)
