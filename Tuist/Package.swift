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
        "Nuke": .framework
    ]
)
#endif

let package = Package(
    name: "Calendar",
    dependencies: [
        .package(url: "https://github.com/Infomaniak/ios-core", .upToNextMajor(from: "18.12.0")),
        .package(url: "https://github.com/Infomaniak/ios-core-ui", .upToNextMajor(from: "25.0.0")),
        .package(url: "https://github.com/Infomaniak/ios-core-uikit", .upToNextMajor(from: "1.0.0")),
        .package(url: "https://github.com/Infomaniak/ios-create-account", .upToNextMajor(from: "24.0.1")),
        .package(url: "https://github.com/Infomaniak/ios-dependency-injection", .upToNextMajor(from: "2.0.6")),
        .package(url: "https://github.com/Infomaniak/ios-device-check", .upToNextMajor(from: "1.1.1")),
        .package(url: "https://github.com/Infomaniak/ios-features", .upToNextMajor(from: "9.0.0")),
        .package(url: "https://github.com/Infomaniak/ios-login", .upToNextMajor(from: "7.8.0"))
    ]
)
