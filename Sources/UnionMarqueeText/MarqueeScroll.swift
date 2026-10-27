import SwiftUI

struct MarqueeScroll: CustomAnimation {
    let speed: Double
    let linearDistance: Double
    let easeOutDistance: Double

    var linearDuration: TimeInterval {
        linearDistance / speed
    }

    var easeOutDuration: TimeInterval {
        2 * easeOutDistance / speed
    }

    var duration: TimeInterval {
        linearDuration + easeOutDuration
    }

    var totalDistance: Double {
        linearDistance + easeOutDistance
    }

    func distance(at time: TimeInterval) -> Double {
        guard time > 0 else { return 0 }
        guard time > linearDuration else { return speed * time }
        guard time < duration else { return totalDistance }
        let elapsed = time - linearDuration
        return linearDistance + speed * elapsed - speed * elapsed * elapsed / (2 * easeOutDuration)
    }

    func speed(at time: TimeInterval) -> Double {
        guard time >= 0, time < duration else { return 0 }
        guard time > linearDuration else { return speed }
        return speed * (1 - (time - linearDuration) / easeOutDuration)
    }

    func animate<V: VectorArithmetic>(value: V, time: TimeInterval, context: inout AnimationContext<V>) -> V? {
        guard speed > 0, totalDistance > 0, time < duration else { return nil }
        return value.scaled(by: distance(at: time) / totalDistance)
    }

    func velocity<V: VectorArithmetic>(value: V, time: TimeInterval, context: AnimationContext<V>) -> V? {
        guard speed > 0, totalDistance > 0, time < duration else { return nil }
        return value.scaled(by: speed(at: time) / totalDistance)
    }
}
