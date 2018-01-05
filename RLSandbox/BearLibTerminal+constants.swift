//
//  BearLibTerminal+constants.swift
//  RLSandbox
//
//  Created by Steve Johnson on 1/5/18.
//  Copyright © 2018 Steve Johnson. All rights reserved.
//

import CBearLibTerminal


public struct RKConstant {
    // Keyboard scancodes for events/states.
    public static let A = TK_A
    public static let B = TK_B
    public static let C = TK_C
    public static let D = TK_D
    public static let E = TK_E
    public static let F = TK_F
    public static let G = TK_G
    public static let H = TK_H
    public static let I = TK_I
    public static let J = TK_J
    public static let K = TK_K
    public static let L = TK_L
    public static let M = TK_M
    public static let N = TK_N
    public static let O = TK_O
    public static let P = TK_P
    public static let Q = TK_Q
    public static let R = TK_R
    public static let S = TK_S
    public static let T = TK_T
    public static let U = TK_U
    public static let V = TK_V
    public static let W = TK_W
    public static let X = TK_X
    public static let Y = TK_Y
    public static let Z = TK_Z
    public static let _1 = TK_1
    public static let _2 = TK_2
    public static let _3 = TK_3
    public static let _4 = TK_4
    public static let _5 = TK_5
    public static let _6 = TK_6
    public static let _7 = TK_7
    public static let _8 = TK_8
    public static let _9 = TK_9
    public static let _0 = TK_0
    public static let RETURN = TK_RETURN
    public static let ENTER = TK_ENTER
    public static let ESCAPE = TK_ESCAPE
    public static let BACKSPACE = TK_BACKSPACE
    public static let TAB = TK_TAB
    public static let SPACE = TK_SPACE
    public static let MINUS = TK_MINUS
    public static let EQUALS = TK_EQUALS
    public static let LBRACKET = TK_LBRACKET
    public static let RBRACKET = TK_RBRACKET
    public static let BACKSLASH = TK_BACKSLASH
    public static let SEMICOLON = TK_SEMICOLON
    public static let APOSTROPHE = TK_APOSTROPHE
    public static let GRAVE = TK_GRAVE
    public static let COMMA = TK_COMMA
    public static let PERIOD = TK_PERIOD
    public static let SLASH = TK_SLASH
    public static let F1 = TK_F1
    public static let F2 = TK_F2
    public static let F3 = TK_F3
    public static let F4 = TK_F4
    public static let F5 = TK_F5
    public static let F6 = TK_F6
    public static let F7 = TK_F7
    public static let F8 = TK_F8
    public static let F9 = TK_F9
    public static let F10 = TK_F10
    public static let F11 = TK_F11
    public static let F12 = TK_F12
    public static let PAUSE = TK_PAUSE
    public static let INSERT = TK_INSERT
    public static let HOME = TK_HOME
    public static let PAGEUP = TK_PAGEUP
    public static let DELETE = TK_DELETE
    public static let END = TK_END
    public static let PAGEDOWN = TK_PAGEDOWN
    public static let RIGHT = TK_RIGHT
    public static let LEFT = TK_LEFT
    public static let DOWN = TK_DOWN
    public static let UP = TK_UP
    public static let KP_DIVIDE = TK_KP_DIVIDE
    public static let KP_MULTIPLY = TK_KP_MULTIPLY
    public static let KP_MINUS = TK_KP_MINUS
    public static let KP_PLUS = TK_KP_PLUS
    public static let KP_ENTER = TK_KP_ENTER
    public static let KP_1 = TK_KP_1
    public static let KP_2 = TK_KP_2
    public static let KP_3 = TK_KP_3
    public static let KP_4 = TK_KP_4
    public static let KP_5 = TK_KP_5
    public static let KP_6 = TK_KP_6
    public static let KP_7 = TK_KP_7
    public static let KP_8 = TK_KP_8
    public static let KP_9 = TK_KP_9
    public static let KP_0 = TK_KP_0
    public static let KP_PERIOD = TK_KP_PERIOD
    public static let SHIFT = TK_SHIFT
    public static let CONTROL = TK_CONTROL
    public static let ALT = TK_ALT

    // Mouse events/states
    public static let MOUSE_LEFT = TK_MOUSE_LEFT
    public static let MOUSE_RIGHT = TK_MOUSE_RIGHT
    public static let MOUSE_MIDDLE = TK_MOUSE_MIDDLE
    public static let MOUSE_X1 = TK_MOUSE_X1
    public static let MOUSE_X2 = TK_MOUSE_X2
    public static let MOUSE_MOVE = TK_MOUSE_MOVE
    public static let MOUSE_SCROLL = TK_MOUSE_SCROLL
    public static let MOUSE_X = TK_MOUSE_X
    public static let MOUSE_Y = TK_MOUSE_Y
    public static let MOUSE_PIXEL_X = TK_MOUSE_PIXEL_X
    public static let MOUSE_PIXEL_Y = TK_MOUSE_PIXEL_Y
    public static let MOUSE_WHEEL = TK_MOUSE_WHEEL
    public static let MOUSE_CLICKS = TK_MOUSE_CLICKS

    // If key was released instead of pressed, it's code will be OR'ed with VK_KEY_RELEASED.
    public static let KEY_RELEASED = TK_KEY_RELEASED

    // Virtual key-codes for internal terminal states/variables.
    // These can be accessed via terminal_state function.
    public static let WIDTH = TK_WIDTH
    public static let HEIGHT = TK_HEIGHT
    public static let CELL_WIDTH = TK_CELL_WIDTH
    public static let CELL_HEIGHT = TK_CELL_HEIGHT
    public static let COLOR = TK_COLOR
    public static let BKCOLOR = TK_BKCOLOR
    public static let LAYER = TK_LAYER
    public static let COMPOSITION = TK_COMPOSITION
    public static let CHAR = TK_CHAR
    public static let WCHAR = TK_WCHAR
    public static let EVENT = TK_EVENT
    public static let FULLSCREEN = TK_FULLSCREEN

    // Other events.
    public static let CLOSE = TK_CLOSE
    public static let RESIZED = TK_RESIZED

    // Generic mode enum. Used in Terminal.composition call only.
    public static let OFF = TK_OFF
    public static let ON = TK_ON

    // Input result codes for terminal_read_str function.
    public static let INPUT_NONE = TK_INPUT_NONE
    public static let INPUT_CANCELLED = TK_INPUT_CANCELLED

    // Text printing alignment.
    public static let ALIGN_DEFAULT = TK_ALIGN_DEFAULT
    public static let ALIGN_LEFT = TK_ALIGN_LEFT
    public static let ALIGN_RIGHT = TK_ALIGN_RIGHT
    public static let ALIGN_CENTER = TK_ALIGN_CENTER
    public static let ALIGN_TOP = TK_ALIGN_TOP
    public static let ALIGN_BOTTOM = TK_ALIGN_BOTTOM
    public static let ALIGN_MIDDLE = TK_ALIGN_MIDDLE
}
