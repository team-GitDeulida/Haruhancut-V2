// swift-tools-version: 6.0
import PackageDescription

#if TUIST
    import struct ProjectDescription.PackageSettings

    let packageSettings = PackageSettings(
        // Customize the product types for specific package product
        // Default is .staticFramework
        // productTypes: ["Alamofire": .framework,]
        // productTypes: [
        //     "RxSwift": .framework,
        //     "RxCocoa": .framework,
        //     "RxRelay": .framework,
        //     "Lottie": .framework,
        //     "ScaleKit": .framework,
        // ]

        // productTypes: 이 SPM product를 Xcode에서 어떤 Mach-O 타입으로 빌드할까?
        // - 즉 어떻게 링크할 지 강제한다
        // - 여기 넣으면 워크스페이스 전역에서 (dynamic or static)으로 빌드해 준다는 말

        // Dynamic Framework
        // - 코드가 바이너리 밖에 따로 존재
        // - 여러 타깃이 같은 코드 사본을 공유
        // - 런타임 로딩 발생
        // - UIKit / Obj-C runtime 영향 받음

        // Static Framework
        // - 각 타깃 바이너리에 코드 복사됨
        // - 여러 모듈에서 쓰면 중복 포함
        // - name mangling / demangle 문제 발생 가능
        // - Firebase를 dynamic로하면 터지는 현상 발생하여 staticFramework으로 지정하였음

        // 여기에 설정되지 않은 파일들은 기본 SPM 규칙으로 돌아간다
        // - 기본 SPM 규칙: 필요한 타깃에서만 해당 product를 링크한다

        // 그래서 안에 뭐를 넣느냐: 
        // - Core / Feature / App / Tests 전부 사용하는 타입이 바뀌면 위험한 라이브러리
        // - Static으로 쓰면 위험한 라이브러리
        
        // 그래서 안에 뭐를 안넣느냐:
        // - UIKit / App lifecycle 전제 라이브러리
        // - RxCocoa, SnapKit, Lottie, Kingfisher
        productTypes: [
            // Rx → runtime 안정성
            "RxSwift": .framework,
            "RxRelay": .framework,
            "RxKakaoSDK": .framework,

            // firebase
            "FirebaseCore": .staticFramework,
            "FirebaseMessaging": .staticFramework,
            "FirebaseAuth": .staticFramework,
            "FirebaseDatabase": .staticFramework,
            "FirebaseStorage": .staticFramework,

            // 기타 → 단순 라이브러리
            "Lottie": .framework,
            "Kingfisher": .framework,
            "ScaleKit": .framework,
        ]

    )
#endif

let package = Package(
    name: "Haruhancut",
    dependencies: [
        // Add your own dependencies here:
        // .package(url: "https://github.com/Alamofire/Alamofire", from: "5.0.0"),
        // You can read more about dependencies here: https://docs.tuist.io/documentation/tuist/dependencies
        .package(
            url: "https://github.com/ReactiveX/RxSwift.git",
            from: "6.9.0"
        ),
        .package(
            url: "https://github.com/airbnb/lottie-ios.git",
            from: "4.6.0"
        ),

        .package(
            url: "https://github.com/kakao/kakao-ios-sdk.git",
            from: "2.27.1"
        ),

        .package(
            url: "https://github.com/kakao/kakao-ios-sdk-rx.git",
            from: "2.27.1"
        ),

        .package(
            url: "https://github.com/firebase/firebase-ios-sdk.git",
            from: "11.14.0"
        ),

        .package(
            url: "https://github.com/indextrown/ScaleKit.git",
            from: "1.1.3"
        ),

        .package(
            url: "https://github.com/onevcat/Kingfisher.git",
            from: "8.6.2"
        )
    ]

)