//
//  ChartBarView.swift
//  Pingu
//
//  Created by Thanos Theodoridis on 3/4/20.
//  Copyright © 2020 Thanos Theodoridis. All rights reserved.
//

import Foundation
import Cocoa

import SnapKit

class ChartBarView: NSView {
    
    // MARK: - Lifecycle
    
    init() {
        
        super.init(frame: .zero)
        
        wantsLayer = true
        layer?.backgroundColor = NSColor.labelColor.cgColor
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Overrides
    
    override func updateLayer() {
        
        super.updateLayer()
        layer?.backgroundColor = NSColor.labelColor.cgColor
        
    }
    
    // MARK: - Public Methods
    
    public func configure(with result: PingResult, avgResponseTime: Float) {
        
        switch result {
        
        case .responseInMilliseconds(let value):
        
            let scaledValue = Rescale(from: (0, Float(avgResponseTime * 2)), to: (1, 12)).rescale(Float(value))
            
            snp.updateConstraints { m in
                m.height.equalTo(min(scaledValue, 12))
            }
            
            switch value {
            case 0..<80:
                layer?.backgroundColor = NSColor.labelColor.cgColor
            case 80..<150:
                layer?.backgroundColor = NSColor(named: NSColor.Name("highPingColor"))?.cgColor
            default :
                layer?.backgroundColor = NSColor(named: NSColor.Name("veryHighPingColor"))?.cgColor
            }
            
        
        case .timeout:
            
            snp.updateConstraints { m in
                m.height.equalTo(0)
            }
        
        default:
            layer?.backgroundColor = .clear
            
        }
        
    }
    
    public func reset() {

        snp.updateConstraints { m in
            m.height.equalTo(0)
        }

        layer?.backgroundColor = .white

    }

    // MARK: - Speed Configuration

    public func configure(with result: SpeedResult, avgSpeed: Double) {

        switch result {

        case .speedInMbps(let mbps):

            // Scale speed to bar height (0-12px range)
            let maxScale = max(avgSpeed * 2, 50) // At least 50 Mbps scale
            let scaledValue = Rescale(from: (0, Float(maxScale)), to: (1, 12)).rescale(Float(mbps))

            snp.updateConstraints { m in
                m.height.equalTo(min(scaledValue, 12))
            }

            // Color thresholds for speed (inverse of latency - higher is better)
            switch mbps {
            case 25...:
                // Good speed (green) - use label color for consistency
                layer?.backgroundColor = NSColor.labelColor.cgColor
            case 10..<25:
                // Moderate speed (amber)
                layer?.backgroundColor = NSColor(named: NSColor.Name("highPingColor"))?.cgColor
            default:
                // Slow speed (red)
                layer?.backgroundColor = NSColor(named: NSColor.Name("veryHighPingColor"))?.cgColor
            }

        case .timeout, .error:

            snp.updateConstraints { m in
                m.height.equalTo(0)
            }

        case .rateLimited:
            // Show small bar with amber color for rate limited
            snp.updateConstraints { m in
                m.height.equalTo(2)
            }
            layer?.backgroundColor = NSColor(named: NSColor.Name("highPingColor"))?.cgColor

        }

    }

}
