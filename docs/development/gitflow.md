# Haruhancut Git 작업 흐름

> 이슈 → 이슈 번호 브랜치 → 커밋 → PR → squash merge 순서로 작업해요. 아래 규칙은 `.github/` 설정, GitHub 저장소 설정, PR #47 이후의 이슈·브랜치·커밋·PR 이력을 확인해 정리했어요.

## 저장소 규칙 요약

| 항목 | 이 프로젝트의 규칙 | 근거 |
| --- | --- | --- |
| 기본 브랜치 | `main` | GitHub 저장소 설정 |
| 이슈 제목 | `[유형] 작업 요약` 또는 `[Tech Spec] 작업 요약` | 이슈 #67~#94 |
| 작업 브랜치 | `<유형>/#<이슈 번호>` (예: `fix/#90`, `docs/#92`) | `.github/issue-branch.yml` |
| 커밋 제목 | `<type>: 한국어 요약` (예: `fix: 의존성 변경 시 빌드 캐시 무효화`) | PR #58~#95의 브랜치 커밋 |
| PR 제목 | `[#<이슈 번호>] 작업 요약` (예: `[#90] 의존성 변경 시 CI 빌드 캐시를 무효화한다`) | PR #48~#95 |
| PR 본문 | `.github/PULL_REQUEST_TEMPLATE.md`의 섹션과 순서, 합쇼체(`-습니다`) | PR 템플릿, PR #80~#95 |
| 병합 방식 | Squash merge. `main`에는 `[#이슈] PR 제목 (#PR)` 한 줄이 남아요. | `main` 이력 |
| 병합 조건 | 필수 체크 `Test / App`, `Test / Core`, `Test / Data` 통과. 필수 승인 수는 0이에요. | `main` 브랜치 보호 규칙 |
| 자동 리뷰 | CodeRabbit이 한국어로 리뷰와 요약을 남겨요. | `.coderabbit.yaml` |

## 한 작업을 PR로 보내는 흐름

```text
이슈 생성·Assignee 지정 → 브랜치 자동 생성 → main 최신화·브랜치 전환 → 변경·검증 → 커밋 → push → PR 생성 → CI·리뷰 → squash merge → 브랜치 자동 삭제
```

한 브랜치와 한 PR에는 이슈 하나의 목적만 담아요.

### 1. 이슈를 만들어요

| 유형 | 라벨 | 브랜치 접두사 | 사용 시점 |
| --- | --- | --- | --- |
| `feature` | `✨ feature` | `feature/` | 새 기능이나 데모를 추가해요. |
| `fix` | `🔧 fix` | `fix/` | 일반 버그를 고쳐요. |
| `hotfix` | `🔥 hotfix` | `hotfix/` | 출시된 앱의 긴급 버그를 고쳐요. |
| `chore` | `⚙️ chore` | `chore/` | CI, 스크립트, 설정, 버전 변경 같은 기타 작업이에요. |
| `refactor` | `🔨 refactor` | `refactor/` | 동작을 유지하면서 구조를 개선해요. |
| `test` | `✅ test` | `test/` | 테스트 코드나 테스트용 스크립트를 작성해요. |
| `docs` | `📃 docs` | `docs/` | README, `docs/`, 템플릿 같은 문서를 수정해요. |

라벨 목록은 `.github/labels.json`에 있어요.

- 템플릿은 일반 작업용 `.github/ISSUE_TEMPLATE/issue.md`와 설계 검토용 `.github/ISSUE_TEMPLATE/tech-spec.md` 중에서 골라요.
- 제목은 `[fix] 로그인 및 알림 활성화 시 FCM 토큰을 동기화한다`처럼 `[유형]` 뒤에 작업 결과를 적어요. Tech Spec 이슈는 `[Tech Spec] ...`을 사용하고 작업 유형 라벨을 따로 붙여요.
- 이슈에는 반드시 위 표의 라벨을 하나 붙여요. 브랜치 접두사와 릴리스 노트 분류가 라벨로 정해져요.
- AI 에이전트는 사용자가 요청하거나 승인한 경우에만 이슈를 만들어요.

```bash
gh issue create \
  --title "[docs] Git 작업 흐름을 저장소 규칙에 맞춘다" \
  --label "📃 docs" \
  --assignee @me \
  --body-file /absolute/path/issue-body.md
```

### 2. 브랜치를 준비해요

이슈에 Assignee를 지정하면 `.github/workflows/issue-auto-branch.yml`이 `<라벨 접두사>#<이슈 번호>` 브랜치를 원격에 만들고 이슈에 댓글을 남겨요. 로컬에서는 기본 브랜치를 최신화한 뒤 같은 이름의 브랜치로 전환해요.

