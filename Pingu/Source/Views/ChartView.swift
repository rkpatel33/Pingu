//
//  ChartView.swift
//  Pingu
//
//  Created by Thanos Theodoridis on 3/4/20.
//  Copyright © 2020 Thanos Theodoridis. All rights reserved.
//

import Foundation
import Cocoa

import SnapKit

class ChartView: NSView {

    // MARK: - Public Properties

    public var desiredWidth: CGFloat {
        var width: CGFloat = iconSize + iconMargin

        // Ping section
        if pingEnabled {
            width += pingBaseLineViewWidth + pingLabelMargin + pingLabel.frame.width
        } else {
            width += pingLabel.frame.width
        }

        // Gap + speed section
        width += sectionGap
        if speedEnabled {
            width += speedBaseLineViewWidth + speedLabelMargin + speedLabel.frame.width
        } else {
            width += speedLabel.frame.width
        }

        return width
    }

    public var pingEnabled: Bool = true {
        didSet {
            updateVisibility()
        }
    }

    public var speedEnabled: Bool = true {
        didSet {
            updateVisibility()
        }
    }

    // MARK: - Private Properties

    // Ping chart
    fileprivate var pingLabel: NSTextField
    fileprivate var pingBaselineView: NSView
    fileprivate var pingChartBarViews: [ChartBarView] = []
    fileprivate var pingResults: [PingResult] = Array(repeating: .responseInMilliseconds(0), count: 6)
    fileprivate let pingLabelMargin: CGFloat = 4
    fileprivate let pingBaseLineViewWidth: CGFloat = 23

    // Speed chart
    fileprivate var speedLabel: NSTextField
    fileprivate var speedBaselineView: NSView
    fileprivate var speedChartBarViews: [ChartBarView] = []
    fileprivate var speedResults: [SpeedResult] = Array(repeating: .speedInMbps(0), count: 6)
    fileprivate let speedLabelMargin: CGFloat = 4
    fileprivate let speedBaseLineViewWidth: CGFloat = 23

    // Spacing between ping and speed sections
    fileprivate let sectionGap: CGFloat = 6

    // Menu bar icon (always visible)
    fileprivate var iconView: NSImageView
    fileprivate let iconSize: CGFloat = 16
    fileprivate let iconMargin: CGFloat = 6

    // Legacy aliases for compatibility
    fileprivate var label: NSTextField { pingLabel }
    fileprivate var baselineView: NSView { pingBaselineView }
    fileprivate var chartBarViews: [ChartBarView] { pingChartBarViews }
    fileprivate var results: [PingResult] {
        get { pingResults }
        set { pingResults = newValue }
    }
    fileprivate let baseLineViewMargin: CGFloat = 4
    fileprivate let baseLineViewWidth: CGFloat = 23

    fileprivate var avgResponseTime: Float {

        var values: [Int] = []

        pingResults.forEach { r in
            if case .responseInMilliseconds(let v) = r {
                values.append(v)
            }
        }

        return values.isEmpty ? 0 : Float(values.reduce(0, +) / values.count)

    }

    fileprivate var avgSpeed: Double {

        var values: [Double] = []

        speedResults.forEach { r in
            if case .speedInMbps(let v) = r {
                values.append(v)
            }
        }

        return values.isEmpty ? 0 : values.reduce(0, +) / Double(values.count)

    }
    
    // MARK: - Lifecycle

