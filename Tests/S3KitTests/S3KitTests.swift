import XCTest
@testable import S3Kit

class S3KitTests: XCTestCase {
    
    //change these
    let bucket = "saltzman.test"
//    let region = "us-east-1"
    let key = "AKIAJYPKZDD7IU7HAYSQ"
    let secret = "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"
    let path = "/tmp/testfile.txt"
//    let credentialsPath = "/Users/joelsaltzman/Sites/S3Kit/s3Credentials.csv"
    
    
    func testUpload() {
        
        do{
            try! "some test text".write(toFile: path, atomically: false, encoding: String.Encoding.utf8)
            let fileURL = URL.init(fileURLWithPath: path)
            
            let result = try S3.with(key: key, and: secret).upload(file: fileURL, to: bucket)
            
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
    
    func testObjectExists() {
        do{
            try! "some test text".write(toFile: path, atomically: false, encoding: String.Encoding.utf8)
            _ = try S3.with(key: key, and: secret).upload(file: URL.init(fileURLWithPath: path), to: bucket)
            let fileName = URL(string: path)!.lastPathComponent
            
            let result = try S3.with(key: key, and: secret).objectExists(objectName: fileName, inBucket: bucket)
            
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
