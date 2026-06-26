// swift-tools-version: 6.0
import PackageDescription

#if TUIST
import ProjectDescription

let packageSettings = PackageSettings(
    productTypes: [
        "DeviceAssociation": .framework,
        "InfomaniakCore": .framework,
        "InfomaniakCoreCommonUI": .framework,
        "InfomaniakCoreSwiftUI": .framework,
        "InfomaniakCoreUIKit": .framework,
        "InfomaniakCreateAccount": .framework,
        "InfomaniakDI": .framework,
        "InfomaniakDeviceCheck": .framework,
        "InfomaniakLogin": .framework,
        "InterAppLogin": .framework,
        "Nuke": .framework,
        "_LottieStub": .framework
    ]
)
#endif

let package = Package(
    name: "Calendar",
    dependencies: [
        .package(url: "https://github.com/Infomaniak/ios-core", .upToNextMajor(from: "19.0.0")),
        .package(url: "https://github.com/Infomaniak/ios-core-ui", .upToNextMajor(from: "26.0.0")),
        .package(url: "https://github.com/Infomaniak/ios-core-uikit", .upToNextMajor(from: "2.0.0")),
        .package(url: "https://github.com/Infomaniak/ios-create-account", .upToNextMajor(from: "25.0.0")),
        .package(url: "https://github.com/Infomaniak/ios-dependency-injection", .upToNextMajor(from: "2.0.6")),
        .package(url: "https://github.com/Infomaniak/ios-device-check", .upToNextMajor(from: "1.1.1")),
        .package(url: "https://github.com/Infomaniak/ios-features", .upToNextMajor(from: "10.0.0")),
        .package(url: "https://github.com/Infomaniak/ios-login", .upToNextMajor(from: "7.8.0")),
        .package(url: "https://github.com/Infomaniak/ios-onboarding", .upToNextMajor(from: "1.1.2")),
        .package(url: "https://github.com/Infomaniak/multiplatform-calendar", revision: "d378e880cd72129e5d7dc76635291787e7d7e80c")
    ]
)
