import PackageDescription

let package = Package(name: "SimpleStorage",
                      platforms: [.iOS(.v9)],
                      products: [.library(name: "SimpleStorage",
                                          targets: ["SimpleStorage"])],
                      targets: [.target(name: "SimpleStorage",
                                        path: "SimpleStorage"),
                                .testTarget(name: "SimpleStorageTests",
                                            dependencies: ["SimpleStorage"],
                                            path: "SimpleStorageTests")],
                      swiftLanguageVersions: [.v5])