```bash
git status --short
git switch main
git pull --ff-only origin main
git fetch origin
git switch docs/#98
```

원격 브랜치가 아직 없거나 이미 로컬에서 작업을 시작했다면 같은 이름으로 직접 만들어요. 원격에 자동 생성된 브랜치가 뒤에 생겨도 이름이 같으므로 push할 때 연결돼요.

```bash
git switch -c docs/#98
```

`codex/fix/#71`처럼 도구 이름을 앞에 붙인 브랜치가 과거에 있었지만, PR #73 이후에는 `<유형>/#<이슈 번호>`만 사용해요. `automation/ios-dependency-updater`는 의존성 업데이트 워크플로(`.github/workflows/dependency-updater.yaml`) 전용 브랜치예요.

### 3. 변경과 검증 결과를 확인해요

```bash
git status --short
git diff
```

예상하지 못한 파일이 보이면 원인을 확인해요. 로컬에만 있는 다른 작업의 변경(예: 커밋하지 않은 `FeedComponent.swift`)은 이번 커밋과 PR에서 제외해요. 앱 코드나 문서를 바꿨다면 [테스트 문서](testing.md)에서 검증 명령을 확인하고, 실행하지 못한 검증도 PR에 적어요.

### 4. 커밋할 파일을 선택하고 확인해요

```bash
git add docs/development/gitflow.md
git diff --staged --stat
git diff --staged
```

이번 커밋에 필요한 경로만 추가해요. `git add .`이나 `git commit -a`를 기본 절차로 사용하지 않아요. `Derived/`, `DerivedData/`, `*.ipa`, `*.dSYM.zip`, `*.xcconfig`, `.env`, Firebase 서비스 계정 JSON은 `.gitignore` 대상이에요. 루트의 `graph.json`·`graph.png`처럼 ignore되지 않은 로컬 산출물도 커밋하지 않아요.

### 5. 커밋해요

커밋 제목은 `<type>: 한국어 요약` 형식이에요. 이슈 번호는 PR 제목에 넣고 커밋 제목에는 넣지 않아요.

| type | 사용 시점 | 이력의 예시 |
| --- | --- | --- |
| `feat` | 기능, 데모, 모듈 구현을 추가해요. | `feat: 프로필 이미지 프리패치 파이프라인 추가` |
| `fix` | 잘못된 동작을 고쳐요. | `fix: APNs 등록 후 FCM 토큰 동기화` |
| `refactor` | 동작을 유지하면서 구조를 바꿔요. | `refactor: modifier capability를 폴더별로 분리` |
| `test` | 테스트 코드나 테스트 스크립트를 추가·수정해요. | `test: FetcherTests 테스트코드 추가` |
| `docs` | 문서와 문서화 주석만 바꿔요. | `docs: Simulator UUID 스크립트 사용법 추가` |
| `chore` | 설정, 운영 스크립트, 버전, 파일 이동을 바꿔요. | `chore: 앱 및 알림 공지 버전을 1.1.2로 변경` |
| `ci` | GitHub Actions, fastlane 등 CI·배포 자동화를 바꿔요. | `ci: 최신 PR 커밋만 빌드하도록 동시 실행을 취소한다` |
| `build` | Tuist 프로젝트·모듈·의존성 구성을 바꿔요. | `build: add Fetcher module scaffold` |
| `style` | 개행·공백처럼 동작이 없는 코드 정리를 해요. | `style: FeedViewController 개행 정리` |

- 요약은 한국어로 쓰고 명사형(`~ 추가`, `~ 수정`, `~ 정리`)으로 끝내는 경우가 가장 많아요. `~한다`로 끝낸 커밋도 있으니 한 PR 안에서는 한 가지로 맞춰요.
- 코드 식별자와 모듈 이름은 원형 그대로 써요. (예: `FeedViewController`, `CollectionViewAdapter`)
- 한 커밋에는 하나의 논리적 변경만 담아요. 제목만으로 이유를 설명하기 어렵다면 본문을 추가해요.
- [AI 작성 표기 규칙](ai-attribution.md)에 따라 AI 공동 작성자 트레일러와 생성 문구를 넣지 않아요.

```bash
git diff --staged
git commit -m "docs: Git 작업 흐름을 저장소 규칙에 맞게 정리"
git log -1 --format=%B
```

### 6. push해요

```bash
git push -u origin docs/#98
```

#### push 전 Claude 코드 리뷰 hook을 설정할 수 있어요

