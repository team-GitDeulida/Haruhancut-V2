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
|  **WidgetKit**  | 앱을 열지 안아도 위젯으로 업로드한 사진을 확인할 수 있도록 구현 |
|  **KakaoSDK**   |                 카카오 소셜 로그인 구현을 위함                  |
|  **GoogleSDK**  |                  구글 소셜 로그인 구현을 위함                   |
| **Kingfisher**  |             이미지 캐싱 처리 및 UI 성능 개선을 위함             |

</br><br/>

# 3. 핵심 성과

### **1. 제네릭 기반 Firebase CRUD 메서드 구현**

> **문제**  
> 엔티티마다 CRUD 함수가 요구되어 JSON 직렬화/역직렬화 로직이 엔티티마다 반복됨.
>
> **해결**  
> `Encodable / Decodable` 기반의 공통 제네릭 CRUD 메서드 구현
>
> **성과**  
> 🔸 **모든 엔티티 CRUD를 하나의 인터페이스로 통일**  
> 🔸 신규 엔티티 추가 시 모델만 만들면 즉시 CRUD 재사용 가능  
> 🔸 유지보수성 대폭 향상 (중복 코드 제거)

```swift
// 제네릭 CRUD
func setValue<T: Encodable>(path: String, value: T) -> Observable<Bool>
func readValue<T: Decodable>(path: String, type: T.Type) -> Observable<T>
func updateValue<T: Encodable>(path: String, value: T) -> Observable<Bool>
func deleteValue(path: String) -> Observable<Bool>

// Repository 예시 — 중복 없는 Firebase 호출
func fetchComments(groupId: String, postId: String) -> Observable<[CommentDTO]> {
    let path = "groups/\(groupId)/posts/\(postId)/comments"
    return firebase.readValue(path: path, type: [CommentDTO].self)
}
```

---

### **2. WidgetKit + App Group 기반 '오늘 최신 사진 1장을' 위젯에 노출**

> **문제**  
> 가족이 올린 "오늘 사진"을 앱 외부 위젯에서 다시 보여주기 위해
> 앱과 위젯 간 데이터를 공유할 수 있는 App Group 도입이 요구됨.  
> 위젯은 앱과 별도 프로세스에서 동작하고 서로의 샌드박스에 접근할 수 없기 때문에
> 앱이 보유한 피드 데이터를 직접 읽을 수 없는 문제 발생
>
> **해결**  
> App Group 공유 컨테이너를 활용하여 앱 -> 위젯으로 사진을 전달하는 파일 기반 데이터 구조 설계
>
> 1. 앱을 켜면 오늘 날짜 기준 가장 최신 1장을 추출
> 2. 해당 이미지를 App Group내부 Photos/<yyyy-MM-dd>/<timestamp>-<postId>.jpg 형태로 저장
>    3, 게시글 삭제 시 동일 postId를 포함한 파일 자동 삭제
> 3. 위젯 Provider는 오늘 날짜 폴더만 스캔하여 파일명 기준 최신 시간 1개 사진만 로딩
> 4. 이전 날짜 폴더는 자정에 자동 삭제되어 용량 안정성 확보
>
> **성과**  
> 🔸 앱을 열지 않아도 홈 화면에서 오늘 최신 사진 1장을 확인 가능  
> 🔸 App Group 기반 파일 공유 구조로 앱·위젯 프로세스 분리 문제를 시스템 레벨에서 해결

```swift
struct PhotoProvider: TimelineProvider {
    let appGroupID = "group.com.indextrown.Haruhancut.WidgetExtension"

    func getTimeline(in context: Context, completion: @escaping (Timeline<PhotoEntry>) -> Void) {
        let now = Date()

        // 1) 오늘 날짜 폴더에서 최신 이미지 로드
        let allFiles = fetchImageFiles(date: now)
        let latestData = allFiles
            .sorted { $0.lastPathComponent > $1.lastPathComponent }
            .first
            .flatMap { try? Data(contentsOf: $0) }

        // 2) 이전 날짜 폴더 정리
        deleteOldPhotoFolders(before: now)

        let entry = PhotoEntry(date: now, imageData: latestData)

        // 3) 다음 자정에 자동 갱신
        completion(Timeline(entries: [entry], policy: .after(computeNextMidnight(after: now))))
    }

    private func fetchImageFiles(date: Date) -> [URL] {
        let dateString = DateFormatter.photoFilenameFormatter.string(from: date)
        guard
            let folder = FileManager.default
                .containerURL(forSecurityApplicationGroupIdentifier: appGroupID)?
                .appendingPathComponent("Photos", isDirectory: true)
                .appendingPathComponent(dateString, isDirectory: true),
            let files = try? FileManager.default.contentsOfDirectory(at: folder,
                                                                     includingPropertiesForKeys: nil)
        else { return [] }

        return files.filter { $0.pathExtension.lowercased() == "jpg" }
    }
}
```
