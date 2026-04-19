fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios beta

```sh
[bundle exec] fastlane ios beta
```

Push a new beta build to TestFlight using Fastlane Match

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).


# 사용법
```swift
// App Store Connect의 기존 메타데이터를 로컬로 내려받아 기본 구조를 만들어준다
fastlane deliver init

// 문구/스크린샷을 이미 App Store Connect에 올려둔 상태라면 필요할 때 다시 동기화
fastlane deliver download_metadata
fastlane deliver download_screenshots

// 메타데이터만 먼저 검증
fastlane precheck

// 앱 바이너리 없이 스토어 문구, 키워드, 설명, 스크린샷만 먼저 반영하고 싶을 때
fastlane deliver

// 릴리즈 빌드(ipa)까지 포함해서 업로드
fastlane deliver --ipa "App.ipa"

// 심사 제출까지 한번에
fastlane deliver --ipa "App.ipa" --submit_for_review
```

```swoft
// 바이너리 업로드 없이 텍스트만 App Store Connect에 올리고 싶을 때
fastlane deliver --skip_binary_upload true --skip_screenshots true

// 릴리즈 노트 포함해서 바이너리까지 같이 업로드
fastlane deliver --ipa "CodeLounge.ipa" --app_version "1.0.6"

// 심사 제출까지 같이: 웹에서 직접 제출 버튼 누르기까지 생략하고 싶으면
fastlane deliver \
  --ipa "CodeLounge.ipa" \
  --app_version "1.0.6" \
  --submit_for_review true
```