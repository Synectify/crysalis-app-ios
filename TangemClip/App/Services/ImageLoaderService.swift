//
//  ImageLoaderService.swift
//  TangemClip
//
//  Created by Andrew Son on 23/03/21.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import UIKit

class ImageLoaderService {
    enum ImageEndpoint: NetworkEndpoint {
        case byBatch(String)
        case byNdefLink(URL)
        
        private var baseURL: URL {
            URL(string: "https://raw.githubusercontent.com/tangem/ndef-registry/main")!
        }
        
        private var imageSuffix: String { "card.png" }
        
        var url: URL {
            switch self {
            case .byBatch(let batch):
                let url = baseURL.appendingPathComponent(batch)
                    .appendingPathComponent(imageSuffix)
                return url
            case .byNdefLink(let link):
                let url = link.appendingPathComponent(imageSuffix)
                return url
            }
        }
        
        var method: String {
            switch self {
            case .byBatch, .byNdefLink:
                return "GET"
            }
        }
        
        var body: Data? {
            nil
        }
        
        var headers: [String : String] {
            ["application/json" : "Content-Type"]
        }
        
    }
    
    enum BackedImages {
        case sergio, marta, `default`, twinCardOne, twinCardTwo
        
        var name: String {
            switch self {
            case .sergio: return "card_tg059"
            case .marta: return "card_tg083"
            case .default: return "card_default"
            case .twinCardOne: return "card_tg085"
            case .twinCardTwo: return "card_tg086"
            }
        }
    }
    
    let networkService: NetworkService
    
    init(networkService: NetworkService) {
        self.networkService = networkService
    }
    
    func loadImage(with cid: String, pubkey: Data, for artworkInfo: ArtworkInfo) -> AnyPublisher<UIImage?, Error> {
        let endpoint = TangemEndpoint.artwork(cid: cid, cardPublicKey: pubkey, artworkId: artworkInfo.id)
        return publisher(for: endpoint)
    }
    
    func loadImage(batch: String) -> AnyPublisher<UIImage?, Error> {
        if batch.isEmpty {
            return backedLoadImage(.default)
        }
        
        let endpoint = ImageEndpoint.byBatch(batch)
        
        return publisher(for: endpoint)
    }
    
    func loadImage(byNdefLink link: String) -> AnyPublisher<UIImage?, Error> {
        guard let url = URL(string: link) else {
            return backedLoadImage(.default)
        }
        
        return publisher(for: ImageEndpoint.byNdefLink(url))
    }
    
    func backedLoadImage(name: String) -> AnyPublisher<UIImage?, Error> {
        let configuration = URLSessionConfiguration.default
        configuration.requestCachePolicy = .returnCacheDataElseLoad
        let session = URLSession(configuration: configuration)
        return session
            .dataTaskPublisher(for: URL(string: "https://app.tangem.com/cards/\(name).png")!)
            .subscribe(on: DispatchQueue.global())
            .tryMap { data, response -> UIImage? in
                if let image = UIImage(data: data) {
                    return image
                }
                
                return nil
            }.eraseToAnyPublisher()
    }
    
    func backedLoadImage(_ image: BackedImages) -> AnyPublisher<UIImage?, Error> {
        backedLoadImage(name: image.name)
    }
    
    private func publisher(for endpoint: NetworkEndpoint) -> AnyPublisher<UIImage?, Error> {
        return networkService
            .requestPublisher(endpoint)
            .subscribe(on: DispatchQueue.global())
            .tryMap { data -> UIImage? in
                if let image = UIImage(data: data) {
                    return image
                }
                
                return nil
            }
            .tryCatch {[weak self] error -> AnyPublisher<UIImage?, Error> in
                guard let self = self else {
                    throw error
                }
                
                return self.backedLoadImage(name: BackedImages.default.name)
            }
            .eraseToAnyPublisher()
    }
}
