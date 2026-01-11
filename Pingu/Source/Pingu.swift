//
//  Application.swift
//  Pingu
//
//  Created by Thanos Theodoridis on 2/4/20.
//  Copyright © 2020 Thanos Theodoridis. All rights reserved.
//

import Cocoa
import ServiceManagement

class Pingu {

    // MARK: - Private Properties

    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private var preferencesPopover: NSPopover?
    private var eventMonitor: EventMonitor?
    private var savedHosts: SavedHosts
    private var pingService: PingService
    private var speedService: SpeedService
    private var chartView: ChartView
    
    // MARK: - Lifecycle

    init() {

        self.chartView = ChartView()
        self.pingService = PingService()
        self.speedService = SpeedService()
        self.savedHosts = SavedHosts.load(fromStore: UserDefaults.standard)

        // Load toggle states from UserDefaults
        chartView.pingEnabled = UserDefaults.standard.pingEnabled
        chartView.speedEnabled = UserDefaults.standard.speedEnabled

        if let selectedHost = savedHosts.selectedHost {

            if UserDefaults.standard.pingEnabled {
                startPinging(host: selectedHost)
            }

        } else {

            let defaultHost = Host(host: "www.google.com", interval: .seconds(1))

            savedHosts.add(defaultHost)
            savedHosts.save(toStore: UserDefaults.standard)

            if UserDefaults.standard.pingEnabled {
                startPinging(host: defaultHost)
            }

        }

        // Start speed testing if enabled
        if UserDefaults.standard.speedEnabled {
            startSpeedTesting()
        }

        configureMenu()

        statusItem.button?.addSubview(chartView)
        statusItem.length = chartView.desiredWidth

        eventMonitor = EventMonitor(mask: .leftMouseDown) { [weak self] event in

            if self?.preferencesPopover?.isShown ?? false {
                self?.hidePreferencesPopover()
            }

        }

    }
    
    // MARK: - Private Properties
    
