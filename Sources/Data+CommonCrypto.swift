//
//  Data+CommonCrypto.swift
//  S3V4Signer
//
//  Created by Joel Saltzman on 9/17/16.
//
//

import Foundation
import CCommonCrypto

// SHA-256 digest as a hex string
func sha256_hexdigest(_ data : Data) -> String {
    
    var bytes = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
    _ = data.withUnsafeBytes{
        CC_SHA256($0, CC_LONG(data.count), &bytes)
    }
    
    let hash = NSMutableString()
    for byte in bytes {
        hash.appendFormat("%02x", byte)
    }
    
    return hash as String
}