프로젝트 문서 키트는 브랜치를 push하기 직전에 Claude Code의 `code-review` 스킬을 돌리는 `pre-push` hook을 선택해서 설치할 수 있어요. 개인 설정이라 `.githooks/`는 `.gitignore`에 넣고 커밋하지 않아요. 나중에 설정하려면 다음 명령을 실행해요.

```bash
npx --yes --package=github:indextrown/codex-skillbook -- project-docs hooks ios-uikit
```

| 항목 | 동작 |
| --- | --- |
| 설정하는 것 | `.githooks/pre-push`를 만들고, `git config core.hooksPath .githooks`를 설정하고, `.gitignore`에 `.githooks/`를 추가해요. |
| 리뷰 범위 | 첫 push와 강제 push는 기본 브랜치에서 갈라진 뒤의 전체 변경, 후속 push는 새로 올라가는 커밋만 리뷰해요. |
| 판정 | 정확성 버그·크래시·데이터 손실·보안 문제가 있으면 `FAIL`이고 push를 중단해요. 정리·스타일 제안은 막지 않아요. |
| 건너뛰는 경우 | 브랜치 삭제, 태그 push, 기본 브랜치 push, 변경이 없는 push |
| 설정값 | `CLAUDE_REVIEW_LEVEL`(기본 `medium`), `CLAUDE_REVIEW_TIMEOUT`(기본 900초) |
| 우회 | `git push --no-verify` (사용자가 요청할 때만 사용해요.) |
| 필요한 도구 | 로그인한 `claude` CLI, `jq`, `perl`. 없으면 리뷰가 필요한 push를 막아요. |
| 마지막 원본 출력 | 리뷰는 `.git/claude-review-last.json`, 판정은 `.git/claude-review-verdict.json` |
| 거절 기록 | 설정을 거절하면 `git config project-docs.gitHooks declined`로 남기고 다시 묻지 않아요. `hooks` 명령은 기록과 관계없이 실행돼요. |

이미 다른 hook 경로를 쓰거나 `.git/hooks`에 사용 중인 hook이 있으면 설정을 바꾸지 않아요. `core.hooksPath`를 바꾸면 `.git/hooks`가 더 이상 실행되지 않기 때문이에요. 한 번 push에 수십 초에서 몇 분이 걸리고 API 비용이 들어요.

### 7. PR을 만들어요

#### PR 제목

`[#<이슈 번호>] 작업 요약` 형식이에요. 요약은 보통 이슈 제목에서 `[유형]`을 뺀 문장을 그대로 사용해요. 최근 PR은 `~한다`로 끝내거나(`[#81] iOS 외부 의존성 업데이트 워크플로우를 추가한다`), 버그 PR은 문제를 명사형으로 적어요(`[#79] 가족 사진이 개인의 오늘 업로드 완료 상태로 처리되는 문제`).

PR #46 이전의 `[feat] ...` 형식은 더 이상 사용하지 않아요. squash merge 제목이 PR 제목이 되므로 `main` 이력을 생각하고 작성해요.

#### PR 본문

`.github/PULL_REQUEST_TEMPLATE.md`의 섹션과 순서를 유지하고, 새로 쓰는 문장은 합쇼체(`~했습니다`)로 써요.

| 섹션 | 작성 기준 |
| --- | --- |
| `## 💡 PR 유형` | 해당하는 유형 하나에 `x`를 표시해요. 여러 성격이 섞였다면 해당 항목을 모두 표시해요. |
| `## ✏️ 변경 사항` | 바뀐 동작과 이유를 목록으로 적어요. 이번 PR에서 하지 않은 일도 리뷰에 필요하면 적어요. |
| `## 🚨 관련 이슈` | `- Closes #<이슈 번호>`로 이슈를 연결해요. |
| `## 🎨 스크린샷` | UI가 바뀌면 GIF·이미지를 넣어요. 아니면 `UI 변경 없음. <작업 종류> 작업입니다.`처럼 적어요. |
| `## ✅ 체크리스트` | 실제로 확인한 항목만 체크해요. Assignees·Reviewers를 지정하지 않았다면 비워 둬요. |
| `## 🔥 추가 설명` | 실행한 검증 명령과 결과, CI에서 확인할 남은 검증, 커밋에서 제외한 로컬 변경을 적어요. 버그 수정은 `### 원인`, `### 검증` 소제목을 둘 수 있어요. |

분량은 변경 규모에 맞춰요. [한국어 윤문 원칙](korean-editing.md)과 [PR 작성 예시](examples/pr-writing-examples.md)를 참고해요.

#### PR 생성 명령