    init() {

        pingLabel = NSTextField()
        pingBaselineView = NSView()
        speedLabel = NSTextField()
        speedBaselineView = NSView()
        iconView = NSImageView()

        super.init(frame: NSRect(x: 0, y: 0, width: 120, height: 22))

        configureViews()

    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Overrides

    override func updateLayer() {

        super.updateLayer()
        pingBaselineView.layer?.backgroundColor = NSColor.secondaryLabelColor.cgColor
        speedBaselineView.layer?.backgroundColor = NSColor.secondaryLabelColor.cgColor

    }
    
    // MARK: - Public Methods

    public func addResult(_ pingResult: PingResult) {

        pingResults.append(pingResult)

        if pingResults.count > 6 {
            pingResults = Array(pingResults.dropFirst())
        }

        updatePingLabel(forPingResult: pingResult)
        updatePingBarViews()

    }

    public func addSpeedResult(_ speedResult: SpeedResult) {

        speedResults.append(speedResult)

        if speedResults.count > 6 {
            speedResults = Array(speedResults.dropFirst())
        }

        updateSpeedLabel(forSpeedResult: speedResult)
        updateSpeedBarViews()

    }

    public func setPausedState(_ paused: Bool) {

        if paused {
            resetPing()
        }

    }

    public func setSpeedPausedState(_ paused: Bool) {

        if paused {
            resetSpeed()
        }

    }

    public func reset() {
        resetPing()
        resetSpeed()
    }

    public func resetPing() {

        pingLabel.stringValue = pingEnabled ? "n/a" : "OFF"
        pingLabel.sizeToFit()
        pingResults = Array(repeating: .responseInMilliseconds(0), count: 6)
        resetPingBarViews()

    }

    public func resetSpeed() {

        speedLabel.stringValue = speedEnabled ? "n/a" : "OFF"
        speedLabel.sizeToFit()
        speedResults = Array(repeating: .speedInMbps(0), count: 6)
        resetSpeedBarViews()

    }
    
    // MARK: - Private Methods

    fileprivate func configureViews() {

        // Configure menu bar icon
        iconView.image = ChartView.makeMenuBarIcon()
        iconView.imageScaling = .scaleNone
        addSubview(iconView)

        iconView.snp.makeConstraints { m in
            m.width.height.equalTo(iconSize)
            m.centerY.equalTo(self)
            m.left.equalTo(self)
        }

        // Configure ping label
        pingLabel.isBezeled = false
        pingLabel.isBordered = false
        pingLabel.isSelectable = false
        pingLabel.isEditable = false
        pingLabel.backgroundColor = .clear
        pingLabel.font = NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .regular)
        pingLabel.textColor = NSColor.secondaryLabelColor

        addSubview(pingLabel)

        // Configure ping baseline
        pingBaselineView.wantsLayer = true

        addSubview(pingBaselineView)

        pingBaselineView.snp.makeConstraints { m in
            m.height.equalTo(1)
            m.width.equalTo(pingBaseLineViewWidth)
            m.bottom.equalTo(self).offset(-4)
            m.left.equalTo(iconView.snp.right).offset(iconMargin)
        }

        pingLabel.snp.makeConstraints { m in
            m.height.equalTo(16)
            m.centerY.equalTo(self).offset(1.5)
            m.left.equalTo(pingBaselineView.snp.right).offset(pingLabelMargin)
        }

        // Create ping bar views
        for i in 0..<6 {

            let v = ChartBarView()
            addSubview(v)

            if i == 0 {

                v.snp.makeConstraints { m in
                    m.left.equalTo(pingBaselineView)
                    m.bottom.equalTo(pingBaselineView).offset(-2)
                    m.width.equalTo(3)
                    m.height.equalTo(1)
                }

            } else {

                v.snp.makeConstraints { m in
                    m.left.equalTo(pingChartBarViews[i-1].snp.right).offset(1)
                    m.bottom.equalTo(pingChartBarViews[i-1])
                    m.width.equalTo(3)
                    m.height.equalTo(1)
                }

            }

            pingChartBarViews.append(v)

        }

        // Configure speed label
        speedLabel.isBezeled = false
        speedLabel.isBordered = false
        speedLabel.isSelectable = false
        speedLabel.isEditable = false
        speedLabel.backgroundColor = .clear
        speedLabel.font = NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .regular)
        speedLabel.textColor = NSColor.secondaryLabelColor

        addSubview(speedLabel)

        // Configure speed baseline
        speedBaselineView.wantsLayer = true

        addSubview(speedBaselineView)

        speedBaselineView.snp.makeConstraints { m in
            m.height.equalTo(1)
            m.width.equalTo(speedBaseLineViewWidth)
            m.bottom.equalTo(self).offset(-4)
            m.left.equalTo(pingLabel.snp.right).offset(sectionGap)
        }

        speedLabel.snp.makeConstraints { m in
            m.height.equalTo(16)
            m.centerY.equalTo(self).offset(1.5)
            m.left.equalTo(speedBaselineView.snp.right).offset(speedLabelMargin)
        }

        // Create speed bar views
        for i in 0..<6 {

            let v = ChartBarView()
            addSubview(v)

            if i == 0 {

                v.snp.makeConstraints { m in
                    m.left.equalTo(speedBaselineView)
                    m.bottom.equalTo(speedBaselineView).offset(-2)
                    m.width.equalTo(3)
                    m.height.equalTo(1)
                }

            } else {

                v.snp.makeConstraints { m in
                    m.left.equalTo(speedChartBarViews[i-1].snp.right).offset(1)
                    m.bottom.equalTo(speedChartBarViews[i-1])
                    m.width.equalTo(3)
                    m.height.equalTo(1)
                }

            }

            speedChartBarViews.append(v)

        }

