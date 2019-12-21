//
//  APIClient.swift
//  Contacts
//
//  Created by Uzair Dhada on 19/10/19.
//  Copyright © 2019 Go Jek. All rights reserved.
//

import Foundation

//-------------------------------------------------------------------------------------------------//
class APIClient: NSObject {
    //--------Shared Client (Singleton) --------------------------------------------------------
    struct SharedKeys {
        static let apiClient = APIClient()
    }
    
    public typealias SuccessHandler = (String, String) -> Void
    public typealias FailureHandler = ([String:Any], String, Int) -> Void
    
    
    static let shared = SharedKeys.apiClient
    
    let urlSession = URLSession.shared
    
    let restClient = APIRestClient.shared
    
    
    private override init() {
        
    }
}

//-------------------------------------------------------------------------------------------------//
extension Dictionary {
    
    func json() -> String {
        var returnValue  = "{}"
        if let jsonData = try? JSONSerialization.data(withJSONObject: self, options: .prettyPrinted) {
            if let jsonString = String.init(data: jsonData, encoding: String.Encoding.utf8) {
                returnValue =  jsonString
            }
        }
        returnValue = returnValue.trimmingCharacters(in: .whitespacesAndNewlines)
        return returnValue
    }
}
extension String {
    
    func decodeJson() ->Any? {
        guard let data  = self.data(using: String.Encoding.utf8) else { return nil }
        guard let jsonObj = try? JSONSerialization.jsonObject(with: data, options: []) else  { return nil }
        return jsonObj
    }
}

extension Data {
    func decodeJson() ->Any? {
        guard let jsonObj = try? JSONSerialization.jsonObject(with: self, options: []) else  { return nil }
        return jsonObj
    }
    func json() -> String? {
        if let jsonString = String.init(data: self, encoding: String.Encoding.utf8) {
            return jsonString
        }else {
            return nil
        }
    }
}

extension Array {
    func json() -> String {
        var returnValue  = "[]"
        if let jsonData = try? JSONSerialization.data(withJSONObject: self, options: JSONSerialization.WritingOptions.prettyPrinted) {
            if let jsonString = String.init(data: jsonData, encoding: String.Encoding.utf8) {
                returnValue =  jsonString
            }
        }
        returnValue = returnValue.trimmingCharacters(in: .whitespacesAndNewlines)
        return returnValue
    }
}




//---------------- API Generic Helpers -----------------------------------------------


extension APIClient {
    
    fileprivate var jsonDecoder: JSONDecoder  {
        let jsonDecoder = JSONDecoder()
//        jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-mm-dd"
        jsonDecoder.dateDecodingStrategy = .formatted(dateFormatter)
        return jsonDecoder
    }
    
    func apiRequestData<T: Decodable>(headers:[String:String]? = nil, params:[String:Any], url:URL, method: APIRestClient.HTTPMethod = .post, completion: @escaping (_ result:Result<T, APIRestClient.APIServiceError>) -> Void) {
        print("\n📍📍📍📍📍📍📍📍📍📍📍📍📍📍📍📍📍📍📍📍📍📍📍📍📍📍📍📍📍📍📍📍📍📍📍📍")
        print("\nAPI URL:👉 \(url.absoluteString)")
        print("\nAPI Params:👉 \(params.json())\n")
        print("\n📍📍📍📍📍📍📍📍📍📍📍📍📍📍📍📍📍📍📍📍📍📍📍📍📍📍📍📍📍📍📍📍📍📍📍📍")
        
        self.restClient.apiDataTask(url: url, method: method, headers: headers, parameters: params, result: { (result) in
            switch result {
            case .success(let (response, data)):
                guard let statusCode = (response as? HTTPURLResponse)?.statusCode, 200...201 ~= statusCode || 204 ~= statusCode else {
                    
                    switch (response as? HTTPURLResponse)?.statusCode {
                    case 404:
                        completion(.failure(.notFound404))
                    case 500:
                        completion(.failure(.internalServerError500))
                    case 422:
                        completion(.failure(.validationErrors422))
                    default:
                        completion(.failure(.invalidResponse))
                    }
                    return
                }
                print("\n📍📍📍📍📍📍📍📍📍📍📍📍📍📍📍📍📍📍📍📍📍📍📍📍📍📍📍📍📍📍📍📍📍📍📍📍")
                print("\nResponse:👉 \(String(describing: data.json()))")
                print("\n📍📍📍📍📍📍📍📍📍📍📍📍📍📍📍📍📍📍📍📍📍📍📍📍📍📍📍📍📍📍📍📍📍📍📍📍")
                do {
                    let values = try self.jsonDecoder.decode(T.self, from: data)
                    completion(.success(values))
                } catch {
                    if method == .delete && statusCode == 204 {
                        completion(.failure(.successWith204))
                    } else {
                        completion(.failure(.decodeError))
                    }
                }
                break
                
            case .failure(let error):
                print(error.localizedDescription)
                completion(.failure(.apiError))
                break
            }
        }).resume()
        
    }
    
    func apiRequestUpload<T: Decodable>(headers:[String:String]? = nil, params:[String:String], files:[String:Any], url:URL, completion: @escaping (_ result:Result<T, APIRestClient.APIServiceError>) -> Void) {
        print("\n📍📍📍📍📍📍📍📍📍📍📍📍📍📍📍📍📍📍📍📍📍📍📍📍📍📍📍📍📍📍📍📍📍📍📍📍")
        print("API URL:👉 \(url.absoluteString)")
        print("\nAPI Params:👉 \(params.json())")
        print("\n📍📍📍📍📍📍📍📍📍📍📍📍📍📍📍📍📍📍📍📍📍📍📍📍📍📍📍📍📍📍📍📍📍📍📍📍")
        
        self.restClient.apiUploadTask(url: url, headers: headers, parameters: params, files: files, result: { (result) in
            switch result {
            case .success(let (response, data)):
                guard let statusCode = (response as? HTTPURLResponse)?.statusCode, 200..<299 ~= statusCode else {
                    completion(.failure(.invalidResponse))
                    return
                }
                
                do {
                    let values = try self.jsonDecoder.decode(T.self, from: data)
                    completion(.success(values))
                } catch {
                    completion(.failure(.decodeError))
                }
                break
                
            case .failure(let error):
                print(error.localizedDescription)
                completion(.failure(.apiError))
                break
            }
        }).resume()
    }
}
