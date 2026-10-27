import Testing
@testable import UnionMarqueeText

struct MarqueeScrollTests {
    let scroll = MarqueeScroll(speed: 30, linearDistance: 200, easeOutDistance: 40)
    let frame = 1.0 / 120

    @Test func travelIsContinuousInPositionAndSpeed() {
        var previous = 0.0
        var previousSpeed = scroll.speed
        var largestSpeedStep = 0.0
        var time = frame
        while time <= scroll.duration + frame {
            let position = scroll.distance(at: time)
            let frameSpeed = (position - previous) / frame
            #expect(position >= previous)
            largestSpeedStep = max(largestSpeedStep, abs(frameSpeed - previousSpeed))
            previousSpeed = frameSpeed
            previous = position
            time += frame
        }
        #expect(largestSpeedStep < 0.2)
        #expect(abs(scroll.distance(at: scroll.duration) - scroll.totalDistance) < 1e-9)
        #expect(scroll.speed(at: scroll.linearDuration - 1e-9) == 30)
        #expect(abs(scroll.speed(at: scroll.linearDuration + 1e-9) - 30) < 1e-6)
        #expect(scroll.speed(at: scroll.duration - 1e-6) < 1e-3)
    }

    @Test func oldHandoffSteppedTheSpeedAndTheNewOneDoesNot() {
        let handoff = scroll.linearDuration
        var oldStep = 0.0
        var newStep = 0.0
        var time = handoff - 6 * frame
        print("time      old_px/s  new_px/s")
        while time <= handoff + 12 * frame {
            let old = (chainedDistance(at: time + frame) - chainedDistance(at: time)) / frame
            let new = (scroll.distance(at: time + frame) - scroll.distance(at: time)) / frame
            print(String(format: "%7.4f  %8.2f  %8.2f", time, old, new))
            oldStep = max(oldStep, abs(old - scroll.speed))
            newStep = max(newStep, abs(new - scroll.speed))
            time += frame
        }
        #expect(oldStep > 4)
        #expect(newStep < 3.2)
    }

    @Test func aLateHandoffStalledTheOldScroll() {
        let handoff = scroll.linearDuration
        let stalled = chainedDistance(at: handoff + 3 * frame, stall: 3 * frame)
        #expect(stalled == scroll.linearDistance)
        #expect(scroll.distance(at: handoff + 3 * frame) > scroll.linearDistance + 0.7)
    }

    func chainedDistance(at time: Double, stall: Double = 0) -> Double {
        if time <= scroll.linearDuration { return scroll.speed * time }
        let elapsed = time - scroll.linearDuration - stall
        guard elapsed > 0 else { return scroll.linearDistance }
        let fraction = min(1, elapsed / scroll.easeOutDuration)
        return scroll.linearDistance + scroll.easeOutDistance * easeOut(fraction)
    }

    func easeOut(_ x: Double) -> Double {
        var low = 0.0, high = 1.0
        for _ in 0..<60 {
            let mid = (low + high) / 2
            let bx = 3 * (1 - mid) * mid * mid * 0.58 + mid * mid * mid
            if bx < x { low = mid } else { high = mid }
        }
        let t = (low + high) / 2
        return 3 * (1 - t) * t * t + t * t * t
    }
}
