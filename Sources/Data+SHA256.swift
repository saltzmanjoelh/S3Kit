//
//  Data+CommonCrypto.swift
//  S3V4Signer
//
//  Created by Joel Saltzman on 9/17/16.
//
//

import Foundation
#if os(macOS)
    import CCommonCrypto
//#elseif os(Linux)
//    import OpenSSL
//    typealias CC_SHA256_DIGEST_LENGTH = SHA256_DIGEST_LENGTH
#endif

// SHA-256 digest as a hex string
public func sha256_hexdigest(_ data : Data) -> String {
    
    
    #if os(macOS)
        var bytes = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        _ = data.withUnsafeBytes{
            CC_SHA256($0, CC_LONG(data.count), &bytes)
        }
        //TODO: implement linux version
//    #elseif os(Linux)
//        let shaContext = UnsafeMutablePointer<SHA256_CTX>.allocate(capacity: 1)//(allocatingCapacity: 1)
//        SHA256_Init(shaContext)
//        _ = data.withUnsafeBytes{
//            SHA256_Update(shaContext, $0, data.count)
//        }
//        
//        var bytes = [UInt8](repeating: 0, count: Int(SHA256_DIGEST_LENGTH))
//        SHA256_Final(&bytes, shaContext)
//        shaContext.deallocate(capacity: 1)
    #endif
    
    let hash = NSMutableString()
    for byte in bytes {
        hash.appendFormat("%02x", byte)
    }
    
    return hash as String

}

