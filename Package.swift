import PackageDescription

#if os(macOS)
let package = Package(
    name: "S3V4Signer",
    dependencies: [
        .Package(url: "https://github.com/saltzmanjoelh/CCommonCrypto.git", versions: Version(0,0,0)..<Version(10,0,0))
    ]
)

//#elseif os(Linux)
//let package = Package(
//    name: "S3V4Signer",
//    dependencies: [
//        .Package(url: "https://github.com/saltzmanjoelh/OpenSSL.git", versions: Version(0,0,0)..<Version(10,0,0))
//    ]
//)
    
#endif
//  https://github.com/csexton/csexton.github.com/blob/master/_posts/2016-03-20-signing-aws-api-requests-in-swift.md
