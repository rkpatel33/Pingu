//
//  SpeedResult.swift
//  Pingu
//

import Foundation

public enum SpeedResult {
    case speedInMbps(Double)
    case timeout
    case rateLimited
    case error
}
