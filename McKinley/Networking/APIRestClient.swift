//
//  APIRestClient.swift
//  Contacts
//
//  Created by Uzair Dhada on 19/10/19.
//  Copyright © 2019 Go Jek. All rights reserved.
//

import Foundation
import UIKit
import MobileCoreServices

protocol APIClientRequirement {
    
    func apiDataTask(url: URL, method:APIRestClient.HTTPMethod?, headers:[String:String]?, parameters:[String: Any]?, result: @escaping (Result<(URLResponse, Data), Error>) -> Void) -> URLSessionDataTask
    func apiUploadTask(url: URL, headers:[String:String]?, parameters:[String: String]?, files:[String: Any], result: @escaping (Result<(URLResponse, Data), Error>) -> Void) -> URLSessionUploadTask
}

extension APIRestClient :  APIClientRequirement {
    
    public func apiDataTask(url: URL, method: APIRestClient.HTTPMethod?, headers: [String : String]?, parameters: [String : Any]?, result: @escaping (_ result:Result<(URLResponse, Data), Error>) -> Void) -> URLSessionDataTask {
        return self.urlSession.apiTask(url: url, method: method, headers: headers, parameters: parameters, result: result)
    }
    
    public func apiUploadTask(url: URL, headers:[String:String]? = nil, parameters:[String: String]?, files:[String: Any], result: @escaping (_ result:Result<(URLResponse, Data), Error>) -> Void) -> URLSessionUploadTask {
        return self.urlSession.apiUploadTask(url: url, headers: headers, parameters: parameters, files: files, result: result)
    }
    
}

class APIRestClient {
    
    struct SharedKeys {
        static let apiRestClient = APIRestClient()
    }
    static let shared = SharedKeys.apiRestClient
    
    public enum APIServiceError: Error {
        
        case apiError // Error return by URLSession.
        case invalidEndpoint // Invalid API
        case invalidResponse // Invalid response received from server
        case noData // No data available
        case decodeError // Json parsing error
        case successWithError(Any)
        case notFound404
        case internalServerError500
        case validationErrors422
        case successWith204
        
    }
    
    enum HTTPMethod : String {
        case get, post, put, delete
    }
    
    fileprivate let urlSession:URLSession
    fileprivate let sessionHandle = URLSessionHandle()
    
    /*
    
    fileprivate let jsonDecoder: JSONDecoder = {
        let jsonDecoder = JSONDecoder()
        jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-mm-dd"
        jsonDecoder.dateDecodingStrategy = .formatted(dateFormatter)
        return jsonDecoder
    }()
 */
    
    private init() {
        
        let config = URLSessionConfiguration.default
        //config.httpAdditionalHeaders = ["User-Agent":"Legit Safari", "Authorization" : "Bearer key1234567"]
        config.timeoutIntervalForRequest = 60
        // use saved cache data if exist, else call the web API to retrieve
        config.requestCachePolicy = NSURLRequest.CachePolicy.reloadIgnoringLocalAndRemoteCacheData
        
        //let session = URLSession(configuration: config)
        
        //SSL Pinning Delegate
        let session = URLSession(configuration: config, delegate: sessionHandle, delegateQueue: OperationQueue.main)
        
        self.urlSession = session
    }
}

//----------------------------------------------------------------------------------------------------------------------//
extension APIRestClient.APIServiceError : Equatable {
    
    static func ==(lhs: APIRestClient.APIServiceError, rhs: APIRestClient.APIServiceError) -> Bool  {
        switch (lhs, rhs) {
        case (.successWithError(_),  .successWithError(_)):
            return true
        case (.apiError, .apiError), (.invalidEndpoint, .invalidEndpoint), (.invalidResponse, .invalidResponse), (.noData, .noData), (.decodeError, .decodeError):
            return true
        default:
            return false
        }
    }
}

//----------------------------------------------------------------------------------------------------------------------//
extension APIRestClient {
    
    /// Create body of the `multipart/form-data` request
    ///
    /// - parameter parameters:   The optional dictionary containing keys and values to be passed to web service
    /// - parameter files:        The optional array of files (UIImage, [UIImage], URL, [URL]) the files to be uploaded
    /// - parameter boundary:     The `multipart/form-data` boundary
    ///
    /// - returns:                The `Data` of the body of the request
    
