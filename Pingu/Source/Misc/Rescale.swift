//
//  Rescale.swift
//  Pingu
//
//  Created by Thanos Theodoridis on 4/4/20.
//  Copyright © 2020 Thanos Theodoridis. All rights reserved.
//

func rescale<T: BinaryFloatingPoint>(_ x: T, from: (T, T), to: (T, T)) -> T {
    let b = (from.1 - from.0) != 0 ? (from.1 - from.0) : 1 / from.1
    let t = (x - from.0) / b
    return to.0 * (1 - t) + to.1 * t
}
