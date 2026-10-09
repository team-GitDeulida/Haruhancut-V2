# Haruhancut 작업 안내

> 하루한컷은 Tuist 모듈형 UIKit 앱이에요(App · Coordinator · Features · Domain · Data · Core · Shared). 아래 문서는 실제 코드와 GitHub 이력을 분석해 정리했어요. `확인 필요` 항목은 팀 합의 전까지 규칙으로 확정하지 마세요.

## 작업 전에 확인할 문서

| 확인할 내용 | 문서 | 확인 기준 |
| --- | --- | --- |
| 프로젝트 소개와 핵심 성과 | `readme.md` | 제품 소개 문서예요. 빌드·테스트 방법은 [테스트](docs/development/testing.md)를 확인해요. |
| 모듈과 의존성 | [아키텍처](docs/architecture/architecture.md) | 모듈을 추가하거나 의존성을 바꾸면 모듈 표를 갱신해요. |
| 의존성 등록과 주입 | [DI Container](docs/architecture/dicontainer.md) | `DIContainer.shared` 등록은 `AppDelegate+Dependency.swift`에서만 하고, Feature Demo 등록도 함께 맞춰요. |
| 화면 패턴 (ReactorKit 기본) | [View·Reactor·ViewModel 계약](docs/architecture/view-viewmodel-protocols.md) | 새 화면은 ReactorKit으로 작성해요. 기존 Input/Output 화면은 유지하고, 전환은 한 화면씩 `🔨 refactor` 이슈로 진행해요. |
| 목록·화면 그리기 | [화면 그리기](docs/architecture/view-rendering.md) | 목록·반복 UI는 CollectionViewAdapter로 그리고, Reactor State에는 Component가 아니라 모델·표시 값을 둬요. |
| Swift 코드 작성 규칙 | [Swift 스타일](docs/development/swiftstyle.md) | 기존 파일은 그 파일의 스타일(A·B)을 유지해요. |
| 테스트 타깃과 실행 명령 | [테스트](docs/development/testing.md) | App 테스트와 UI 테스트는 실제 Firebase를 사용하니 사용자 확인 없이 로컬에서 실행하지 않아요. |
| 한국어 문서 윤문 | [한국어 윤문 원칙](docs/development/korean-editing.md) · [문서 윤문 예시](docs/development/examples/korean-editing-examples.md) | 독자의 목적과 작업 범위를 정하고 원문의 의미·사실·보호 구간을 유지한다. |
| PR 제목·본문 작성 | [한국어 윤문 원칙](docs/development/korean-editing.md) · [PR 작성 예시](docs/development/examples/pr-writing-examples.md) | PR 템플릿 섹션을 유지하고 본문은 합쇼체(`-습니다`)로 쓴다. 변경 규모에 맞는 이유·결과·검증만 적는다. |
| 이슈·브랜치·커밋·PR 규칙 | [Git 작업 흐름](docs/development/gitflow.md) | 브랜치 `<유형>/#<이슈>`, 커밋 `<type>: 요약`, PR `[#<이슈>] 요약`, squash merge를 따라요. |
| 커밋·PR의 AI 작성 표기 | [AI 작성 표기 규칙](docs/development/ai-attribution.md) | AI 공동 작성자 트레일러와 생성 문구·세션 링크를 넣지 않아요. |
| RxSwift·RxCocoa·ReactorKit 사용 기준 | [RxSwift](docs/architecture/rxswift.md) · [바인딩 정책](docs/architecture/rxswift-binding-policy.md) · [Input/Output](docs/architecture/rxswift-input-output.md) | ReactorKit State는 조각별로 `Driver`로 표시하고, 일회성 이벤트는 `@Pulse`로 보내요. |

## 작업 중 판단 기준

| 상황 | 판단 기준 |
| --- | --- |
| 문서와 코드 또는 프로젝트 설정이 달라요. | 실제 코드와 프로젝트 설정을 기준으로 작업하고 관련 문서도 함께 고쳐요. |
| 아키텍처, 라이브러리, 빌드 명령이나 팀 정책을 확인하지 못했어요. | 단정하지 말고 `확인 필요`라고 표시해요. 확인할 파일이나 명령도 함께 적어요. |
| 구조나 실행 방법을 바꿨어요. | 변경한 동작을 설명하는 문서도 같은 작업에서 갱신해요. |
| 커밋 메시지나 PR 본문을 작성해요. | `Co-Authored-By: Claude` 같은 AI 공동 작성자 트레일러, `Generated with Claude Code` 같은 생성 문구와 AI 세션 링크를 넣지 않아요. 실제 사람의 기여 기록은 유지해요. |
| 이슈를 새로 만들어야 해요. | 사용자가 요청하거나 승인한 경우에만 만들어요. 라벨을 붙이고 Assignee를 지정하면 브랜치가 자동으로 생겨요. |
| `tuist` 명령을 실행해요. | 비대화형 셸에서는 `mise.toml`의 버전이 적용되지 않을 수 있어요. `mise exec -- tuist ...`로 실행해요. |
| push 전 코드 리뷰 git hook이 설정돼 있지 않아요. | `git config core.hooksPath`가 `.githooks`가 아니고 `git config project-docs.gitHooks`가 `declined`가 아니면, 작업을 시작할 때 사용자에게 설정할지 한 번 물어요. 승낙하면 `npx --yes --package=github:indextrown/codex-skillbook -- project-docs hooks ios-uikit --apply`를 실행해요. 거절하면 `git config project-docs.gitHooks declined`로 기록하고 다시 묻지 않아요. 동작은 [Git 작업 흐름](docs/development/gitflow.md#push-전-claude-코드-리뷰-hook을-설정할-수-있어요)을 따라요. |
| push했는데 git hook이 `FAIL`을 냈어요. | 지적된 문제를 고치고 다시 push해요. `git push --no-verify`는 사용자가 요청할 때만 써요. |

## 작업 완료 전 확인

- [ ] 변경한 동작과 관련 문서의 설명을 맞췄어요.
- [ ] 확인하지 못한 내용에는 `확인 필요`와 확인 대상을 남겼어요.
- [ ] 프로젝트에 맞는 테스트를 실행하고 결과를 기록했어요. CI에서 실행하지 않는 Feature 테스트는 로컬 결과를 PR에 적었어요.
- [ ] 커밋 메시지와 PR 본문에 AI 공동 작성자·생성 문구·세션 링크가 없는지 확인했어요.
