import SwiftUI

public extension Text {
    func marquee(speed: Double = 30.0, delay: Double = 4.0, insets: CGFloat? = nil, easeOutDistance: CGFloat = 40.0) -> some View {
        MarqueeText(text: self, speed: speed, delay: delay, insets: insets, easeOutDistance: easeOutDistance)
    }
}

struct MarqueeText: View {
    let text: Text
    let speed: Double
    let delay: Double
    let insets: CGFloat?
    let easeOutDistance: CGFloat

    @Environment(\.multilineTextAlignment) private var textAlignment

    @State private var contentWidth: CGFloat = 0
    @State private var contentHeight: CGFloat = 0
    @State private var containerWidth: CGFloat = 0
    @State private var offset: CGFloat = 0
    @State private var animationID = UUID()

    private var needsScrolling: Bool {
        contentWidth > containerWidth && containerWidth > 0
    }

    private var spacing: CGFloat {
        contentHeight * 2
    }

    private var featherWidth: CGFloat {
        insets ?? (contentHeight * 0.6)
    }

    private var totalDistance: CGFloat {
        contentWidth + spacing
    }

    private var linearDistance: CGFloat {
        max(0, totalDistance - easeOutDistance)
    }

    private var linearDuration: Double {
        linearDistance / speed
    }

    private var easeOutDuration: Double {
        (easeOutDistance / speed) * 2.0
    }

    private var frameAlignment: Alignment {
        switch textAlignment {
        case .leading: return .leading
        case .center: return .center
        case .trailing: return .trailing
        }
    }

    var body: some View {
        text
            .lineLimit(1)
            .frame(maxWidth: .infinity, alignment: frameAlignment)
            .opacity(needsScrolling ? 0 : 1)
            .background(
                GeometryReader { containerGeometry in
                    text
                        .fixedSize()
                        .hidden()
                        .background(
                            GeometryReader { textGeometry in
                                Color.clear
                                    .onAppear {
                                        contentWidth = textGeometry.size.width
                                        contentHeight = textGeometry.size.height
                                        containerWidth = containerGeometry.size.width
                                    }
                                    .onChange(of: textGeometry.size.width) { _, newWidth in
                                        contentWidth = newWidth
                                    }
                                    .onChange(of: textGeometry.size.height) { _, newHeight in
                                        contentHeight = newHeight
                                    }
                                    .onChange(of: containerGeometry.size.width) { _, newWidth in
                                        containerWidth = newWidth
                                    }
                            }
                        )
                }
            )
            .overlay {
                if needsScrolling && containerWidth > 0 {
                    HStack(spacing: spacing) {
                        text.fixedSize()
                        text.fixedSize()
                    }
                    .offset(x: offset + featherWidth)
                    .frame(width: containerWidth + featherWidth, height: contentHeight, alignment: .leading)
                    .clipped()
                    .mask {
                        HStack(spacing: 0) {
                            LinearGradient(
                                colors: [.clear, .black],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            .frame(width: featherWidth)

                            Rectangle().fill(.black)

                            LinearGradient(
                                colors: [.black, .clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            .frame(width: featherWidth)
                        }
                    }
                    .frame(width: containerWidth, alignment: .trailing)
                }
            }
            .onChange(of: needsScrolling) { _, newValue in
                if newValue {
                    animationID = UUID()
                } else {
                    resetOffset()
                }
            }
            .task(id: animationID) {
                guard needsScrolling else { return }
                await runAnimationLoop()
            }
    }

    private func runAnimationLoop() async {
        resetOffset()

        try? await Task.sleep(for: .seconds(delay))

        while !Task.isCancelled && needsScrolling {
            withAnimation(.linear(duration: linearDuration)) {
                offset = -linearDistance
            }

            try? await Task.sleep(for: .seconds(linearDuration))
            guard !Task.isCancelled else { break }

            withAnimation(.easeOut(duration: easeOutDuration)) {
                offset = -totalDistance
            }

            try? await Task.sleep(for: .seconds(easeOutDuration))
            guard !Task.isCancelled else { break }

            resetOffset()

            try? await Task.sleep(for: .seconds(delay))
        }
    }

    private func resetOffset() {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            offset = 0
        }
    }
}
