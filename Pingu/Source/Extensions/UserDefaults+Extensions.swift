//
//  UserDefaults+Extensions.swift
//  Pingu
//
//  Created by Thanos Theodoridis on 2/4/20.
//  Copyright © 2020 Thanos Theodoridis. All rights reserved.
//

import Foundation

extension UserDefaults {
    
    var preferredPingInterval: TimeInterval {
        
        get {
            return double(forKey: #function)
        }
        
        set {
            set(newValue, forKey: #function)
        }
        
    }
    
    var launchAtLogin: Bool {

        get {
            return bool(forKey: #function)
        }

        set {
            set(newValue, forKey: #function)
        }

    }

    var pingEnabled: Bool {

        get {
            // Default to true if not set
            if object(forKey: #function) == nil {
                return true
            }
            return bool(forKey: #function)
        }

        set {
            set(newValue, forKey: #function)
        }

    }

    var speedEnabled: Bool {

        get {
            // Default to true if not set
            if object(forKey: #function) == nil {
                return true
            }
            return bool(forKey: #function)
        }

        set {
            set(newValue, forKey: #function)
        }

    }

}


