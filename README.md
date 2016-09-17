# S3V4Signer
Cross-platform S3 v4 URL Signer to upload files to s3


```
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