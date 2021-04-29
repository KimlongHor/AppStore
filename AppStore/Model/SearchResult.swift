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
    let screenshotUrls: [String]
    let artworkUrl100: String // app icon
    
    var formattedPrice: String?
    let description: String
    var releaseNotes: String?
}