```bash
gh auth status
gh pr create \
  --base main \
  --head "docs/#98" \
  --title "[#98] 문서 키트를 하루한컷 코드베이스와 Git 컨벤션에 맞게 정리한다" \
  --label "📃 docs" \
  --body-file /absolute/path/pr-body.md
```

- PR에도 이슈와 같은 라벨을 붙여요. `.github/release-drafter.yml`과 `.github/release.yml`이 PR 라벨로 릴리스 노트를 분류해요. 분류 라벨이 없으면 기능·버그·개선 항목에 들어가지 않아요. (PR #80, #82, #84, #93, #95는 라벨 없이 병합·생성됐어요.)
- 작업이 이어지면 `--draft`로 만들고, 리뷰 준비가 끝나면 Ready for review로 바꿔요. (예: PR #95)
- `gh`가 없다면 임의로 설치하지 말고 사용자에게 설치 여부를 물어요.

### 8. CI와 리뷰를 확인해요

- PR을 열면 `.github/workflows/build-and-test.yml`이 App·Core·Data 테스트를 실행해요. 세 체크가 모두 통과해야 병합할 수 있어요.
- PR에 `/하루한컷 빌드하고 테스트` 댓글을 달면 `.github/workflows/pr-command.yml`이 같은 빌드·테스트를 다시 실행해요.
- CodeRabbit 리뷰는 한국어로 달리고, PR 본문 아래에 `Summary by CodeRabbit`을 자동으로 붙여요. 이 요약 블록은 직접 수정하지 않아요.

### 9. 병합하고 정리해요

- **Squash and merge**로 병합해요. 커밋 제목은 PR 제목에 `(#PR 번호)`가 붙은 형태로 맞추고(`[#90] 의존성 변경 시 CI 빌드 캐시를 무효화한다 (#91)`), 본문에는 브랜치 커밋 목록(`* fix: ...`)이 남아요.
- 커밋이 하나뿐인 PR은 GitHub가 커밋 제목을 기본값으로 제안해요. 병합할 때 PR 제목으로 바꿔요.
- 병합되면 `issue-auto-branch.yml`이 작업 브랜치를 원격에서 삭제하고, PR의 `Closes #N`이 이슈를 닫아요.

```bash
git switch main
git pull --ff-only origin main
git branch -d docs/#98
```

squash merge 뒤에는 로컬 브랜치가 병합되지 않은 것으로 보일 수 있어요. PR이 병합됐는지 확인한 뒤에만 `git branch -D`를 사용해요.

## 자동화가 만드는 PR

| 브랜치 | PR 제목 | 설명 |
| --- | --- | --- |
| `automation/ios-dependency-updater` | `chore(deps): update external dependencies` | 매주 월요일 의존성 업데이트 워크플로가 만들어요. 커밋 제목은 `chore: update iOS external dependencies`이고 `dependencies` 라벨이 붙어요. |

## 커밋·PR 전 체크리스트

- [ ] 브랜치 이름이 `<유형>/#<이슈 번호>`이고 대상 브랜치가 `main`이에요.
- [ ] stage한 파일이 모두 이번 이슈와 관련 있어요.
- [ ] 비밀값, 빌드 산출물, 다른 작업의 로컬 변경을 제외했어요.
- [ ] 커밋 제목이 `<type>: 한국어 요약`이고, PR 제목이 `[#<이슈 번호>] 요약`이에요.
- [ ] PR 본문이 템플릿 섹션을 유지하고 `Closes #<이슈 번호>`를 포함해요.
- [ ] PR에 이슈와 같은 라벨을 붙였어요.
- [ ] [AI 작성 표기 규칙](ai-attribution.md)에 따라 AI 공동 작성자·생성 문구·세션 링크를 제외했어요.
- [ ] 실행한 검증과 실행하지 못한 검증을 PR에 적었어요.

## 안전하게 작업해요

- `git reset --hard`, `git checkout -- <파일>`, `git restore <파일>`은 커밋하지 않은 변경을 잃게 할 수 있어요. 복구 대상을 확인하지 않고 실행하지 않아요.
- `main`에는 직접 push하지 않고 PR로 병합해요. 브랜치 보호 규칙이 강제 push와 삭제를 막아요. 관리자에게는 보호 규칙이 강제되지 않으니(`enforce_admins: false`) 직접 push하지 않도록 주의해요.
- Firebase 서비스 계정 JSON(`firebase/fcm/*firebase-adminsdk*.json`), `*.xcconfig`(`Projects/Shared/Configs/Shared.xcconfig` 포함), `.env`, 인증서·프로비저닝 파일을 커밋하지 않아요.
