//
//  Data+Extensions.swift
//  Pingu
//
//  Created by Thanos Theodoridis on 4/4/20.
//  Copyright © 2020 Thanos Theodoridis. All rights reserved.
//

import Foundation

extension Data {

    public var socketAddress: sockaddr {
        self.withUnsafeBytes { buffer in
            buffer.load(as: sockaddr.self)
        }
    }

}
