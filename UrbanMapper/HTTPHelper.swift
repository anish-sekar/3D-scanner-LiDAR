//
//  HTTPHelper.swift
//  UrbanMapper
//
//  Created by Prajnya Prabhu on 11/29/20.
//

import Foundation


/// Create request
///
/// - parameter userid:   The userid to be passed to web service
/// - parameter password: The password to be passed to web service
/// - parameter email:    The email address to be passed to web service
///
/// - returns:            The `URLRequest` that was created

//func createRequest(userid: String, password: String, email: String) throws -> URLRequest {
//    let parameters = [
//        "user_id"  : userid,
//        "email"    : email,
//        "password" : password]  // build your dictionary however appropriate
//
//    let boundary = generateBoundaryString()
//
//    let url = URL(string: "https://example.com/imageupload.php")!
//    var request = URLRequest(url: url)
//    request.httpMethod = "POST"
//    request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
//
//    let fileURL = Bundle.main.url(forResource: "image1", withExtension: "png")!
//    request.httpBody = try createBody(with: parameters, filePathKey: "file", urls: [fileURL], boundary: boundary)
//
//    return request
//}

/// Create body of the `multipart/form-data` request
///
/// - parameter parameters:   The optional dictionary containing keys and values to be passed to web service.
/// - parameter filePathKey:  The optional field name to be used when uploading files. If you supply paths, you must supply filePathKey, too.
/// - parameter urls:         The optional array of file URLs of the files to be uploaded.
/// - parameter boundary:     The `multipart/form-data` boundary.
///
/// - returns:                The `Data` of the body of the request.

//private func createBody(with parameters: [String: String]?, filePathKey: String, urls: [URL], boundary: String) throws -> Data {
//    var body = Data()
//
//    parameters?.forEach { (key, value) in
//        body.append("--\(boundary)\r\n")
//        body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
//        body.append("\(value)\r\n")
//    }
//
//    for url in urls {
//        let filename = url.lastPathComponent
//        let data = try Data(contentsOf: url)
//        let mimetype = mimeType(for: filename)
//
//        body.append("--\(boundary)\r\n")
//        body.append("Content-Disposition: form-data; name=\"\(filePathKey)\"; filename=\"\(filename)\"\r\n")
//        body.append("Content-Type: \(mimetype)\r\n\r\n")
//        body.append(data)
//        body.append("\r\n")
//    }
//
//    body.append("--\(boundary)--\r\n")
//    return body
//}

/// Create boundary string for multipart/form-data request
///
/// - returns:            The boundary string that consists of "Boundary-" followed by a UUID string.

private func generateBoundaryString() -> String {
    return "Boundary-\(UUID().uuidString)"
}

/// Determine mime type on the basis of extension of a file.
///
/// This requires `import MobileCoreServices`.
///
/// - parameter path:         The path of the file for which we are going to determine the mime type.
///
/// - returns:                Returns the mime type if successful. Returns `application/octet-stream` if unable to determine mime type.

//private func mimeType(for path: String) -> String {
//    let pathExtension = URL(fileURLWithPath: path).pathExtension as NSString
//
//    guard
//        let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, pathExtension, nil)?.takeRetainedValue(),
//        let mimetype = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType)?.takeRetainedValue()
//    else {
//        return "application/octet-stream"
//    }
//
//    return mimetype as String
//}
