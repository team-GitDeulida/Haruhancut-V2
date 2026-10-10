# Haruhancut 시뮬레이터 메모리 줄이기

> 로컬에서 개발할 때 [simslim](https://github.com/MobAI-App/simslim)으로 시뮬레이터 안의 백그라운드 서비스를 꺼서 RAM 사용량을 줄여요. 선택 사항이에요. 바뀌는 것은 지정한 시뮬레이터의 서비스 설정뿐이고, Mac 본체와 CI에는 영향이 없어요.

## 요약

| 항목 | 값 | 근거 |
| --- | --- | --- |
| 도구 | simslim 0.12.2 (Homebrew) | `simslim version` |
| 프로필 | `scripts/simslim/dev.json`(평소 개발), `scripts/simslim/widget.json`(위젯 작업) | 2026-10-10에 simslim 0.12.2에서 형식 검사를 통과했어요. |
| 지원 런타임 | iOS 18.5 이상은 재부팅해도 설정이 유지돼요. 그보다 낮은 런타임은 부팅할 때마다 다시 적용해요. | simslim README |
| 기대 효과 | 모든 범주를 끄면 시뮬레이터 1대가 4.0GB에서 0.9GB로 줄었다고 해요(iOS 26.5). 우리 프로필은 일부 범주를 켜 두므로 덜 줄어요. | simslim README. 우리 프로필로 잰 값은 `확인 필요` |

simslim은 꺼도 안전하다고 확인된 서비스만 꺼요. 이 허용 목록은 15개 범주, 약 170개 서비스예요. 범주는 `simslim profiles`, 범주 안의 서비스는 `simslim profiles <범주>`로 확인해요.

## 프로필이 켜 두는 서비스

| 켜 두는 범주·서비스 | 필요한 앱 기능 | `dev.json` | `widget.json` |
| --- | --- | --- | --- |
| `photos` | 사진 선택 (`HomeV2Coordinator`·`ProfileCoordinatorV2`의 `UIImagePickerController`) | 켬 | 켬 |
| `icloud` | Apple 로그인 (`App.entitlements`의 `com.apple.developer.applesignin`) | 켬 | 켬 |
| `com.apple.apsd` | FCM 푸시 (`App.entitlements`의 `aps-environment`) | 켬 | 켬 |
| `widgets` | 홈 화면 위젯 (`HaruhancutWidget`) | 끔 | 켬 |

나머지 범주(Siri, Spotlight, 메일·캘린더, Safari 동기화, App Store·StoreKit 등)는 두 프로필 모두 꺼요. `widgets` 범주는 서비스가 4개뿐이지만 절감량이 가장 커요(README 기준 약 675MB). 그래서 평소에는 끄고, 위젯을 작업할 때만 `widget.json`으로 바꿔요.

## 설치해요

```bash
brew install mobai-app/tap/simslim
```

이미 설치했다면 최신 버전으로 올려요. 0.12.1보다 낮은 버전에서는 Spotlight 앱 메모리가 계속 늘어나요. 0.12.0보다 낮은 버전에서는 Xcode가 앱을 실행할 때마다 최대 10초를 기다려요.

```bash
brew upgrade simslim
```

## 처음 적용해요

명령은 저장소 루트에서 실행해요.

1. 개발에 쓸 시뮬레이터의 UDID를 확인해요. iOS 18.5 이상 런타임을 골라요.

   ```bash
   simslim list
   ```

2. (선택) 줄이기 전의 메모리를 재요. 부팅하고 1~2분 기다린 뒤 재야 값이 안정돼요.

   ```bash
   simslim boot <UDID>
   simslim measure <UDID>
   ```

3. 프로필을 적용해요. simslim이 시뮬레이터를 끄고 설정을 쓴 뒤 다시 켜요. 실행 중인 앱은 종료돼요.

   ```bash
   simslim on <UDID> --profile scripts/simslim/dev.json
   ```

4. 적용 결과를 확인해요.

   ```bash
   simslim verify <UDID> --profile scripts/simslim/dev.json
   simslim doctor <UDID> --requires push,photos,keychain-sync
   simslim measure <UDID>
   ```

   `verify`는 시뮬레이터 설정이 프로필과 정확히 같은지 확인해요. `doctor`는 앱에 필요한 푸시(`apsd`), 사진(`assetsd`), Apple 계정(`akd`) 서비스가 켜져 있는지 확인해요. 둘 다 문제가 있으면 0이 아닌 종료 코드로 끝나요.

## 예시 적용이에요

iPhone 17 (iOS 27.0) 시뮬레이터에 적용한 예시예요. 이 기기의 UDID는 `7AD2920B-36F6-4B7A-B3B9-14DEE96A5F74`예요. UDID는 시뮬레이터를 만들 때 정해져서 Mac마다 달라요. 내 Mac에서는 `simslim list`로 확인한 값으로 바꿔서 실행해요.

```bash
# 시뮬레이터 목록에서 UDID 확인
simslim list
# 7AD2920B-36F6-4B7A-B3B9-14DEE96A5F74  iPhone 17  iOS 27.0  shutdown

# 줄이기 전 메모리 측정 (부팅 후 1~2분 기다린 뒤)
simslim boot 7AD2920B-36F6-4B7A-B3B9-14DEE96A5F74
simslim measure 7AD2920B-36F6-4B7A-B3B9-14DEE96A5F74

# 평소 개발용 프로필 적용 (시뮬레이터가 꺼졌다가 다시 켜져요)
simslim on 7AD2920B-36F6-4B7A-B3B9-14DEE96A5F74 --profile scripts/simslim/dev.json

# 적용 결과 확인
simslim verify 7AD2920B-36F6-4B7A-B3B9-14DEE96A5F74 --profile scripts/simslim/dev.json
simslim doctor 7AD2920B-36F6-4B7A-B3B9-14DEE96A5F74 --requires push,photos,keychain-sync

# 줄인 후 메모리 측정 (1~2분 기다린 뒤)
simslim measure 7AD2920B-36F6-4B7A-B3B9-14DEE96A5F74
```

위젯을 작업할 때는 위젯용 프로필로 바꾸고, 작업이 끝나면 평소 개발용 프로필로 되돌려요.

```bash
# 위젯 작업용 프로필로 변경
simslim on 7AD2920B-36F6-4B7A-B3B9-14DEE96A5F74 --profile scripts/simslim/widget.json

# 평소 개발용 프로필로 복귀
simslim on 7AD2920B-36F6-4B7A-B3B9-14DEE96A5F74 --profile scripts/simslim/dev.json
```

시뮬레이터를 원래 상태로 되돌리려면 이렇게 해요.

```bash
simslim off 7AD2920B-36F6-4B7A-B3B9-14DEE96A5F74
```

## 평소에 써요

| 상황 | 할 일 |
| --- | --- |
| 개발 | Xcode에서 그 시뮬레이터를 골라 평소처럼 실행해요. 줄인 상태는 재부팅해도 유지돼요. |
| 위젯 작업 | `simslim on <UDID> --profile scripts/simslim/widget.json`으로 바꾸고, 끝나면 `dev.json`으로 되돌려요. 바꿀 때마다 재부팅해요. |
| 앱 기능이 동작하지 않아요. | 프로필의 `except`에 범주를, `keep`에 서비스 이름을 추가하고 `simslim on`을 다시 실행해요. 팀 모두에게 필요한 변경이면 프로필 파일을 고쳐 PR로 올려요. |
| RAM이 여전히 부족해요. | Xcode는 실행이 끝나도 시뮬레이터를 켜 둬요. 쓰지 않는 시뮬레이터는 `xcrun simctl shutdown all`로 꺼요. |
| 시뮬레이터를 초기화했거나 Xcode·런타임을 업데이트했어요. | 기본 상태로 돌아갈 수 있어요. `verify`가 실패하면 `simslim on`을 다시 실행해요. |
| iOS 18.5보다 낮은 런타임을 써요. | 설정이 재부팅 후 사라져서 `simslim on`이 거부돼요. 부팅할 때마다 `simslim on <UDID> --no-reboot --profile scripts/simslim/dev.json`을 실행해요. |
| 원래대로 되돌려요. | `simslim off <UDID>` |
| 메모리를 실시간으로 봐요. | `simslim top` |

## 동작 방식과 주의할 점

- simslim은 끌 서비스 목록을 시뮬레이터마다 저장해요. 시뮬레이터는 다음 부팅부터 그 서비스를 띄우지 않아요.
- 이 목록을 쓰는 위치는 Apple이 공개하지 않은 CoreSimulator 내부 동작이에요. 설정이 먹히지 않으면 simslim이 서비스를 하나씩 끄는 느린 방법으로 다시 적용하고, 부팅 후 결과를 읽어 확인해요.
- 줄어드는 것은 시뮬레이터 안의 서비스예요. Xcode와 Simulator 앱 자체의 메모리는 그대로예요.
- 두 프로필 모두 Spotlight 검색, Siri, App Store·StoreKit, 유니버설 링크(`swcd`), 연락처·캘린더 선택기를 꺼요. 앱에 이런 기능을 추가하면 프로필도 함께 고쳐요.

## 확인 필요

- `dev.json`을 적용한 시뮬레이터에서 카카오 로그인, Apple 로그인, 사진 업로드, 알림 권한 창이 동작하는지 아직 확인하지 않았어요. 확인할 대상: iOS 27.0 시뮬레이터에 `dev.json`을 적용하고 앱을 실행해요.
- 우리 프로필로 줄어든 메모리 값을 아직 재지 않았어요. 확인할 명령: [처음 적용해요](#처음-적용해요) 2단계와 4단계의 `simslim measure`.
- simslim의 범주별 메모리 수치는 iOS 26.5 기준이에요. iOS 27 런타임에는 허용 목록에 없는 새 서비스가 있을 수 있어요.
