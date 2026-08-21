// swift-tools-version: 6.0
import PackageDescription

#if TUIST
import ProjectDescription

let packageSettings = PackageSettings(
    productTypes: [
        "DesignSystem": .framework,
        "DeviceAssociation": .framework,
        "ESDSCalendar": .framework,
        "InfomaniakCoreCommonUI": .framework,
        "InfomaniakCoreSwiftUI": .framework,
        "InfomaniakCoreUIKit": .framework,
        "InfomaniakCore": .framework,
        "InfomaniakCreateAccount": .framework,
        "InfomaniakDeviceCheck": .framework,
        "InfomaniakDI": .framework,
        "InfomaniakLogin": .framework,
        "InterAppLogin": .framework,
        "NukeUI": .framework,
        "Nuke": .framework,
        "_LottieStub": .framework
    ]
)
#endif

let package = Package(
    name: "Calendar",
    dependencies: [
        .package(url: "https://github.com/Infomaniak/InfiniteScrollViews", branch: "feat/custom-background-color"),
        .package(url: "https://github.com/Infomaniak/ios-core", .upToNextMajor(from: "19.0.0")),
        .package(url: "https://github.com/Infomaniak/ios-core-uikit", .upToNextMajor(from: "2.0.0")),
        .package(url: "https://github.com/Infomaniak/ios-core-ui", .upToNextMajor(from: "26.0.0")),
        .package(url: "https://github.com/Infomaniak/ios-create-account", .upToNextMajor(from: "25.0.0")),
        .package(url: "https://github.com/Infomaniak/ios-dependency-injection", .upToNextMajor(from: "2.0.6")),
        .package(url: "https://github.com/Infomaniak/ios-design-system.git", .upToNextMinor(from: "0.2.0")),
        .package(url: "https://github.com/Infomaniak/ios-device-check", .upToNextMajor(from: "1.1.1")),
        .package(url: "https://github.com/Infomaniak/ios-features", .upToNextMajor(from: "10.2.0")),
        .package(url: "https://github.com/Infomaniak/ios-login", .upToNextMajor(from: "7.8.0")),
        .package(url: "https://github.com/Infomaniak/ios-onboarding", .upToNextMajor(from: "1.1.2")),
        .package(url: "https://github.com/Infomaniak/multiplatform-calendar", .upToNextMajor(from: "0.6.0"))
    ]
)
