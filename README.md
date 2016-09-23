# S3Kit

Easily upload files to S3\. Doesn't work in Linux at the moment

TODO: Add Linux compatibility

```
//let result = try S3.with(credentials: credentialsPath).upload(file: fileURL, to: bucket)
let result = try S3.with(key: "1234" and: "secret1234").upload(file: fileURL, to: bucket)
var description = result.response.description
if let data = result.data as? Data {
    if let text = NSString(data:data, encoding:String.Encoding.utf8.rawValue) as? String {
        description += "\n\(text)"
    }
}
```
