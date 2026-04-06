import AppKit

class NotchSpaceManager {
    private var spaceID: CGSSpaceID = 0
    private let connectionID: CGSConnectionID

    init() {
        connectionID = _CGSDefaultConnection()
        print("[bnotch] CGS connection: \(connectionID)")
        createSpace()
    }

    private func createSpace() {
        spaceID = CGSSpaceCreate(connectionID, 0x1, nil)
        print("[bnotch] CGS space created: \(spaceID)")

        let maxLevel = Int(Int32.max) // 2147483647
        CGSSpaceSetAbsoluteLevel(connectionID, spaceID, maxLevel)
        print("[bnotch] CGS space level set to: \(maxLevel)")

        CGSShowSpaces(connectionID, [spaceID] as CFArray)
    }

    func addWindow(_ window: NSWindow) {
        let windowID = window.windowNumber
        guard windowID > 0 else {
            print("[bnotch] Invalid window number: \(windowID)")
            return
        }
        print("[bnotch] Adding window \(windowID) to space \(spaceID)")
        CGSAddWindowsToSpaces(connectionID, [windowID] as CFArray, [spaceID] as CFArray)
    }

    func removeWindow(_ window: NSWindow) {
        let windowID = window.windowNumber
        guard windowID > 0 else { return }
        CGSRemoveWindowsFromSpaces(connectionID, [windowID] as CFArray, [spaceID] as CFArray)
    }
}