        // Initial visibility
        updateVisibility()

    }

    fileprivate func updateVisibility() {

        // Ping chart elements (baseline + bars)
        pingBaselineView.isHidden = !pingEnabled
        pingChartBarViews.forEach { $0.isHidden = !pingEnabled }

        // Speed chart elements (baseline + bars)
        speedBaselineView.isHidden = !speedEnabled
        speedChartBarViews.forEach { $0.isHidden = !speedEnabled }

        // Labels are always visible — show "OFF" when disabled
        if !pingEnabled {
            pingLabel.stringValue = "OFF"
            pingLabel.sizeToFit()
        }
        if !speedEnabled {
            speedLabel.stringValue = "OFF"
            speedLabel.sizeToFit()
        }

        // Ping label position
        if pingEnabled {
            pingBaselineView.snp.remakeConstraints { m in
                m.height.equalTo(1)
                m.width.equalTo(pingBaseLineViewWidth)
                m.bottom.equalTo(self).offset(-4)
                m.left.equalTo(iconView.snp.right).offset(iconMargin)
            }
            pingLabel.snp.remakeConstraints { m in
                m.height.equalTo(16)
                m.centerY.equalTo(self).offset(1.5)
                m.left.equalTo(pingBaselineView.snp.right).offset(pingLabelMargin)
            }
        } else {
            pingLabel.snp.remakeConstraints { m in
                m.height.equalTo(16)
                m.centerY.equalTo(self).offset(1.5)
                m.left.equalTo(iconView.snp.right).offset(iconMargin)
            }
        }

        // Speed label position
        if speedEnabled {
            speedBaselineView.snp.remakeConstraints { m in
                m.height.equalTo(1)
                m.width.equalTo(speedBaseLineViewWidth)
                m.bottom.equalTo(self).offset(-4)
                m.left.equalTo(pingLabel.snp.right).offset(sectionGap)
            }
            speedLabel.snp.remakeConstraints { m in
                m.height.equalTo(16)
                m.centerY.equalTo(self).offset(1.5)
                m.left.equalTo(speedBaselineView.snp.right).offset(speedLabelMargin)
            }
        } else {
            speedLabel.snp.remakeConstraints { m in
                m.height.equalTo(16)
                m.centerY.equalTo(self).offset(1.5)
                m.left.equalTo(pingLabel.snp.right).offset(sectionGap)
            }
        }

    }

    fileprivate func updatePingLabel(forPingResult pingResult: PingResult) {

        switch pingResult {

        case .responseInMilliseconds(let v):
            pingLabel.stringValue = "\(v)ms"

        case .timeout:
            pingLabel.stringValue = "t/o"

        default:
            pingLabel.stringValue = "n/a"
        }

        pingLabel.sizeToFit()

    }

    fileprivate func updateSpeedLabel(forSpeedResult speedResult: SpeedResult) {

        switch speedResult {

        case .speedInMbps(let v):
            if v >= 100 {
                speedLabel.stringValue = "\(Int(v))M"
            } else {
                speedLabel.stringValue = String(format: "%.1fM", v)
            }

        case .timeout, .error:
            speedLabel.stringValue = "t/o"

        case .rateLimited:
            speedLabel.stringValue = "lim"

        }

        speedLabel.sizeToFit()

    }

    fileprivate func updatePingBarViews() {

        for (i, result) in pingResults.enumerated() {
            pingChartBarViews[i].configure(with: result, avgResponseTime: avgResponseTime)
        }

    }

    fileprivate func updateSpeedBarViews() {

        for (i, result) in speedResults.enumerated() {
            speedChartBarViews[i].configure(with: result, avgSpeed: avgSpeed)
        }

    }

    fileprivate func resetPingBarViews() {
        pingChartBarViews.forEach { $0.reset() }
    }

    fileprivate func resetSpeedBarViews() {
        speedChartBarViews.forEach { $0.reset() }
    }

    fileprivate static func makeMenuBarIcon() -> NSImage {
        let config = NSImage.SymbolConfiguration(pointSize: 13, weight: .medium)
        let image = NSImage(systemSymbolName: "dot.radiowaves.left.and.right", accessibilityDescription: "Pingu")!
        return image.withSymbolConfiguration(config)!
    }

}
