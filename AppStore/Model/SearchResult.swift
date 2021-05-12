//
//  SearchResult.swift
//  AppStore
//
//  Created by horkimlong on 28/12/20.
//

import Foundation

struct SearchResults: Decodable {
    let resultCount: Int
    let results: [Result]
}

struct Result: Decodable {
    let trackId: Int
    let trackName: String
    let primaryGenreName: String
    let averageUserRating: Float?
    var screenshotUrls: [String]?
    let artworkUrl100: String // app icon
    
    var formattedPrice: String?
    var description: String?
    var releaseNotes: String?
    
    var artistName: String?
    var collectionName: String?
}
