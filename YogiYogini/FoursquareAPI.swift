//
//  FoursquareAPI.swift
//  YogiYogini
//
//  Created by A. Anthony Castillo on 3/3/16.
//  Copyright © 2016 Alon Consulting. All rights reserved.
//

import Foundation

private let kCLIENT_ID = "JVA4E2YMEKOMFDOQSC05U12U225EJHHQHIHY41TPRNQQWYXW"
private let kCLIENT_SECRET = "J223UY0ECDXCGI0MYXVJIUGYVFSULGLNQOEZMH42KMEGEIHT"
private let kAPI_VERSION = "20151201"
private let kAPI_TYPE = "foursquare"
private let kYOGA_SEARCH_CATEGORY_ID = "4bf58dd8d48988d102941735"

private struct FourSquareURL
{
    static let Venues = "https://api.foursquare.com/v2/venues/explore"
    static let Search = "https://api.foursquare.com/v2/venues/search"
}

class FoursquareRequestController: NSObject
{
    typealias CompletionHander = (result: AnyObject!, error: NSError?) -> Void
    
    private func escapedParameters(parameters: [String : AnyObject]) -> String
    {
        var urlVars = [String]()
        for (key, value) in parameters {
            
            let stringValue = "\(value)"
            let escapedValue = stringValue.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
            urlVars += [key + "=" + "\(escapedValue!)"]
        }
        return (!urlVars.isEmpty ? "?" : "") + urlVars.joinWithSeparator("&")
    }
    
    private func callAPIEndpoint(url: String, arguments: NSDictionary, apiCompletion: CompletionHander)
    {
        let session = NSURLSession.sharedSession()
        let urlString = url + escapedParameters(arguments as! [String : AnyObject])
        let url = NSURL(string: urlString)!
        let request = NSURLRequest(URL: url)
        let task = session.dataTaskWithRequest(request)
        { (data, response, error) in
            
            guard (error == nil) else
            {
                let errorJSON = ["error": "There was an error with the call to Foursquare."]
                apiCompletion(result: errorJSON, error: error)
                return
            }
            
            guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else
            {
                var errorJSON = [String: String]()
                if let response = response as? NSHTTPURLResponse {
                    errorJSON = ["error": "Your request returned an invalid response. Status code: \(response.statusCode)!"]
                    
                } else if let response = response {
                    errorJSON = ["error": "Your request returned an invalid response. Response: \(response)!"]
                    
                } else {
                    errorJSON = ["error": "Your request returned an invalid response."]
                }
                apiCompletion(result: errorJSON, error: error)
                return
            }
            
            guard let data = data else
            {
                let errorJSON = ["error": "No data was returned by the request!"]
                apiCompletion(result: errorJSON, error: error)
                return
            }
            
            let json: AnyObject!
            do {
                json = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
                apiCompletion(result: json, error: error)
                
            } catch {
                let errorJSON = ["error": "Could not parse the data as JSON: \n'\(data)'"]
                apiCompletion(result: errorJSON, error: nil)
                return
            }
        }
        task.resume()
    }
    
    func exploreVenues(lat: Double, lon: Double, query: String, completion: CompletionHander)
    {
        let coords = "\(lat),\(lon)"
        let methodArguments = [
            "client_id": kCLIENT_ID,
            "client_secret": kCLIENT_SECRET,
            "ll": coords,
            "v": kAPI_VERSION,
            "m": kAPI_TYPE,
            "sortByDistance": "1",
            "query": query,
        ]
        
        callAPIEndpoint(FourSquareURL.Venues, arguments: methodArguments, apiCompletion:
        { (json, error) in
            
            guard error == nil else
            {
                completion(result: json, error: error)
                return
            }
            
            guard let meta = json["meta"] as? NSDictionary else {
                print("Cannot get meta info from root dictionary: \(json)")
                // TODO: error condition
                return
            }
            
            guard let response = json["response"] as? NSDictionary else {
                print("Cannot find response in root: \(json)")
                // TODO: error condition
                return
            }
            
            guard let group = response["groups"]![0] as? NSDictionary else {
                print("Could not get group from response: \(response)")
                // TODO: error condition
                return
            }
            
            guard let venues = group["items"] as? NSArray else {
                print("Could not get venues from group: \(group)")
                // TODO: error condition
                return
            }
            let result = NSDictionary(objects: [meta, venues], forKeys: ["meta", "venues"])
            completion(result: result, error: error)
        })
    }
    
    func searchYogaVenues(lat: Double, lon: Double, name: String, completion:CompletionHander)
    {
        let coords = "\(lat),\(lon)"
        let methodArguments = [
            "client_id": kCLIENT_ID,
            "client_secret": kCLIENT_SECRET,
            "ll": coords,
            "v": kAPI_VERSION,
            "m": kAPI_TYPE,
            "query": name,
        ]
        
        callAPIEndpoint(FourSquareURL.Search, arguments: methodArguments, apiCompletion: { (json, error) in
            
            guard error == nil else
            {
                completion(result: json, error: error)
                return
            }
            
            guard let meta = json["meta"] as? NSDictionary else {
                print("Cannot get meta info from root dictionary: \(json)")
                // TODO: error condition
                return
            }
            
            guard let response = json["response"] as? NSDictionary else {
                print("Cannot find response in root: \(json)")
                // TODO: error condition
                return
            }
            
            guard let venues = response["venues"] as? NSArray else {
                print("Could not get venues from response: \(response)")
                // TODO: error condition
                return
            }
            let result = NSDictionary(objects: [meta, venues], forKeys: ["meta", "venues"])
            completion(result: result, error: error)
        })
    }
}