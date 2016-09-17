import XCTest
@testable import S3V4Signer

class S3V4SignerTests: XCTestCase {
    
    //change these
    let bucket = ""
    let key = ""
    let secret = ""
    let region = "us-east-1"
    let path = "/Users/joelsaltzman/Desktop/test.txt"
    
    
    func testS3V4Signer() {

        try! "testS3V4Signer".write(toFile: path, atomically: false, encoding: String.Encoding.utf8)
        let fileURL = URL.init(fileURLWithPath: path)
        let fileData = try! Data(contentsOf: fileURL)
        let bodyDigest = sha256_hexdigest(fileData)
        let url = URL(string: "https://s3.amazonaws.com/\(bucket)/\(fileURL.lastPathComponent)")!
        let request = NSMutableURLRequest(url: url)
        let fileStream = InputStream(fileAtPath: path)!
        
        request.httpMethod = "PUT"
        request.httpBodyStream = fileStream
        
        //create the signer
        let signer = S3V4Signer(accessKey: key, secretKey: secret, regionName: region)
        //create the signed headers
        let headers = signer.signedHeaders(url: url as NSURL, bodyDigest: bodyDigest)
        
        //set the headers on an URLRequest
        for (key, value) in headers {
            request.addValue(value, forHTTPHeaderField: key)
        }
        //don't forget the file details
        request.addValue("\(fileData.count)", forHTTPHeaderField: "Content-Length")
        request.addValue("file/txt", forHTTPHeaderField: "Content-Type")
        
        //send the request
        var response: URLResponse?
        do {
            let data = try NSURLConnection.sendSynchronousRequest(request as URLRequest, returning: &response)
            if let httpResponse = response as? HTTPURLResponse {
                let text = NSString(data:data, encoding:String.Encoding.utf8.rawValue) as? String
                NSLog("Response from AWS S3: \(httpResponse.description)\n\(text!)")
            }
        } catch (let e) {
            print(e)
        }
    }

    static var allTests : [(String, (S3V4SignerTests) -> () throws -> Void)] {
        return [
            ("testS3V4Signer", testS3V4Signer),
        ]
    }
}
