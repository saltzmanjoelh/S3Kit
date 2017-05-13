//
//  S3.swift
//  S3Kit
//
//  Created by Joel Saltzman on 9/17/16.
//
//

import Foundation

public enum S3KitError: Error {
    case invalidCredentialFile(message: String)
    case secretNotFound
    case keyNotFound
    case timedOut
    case noResponse
    case responseError(code: Int)
    case invalidURL
    case aws(message: String)
}

public struct S3 {
    let key: String
    let secret: String
    
    static public func with(credentials path: String) throws -> S3 {
        let credentials = try parseCredentials(at: path)
        let instance = S3(key: credentials.key, secret: credentials.secret)
        return instance
    }
    static public func with(key: String, and secret: String) throws -> S3 {
        let instance = S3(key: key, secret: secret)
        return instance
    }
    static private func parseCredentials(at path:String) throws -> (key: String, secret: String) {
        //make sure that the file exists
        guard FileManager.default.fileExists(atPath: path) else {
            throw S3KitError.invalidCredentialFile(message: "Credentials file doesn't exist: \(path)")
        }
        //open it
        guard let fileData = FileManager.default.contents(atPath: path) else {
            throw S3KitError.invalidCredentialFile(message: "Unable to open credentials file: \(path)")
        }
        //split by comma
        guard let file = String.init(data: fileData, encoding: String.Encoding.utf8) else {
            throw S3KitError.invalidCredentialFile(message: "Unable to parse credentials file: \(path)")
        }
        var components = file.components(separatedBy: ",")
        guard components.count >= 2 else {
            throw S3KitError.invalidCredentialFile(message: "Credentials file must have a key and secret separated by a comma")
        }
        guard let secret = components.popLast()?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) else {
            throw S3KitError.secretNotFound
        }
        guard let key = components.popLast()?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) else {
            throw S3KitError.keyNotFound
        }
        return (key, secret)
    }
    
    
    public func upload(file fileURL: URL, to bucket: String, in region: String = "us-east-1") throws -> (data: NSData?, response: HTTPURLResponse) {
        
        let s3URL = URL(string: "https://s3.amazonaws.com/\(bucket)/\(fileURL.lastPathComponent)")!
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
        let headers = try signer.signedHeaders(url: s3URL, bodyDigest: bodyDigest, httpMethod: "PUT")
        //set the headers on an URLRequest
        for (key, value) in headers {
            request.addValue(value, forHTTPHeaderField: key)
        }
        //don't forget the file details
        request.addValue("\(fileData.count)", forHTTPHeaderField: "Content-Length")
        request.addValue("file/\(fileURL.pathExtension)", forHTTPHeaderField: "Content-Type")
        
        //send the request
        var data: Data?, response: URLResponse?, error: NSError?
        let semaphore = DispatchSemaphore(value: 0)
        URLSession.shared.dataTask(with: request as URLRequest) { (d:Data?, r:URLResponse?, e:Error?) -> Void in
            data = d
            response = r
            error = e as NSError?
            semaphore.signal()
        }.resume()
        let timeoutResult = semaphore.wait(timeout: DispatchTime.distantFuture)
        
        if timeoutResult == .timedOut {
            throw S3KitError.timedOut
        }
        if error != nil {
            throw error!
        }

        
        guard let urlResponse = response as? HTTPURLResponse else {
            throw S3KitError.noResponse
        }
        if urlResponse.statusCode != 200 {
            var description = ""
            if let theData = data {
                if let text = String.init(data: theData, encoding: .utf8) {
                    description += "\n\(text)"
                }
                throw S3KitError.aws(message: description)
                //            print("request: \(request.allHTTPHeaderFields)\n\nresponse: \(response?.description)\n\ndescription: \(description)")
            }
            throw S3KitError.noResponse
        }
        
        
        return (data! as NSData?, urlResponse)
    }
    
    
    
    
    public func objectExists(objectName: String, inBucket bucket: String, inRegion region: String = "us-east-1") throws -> Bool {
        
        let s3URL = URL(string: "https://s3.amazonaws.com/\(bucket)/\(objectName)")!
        let signer = S3V4Signer(accessKey: key, secretKey: secret, regionName: region)//create the signer
        
        //create an URL Request
        let request = NSMutableURLRequest(url: s3URL)
        request.httpMethod = "HEAD"
        
        //create the signed headers
        let bodyDigest = sha256_hexdigest("".data(using: String.Encoding.utf8)!)
        let headers = try signer.signedHeaders(url: s3URL, bodyDigest: bodyDigest, httpMethod: "HEAD")
        //set the headers on an URLRequest
        for (key, value) in headers {
            request.addValue(value, forHTTPHeaderField: key)
        }
        
        //send the request
        var response: URLResponse?, error: NSError?
        let semaphore = DispatchSemaphore(value: 0)
        URLSession.shared.dataTask(with: request as URLRequest) {
            response = $1; error = $2 as NSError?
            var description = ""
            if let data = $0 {
                if let text = String.init(data: data, encoding: .utf8) {
                    description += "\n\(text)"
                }
            }
            print("request: \(String(describing: request.allHTTPHeaderFields))\n\nresponse: \(String(describing: response?.description))\n\ndescription: \(description)")
            semaphore.signal()
            }.resume()
        let timeoutResult = semaphore.wait(timeout: DispatchTime.distantFuture)
        
        if timeoutResult == .timedOut {
            throw S3KitError.timedOut
        }
        if error != nil {
            throw error!
        }
        guard let urlResponse = response as? HTTPURLResponse else {
            throw S3KitError.noResponse
        }
        return urlResponse.statusCode == 200
    }
}
