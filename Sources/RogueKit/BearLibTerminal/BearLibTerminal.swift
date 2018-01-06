//
//  BearLibTerminal.swift
//  RLSandbox
//
//  Created by Steve Johnson on 1/5/18.
//  Copyright © 2018 Steve Johnson. All rights reserved.
//

import Foundation
import CBearLibTerminal


public enum RogueKitError: Error {
    case StringEncodingError
}


public typealias RKInt = Int32
public typealias RKColor = UInt32

public struct RKRect: Equatable {
    public var x: RKInt
    public var y: RKInt
    public var w: RKInt
    public var h: RKInt
    public static func ==(_ a: RKRect, _ b: RKRect) -> Bool { return a.x == b.x && a.y == b.y && a.w == b.w && a.h == b.h }
    public init(x: RKInt, y: RKInt, w: RKInt, h: RKInt) {
        self.x = x
        self.y = y
        self.w = w
        self.h = h
    }
}

public struct RKPoint: Equatable {
    public var x: RKInt
    public var y: RKInt
    public static var zero = RKPoint(x: 0, y: 0)
    public static func ==(_ a: RKPoint, _ b: RKPoint) -> Bool { return a.x == b.x && a.y == b.y }
    public init(x: RKInt, y: RKInt) {
        self.x = x
        self.y = y
    }
}
extension RKPoint: Hashable {
    public var hashValue: Int {
        return x.hashValue &* 31 &+ y.hashValue
    }
}

public struct RKSize: Equatable {
    public var w: RKInt
    public var h: RKInt
    public static func ==(_ a: RKSize, _ b: RKSize) -> Bool { return a.w == b.w && a.h == b.h }
    public init(w: RKInt, h: RKInt) {
        self.w = w
        self.h = h
    }
}


public protocol RKTerminalInterface: class {
    func open()
    func close()
    @discardableResult func configure(_ config: String) -> Bool

    func refresh()
    func clear()
    func clear(area: RKRect)
    func crop(area: RKRect)
    func delay(milliseconds: RKInt)

    func measure(string: String) -> RKSize
    @discardableResult func print(point: RKPoint, string: String) -> RKSize
    func put(point: RKPoint, code: RKInt)
    func put(point: RKPoint, code: RKInt, offset: RKPoint, nw: RKColor, sw: RKColor, se: RKColor, ne: RKColor)

    func getColor(name: String) -> RKColor
    func getColor(a: UInt8, r: UInt8, g: UInt8, b: UInt8) -> RKColor
    func pickCode(point: RKPoint, index: RKInt) -> RKInt
    func pickForegroundColor(point: RKPoint, index: RKInt) -> RKColor
    func pickBackgroundColor(point: RKPoint, index: RKInt) -> RKColor

    func peek() -> Int32
    func read() -> Int32
    func state(_ slot: Int32) -> Int32
    func check(_ slot: Int32) -> Bool
    func readString(point: RKPoint, max: RKInt) -> String?

    var hasInput: Bool { get }
    var layer: RKInt { get set }
    var foregroundColor: RKColor { get set }
    var backgroundColor: RKColor { get set }
    var isCompositionEnabled: Bool { get set }
}

public extension RKTerminalInterface {
    public func waitForExit() {
        while self.read() != RKConstant.CLOSE { }
        self.close()
    }
}

public class RKTerminal: RKTerminalInterface {
    public static var main: RKTerminalInterface = { RKTerminal() }()

    public init() { }

    public func open() { terminal_open() }

    public func close() { terminal_close() }

    @discardableResult
    public func configure(_ config: String) -> Bool {
        let s = Array(config.utf8CString)
        return terminal_set(UnsafePointer(s)) != 0
    }

    public func refresh() { terminal_refresh() }

    public func clear() { terminal_clear() }

    public func check(_ slot: Int32) -> Bool { return terminal_check(slot) != 0 }

    public func state(_ slot: Int32) -> Int32 { return terminal_state(slot) }

    public func clear(area: RKRect) {
        terminal_clear_area(area.x, area.y, area.w, area.h)
    }

    public func crop(area: RKRect) {
        terminal_crop(area.x, area.y, area.w, area.h)
    }

    public func delay(milliseconds: RKInt) {
        terminal_delay(milliseconds)
    }

    public func measure(string: String) -> RKSize {
        let s = Array(string.utf8CString)
        let result: dimensions_t = terminal_measure(UnsafePointer(s))
        return RKSize(w: result.width, h: result.height)
    }

    @discardableResult
    public func print(point: RKPoint, string: String) -> RKSize {
        let s = Array(string.utf8CString)
        let result = terminal_print(point.x, point.y, UnsafePointer(s))
        return RKSize(w: result.width, h: result.height)
    }

    public func put(point: RKPoint, code: RKInt) {
        terminal_put(point.x, point.y, code)
    }

    public func put(point: RKPoint, code: RKInt, offset: RKPoint, nw: RKColor, sw: RKColor, se: RKColor, ne: RKColor) {
        let cornersArray: [color_t] = [nw, sw, se, ne]
        let ptr = UnsafeMutablePointer(mutating: cornersArray)
        terminal_put_ext(point.x, point.y, offset.x, offset.y, code, ptr)
    }

    public func getColor(name: String) -> RKColor {
        let s = Array(name.utf8CString)
        return color_from_name(UnsafePointer(s))
    }

    public func getColor(a: UInt8, r: UInt8, g: UInt8, b: UInt8) -> RKColor {
        return color_from_argb(a, r, g, b)
    }

    public func pickCode(point: RKPoint, index: RKInt) -> RKInt {
        return terminal_pick(point.x, point.y, index)
    }

    public func pickForegroundColor(point: RKPoint, index: RKInt) -> RKColor {
        return terminal_pick_color(point.x, point.y, index)
    }

    public func pickBackgroundColor(point: RKPoint, index: RKInt) -> RKColor {
        return terminal_pick_bkcolor(point.x, point.y)
    }

    public func peek() -> Int32 {
        return terminal_peek()
    }

    public func read() -> Int32 {
        return terminal_read()
    }

    public func readString(point: RKPoint, max: RKInt) -> String? {
        var bytes = [Int8](repeating: 0, count: Int(max))
        let result = terminal_read_str(point.x, point.y, &bytes, max)
        if result <= 0 {
            return nil
        }
        let data: Data = Data(bytes: bytes.map({ UInt8(bitPattern: $0) }))
        if let longString = String(data: data, encoding: .utf8) {
            return String(longString.prefix(Int(result)))
        } else {
            return nil
        }
    }

    public var hasInput: Bool {
        return terminal_has_input() != 0
    }

    public var layer: RKInt {
        get { return terminal_state(TK_LAYER) }
        set { terminal_layer(newValue) }
    }

    public var foregroundColor: RKColor {
        get { return RKColor(bitPattern: terminal_state(TK_COLOR)) }
        set { terminal_color(newValue) }
    }

    public var backgroundColor: RKColor {
        get { return RKColor(bitPattern: terminal_state(TK_BKCOLOR)) }
        set { terminal_bkcolor(newValue) }
    }

    public var isCompositionEnabled: Bool {
        get { return terminal_state(RKConstant.COMPOSITION) == RKConstant.ON }
        set { terminal_composition(newValue ? RKConstant.ON : RKConstant.OFF) }
    }
}
