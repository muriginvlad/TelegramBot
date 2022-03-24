//
//  File.swift
//  
//
//  Created by Vladislav on 24.03.2022.
//

import Foundation

class DataFetcher {
    
    static let share = DataFetcher()
    
    private let urlSession: URLSession
    
    init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
    }
    
    private func request(url: URL, completionHandler: @escaping ((Data?, URLResponse?, Error?) -> Void)) {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let task = urlSession.dataTask(with: request, completionHandler: completionHandler)
        task.resume()
    }
    
    
    func getShortURL(urlString: String, closure: @escaping ((String) -> Void)) {
        let url = URL(string: "https://clck.ru/--?url=" + "\(urlString)")!
        
        request(url: url) { (data, response, error) in
            if let error = error {
                closure(error.localizedDescription)
            }
            
            guard let data = data else {
                print("DataFetcherErrors.didNotRecieveData")
                return
            }
            
            closure(String(decoding: data, as: UTF8.self))
        }
    }
}

