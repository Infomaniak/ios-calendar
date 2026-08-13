/*
 Infomaniak Calendar - iOS App
 Copyright (C) 2026 Infomaniak Network SA

 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import Foundation
import ProjectDescription
import ProjectDescriptionHelpers

let onboardingView = Feature(
    name: "OnboardingView",
    additionalDependencies: [
        TargetDependency.target(name: "\(Constants.projectName)Resources"),
        TargetDependency.external(name: "InfomaniakCore"),
        TargetDependency.external(name: "InfomaniakCoreSwiftUI"),
        TargetDependency.external(name: "InfomaniakDeviceCheck"),
        TargetDependency.external(name: "InfomaniakLogin"),
        TargetDependency.external(name: "InfomaniakOnboarding"),
        TargetDependency.external(name: "InterAppLogin"),
        TargetDependency.external(name: "InfomaniakCreateAccount")
    ]
)

let preloadingView = Feature(
    name: "PreloadingView",
    additionalDependencies: [
        TargetDependency.external(name: "DesignSystem"),
        TargetDependency.external(name: "InfomaniakCore"),
        TargetDependency.external(name: "InfomaniakCoreCommonUI"),
        TargetDependency.external(name: "InfomaniakCoreSwiftUI"),
        TargetDependency.external(name: "InfomaniakDI")
    ]
)

let eventDetailsView = Feature(
    name: "EventDetailsView",
    additionalDependencies: [
        TargetDependency.target(name: "\(Constants.projectName)Resources"),
        TargetDependency.external(name: "DesignSystem"),
        TargetDependency.external(name: "ESDSCalendar"),
        TargetDependency.external(name: "InfomaniakCoreSwiftUI"),
        TargetDependency.external(name: "InfomaniakDI")
    ]
)

let calendarView = Feature(
    name: "CalendarView",
    additionalDependencies: [
        eventDetailsView,
        TargetDependency.target(name: "\(Constants.projectName)Resources"),
        TargetDependency.external(name: "DesignSystem"),
        TargetDependency.external(name: "InfomaniakDI"),
        TargetDependency.external(name: "ESDSCalendar")
    ]
)

let createEditEventView = Feature(name: "CreateEditEventView", additionalDependencies: [])

let settingsView = Feature(name: "SettingsView", additionalDependencies: [])

let calendarListView = Feature(
    name: "CalendarListView",
    additionalDependencies: [
        settingsView,
        TargetDependency.target(name: "CalendarResources"),
        TargetDependency.external(name: "ESDSFoundation"),
        TargetDependency.external(name: "InfomaniakDI"),
        TargetDependency.external(name: "InfomaniakCoreSwiftUI")
    ]
)

let mainView = Feature(
    name: "MainView",
    additionalDependencies: [
        calendarView,
        createEditEventView,
        eventDetailsView,
        calendarListView,
        settingsView,
        TargetDependency.target(name: "CalendarResources"),
        TargetDependency.external(name: "InfomaniakDI")
    ]
)

let rootView = Feature(
    name: "RootView",
    additionalDependencies: [
        onboardingView,
        preloadingView,
        mainView,
        TargetDependency.external(name: "InfomaniakDI")
    ]
)

let mainiOSAppFeatures = [
    onboardingView,
    preloadingView,
    calendarView,
    createEditEventView,
    eventDetailsView,
    calendarListView,
    settingsView,
    mainView,
    rootView
]

let project = Project(
    name: Constants.projectName,
    options: .options(developmentRegion: "en"),
    targets: mainiOSAppFeatures.asTargets + [
        .target(
            name: Constants.projectName,
            destinations: .iOS,
            product: .app,
            bundleId: Constants.baseIdentifier,
            deploymentTargets: Constants.deploymentTarget,
            infoPlist: "\(Constants.projectName)/Resources/Info.plist",
            resources: [
                "\(Constants.projectName)/Resources/LaunchScreen.storyboard",
                "\(Constants.projectName)/Resources/Assets.xcassets",
                "\(Constants.projectName)/Resources/PrivacyInfo.xcprivacy",
                "\(Constants.projectName)/Resources/Localizable/**/InfoPlist.strings",
                "\(Constants.projectName)/Resources/AppIcon.icon/**"
            ],
            buildableFolders: [
                .folder("\(Constants.projectName)/Sources")
            ],
            entitlements: "\(Constants.projectName)/Resources/\(Constants.projectName).entitlements",
            scripts: [
                Constants.swiftlintScript,
                Constants.stripSymbolsScript
            ],
            dependencies: [
                .target(name: "\(Constants.projectName)Core"),
                .target(name: "\(Constants.projectName)CoreUI"),
                .target(name: "\(Constants.projectName)Resources"),
                rootView.asDependency,
                .external(name: "InfomaniakCore"),
                .external(name: "InfomaniakCoreSwiftUI"),
                .external(name: "InfomaniakDI"),
                .external(name: "InfomaniakLogin"),
                .external(name: "InterAppLogin"),
                .external(name: "InfomaniakCreateAccount"),
                .external(name: "ESDSCalendar")
            ],
            settings: .settings(base: Constants.baseSettings),
            environmentVariables: [
                "hostname": .environmentVariable(value: "\(ProcessInfo.processInfo.hostName).", isEnabled: true)
            ]
        ),
        .target(name: "\(Constants.projectName)Core",
                destinations: Constants.destinations,
                product: Constants.productTypeBasedOnEnv,
                bundleId: "\(Constants.baseIdentifier).core",
                deploymentTargets: Constants.deploymentTarget,
                infoPlist: .default,
                buildableFolders: [
                    .folder("\(Constants.projectName)Core/")
                ],
                dependencies: [
                    .target(name: "\(Constants.projectName)Resources"),
                    .external(name: "MultiplatformCalendar"),
                    .external(name: "DeviceAssociation"),
                    .external(name: "InfomaniakCore"),
                    .external(name: "InfomaniakDI"),
                    .external(name: "InfomaniakDeviceCheck"),
                    .external(name: "InfomaniakLogin"),
                    .external(name: "InterAppLogin")
                ],
                settings: .settings(base: Constants.baseSettings)),
        .target(name: "\(Constants.projectName)CoreUI",
                destinations: Constants.destinations,
                product: Constants.productTypeBasedOnEnv,
                bundleId: "\(Constants.baseIdentifier).coreui",
                deploymentTargets: Constants.deploymentTarget,
                infoPlist: .default,
                buildableFolders: [
                    .folder("\(Constants.projectName)CoreUI/")
                ],
                dependencies: [
                    .target(name: "\(Constants.projectName)Core"),
                    .target(name: "\(Constants.projectName)Resources"),
                    .external(name: "ESDSFoundation"),
                    .external(name: "InfomaniakCore"),
                    .external(name: "InfomaniakCoreSwiftUI"),
                    .external(name: "InfomaniakDI"),
                    .external(name: "NukeUI")
                ],
                settings: .settings(base: Constants.baseSettings)),
        .target(name: "\(Constants.projectName)Resources",
                destinations: Constants.destinations,
                product: Constants.productTypeBasedOnEnv,
                bundleId: "\(Constants.baseIdentifier).resources",
                deploymentTargets: Constants.deploymentTarget,
                infoPlist: .default,
                resources: [
                    "\(Constants.projectName)Resources/**/*.xcassets",
                    "\(Constants.projectName)Resources/**/*.strings",
                    "\(Constants.projectName)Resources/**/*.stringsdict",
                    "\(Constants.projectName)Resources/**/*.json"
                ],
                settings: .settings(base: Constants.baseSettings)),
        .target(
            name: "\(Constants.projectName)Tests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "\(Constants.baseIdentifier).tests",
            infoPlist: .default,
            buildableFolders: [
                .folder("\(Constants.projectName)Tests")
            ],
            dependencies: [.target(name: Constants.projectName)]
        ),
        .target(
            name: "\(Constants.projectName)UITests",
            destinations: .iOS,
            product: .uiTests,
            bundleId: "\(Constants.baseIdentifier).uitests",
            infoPlist: .default,
            buildableFolders: [
                .folder("\(Constants.projectName)UITests")
            ],
            dependencies: [.target(name: Constants.projectName)]
        )
    ],
    fileHeaderTemplate: .file("file-header-template.txt")
)
