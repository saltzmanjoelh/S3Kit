import XCTest
@testable import S3Kit

class S3KitTests: XCTestCase {
    
    //change these
    let bucket = "saltzman.test"
//    let region = "us-east-1"
    let key = ProcessInfo.processInfo.environment["KEY"] ?? ""
    let secret = ProcessInfo.processInfo.environment["SECRET"] ?? ""
    let path = "/tmp/testfile.txt"
    let credentialsPath = "/Users/joelsaltzman/Sites/S3Kit/s3Credentials.csv"
    
    
    func testUpload() {
        
        do{
            try! "some test text".write(toFile: path, atomically: false, encoding: String.Encoding.utf8)
            let fileURL = URL.init(fileURLWithPath: path)
            
            let s3 = key == "" ? try S3.with(credentials: credentialsPath) : try S3.with(key: key, and: secret)
            let result = try s3.upload(file: fileURL, to: bucket)
            
            var description = result.response.description
            if let data = result.data {
                if let text = String.init(data: data as Data, encoding: .utf8) {
                    description += "\n\(text)"
                }
            }
            XCTAssertEqual(result.response.statusCode, 200, description)
        } catch let e {
            XCTFail("\(e)")
        }
    }
    
    func testObjectExists() {
        do{
            let s3 = key == "" ? try S3.with(credentials: credentialsPath) : try S3.with(key: key, and: secret)
            try! "some test text".write(toFile: path, atomically: false, encoding: String.Encoding.utf8)
            _ = try s3.upload(file: URL.init(fileURLWithPath: path), to: bucket)
            let fileName = URL(string: path)!.lastPathComponent
            
            let result = try s3.objectExists(objectName: fileName, inBucket: bucket)
            
            XCTAssertTrue(result)
        } catch let e {
            XCTFail("\(e)")
        }
    }

    static var allTests : [(String, (S3KitTests) -> () throws -> Void)] {
        return [
            ("testUpload", testUpload),
        ]
    }
}
