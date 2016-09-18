# S3V4Signer
Cross-platform S3 v4 URL Signer to upload files to s3


```
//get the file
let fileURL = URL.init(fileURLWithPath: path)
let fileData = try! Data(contentsOf: fileURL)
let bodyDigest = sha256_hexdigest(fileData)

//create an URL Request
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
```
