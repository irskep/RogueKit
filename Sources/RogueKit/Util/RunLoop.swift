//
//  RunLoop.swift
//  RogueKit
//
//  Created by Steve Johnson on 3/1/18.
//

import Foundation


protocol RunLoopProtocol: class {
  func start()
  func stop()
}


class NaiveRunLoop: RunLoopProtocol {
  let block: () -> Void
  var isStopped = false

  init(block: @escaping () -> Void) {
    self.block = block

    DispatchQueue.main.async {
      self.start()
    }
  }

  func start() {
    while !isStopped {
      block()
      Thread.sleep(forTimeInterval: 0.0125)
    }
    print("stopped")
  }

  func stop() {
    print("stopping")
    isStopped = true
  }
}


#if os(iOS)
  import QuartzCore

  /// I have never tested this code.
  class RunLoop: RunLoopProtocol {
    let block: () -> Void
    let displayLink: CADisplayLink

    init(block: @escaping () -> Void) {
      self.block = block
      self.displayLink = CADisplayLink(target: self,
                                       selector: #selector(step))
    }

    func start() {
      displayLink.add(to: .current, forMode: .defaultRunLoopMode)
    }

    @objc func step() {
      block()
    }

    func stop() {
      displayLink.invalidate()
    }
  }

  func runLoop(block: @escaping () -> Void) -> RunLoopProtocol {
    return DisplayLinkWrapper(block: block)
  }
#elseif os(OSX)
  typealias RunLoop = NaiveRunLoop

  func runLoop(block: @escaping () -> Void) -> RunLoopProtocol {
    return NaiveRunLoop(block: {
//    return RunLoop(block: {
      if Thread.isMainThread {
        block()
      } else {
        fatalError("not gonna happen")
      }
    })
  }
#else
  func runLoop(block: @escaping () -> Void) -> RunLoopProtocol {
    fatalError("Not yet implemented on Linux. Needs some kind of timer.")
  }
#endif
