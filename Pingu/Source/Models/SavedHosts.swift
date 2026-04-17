//
//  SavedHosts.swift
//  Pingu
//
//  Created by Thanos Theodoridis on 3/4/20.
//  Copyright © 2020 Thanos Theodoridis. All rights reserved.
//

import Foundation

class SavedHosts: Codable {
    
    // MARK: - Static Properties
    
    static let storeKey = "com.pingu.save-hosts"
    
    // MARK: - Public Properties
    
    public private(set) var hosts: [Host] = []
    public var selectedHost: Host? {
        hosts.first { $0.selected }
    }
    
    // MARK: - Static Methods
    
    static func load(fromStore store: UserDefaults) -> SavedHosts {
        guard let data = store.data(forKey: SavedHosts.storeKey),
              let saved = try? JSONDecoder().decode(SavedHosts.self, from: data) else {
            return SavedHosts()
        }
        return saved
    }
    
    // MARK: - Public Methods

    public func save(toStore store: UserDefaults) {
        
        let encoder = JSONEncoder()
        
        if let encoded = try? encoder.encode(self) {
            store.set(encoded, forKey: SavedHosts.storeKey)
        }
        
    }
    
    public func add(_ newHost: Host) {
        
        if hosts.count >= 5 {
            hosts = hosts.dropLast()
        }
        
        hosts.insert(newHost, at: 0)
        setSelected(newHost)
        
    }
    
    public func setSelected(_ selectedHost: Host) {
        hosts.forEach { $0.selected = false }
        hosts.first(where: { $0 == selectedHost })?.selected = true
    }
    
}
