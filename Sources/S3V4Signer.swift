//
//  S3V4Signer.swift
//  S3V4Signer
//
//  Created by Joel Saltzman on 9/17/16.
//
//  https://github.com/csexton/csexton.github.com/blob/master/_posts/2016-03-20-signing-aws-api-requests-in-swift.md

import Foundation
#if os(macOS)
    import CCommonCrypto
//#elseif os(Linux)
//    import OpenSSL
#endif

public enum S3V4SignerError: Error {
    case invalidHost(host: URL)
    case invalidPath(path: URL)
}

public struct S3V4Signer {

    let accessKey: String
    let secretKey: String
    let regionName: String
    let serviceName: String

    public init(accessKey: String, secretKey: String, regionName: String, serviceName: String = "s3") {
        self.accessKey = accessKey
        self.secretKey = secretKey
        self.regionName = regionName
        self.serviceName = serviceName
    }

    public func signedHeaders(url: URL, bodyDigest: String, httpMethod: String = "PUT", date: NSDate = NSDate()) throws -> [String: String] {
        guard let host = url.host else {
            throw S3V4SignerError.invalidHost(host:url)
        }

        let datetime = timestamp(date: date)

        var headers = [
            "x-amz-content-sha256": bodyDigest,
            "x-amz-date": datetime,
            "x-amz-acl" : "public-read",
            "Host": host,
            ]
        headers["Authorization"] = try authorization(url: url, headers: headers, datetime: datetime, httpMethod: httpMethod, bodyDigest: bodyDigest)

        return headers
    }

    // MARK: Utilities

    private func pathForURL(url: URL) -> String? {
        var path = url.path
        if path.isEmpty {
            path = "/"
        }
        return path
    }

    public func sha256(str: String) -> String {
        let data = str.data(using: String.Encoding.utf8)!
        var hash =  [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        _ = data.withUnsafeBytes{
            CC_SHA256($0, CC_LONG(data.count), &hash)
        }

        let res = NSData(bytes: hash, length: Int(CC_SHA256_DIGEST_LENGTH))
        return hexdigest(data: res)
    }

    private func hmac(string: NSString, key: NSData) -> NSData {
        let data = string.cString(using: String.Encoding.utf8.rawValue)
        let dataLen = Int(string.lengthOfBytes(using: String.Encoding.utf8.rawValue))
        let digestLen = Int(CC_SHA256_DIGEST_LENGTH)
        let result = UnsafeMutablePointer<CUnsignedChar>.allocate(capacity: digestLen)
        CCHmac(CCHmacAlgorithm(kCCHmacAlgSHA256), key.bytes, key.length, data, dataLen, result);
        return NSData(bytes: result, length: digestLen)
    }

    private func hexdigest(data: NSData) -> String {
        var hex = String()
        var byte: UInt8 = 0

        for i: Int in 0 ..< data.length {
            data.getBytes(&byte, range: NSMakeRange(i, 1))
            hex += String(format: "%02x", byte)
        }
        return hex
    }

    private func timestamp(date: NSDate) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
        formatter.timeZone = NSTimeZone(name: "UTC") as TimeZone!
        formatter.locale = NSLocale(localeIdentifier: "en_US_POSIX") as Locale!
        return formatter.string(from: date as Date)
    }

    // MARK: Methods Ported from AWS SDK

    private func authorization(url: URL, headers: Dictionary<String, String>, datetime: String, httpMethod: String, bodyDigest: String) throws -> String {
        let cred = credential(datetime: datetime)
        let shead = signedHeaders(headers: headers)
        let sig = try signature(url: url, headers: headers, datetime: datetime, httpMethod: httpMethod, bodyDigest: bodyDigest)

        return [
            "AWS4-HMAC-SHA256 Credential=\(cred)",
            "SignedHeaders=\(shead)",
            "Signature=\(sig)",
            ].joined(separator: ", ")
    }

    private func credential(datetime: String) -> String {
        return "\(accessKey)/\(credentialScope(datetime: datetime))"
    }

    private func signedHeaders(headers: [String:String]) -> String {
        var list = Array(headers.keys).map { $0.lowercased() }.sorted()
        if let itemIndex = list.index(of: "authorization") {
            list.remove(at: itemIndex)
        }
        return list.joined(separator: ";")
    }

    private func canonicalHeaders(headers: [String: String]) -> String {
        var list = [String]()
        let keys = Array(headers.keys).sorted {$0.localizedCompare($1) == ComparisonResult.orderedAscending}

        for key in keys {
            if key.caseInsensitiveCompare("authorization") != ComparisonResult.orderedSame {
                // Note: This does not strip whitespace, but the spec says it should
                list.append("\(key.lowercased()):\(headers[key]!)")
            }
        }
        return list.joined(separator: "\n")
    }

    private func signature(url: URL, headers: [String: String], datetime: String, httpMethod: String, bodyDigest: String) throws -> String {
        let secret = NSString(format: "AWS4%@", secretKey).data(using: String.Encoding.utf8.rawValue)!
        let date = hmac(string: datetime.substring(to: datetime.characters.index(datetime.startIndex, offsetBy: 8))
            as NSString, key: secret as NSData)
        let region = hmac(string: regionName as NSString, key: date)
        let service = hmac(string: serviceName as NSString, key: region)
        let credentials = hmac(string: "aws4_request", key: service)
        let string = try stringToSign(datetime: datetime, url: url, headers: headers, httpMethod: httpMethod, bodyDigest: bodyDigest)
        let sig = hmac(string: string as NSString, key: credentials)
        return hexdigest(data: sig)
    }

    private func credentialScope(datetime: String) -> String {
        return [
            datetime.substring(to: datetime.characters.index(datetime.startIndex, offsetBy: 8)),
            regionName,
            serviceName,
            "aws4_request"
            ].joined(separator: "/")
    }

    private func stringToSign(datetime: String, url: URL, headers: [String: String], httpMethod: String, bodyDigest: String) throws -> String {
        return [
            "AWS4-HMAC-SHA256",
            datetime,
            credentialScope(datetime: datetime),
            try sha256(str: canonicalRequest(url: url, headers: headers, httpMethod: httpMethod, bodyDigest: bodyDigest)),
            ].joined(separator: "\n")
    }

    private func canonicalRequest(url: URL, headers: [String: String], httpMethod: String, bodyDigest: String) throws -> String {
        guard let path = pathForURL(url: url) else {                        // Resource Path
            throw S3V4SignerError.invalidPath(path: url)
        }
        let query = url.query ?? ""                                         // Canonicalized Query String
        let rawHeadersString = "\(canonicalHeaders(headers: headers))\n"    // Canonicalized Header String (Plus a newline for some reason)
        let signedHeadersString = signedHeaders(headers: headers)           // Signed Headers String
        return [httpMethod, path, query, rawHeadersString, signedHeadersString, bodyDigest].joined(separator:"\n")
    }
}