    fileprivate func configureMenu() {
        
        let menu = NSMenu()
        
        if !savedHosts.hosts.isEmpty {
            
            for host in savedHosts.hosts {
                
                let hostItem = HostMenuItem(host: host, action: #selector(self.didSelectHostItem(_:)))
                hostItem.target = self
                hostItem.state = host.selected ? .on : .off
                
                menu.addItem(hostItem)
                
            }
            
            menu.addItem(.separator())
            
        }
        
        if pingService.isPinging {

            let item = NSMenuItem(title: "Pause", action: #selector(self.didSelectStopPinging), keyEquivalent: "")
            item.target = self

            menu.addItem(item)
            menu.addItem(.separator())

        } else {

            if let _ = savedHosts.selectedHost {

                let item = NSMenuItem(title: "Resume", action: #selector(self.didSelectStartPinging), keyEquivalent: "")
                item.target = self

                menu.addItem(item)
                menu.addItem(.separator())

            }

        }

        let preferencesMenuItem = NSMenuItem(title: "Add host...",
                                             action: #selector(didSelectPrefencesMenuItem),
                                             keyEquivalent: "")
        preferencesMenuItem.target = self

        menu.addItem(preferencesMenuItem)
        menu.addItem(.separator())

        // Toggle menu items
        let pingToggle = NSMenuItem(title: "Ping Testing",
                                    action: #selector(didSelectPingToggle),
                                    keyEquivalent: "")
        pingToggle.target = self
        pingToggle.state = UserDefaults.standard.pingEnabled ? .on : .off

        let speedToggle = NSMenuItem(title: "Speed Testing",
                                     action: #selector(didSelectSpeedToggle),
                                     keyEquivalent: "")
        speedToggle.target = self
        speedToggle.state = UserDefaults.standard.speedEnabled ? .on : .off

        menu.addItem(pingToggle)
        menu.addItem(speedToggle)
        menu.addItem(.separator())

        let launchAtLogin = NSMenuItem(title: "Launch at login",
                                             action: #selector(didSelectLaunchAtLogin),
                                             keyEquivalent: "")
        launchAtLogin.target = self
        launchAtLogin.state = UserDefaults.standard.launchAtLogin ? .on : .off

        let quitMenuItem = NSMenuItem(title: "Quit",
                                       action: #selector(didSelectQuitMenuItem),
                                       keyEquivalent: "")
        quitMenuItem.target = self

        menu.addItem(launchAtLogin)
        menu.addItem(quitMenuItem)

        statusItem.menu = menu

    }
    
    // MARK: - Private methods
    
    fileprivate func showPreferencesPopover() {
        
        preferencesPopover = NSPopover()
        preferencesPopover?.contentViewController = PreferencesViewController(pingService: pingService, delegate: self)
        
        if let button = statusItem.button {
            preferencesPopover?.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
        
        eventMonitor?.start()
        
    }
    
    fileprivate func hidePreferencesPopover() {
        
        preferencesPopover?.close()
        eventMonitor?.stop()
        
    }
    
    fileprivate func startPinging(host: Host) {
        
        pingService.startPinging(host: host.host,
                                 interval: host.interval.timeInterval)
        { [weak self] pingResult in
            
            DispatchQueue.main.sync {
                self?.chartView.addResult(pingResult)
                self?.statusItem.length = self?.chartView.desiredWidth ?? 0
            }
            
        }
        
    }
    
    fileprivate func stopPinging() {

        pingService.stopPinging()
        configureMenu()
        chartView.setPausedState(true)

    }

    fileprivate func startSpeedTesting() {

        speedService.observer = { [weak self] speedResult in
            DispatchQueue.main.async {
                self?.chartView.addSpeedResult(speedResult)
                self?.statusItem.length = self?.chartView.desiredWidth ?? 0
            }
        }

        speedService.startSpeedTest()

    }

    fileprivate func stopSpeedTesting() {

        speedService.stopSpeedTest()
        chartView.setSpeedPausedState(true)

    }
    
    // MARK: - Selectors
    
    @objc fileprivate func didSelectPrefencesMenuItem() {
        preferencesPopover?.isShown ?? false ? hidePreferencesPopover() : showPreferencesPopover()
    }
    
    @objc fileprivate func didSelectQuitMenuItem() {
        NSApp.terminate(self)
    }
    
    @objc fileprivate func didSelectHostItem(_ item: HostMenuItem) {
        
        savedHosts.setSelected(item.host)
        savedHosts.save(toStore: UserDefaults.standard)
        
        startPinging(host: item.host)
        chartView.reset()
        configureMenu()
        
    }
    
    @objc fileprivate func didSelectStopPinging() {
        stopPinging()
    }
    
    @objc fileprivate func didSelectStartPinging() {
        
        guard let selectedHost = savedHosts.selectedHost else { return }
        
        startPinging(host: selectedHost)
        configureMenu()
        
    }
    
    @objc fileprivate func didSelectLaunchAtLogin() {

        UserDefaults.standard.launchAtLogin.toggle()
        SMLoginItemSetEnabled(pinguLauncherBundleId as CFString, UserDefaults.standard.launchAtLogin)

        print("Launch at login: \(UserDefaults.standard.launchAtLogin)")

        configureMenu()

    }

    @objc fileprivate func didSelectPingToggle() {

        UserDefaults.standard.pingEnabled.toggle()
        let enabled = UserDefaults.standard.pingEnabled

        chartView.pingEnabled = enabled

        if enabled {
            if let selectedHost = savedHosts.selectedHost {
                startPinging(host: selectedHost)
            }
        } else {
            pingService.stopPinging()
            chartView.resetPing()
        }

        statusItem.length = chartView.desiredWidth
        configureMenu()

    }

    @objc fileprivate func didSelectSpeedToggle() {

        UserDefaults.standard.speedEnabled.toggle()
        let enabled = UserDefaults.standard.speedEnabled

        chartView.speedEnabled = enabled

        if enabled {
            startSpeedTesting()
        } else {
            stopSpeedTesting()
            chartView.resetSpeed()
        }

        statusItem.length = chartView.desiredWidth
        configureMenu()

    }

}

// MARK: - PreferencesViewControllerDelegate

extension Pingu: PreferencesViewControllerDelegate {
    
    func preferencesViewController(_ ctrl: PreferencesViewController,
                                   didAddHost host: String, interval: PingInterval)
    {
       
        
        let h = Host(host: host, interval: interval)
        
        savedHosts.add(h)
        savedHosts.save(toStore: UserDefaults.standard)
        
        startPinging(host: h)
        
        configureMenu()
        hidePreferencesPopover()
        
    }
    
}
