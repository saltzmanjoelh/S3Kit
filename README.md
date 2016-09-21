# S3Uploader
Easily upload files to S3. Doesn't work in Linux at the moment

TODO: Add Linux compatibility

```
let result = try S3Uploader.upload(file: fileURL, to: bucket, in: region, key: key, secret: secret)
var description = result.response.description
if let data = result.data as? Data {
	if let text = NSString(data:data, encoding:String.Encoding.utf8.rawValue) as? String {
		description += "\n\(text)"
	}
}
```
