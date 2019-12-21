//
//  APIHelper.swift
//  Contacts
//
//  Created by Uzair Dhada on 19/10/19.
//  Copyright © 2019 Go Jek. All rights reserved.
//

import Foundation

protocol APIEnvironmentRequirements {
    var baseURL:String { get }
//    var apiVersion:String {get}
}

enum API : String {
    case login       = "https://reqres.in/"
}


enum APIEnvironment: APIEnvironmentRequirements {
    
    case alpha   /* ------- Development -----------*/
    case beta    /* ------- STAGING ---------------*/
    case preProd /* ------- PRE PRODUCTION --------*/
    case prod    /* ------- PRODUCTION ------------*/
    
    var baseURL: String {
        
        switch self {
        case .alpha :   return ""
        case .beta:     return ""
        case .preProd:  return ""
        case .prod:     return ""
        }
    }
    
//    var apiVersion: String {
//        switch self {
//        case .alpha:    return "1.0"
//        case .beta:     return "1.0"
//        case .preProd:  return "1.0"
//        case .prod:     return "1.0"
//        }
//    }
    
}


extension API {
    //-------- Environment must be defained in confing not here this for testing -----
    static var environment:APIEnvironment = .beta    //----------------------------------------------------------------//
}


protocol APICallRequirements {
    var apiRelativePath:String  { get }
    var url:String { get }
    
    var apiHeader: [String:String]! {get}
//    func finalParameters(from parameters: [String : Any]) -> [String : Any]

    func apiRequestData<T: Decodable>(method:APIRestClient.HTTPMethod?, params:[String:Any], completion: @escaping (_ result:Result<T, APIRestClient.APIServiceError>) -> Void)
    func apiRequestUpload<T: Decodable>(params:[String:String], files:[String:Any], completion: @escaping (_ result:Result<T, APIRestClient.APIServiceError>) -> Void)
}

extension API : APICallRequirements {
    
    var apiRelativePath:String {
        return API.environment.baseURL /*+ API.environment.apiVersion*/
    }
    
    var apiHeader: [String : String]! {
        return [/*"Content-Type":"application/json",*/
                "access-control-allow-headers": "Origin, X-Requested-With, Content-Type, Accept",
            "access-control-allow-methods": "GET, POST, PUT",
            "access-control-allow-origin":"*",
            "server": "cloudflare-nginx"]
    }
    
//    func finalParameters(from parameters: [String : Any]) -> [String : Any] {
//
//        let finalParameters  = parameters
//        if self != .appConfig {
//
//        }else {
//
//        }
//
//        return finalParameters
//
//    }
    
    private static var client = APIClient.shared
    var url:String {
      
        switch self {
            
        default:
            return self.rawValue
        }
       
    }

    
    //--------------------------------- REST CLIENT GENERIC API's-----------------------------------------------------------
    
    func apiRequestData<T: Decodable>(method:APIRestClient.HTTPMethod? = .post, params:[String:Any], completion: @escaping (_ result:Result<T, APIRestClient.APIServiceError>) -> Void) {
        
//        let finalParams = self.finalParameters(from: params)
        let headers = self.apiHeader
        
//        switch self {
//        case .detailContact:
//            let url = self.url + (params["contactID"] as! String) + ".json"
//            var params = params
//            params.removeValue(forKey: "contactID")
//            API.client.apiRequestData(headers: headers, params: params, url: URL(string: url)!, method: method ?? .post, completion: completion)
//        default:
            API.client.apiRequestData(headers: headers, params: params, url: URL(string: self.url)!, method: method ?? .post, completion: completion)
//        }
    }
    

    func apiRequestUpload<T: Decodable>(params:[String:String], files:[String:Any], completion: @escaping (_ result:Result<T, APIRestClient.APIServiceError>) -> Void) {
        
//        let finalParams = self.finalParameters(from: params)
        let headers = self.apiHeader
        
//        if let uploadParams = finalParams as? [String:String] {
            API.client.apiRequestUpload(headers: headers, params: params, files: files, url: URL(string: self.url)!, completion: completion)
//        } else {
//            print("For upload request, We only supports [String:String] params as post.")
//        }
    }
}
