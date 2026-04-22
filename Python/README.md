# Localization Generator

`Python/localizable.csv`를 기준으로 하루한컷 프로젝트의 iOS 로컬라이징 파일을 생성하는 스크립트입니다.

생성 대상:

- `Projects/Shared/DSKit/Resources/Localizing/en.lproj/Localizable.strings`
- `Projects/Shared/DSKit/Resources/Localizing/ko.lproj/Localizable.strings`
- `Projects/Shared/DSKit/Resources/Localizing/ja.lproj/Localizable.strings`
- `Projects/Shared/DSKit/Sources/Extensions+/LocalizationKey.swift`

현재 프로젝트는 문자열 키에 직접 `.localized()`를 붙여 사용할 수도 있고, 생성된 `LocalizationKey` enum을 통해 타입 안전하게 접근할 수도 있습니다.

# CSV 형식

`localizable.csv`는 아래 형식을 따릅니다.

```csv
key,en,ko,ja
common.next,Next,다음
auth.signin.apple,Continue with Apple,Apple로 계속하기
```

- `key`: 로컬라이제이션 키
- `en`, `ko`, `ja`: 각 언어 번역값

주의:

- 값 안에 쉼표(`,`)가 들어가면 CSV 규칙에 따라 큰따옴표로 감싸야 합니다.
- 줄바꿈은 실제 개행 대신 `\n` 문자열로 넣어야 `.strings` 파일과 동일하게 유지됩니다.

# 가상환경 설정

```bash
cd Python
python3 -m venv venv
source venv/bin/activate
```

# 라이브러리 설치

```bash
pip install -r requirements.txt
```

현재 스크립트는 표준 라이브러리만 사용하므로 추가 패키지는 필요하지 않습니다.

# 실행 방법

```bash
# 루트에서 실행
python3 Python/localization.py

# 또는 Python 폴더에서 실행
cd Python
python3 localization.py
```

# 동작 방식

1. `Python/localizable.csv`를 읽습니다.
2. `Projects/Shared/DSKit/Resources/Localizing` 아래의 `en.lproj`, `ko.lproj`, `ja.lproj`에 `Localizable.strings`를 생성합니다.
3. `Projects/Shared/DSKit/Sources/Extensions+/LocalizationKey.swift`를 생성합니다.
4. 기존 `.strings` 파일 상단의 주석 블록은 유지하고, 본문 번역 항목만 CSV 기준으로 갱신합니다.
