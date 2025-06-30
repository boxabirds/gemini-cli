// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Gemini",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .executable(name: "Gemini", targets: ["Gemini"])
    ],
    targets: [
        .executableTarget(
            name: "Gemini"
        )
    ]
)
