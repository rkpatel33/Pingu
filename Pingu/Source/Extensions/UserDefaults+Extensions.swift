//
//  UserDefaults+Extensions.swift
//  Pingu
//
//  Created by Thanos Theodoridis on 2/4/20.
//  Copyright © 2020 Thanos Theodoridis. All rights reserved.
//

import Foundation

extension UserDefaults {

    var launchAtLogin: Bool {
        get { bool(forKey: #function) }
        set { set(newValue, forKey: #function) }
    }

    var pingEnabled: Bool {
        get { bool(forKey: #function) }
        set { set(newValue, forKey: #function) }
    }

    var speedEnabled: Bool {
        get { bool(forKey: #function) }
        set { set(newValue, forKey: #function) }
    }

}
