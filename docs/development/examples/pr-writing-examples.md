---
title: 변경 규모에 맞춘 PR 작성 예시
description: 하루한컷 PR 템플릿을 유지하면서 문서·CI 수정, 버그 수정, 모듈 구조 변경에 필요한 설명과 검증을 고르는 예시다.
---

# Haruhancut 변경 규모에 맞춘 PR 작성 예시

PR에는 리뷰어가 변경 이유와 결과를 판단할 정보를 적는다. 하루한컷 PR은 `.github/PULL_REQUEST_TEMPLATE.md`의 섹션과 순서를 유지하고, 본문 문장은 합쇼체(`-습니다`)로 쓴다. 제목·본문 형식은 [Git 작업 흐름](../gitflow.md#7-pr을-만들어요)을 따른다.

아래 예시는 실제 PR(#80, #88, #95)의 구조를 참고해 줄였다. 새 PR에서는 현재 diff와 실행 결과로 내용을 바꾸고, 예시의 성공 문구를 그대로 복사하지 않는다.

## 템플릿 섹션을 채우는 기준

| 섹션 | 채우는 내용 | 생략·대체 방법 |
| --- | --- | --- |
| `💡 PR 유형` | 해당 유형에 `x` | 항목을 지우지 않고 체크만 한다. |
| `✏️ 변경 사항` | 바뀐 동작과 이유. 이번 PR에서 하지 않은 범위 | 파일 목록이나 커밋 순서를 옮기지 않는다. |
| `🚨 관련 이슈` | `- Closes #<이슈 번호>` | 이슈 없는 PR은 만들지 않는다. |
| `🎨 스크린샷` | UI 변경 GIF·이미지 | `UI 변경 없음. <작업 종류> 작업입니다.` |
| `✅ 체크리스트` | 실제로 확인한 항목만 체크 | 확인하지 않은 항목은 비워 둔다. |
| `🔥 추가 설명` | 검증 명령과 결과, 남은 검증, 제외한 로컬 변경, 필요하면 `### 원인` | 추가 정보가 없으면 검증만 적는다. |

## 작은 CI·문서 수정은 변경 이유와 검증만 적는다

상황: 의존성 업데이트 워크플로가 Simulator UUID를 잘못 추출해 `SIM_UDID`에 디바이스 행 전체가 들어갔다. 정규식의 중복 이스케이프를 제거했다.

제목: `[#87] 의존성 업데이트 워크플로우의 Simulator UUID 추출 오류 수정`

```markdown
## ✏️ 변경 사항

- Simulator UUID 추출식의 중복 이스케이프를 제거해 `SIM_UDID`에 UUID만 저장하도록 수정했습니다.
- `sed -nE`를 사용해 정규식이 일치하지 않을 때 디바이스 원본 행이 출력되지 않도록 했습니다.

## 🚨 관련 이슈

- Closes #87

## 🎨 스크린샷

해당 없음. GitHub Actions 자동화 작업입니다.

## 🔥 추가 설명

- CI 로그의 Simulator 행을 입력해 UUID만 출력되는 것을 확인했습니다.
- `python3 -m unittest scripts/tests/test_update_ios_dependencies.py`를 실행했습니다. (9 tests passed)
- 실제 Simulator 빌드·테스트는 PR CI에서 확인이 필요합니다.
```

변경 이유·결과·검증이 모두 있다. 로컬에서 확인한 범위와 CI에서 확인할 범위를 나눠 적었다. 실행하지 않은 iOS 테스트를 통과했다고 쓰지 않는다.

## 버그 수정은 발생 조건, 원인, 바뀐 동작을 설명한다

상황: 가족 중 한 명만 오늘 사진을 올려도 모든 구성원에게 `오늘 사진 추가 완료`가 표시되고 카메라 버튼이 비활성화됐다.

제목: `[#79] 가족 사진이 개인의 오늘 업로드 완료 상태로 처리되는 문제`

```markdown
## ✏️ 변경 사항

- 가족 전체의 오늘 피드와 현재 사용자의 오늘 업로드 상태를 분리했습니다.
- 현재 사용자의 `userId`와 일치하는 오늘 사진이 있을 때만 완료 문구를 표시하고 카메라 버튼을 비활성화합니다.
- 게시물 삭제가 실패하면 개인 업로드 상태도 이전 값으로 복원합니다.
- 가족만 업로드한 경우, 본인만 업로드한 경우, 함께 업로드한 경우의 회귀 테스트를 추가했습니다.

## 🔥 추가 설명

### 원인

`FeedReactor`가 가족 전체의 오늘 게시물로 `components`를 만들고, `FeedViewController`가 `components.isEmpty`를 개인의 업로드 완료 여부로 사용했습니다.

### 검증

- `tuist test HomeFeatureV2`: 7개 테스트 통과
- `xcodebuild build -workspace Haruhancut.xcworkspace -scheme App -configuration Debug -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO`: App 빌드 성공
```

`isEmpty 조건 변경`처럼 diff에 보이는 항목을 나열하지 않고 발생 조건과 결과를 연결했다. 실패 시 복원은 리뷰어가 확인할 동작이므로 생략하지 않는다. 원인은 `🔥 추가 설명` 아래 소제목으로 둔다.

## 모듈·구조 변경은 포함하지 않은 범위와 후속 작업을 남긴다

상황: `Projects/Shared/Fetcher` 모듈의 뼈대와 테스트 타깃을 추가했다. 기존 UseCase 이전은 같은 Draft PR에서 이어서 진행한다.

제목: `[#94] Fetcher로 Remote와 Local 데이터 조회 정책을 통합한다`

```markdown
## ✏️ 변경 사항

- `Projects/Shared/Fetcher`에 독립적인 Fetcher 프레임워크 모듈을 추가했습니다.
- Remote/Local 조회 흐름을 RxSwift로 구성하도록 `RxSwift`를 직접 의존합니다.
- `FetcherTests` 타깃과 공유 `Fetcher` 스킴을 추가했습니다.
- 이번 커밋에는 Domain 의존성 연결과 기존 UseCase 이전을 포함하지 않았습니다.

## 🔥 추가 설명

- `tuist generate --no-open` 성공
- Fetcher 스킴 iOS Simulator Debug 빌드 성공
- 로컬의 `FeedComponent.swift` 미커밋 변경은 커밋과 PR에서 제외했습니다.
- Auth/Group UseCase 이전은 이 Draft PR에서 계속 진행합니다.
```

모듈 추가는 Tuist 그래프와 스킴에 영향을 주므로 `tuist generate` 결과를 남긴다. 아직 하지 않은 작업을 적어 두면 리뷰어가 Draft 상태의 범위를 판단할 수 있다. 여러 영역에 걸친 큰 변경(예: PR #72의 FCM 토큰 동기화)은 `문제와 원인` 표나 처리 순서 다이어그램을 `🔥 추가 설명`에 더할 수 있지만, 템플릿 섹션 자체는 지우지 않는다.

## 검증 결과가 없으면 그대로 밝힌다

`테스트 완료`, `문제없음`, `기존 동작 유지`는 근거 없이 쓰지 않는다. 문서만 바꿨다면 `검증: git diff --check와 상대 링크 대상 파일 존재를 확인했습니다.`처럼 실제 확인한 내용을 쓴다. 필수 체크(`Test / App`, `Test / Core`, `Test / Data`)를 로컬에서 실행하지 못했다면 CI에서 확인한다고 적는다.

게시하기 전에는 다음을 확인한다.

- `✏️ 변경 사항` 첫 항목에서 무엇이 왜 달라지는지 알 수 있는가?
- 같은 사실을 제목·변경 사항·추가 설명에서 반복하지 않는가?
- 조건·호환성·검증 한계를 줄이는 과정에서 숨기지 않았는가?
- 실제 diff와 검증 결과에 없는 주장을 추가하지 않았는가?
- `Summary by CodeRabbit` 블록은 CodeRabbit이 붙이므로 직접 작성하지 않았는가?

## 관련 문서

- [한국어 윤문 원칙](../korean-editing.md): 작업 범위와 정보 구성 기준
- [문서 윤문 예시](korean-editing-examples.md): 문장의 주체·조건을 보존하는 전후 비교
- [Git 작업 흐름](../gitflow.md): 이슈·브랜치·커밋·PR 규칙
- [AI 작성 표기 규칙](../ai-attribution.md): 커밋·PR의 자동 출처 표기 제외
