//
//  Service.swift
//  AppStore
//
//  Created by horkimlong on 28/12/20.
//

import Foundation

class Service {
    static let shared = Service() // singleton
    
    func fetchApps(searchTerm: String, completion: @escaping (SearchResults?, Error?) -> ()) {
        let urlString = "https://itunes.apple.com/search?term=\(searchTerm)&entity=software"
        
        fetchGenericJSONData(urlString: urlString, completion: completion)
    }
    
    func fetchGames(completion: @escaping (AppGroup?, Error?) -> ()) {
        let url = "https://rss.itunes.apple.com/api/v1/us/ios-apps/new-games-we-love/all/50/explicit.json"
        
        fetchGenericJSONData(urlString: url, completion: completion)
    }
    
    func fetchTopGrossing(completion: @escaping (AppGroup?, Error?) -> ()) {
        let url = "https://rss.itunes.apple.com/api/v1/us/ios-apps/top-grossing/all/50/explicit.json"
        
        fetchGenericJSONData(urlString: url, completion: completion)
    }
    
    func fetchTopFreeApp(completion: @escaping (AppGroup?, Error?) -> ()) {
        let url = "https://rss.itunes.apple.com/api/v1/us/ios-apps/top-free/all/50/explicit.json"
        
        fetchGenericJSONData(urlString: url, completion: completion)
    }
    
    
    func fetchSocialApps(completion: @escaping ([SocialApp]?, Error?) -> Void) {
        let urlString = "https://api.letsbuildthatapp.com/appstore/social"
        
        fetchGenericJSONData(urlString: urlString, completion: completion)
    }
    
    func fetchGenericJSONData<T: Decodable>(urlString: String, completion: @escaping (T?, Error?) -> ()) {
        guard let url = URL(string: urlString) else {return}
        
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            
            if let error = error {
                completion(nil, error)
                return
            }
            
            do {
                guard let safeData = data else {return}
                let objects = try JSONDecoder().decode(T.self, from: safeData)
                
//                appGroup.feed.results.forEach({print($0.name)})
                completion(objects, nil)
                
            } catch {
                print("Fail to decode: ", error)
                completion(nil, error)
            }
        }.resume()
    }
}

// Stack

class Stack<T> {
    var items = [T]()
    
    func push(item: T) {
        items.append(item)
    }
    
    func pop() -> T? {
        return items.last
    }
}

