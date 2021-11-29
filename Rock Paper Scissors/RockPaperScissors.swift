//
//  ViewController.swift
//  RPSrng
//
//  Created by Вильян Яумбаев on 29.11.2021.
//

import UIKit

enum Ttype: CaseIterable {
    case r
    case p
    case s
    var text: String {
        switch self {
        case .r: return "🪨​"
        case .p: return "📃"
        case .s: return "✂️​"
        }
    }
    var target: Ttype {
        switch self {
        case .r: return .s
        case .p: return .r
        case .s: return .p
        }
    }
}

let frameStep: CGFloat = 5
let height = UIScreen.main.bounds.height
let width = UIScreen.main.bounds.width

class MyTextLayer: CATextLayer {
    var type: Ttype!
}

class ViewController: UIViewController {
    //    🪨​✂️​📃
    var timer: Timer?
    var gameTick: TimeInterval = 0.2
    var points: [MyTextLayer] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        startField()
        view.addSubview(fieldView)
        view.addSubview(startStop)
        startStop.setTitle("Start", for: .normal)
        startStop.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        startStop.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        startStop.addTarget(self, action: #selector(startStopAction(_:)), for: .touchUpInside)
        startStop.frame = UIScreen.main.bounds
        fieldView.frame = UIScreen.main.bounds
    }

    @objc func startStopAction(_ sender: UIButton) {
        startField()
        timer?.invalidate()
        timer = .scheduledTimer(timeInterval: gameTick, target: self, selector: #selector(firePlay), userInfo: nil, repeats: true)
        timer?.fire()
        startStop.setTitle("Restart", for: .normal)
    }
    var fieldView: UIView = .init()
    var startStop: UIButton = .init(type: .system)

    @objc func firePlay() {
        for j in 0..<self.points.count {
            let ttype = self.points[j].type!
            let targetPoints = self.points.filter { $0.type == ttype.target }
            guard j >= 0 && j < self.points.count,
                  let nearestIndex = self.points[j].findNearest(to: targetPoints)
            else { continue }
            let nearestLay = targetPoints[nearestIndex]
            let newFrame = self.points[j].frame.step(to: nearestLay.frame)
            if newFrame.intersects(nearestLay.frame) {
                nearestLay.string = ttype.text
                nearestLay.type = ttype
            }
            self.points[j].frame = newFrame
        }
        let p = self.points.filter { $0.type == .p }
        let r = self.points.filter { $0.type == .r }
        let s = self.points.filter { $0.type == .s }
        if p.isEmpty && r.isEmpty
            || p.isEmpty && s.isEmpty
            || r.isEmpty && s.isEmpty {
            self.timer?.invalidate()
            self.timer = nil
            DispatchQueue.main.async { self.startStop.setTitle("Start", for: .normal) }
        }
    }

    func startField() {
        fieldView.layer.sublayers?.removeAll()
        var j = 0
        points = []
        for ttype in Ttype.allCases {
            let count = 50
            for _ in 0...count {
                let lay = MyTextLayer()
                lay.type = ttype
                lay.string = ttype.text
                lay.fontSize = 10
                points.append(lay)
                let offsetX = CGFloat.random(in: 20...width-40)
                let offsetY = CGFloat.random(in: 50...height-50)
                lay.frame = .init(
                    x: offsetX,
                    y: offsetY,
                    width: 15,
                    height: 15
                )
                fieldView.layer.addSublayer(lay)
                j += 1
            }
        }
    }

}



extension CGRect {
    func distance(to point: CGPoint) -> CGFloat {
        return center.distance(to: point)
    }

    var center: CGPoint {
        .init(x: maxX + minX / 2, y: maxY + minY / 2)
    }

    func getOrigin(for center: CGPoint) -> CGPoint {
        .init(x: center.x - (width / 2), y: center.y - (height / 2))
    }

    func step(to rect: CGRect) -> CGRect {
        var new = self
        new.origin = origin.step(to: rect.origin)
        return new
    }

    func willIntersect(to layers: [CATextLayer]) -> Bool {
        for i in layers {
            if self.intersects(i.frame) {
                return true
            }
        }
        return false
    }
}
extension CATextLayer {
    func findNearest(to layers: [CATextLayer]) -> Int? {
        let enumerated = layers
            .map { $0.frame.distance(to: frame.center) }
            .enumerated()
        let min = enumerated
            .min(by: { $0.element < $1.element })
        return min?.offset
    }
}

extension CGPoint {
    func distance(to point: CGPoint) -> CGFloat {

        let fx = (x - point.x)
        let fy = (y - point.y)
        return sqrt(fx*fx + fy*fy)
    }

    func step(to point: CGPoint) -> CGPoint {
        var new = self
        let angle = atan2(new.y - point.y, new.x - point.x) * 180 / .pi
        let fx = abs(frameStep * sin(angle))
        let fy = abs(frameStep * cos(angle))
        if new.x > point.x {
            new.x -= fx
        } else if new.x < point.x {
            new.x += fx
        }
        if new.y > point.y {
            new.y -= fy
        } else if new.y < point.y {
            new.y += fy
        }
        new.x = min(max(new.x, 20), width - 40)
        new.y = min(max(new.y, 50), height - 50)
        return new
    }
}
