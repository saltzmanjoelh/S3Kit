import XCTest
@testable import S3Kit

class S3KitTests: XCTestCase {
    
    //change these
    let bucket = "saltzman.test"
//    let region = "us-east-1"
    let path = "/Users/joelsaltzman/Sites/S3Kit/Tests/file.tar"
    let credentialsPath = "/Users/joelsaltzman/Sites/S3Kit/s3Credentials.csv"
    
    func testUpload() {

        try! "some test text".write(toFile: path, atomically: false, encoding: String.Encoding.utf8)
        let fileURL = URL.init(fileURLWithPath: path)
        do{
            let result = try S3.with(credentials: credentialsPath).upload(file: fileURL, to: bucket)
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

    static var allTests : [(String, (S3KitTests) -> () throws -> Void)] {
        return [
            ("testUpload", testUpload),
        ]
    }
}
