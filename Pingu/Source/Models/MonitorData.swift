//
//  MonitorData.swift
//  Pingu
//

import Foundation
import Combine

struct TimestampedPing: Identifiable {
    let id = UUID()
    let date: Date
    let value: Int // milliseconds, -1 for timeout
}

struct TimestampedSpeed: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double // Mbps, -1 for error, -2 for rate limited
}

class MonitorData: ObservableObject {

    @Published var pingHistory: [TimestampedPing] = []
    @Published var speedHistory: [TimestampedSpeed] = []

    private let maxAge: TimeInterval = 900 // 15 minutes

    var latestPing: TimestampedPing? {
        pingHistory.last
    }

    var latestSpeed: TimestampedSpeed? {
        speedHistory.last
    }

    func addPing(_ result: PingResult) {
        let entry: TimestampedPing
        switch result {
        case .responseInMilliseconds(let ms):
            entry = TimestampedPing(date: Date(), value: ms)
        case .timeout:
            entry = TimestampedPing(date: Date(), value: -1)
        default:
            return
        }
        pingHistory.append(entry)
        trimPingHistory()
    }

    func addSpeed(_ result: SpeedResult) {
        let entry: TimestampedSpeed
        switch result {
        case .speedInMbps(let mbps):
            entry = TimestampedSpeed(date: Date(), value: mbps)
        case .timeout, .error:
            entry = TimestampedSpeed(date: Date(), value: -1)
        case .rateLimited:
            entry = TimestampedSpeed(date: Date(), value: -2)
        }
        speedHistory.append(entry)
        trimSpeedHistory()
    }

    private func trimPingHistory() {
        let cutoff = Date().addingTimeInterval(-maxAge)
        pingHistory.removeAll { $0.date < cutoff }
    }

    private func trimSpeedHistory() {
        let cutoff = Date().addingTimeInterval(-maxAge)
        speedHistory.removeAll { $0.date < cutoff }
    }

}
