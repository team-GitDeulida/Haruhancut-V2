# iOS external dependency updater

이 워크플로는 하루한컷의 직접 Swift Package 의존성을 확인하고, 검증에 성공한 변경만 Pull Request로 만든다. Firebase Functions와 npm 의존성은 다루지 않는다.

## 실행

- 자동 실행: 매주 월요일 오전 9시(KST)
- 수동 실행: Actions에서 iOS External Dependency Updater를 선택한 뒤 Run workflow를 실행한다.
- dry-run: 수동 실행에서 dry_run을 선택한다. 후보와 제외 사유만 Job Summary에 남기며 파일, 브랜치, PR을 만들지 않는다.

## 업데이트 범위

- 대상은 Tuist/Package.swift의 .package(url: ..., from: ...) 직접 의존성이다.
- Package.resolved는 Tuist가 실제로 고정한 버전 목록이다. 스크립트가 안전한 후보를 선택하면 Package.swift의 하한 버전을 갱신하고, tuist install이 Package.resolved를 다시 만든다.
- 일반 패키지는 같은 major 안의 patch/minor만 자동 반영한다.
- Firebase iOS SDK와 Kakao SDK는 patch만 자동 반영한다.
- major, prerelease, 안정 SemVer 태그를 찾을 수 없는 패키지, 직접 선언되지 않은 전이 의존성은 제외한다.

## PR 생성 조건

변경이 있을 때만 아래 검증을 실행한다.

1. tuist install
2. tuist generate --no-open
3. Core, Data, App의 xcodebuild build-for-testing 및 test-without-building

하나라도 실패하면 workflow는 실패하고 PR을 만들지 않는다. 통과하면 chore(deps): update external dependencies 제목과 dependencies 라벨로 하나의 PR을 생성하거나 기존 updater PR을 갱신한다. 자동 병합과 자동 배포는 하지 않는다.

## 실패 대응

- Git 태그 조회 실패는 안전하지 않은 부분 갱신을 막기 위해 workflow를 실패시킨다. 실행 로그의 version-lookup-failed 항목을 확인한다.
- 버전 표기가 X.Y.Z 또는 vX.Y.Z가 아니면 해당 패키지는 no-stable-semver-tags로 보고하고 건너뛴다.
- iOS 빌드·테스트 실패는 updater PR을 만들지 않는다. CI 로그에서 실패한 모듈을 확인하고, 필요하면 해당 패키지를 patch 전용 목록에 추가하거나 수동으로 업데이트한다.

## GitHub 설정

저장소 Settings → Actions → General → Workflow permissions에서 GitHub Actions에 읽기·쓰기 권한과 Pull Request 생성 권한을 허용해야 한다. 워크플로는 updater 브랜치 push, PR 생성, dependencies 라벨 적용을 위해 contents: write, pull-requests: write, issues: write를 사용한다.