    fileprivate class func createMultiPartBody( parameters: [String: String]?, files:[String: Any]? = nil, boundary:String? =   APIRestClient.generateBoundaryString()) -> Data {
        
        var body = Data()
        if parameters != nil {
            for (key, value) in parameters! {
                body.append("--\(boundary!)\r\n")
                body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
                body.append("\(value)\r\n")
            }
        }
        
        if let files = files {
            for (key, value) in files {
                if let image = value as? UIImage {
                    body.append(image: image, name: key, fileName: "\(key)_\(UUID().uuidString).jpg", boundary: boundary)
                    print("\(key)_\(UUID().uuidString).jpg")
                } else if let images = value as? [UIImage] {
                    for (index, item) in images.enumerated() {
                        body.append(image: item, name: "\(key)[\(index)]", fileName: "\(key)_\(UUID().uuidString).jpg", boundary: boundary)
                        print("\(key)_\(UUID().uuidString).jpg")
                    }
                    //Other File Code Later
                }else if let url  = value as? URL {
                    body.append(url: url, name: key, fileName: "\(key).\(url.pathExtension)", boundary: boundary)
                }else if let urls = value as? [URL] {
                    for (index, item) in urls.enumerated() {
                        body.append(url: item, name: "\(key)[\(index)]", fileName: "\(key)\(index).\(item.pathExtension)", boundary: boundary)
                    }
                }
            }
        }
        
        
        body.append("--\(boundary!)--\r\n")
        return body
    }
    
    /// Create boundary string for multipart/form-data request
    ///
    /// - returns:            The boundary string that consists of "Boundary-" followed by a UUID string.
    
    fileprivate static func generateBoundaryString() -> String {
        return "Boundary-\(UUID().uuidString)"
    }
    
    /// Determine mime type on the basis of extension of a file.
    ///
    /// This requires `import MobileCoreServices`.
    ///
    /// - parameter path: The path of the file for which we are going to determine the mime type.
    ///
    /// - returns: Returns the mime type if successful. Returns `application/octet-stream` if unable to determine mime type.
    
    fileprivate static func mimeType(for path: String) -> String {
        let url = URL(fileURLWithPath: path)
        let pathExtension = url.pathExtension
        
        if let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, pathExtension as NSString, nil)?.takeRetainedValue() {
            if let mimetype = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType)?.takeRetainedValue() {
                return mimetype as String
            }
        }
        return "application/octet-stream"
    }
}

//---------------------------------------------------------------------------------//

extension Data {
    
    /// Append string to Data
    ///
    /// Rather than littering my code with calls to `data(using: .utf8)` to convert `String` values to `Data`, this wraps it in a nice convenient little extension to Data. This defaults to converting using UTF-8.
    ///
    /// - parameter string: The string to be added to the `Data`.
    
    mutating func append(_ string: String, using encoding: String.Encoding = .utf8) {
        if let data = string.data(using: encoding) {
            append(data)
        }
    }
    
    mutating func append(data:Data, name:String, fileName:String, mimeType: String, boundary:String? = APIRestClient.generateBoundaryString()) {
        
        // name : `key` for file parameter value
        self.append("--\(boundary!)\r\n")
        self.append("Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(fileName)\"\r\n")
        self.append("Content-Type: \(mimeType)\r\n\r\n")
        self.append(data)
        self.append("\r\n")
    }
    
    mutating func append(url:URL, name:String, fileName:String, boundary:String? = APIRestClient.generateBoundaryString()) {
        
        let data = try! Data(contentsOf: url)
        let mimeType = APIRestClient.mimeType(for: url.path)
        
        // name : `key` for file parameter value
        self.append("--\(boundary!)\r\n")
        self.append("Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(fileName)\"\r\n")
        self.append("Content-Type: \(mimeType)\r\n\r\n")
        self.append(data)
        self.append("\r\n")
    }
    
    mutating func append(image:UIImage, name:String, fileName:String, boundary:String? = APIRestClient.generateBoundaryString()) {
        
        // name : `key` for file parameter value
        let imageData = image.jpegData(compressionQuality: 0.6)
        
        self.append("--\(boundary!)\r\n")
        self.append("Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(fileName)\"\r\n")
        self.append("Content-Type: image/jpg\r\n\r\n")
        self.append(imageData!)
        self.append("\r\n")
    }
}

//---------------------------------------------------------------------------------//
extension URLRequest {
    
    //Post request
    mutating func configureRquestHeader(headers:[String:String]?) {
        //For Headers
        if let headers = headers {
            for (key, value) in headers {
                self.addValue(value, forHTTPHeaderField: key)
            }
        }
    }
    
    mutating func configurePostRquest(params:[String:Any]?) {
        
        //Params:
        if let params = params, params.keys.count > 0 {
            do {
                let json = try JSONSerialization.data(withJSONObject: params, options: .prettyPrinted)
                self.httpBody = json
            } catch let error as NSError {
                print(error.description)
                //JetMethods.printJet(message: error.description)
            }
        }
    }
    
