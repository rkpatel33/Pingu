//
//  ChartPopoverView.swift
//  Pingu
//

import SwiftUI
import Charts

struct ChartPopoverView: View {

    @ObservedObject var data: MonitorData
    var pingEnabled: Bool
    var speedEnabled: Bool

    var body: some View {
        HStack(spacing: 24) {
            pingChart
            speedChart
        }
        .padding(20)
        .frame(width: 560, height: 280)
    }

    // MARK: - Ping Chart

    private var pingChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text("Ping")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                Spacer()
                if !pingEnabled {
                    Text("OFF")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.secondary)
                } else if let latest = data.latestPing {
                    if latest.value < 0 {
                        Text("Timeout")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.red)
                    } else {
                        Text("\(latest.value)ms")
                            .font(.system(size: 20, weight: .medium).monospacedDigit())
                            .foregroundColor(.primary)
                    }
                }
            }

            if !pingEnabled {
                Spacer()
            } else { Chart {
                ForEach(validPings) { point in
                    AreaMark(
                        x: .value("Time", point.date),
                        y: .value("ms", point.value)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(
                        .linearGradient(
                            colors: [.blue.opacity(0.2), .blue.opacity(0.02)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                    LineMark(
                        x: .value("Time", point.date),
                        y: .value("ms", point.value)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(.blue)
                    .lineStyle(StrokeStyle(lineWidth: 1.5))
                }

                // Timeouts
                ForEach(timeoutPings) { point in
                    PointMark(
                        x: .value("Time", point.date),
                        y: .value("ms", 0)
                    )
                    .foregroundStyle(.red.opacity(0.8))
                    .symbolSize(30)
                }

                // Warning threshold
                RuleMark(y: .value("Warning", 80))
                    .foregroundStyle(.orange.opacity(0.4))
                    .lineStyle(StrokeStyle(lineWidth: 0.5, dash: [4, 3]))

                // Danger threshold
                RuleMark(y: .value("Danger", 150))
                    .foregroundStyle(.red.opacity(0.4))
                    .lineStyle(StrokeStyle(lineWidth: 0.5, dash: [4, 3]))
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .minute, count: 2)) {
                    AxisValueLabel(format: .dateTime.hour().minute())
                        .font(.system(size: 9))
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(.quaternary)
                }
            }
            .chartYAxis {
                AxisMarks {
                    AxisValueLabel()
                        .font(.system(size: 9))
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(.quaternary)
                }
            }
            .chartYAxisLabel("ms", position: .top, alignment: .trailing)
            }
        }
    }

    // MARK: - Speed Chart

    private var speedChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text("Speed")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                Spacer()
                if !speedEnabled {
                    Text("OFF")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.secondary)
                } else if let latest = data.latestSpeed {
                    if latest.value < 0 {
                        Text(latest.value == -2 ? "Rate Limited" : "Timeout")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(latest.value == -2 ? .orange : .red)
                    } else if latest.value >= 100 {
                        Text("\(Int(latest.value)) Mbps")
                            .font(.system(size: 20, weight: .medium).monospacedDigit())
                            .foregroundColor(.primary)
                    } else {
                        Text(String(format: "%.1f Mbps", latest.value))
                            .font(.system(size: 20, weight: .medium).monospacedDigit())
                            .foregroundColor(.primary)
                    }
                }
            }

            if !speedEnabled {
                Spacer()
            } else { Chart {
                ForEach(validSpeeds) { point in
                    AreaMark(
                        x: .value("Time", point.date),
                        y: .value("Mbps", point.value)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(
                        .linearGradient(
                            colors: [.blue.opacity(0.2), .blue.opacity(0.02)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                    LineMark(
                        x: .value("Time", point.date),
                        y: .value("Mbps", point.value)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(.blue)
                    .lineStyle(StrokeStyle(lineWidth: 1.5))
                }

                // Timeouts/errors
                ForEach(failedSpeeds) { point in
                    PointMark(
                        x: .value("Time", point.date),
                        y: .value("Mbps", 0)
                    )
                    .foregroundStyle(point.value == -2 ? .orange.opacity(0.8) : .red.opacity(0.8))
                    .symbolSize(30)
                }

                // Slow threshold
                RuleMark(y: .value("Slow", 10))
                    .foregroundStyle(.red.opacity(0.4))
                    .lineStyle(StrokeStyle(lineWidth: 0.5, dash: [4, 3]))

                // Moderate threshold
                RuleMark(y: .value("Moderate", 25))
                    .foregroundStyle(.orange.opacity(0.4))
                    .lineStyle(StrokeStyle(lineWidth: 0.5, dash: [4, 3]))
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .minute, count: 2)) {
                    AxisValueLabel(format: .dateTime.hour().minute())
                        .font(.system(size: 9))
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(.quaternary)
                }
            }
            .chartYAxis {
                AxisMarks {
                    AxisValueLabel()
                        .font(.system(size: 9))
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(.quaternary)
                }
            }
            .chartYAxisLabel("Mbps", position: .top, alignment: .trailing)
            }
        }
    }

    // MARK: - Helpers

    private var validPings: [TimestampedPing] {
        data.pingHistory.filter { $0.value >= 0 }
    }

    private var timeoutPings: [TimestampedPing] {
        data.pingHistory.filter { $0.value < 0 }
    }

    private var validSpeeds: [TimestampedSpeed] {
        data.speedHistory.filter { $0.value >= 0 }
    }

    private var failedSpeeds: [TimestampedSpeed] {
        data.speedHistory.filter { $0.value < 0 }
    }

}
