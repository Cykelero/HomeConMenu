//
//  PowerMenu.swift
//  macOSBridge
//
//  Created by Yuichi Yoshida on 2022/03/20.
//
//  MIT License
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import Cocoa

class ToggleMenuItem: NSMenuItem, MenuItemFromUUID {
    func UUIDs() -> [UUID] {
        return characteristicIdentifiers
    }
    
    var icon: NSImage? {
        return NSImage(systemSymbolName: "powerplug", accessibilityDescription: nil)
    }
    
    func bind(with uniqueIdentifier: UUID) -> Bool {
        return characteristicIdentifiers.contains(where: { $0 == uniqueIdentifier })
    }
    
    let characteristicIdentifiers: [UUID]
    var mac2ios: mac2iOS?
    
    @IBAction func toggle(sender: NSMenuItem) {
        if characteristicIdentifiers.count == 1 {
            for uuid in characteristicIdentifiers {
                self.mac2ios?.toggleValue(uniqueIdentifier: uuid)
            }
            self.state = (self.state == .on) ? .off : .on
        } else {
            guard let sample = characteristicIdentifiers.first else { return }
            guard let state = self.mac2ios?.getPowerState(uniqueIdentifier: sample) else { return }
            for uuid in characteristicIdentifiers {
                self.mac2ios?.setPowerState(uniqueIdentifier: uuid, state: !state)
            }
        }
    }
    
    func update(value: Int) {
        guard let sample = characteristicIdentifiers.first else { return }
        guard let state = self.mac2ios?.getPowerState(uniqueIdentifier: sample) else { return }
        self.state = state ? .on : .off
    }
        
    init?(serviceGroupInfo: ServiceGroupInfoProtocol, mac2ios: mac2iOS?) {

        let characteristicInfos = serviceGroupInfo.services.map({ $0.characteristics }).flatMap({ $0 })
           
        let infos = characteristicInfos.filter({ $0.type == .powerState })
        
        guard infos.count > 0 else { return nil }
        
        guard let sample = infos.first else { return nil}
        
        
        let uuids = infos.map({$0.uniqueIdentifier})
        
        self.mac2ios = mac2ios
        self.characteristicIdentifiers = uuids
        super.init(title: serviceGroupInfo.name, action: nil, keyEquivalent: "")

        if let number = sample.value as? Int {
            self.state = (number == 0) ? .off : .on
        }
        self.image = self.icon
        self.action = #selector(self.toggle(sender:))
        self.target = self
    }
        
    init?(serviceInfo: ServiceInfoProtocol, mac2ios: mac2iOS?) {
        guard let powerStateChara = serviceInfo.characteristics.first(where: { obj in
            obj.type == .powerState
        }) else { return nil }
        
        self.mac2ios = mac2ios
        self.characteristicIdentifiers = [powerStateChara.uniqueIdentifier]
        super.init(title: serviceInfo.name, action: nil, keyEquivalent: "")
        
        if let number = powerStateChara.value as? Int {
            self.state = (number == 0) ? .off : .on
        }
        self.image = self.icon
        self.action = #selector(self.toggle(sender:))
        self.target = self
    }
    
    override init(title string: String, action selector: Selector?, keyEquivalent charCode: String) {
        fatalError()
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class LightGroupMenuItem: ToggleMenuItem {
    override var icon: NSImage? {
        return NSImage(systemSymbolName: "lightbulb", accessibilityDescription: nil)
    }
}

class SwitchMenuItem: ToggleMenuItem {
    override var icon: NSImage? {
        return NSImage(systemSymbolName: "switch.2", accessibilityDescription: nil)
    }
}

class OutletMenuItem: ToggleMenuItem {
    override var icon: NSImage? {
        return NSImage(systemSymbolName: "powerplug", accessibilityDescription: nil)
    }
}
