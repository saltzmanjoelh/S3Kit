import XCTest
@testable import S3Uploader

class S3UploaderTests: XCTestCase {
    
    //change these
    let bucket = "saltzman.test"
    let region = "us-east-1"
    let path = "/Users/joelsaltzman/Sites/S3Uploader/Tests/file.tar"
    
    
    var key = ""
    var secret = ""
    override func setUp() {
        do {
            //create a comma delimited file like: keyGoesHere,secreteGoesHere
            let credentials = try S3Uploader.parseCredentials(at: "/Users/joelsaltzman/Sites/S3Uploader/s3Credentials.csv")
            key = credentials.key
            secret = credentials.secret
        } catch let e {
            XCTFail("\(e)")
        }
    }
    
    func testS3Uploader() {
        
//        try! "testS3Uploader".write(toFile: path, atomically: false, encoding: String.Encoding.utf8)
        let fileURL = URL.init(fileURLWithPath: path)
        let fileData = try! Data(contentsOf: fileURL)
        let bodyDigest = sha256_hexdigest(fileData)
        let s3URL = URL(string: "https://s3.amazonaws.com/\(bucket)/\(fileURL.lastPathComponent)")!
        let request = NSMutableURLRequest(url: s3URL)
        let fileStream = InputStream(fileAtPath: path)!
        
        request.httpMethod = "PUT"
        request.httpBodyStream = fileStream
        
        //create the signer
        let signer = S3V4Signer(accessKey: key, secretKey: secret, regionName: region)
        //create the signed headers
        let headers = try! signer.signedHeaders(url: s3URL, bodyDigest: bodyDigest)
        
        //set the headers on an URLRequest
        for (key, value) in headers {
            request.addValue(value, forHTTPHeaderField: key)
        }
        //don't forget the file details
        request.addValue("\(fileData.count)", forHTTPHeaderField: "Content-Length")
        request.addValue("file/tar", forHTTPHeaderField: "Content-Type")
        
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
    //TODO: top one works, bottom one doesnt. Also, uploading file.txt returns code 200 but file.zip gets 403
    
    func testUpload() {

        try! "some test text".write(toFile: path, atomically: false, encoding: String.Encoding.utf8)
        let fileURL = URL.init(fileURLWithPath: path)
        do{
            let result = try S3Uploader.upload(file: fileURL, to: bucket, in: region, key: key, secret: secret)
            var description = result.response.description
            if let data = result.data as? Data {
                if let text = NSString(data:data, encoding:String.Encoding.utf8.rawValue) as? String {
                    description += "\n\(text)"
                }
            }
            XCTAssertEqual(result.response.statusCode, 200, description)
        } catch let e {
            XCTFail("\(e)")
        }
    }

    static var allTests : [(String, (S3UploaderTests) -> () throws -> Void)] {
        return [
            ("testUpload", testUpload),
        ]
    }
}
