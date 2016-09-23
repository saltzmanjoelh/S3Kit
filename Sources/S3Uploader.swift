//
//  S3Uploader.swift
//  XcodeHelper
//
//  Created by Joel Saltzman on 9/17/16.
//
//

import Foundation

public enum S3UploaderError: Error {
    case timedOut
    case noResponse
    case credentialFile(message: String)
    case secretNotFound
    case keyNotFound
}

public struct S3Uploader {
    static public func parseCredentials(at path:String) throws -> (key: String, secret: String) {
        //make sure that the file exists
        guard FileManager.default.fileExists(atPath: path) else {
            throw S3UploaderError.credentialFile(message: "Credentials file doesn't exist: \(path)")
        }
        //open it
        guard let fileData = FileManager.default.contents(atPath: path) else {
            throw S3UploaderError.credentialFile(message: "Unable to open credentials file: \(path)")
        }
        //split by comma
        guard let file = String.init(data: fileData, encoding: String.Encoding.utf8) else {
            throw S3UploaderError.credentialFile(message: "Unable to parse credentials file: \(path)")
        }
        var components = file.components(separatedBy: ",")
        guard components.count >= 2 else {
            throw S3UploaderError.credentialFile(message: "Credentials file must have a key and secret separated by a comma")
        }
        guard let secret = components.popLast()?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) else {
            throw S3UploaderError.secretNotFound
        }
        guard let key = components.popLast()?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) else {
            throw S3UploaderError.keyNotFound
        }
        return (key, secret)
    }
    
    static public func upload(file fileURL: URL, to bucket: String, in region: String, with credentialsPath: String) throws -> (data: NSData?, response: HTTPURLResponse) {
        let credentials = try parseCredentials(at: credentialsPath)
        return try upload(file: fileURL, to: bucket, in: region, key: credentials.key, secret: credentials.secret)
        
    }
    static public func upload(file fileURL: URL, to bucket: String, in region: String, key: String, secret: String) throws -> (data: NSData?, response: HTTPURLResponse) {
        
        let s3URL = URL(string: "https://\(bucket).s3.amazonaws.com/\(fileURL.lastPathComponent)")!
        let signer = S3V4Signer(accessKey: key, secretKey: secret, regionName: region)//create the signer
        
        
        //get the file
        let fileData = try! Data(contentsOf: fileURL)
        let bodyDigest = sha256_hexdigest(fileData)
        let fileStream = InputStream(fileAtPath: fileURL.path)!

        //create an URL Request
        let request = NSMutableURLRequest(url: s3URL)
        request.httpMethod = "PUT"
        request.httpBodyStream = fileStream
        
        //create the signed headers
        let headers = try signer.signedHeaders(url: s3URL, bodyDigest: bodyDigest)
        //set the headers on an URLRequest
        for (key, value) in headers {
            request.addValue(value, forHTTPHeaderField: key)
        }
        //don't forget the file details
        request.addValue("\(fileData.count)", forHTTPHeaderField: "Content-Length")
        request.addValue("file/\(fileURL.pathExtension)", forHTTPHeaderField: "Content-Type")
        
        //send the request
        var data: NSData?, response: URLResponse?, error: NSError?
        let semaphore = DispatchSemaphore(value: 0)
        URLSession.shared.dataTask(with: request as URLRequest) {
            data = $0 as NSData?; response = $1; error = $2 as NSError?
            semaphore.signal()
        }.resume()
        let timeoutResult = semaphore.wait(timeout: DispatchTime.distantFuture)
        
        if timeoutResult == .timedOut {
            throw S3UploaderError.timedOut
        }
        if error != nil {
            throw error!
        }
        guard let urlResponse = response as? HTTPURLResponse else {
            throw S3UploaderError.noResponse
        }
        if urlResponse.statusCode != 200 {
            throw S3UploaderError.noResponse
        }
        
        
        return (data! as NSData?, urlResponse)
    }
    
}
