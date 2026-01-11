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
        var width: CGFloat = 0

        if pingEnabled {
            width += pingBaseLineViewWidth + pingLabelMargin + pingLabel.frame.width
        }

        if speedEnabled {
            if pingEnabled {
                width += separatorMargin * 2 + separatorWidth
            }
            width += speedBaseLineViewWidth + speedLabelMargin + speedLabel.frame.width
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
    fileprivate let pingLabelMargin: CGFloat = 6
    fileprivate let pingBaseLineViewWidth: CGFloat = 22

    // Speed chart
    fileprivate var speedLabel: NSTextField
    fileprivate var speedBaselineView: NSView
    fileprivate var speedChartBarViews: [ChartBarView] = []
    fileprivate var speedResults: [SpeedResult] = Array(repeating: .speedInMbps(0), count: 6)
    fileprivate let speedLabelMargin: CGFloat = 6
    fileprivate let speedBaseLineViewWidth: CGFloat = 22

    // Separator
    fileprivate var separatorView: NSView
    fileprivate let separatorWidth: CGFloat = 1
    fileprivate let separatorMargin: CGFloat = 8

    // Legacy aliases for compatibility
    fileprivate var label: NSTextField { pingLabel }
    fileprivate var baselineView: NSView { pingBaselineView }
    fileprivate var chartBarViews: [ChartBarView] { pingChartBarViews }
    fileprivate var results: [PingResult] {
        get { pingResults }
        set { pingResults = newValue }
    }
    fileprivate let baseLineViewMargin: CGFloat = 6
    fileprivate let baseLineViewWidth: CGFloat = 22

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
        separatorView = NSView()

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
        separatorView.layer?.backgroundColor = NSColor.tertiaryLabelColor.cgColor

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

        pingLabel.stringValue = "n/a"
        pingResults = Array(repeating: .responseInMilliseconds(0), count: 6)
        resetPingBarViews()

    }

    public func resetSpeed() {

        speedLabel.stringValue = "n/a"
        speedResults = Array(repeating: .speedInMbps(0), count: 6)
        resetSpeedBarViews()

    }
    
    // MARK: - Private Methods

    fileprivate func configureViews() {

        // Configure ping label
        pingLabel.isBezeled = false
        pingLabel.isBordered = false
        pingLabel.isSelectable = false
        pingLabel.isEditable = false
        pingLabel.backgroundColor = .clear

        addSubview(pingLabel)

        // Configure ping baseline
        pingBaselineView.wantsLayer = true

        addSubview(pingBaselineView)

        pingBaselineView.snp.makeConstraints { m in
            m.height.equalTo(1)
            m.width.equalTo(pingBaseLineViewWidth)
            m.bottom.equalTo(self).offset(-4)
            m.left.equalTo(self)
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
                    m.width.equalTo(2)
                    m.height.equalTo(1)
                }

            } else {

                v.snp.makeConstraints { m in
                    m.left.equalTo(pingChartBarViews[i-1].snp.right).offset(2)
                    m.bottom.equalTo(pingChartBarViews[i-1])
                    m.width.equalTo(2)
                    m.height.equalTo(1)
                }

            }

            pingChartBarViews.append(v)

        }

        // Configure separator
        separatorView.wantsLayer = true
        addSubview(separatorView)

        separatorView.snp.makeConstraints { m in
            m.height.equalTo(14)
            m.width.equalTo(separatorWidth)
            m.centerY.equalTo(self)
            m.left.equalTo(pingLabel.snp.right).offset(separatorMargin)
        }

        // Configure speed label
        speedLabel.isBezeled = false
        speedLabel.isBordered = false
        speedLabel.isSelectable = false
        speedLabel.isEditable = false
        speedLabel.backgroundColor = .clear

        addSubview(speedLabel)

        // Configure speed baseline
        speedBaselineView.wantsLayer = true

        addSubview(speedBaselineView)

        speedBaselineView.snp.makeConstraints { m in
            m.height.equalTo(1)
            m.width.equalTo(speedBaseLineViewWidth)
            m.bottom.equalTo(self).offset(-4)
            m.left.equalTo(separatorView.snp.right).offset(separatorMargin)
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
                    m.width.equalTo(2)
                    m.height.equalTo(1)
                }

            } else {

                v.snp.makeConstraints { m in
                    m.left.equalTo(speedChartBarViews[i-1].snp.right).offset(2)
                    m.bottom.equalTo(speedChartBarViews[i-1])
                    m.width.equalTo(2)
                    m.height.equalTo(1)
                }

            }

            speedChartBarViews.append(v)

        }

        // Initial visibility
        updateVisibility()

    }

    fileprivate func updateVisibility() {

        // Ping views
        pingLabel.isHidden = !pingEnabled
        pingBaselineView.isHidden = !pingEnabled
        pingChartBarViews.forEach { $0.isHidden = !pingEnabled }

        // Speed views
        speedLabel.isHidden = !speedEnabled
        speedBaselineView.isHidden = !speedEnabled
        speedChartBarViews.forEach { $0.isHidden = !speedEnabled }

        // Separator only visible when both are enabled
        separatorView.isHidden = !(pingEnabled && speedEnabled)

        // Update constraints based on visibility
        if pingEnabled && !speedEnabled {
            // Only ping - position at left
            pingBaselineView.snp.remakeConstraints { m in
                m.height.equalTo(1)
                m.width.equalTo(pingBaseLineViewWidth)
                m.bottom.equalTo(self).offset(-4)
                m.left.equalTo(self)
            }
        } else if !pingEnabled && speedEnabled {
            // Only speed - position at left
            speedBaselineView.snp.remakeConstraints { m in
                m.height.equalTo(1)
                m.width.equalTo(speedBaseLineViewWidth)
                m.bottom.equalTo(self).offset(-4)
                m.left.equalTo(self)
            }
            speedLabel.snp.remakeConstraints { m in
                m.height.equalTo(16)
                m.centerY.equalTo(self).offset(1.5)
                m.left.equalTo(speedBaselineView.snp.right).offset(speedLabelMargin)
            }
        } else if pingEnabled && speedEnabled {
            // Both enabled - restore normal layout
            pingBaselineView.snp.remakeConstraints { m in
                m.height.equalTo(1)
                m.width.equalTo(pingBaseLineViewWidth)
                m.bottom.equalTo(self).offset(-4)
                m.left.equalTo(self)
            }
            speedBaselineView.snp.remakeConstraints { m in
                m.height.equalTo(1)
                m.width.equalTo(speedBaseLineViewWidth)
                m.bottom.equalTo(self).offset(-4)
                m.left.equalTo(separatorView.snp.right).offset(separatorMargin)
            }
            speedLabel.snp.remakeConstraints { m in
                m.height.equalTo(16)
                m.centerY.equalTo(self).offset(1.5)
                m.left.equalTo(speedBaselineView.snp.right).offset(speedLabelMargin)
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

}
