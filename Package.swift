// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "VoiceToTextInput",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "VoiceToTextInput",
            targets: ["VoiceToTextInput"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "VoiceToTextInput",
            path: "Sources/VoiceToTextInput",
            linkerSettings: [
                .unsafeFlags([
                    "-Xlinker", "-sectcreate",
                    "-Xlinker", "__TEXT",
                    "-Xlinker", "__info_plist",
                    "-Xlinker", "Sources/Resources/Info.plist"
                ])
            ]
        ),
        .testTarget(
            name: "VoiceToTextInputTests",
            dependencies: ["VoiceToTextInput"],
            path: "Tests/VoiceToTextInputTests"
        )
    ]
)
