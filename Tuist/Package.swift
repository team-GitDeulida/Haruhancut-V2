// swift-tools-version: 6.0
import PackageDescription

#if TUIST
    import struct ProjectDescription.PackageSettings

    let packageSettings = PackageSettings(
        // Customize the product types for specific package product
        // Default is .staticFramework
        // productTypes: ["Alamofire": .framework,]
        productTypes: [
            "RxSwift": .framework,
            "RxCocoa": .framework,
            "RxRelay": .framework,
            "Lottie": .framework,
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