    mutating func configureGetRquest(params:[String:String]?) {
        
        //Params:
        if let params = params, params.keys.count > 0 {
            var urlComponents = URLComponents(url: self.url!, resolvingAgainstBaseURL: false)
            let queryItems = params.map{
                return URLQueryItem(name: "\($0)", value: "\($1)")
            }
            urlComponents?.queryItems = queryItems
            self.url = urlComponents?.url
        }
    }
}

//---------------------------------------------------------------------------------//
// API Calling Helpers :
//---------------------------------------------------------------------------------//

extension URLSession {
    
    func dataTask(with url: URL, result: @escaping (Result<(URLResponse, Data), Error>) -> Void) -> URLSessionDataTask {
        return dataTask(with: url) { (data, response, error) in
            if let error = error {
                result(.failure(error))
                return
            }
            guard let response = response, let data = data else {
                let error = NSError(domain: "error", code: 0, userInfo: nil)
                result(.failure(error))
                return
            }
            result(.success((response, data)))
        }
    }
}

extension URLSession {
    
    // --  Default is POST request
    fileprivate func apiTask(url: URL, method:APIRestClient.HTTPMethod? = nil, headers:[String:String]? = nil, parameters:[String: Any]?, result: @escaping (_ result:Result<(URLResponse, Data), Error>) -> Void) -> URLSessionDataTask {
        
        var request = URLRequest(url: url)
        
        if let method = method, method == .get {
            if let parameters = parameters as?  [String : String] {
                request.configureGetRquest(params: parameters)
                request.httpMethod = "GET"
            }else {
                //Get parameter value must be string for every key
            }
        } else if let method = method, method == .put {
            request.httpMethod = "PUT"
            request.configurePostRquest(params: parameters)
        } else if let method = method, method == .delete {
            request.httpMethod = "DELETE"
            request.configurePostRquest(params: parameters)
        } else {
            request.httpMethod = "POST"
            request.configurePostRquest(params: parameters)
        }
        
        if let headers = headers {
            request.configureRquestHeader(headers: headers)
        }
        
        return dataTask(with: request) { (data, response, error) in
    
            if let error = error {
                result(.failure(error))
                return
            }
            guard let response = response, let data = data else {
                let error = NSError(domain: "error", code: 0, userInfo: nil)
                result(.failure(error))
                return
            }
            result(.success((response, data)))
        }
    }
    
    fileprivate func apiUploadTask(url: URL, headers:[String:String]? = nil, parameters:[String: String]?, files:[String: Any], result: @escaping (_ result:Result<(URLResponse, Data), Error>) -> Void) -> URLSessionUploadTask {
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        if let headers = headers {
            request.configureRquestHeader(headers: headers)
        }
        let boundary = APIRestClient.generateBoundaryString()
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
    
        let formData = APIRestClient.createMultiPartBody(parameters: parameters, files: files, boundary: boundary)
        return uploadTask(with: request, from: formData) { (data, response, error) in
            
            if let error = error {
                result(.failure(error))
                return
            }
            guard let response = response, let data = data else {
                let error = NSError(domain: "error", code: 0, userInfo: nil)
                result(.failure(error))
                return
            }
            result(.success((response, data)))
        }
    }
}

//------------------------------------------------------------------------------------------------
//-------------------------------------- SSL pinning ---------------------------------------------
//------------------------------------------------------------------------------------------------
class URLSessionHandle:NSObject,  URLSessionDelegate {
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if (challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust) {
            if let serverTrust = challenge.protectionSpace.serverTrust {
//                var secresult = SecTrustResultType.invalid
//                let status = SecTrustEvaluate(serverTrust, &secresult)
                let status = SecTrustEvaluateWithError(serverTrust, nil)
                
//                if (errSecSuccess == status) {
                if (status) {
                    if let serverCertificate = SecTrustGetCertificateAtIndex(serverTrust, 0) {
                        let serverCertificateData = SecCertificateCopyData(serverCertificate)
                        let data = CFDataGetBytePtr(serverCertificateData);
                        let size = CFDataGetLength(serverCertificateData);
                        let cert1 = NSData(bytes: data, length: size)
                        let file_der = Bundle.main.path(forResource: "name-of-cert-file", ofType: "cer")
                        
                        if let file = file_der {
                            if let cert2 = NSData(contentsOfFile: file) {
                                if cert1.isEqual(to: cert2 as Data) {
                                    completionHandler(URLSession.AuthChallengeDisposition.useCredential, URLCredential(trust:serverTrust))
                                    return
                                }
                            }
                        }
                    }
                }
            }
        }
        // Pinning failed
        completionHandler(URLSession.AuthChallengeDisposition.cancelAuthenticationChallenge, nil)
    }
}
//------------------------------------------------------------------------------------------------
