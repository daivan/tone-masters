import SwiftUI

struct TunerGaugeView: View {
    let centsDeviation: Double
    let isActive: Bool

    private let arcRadius: CGFloat = 100
    private let needleLength: CGFloat = 80

    // Map ±50 cents → ±85 degrees from vertical (center = -90° = pointing up)
    private var needleAngle: Angle {
        let clamped = max(-50, min(50, centsDeviation))
        return .degrees(clamped / 50.0 * 85.0)
    }

    private var needleColor: Color {
        guard isActive else { return .secondary }
        let abs = abs(centsDeviation)
        if abs < 30 { return .green }
        if abs < 50 { return .yellow }
        return .red
    }

    var body: some View {
        ZStack {
            // Background arc
            ArcShape(startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
                .stroke(Color.secondary.opacity(0.15), lineWidth: 10)
                .frame(width: arcRadius * 2, height: arcRadius)

            // Color zones
            // Red zones (outside ±30¢)
            ArcShape(startAngle: .degrees(180), endAngle: .degrees(148.5), clockwise: false)
                .stroke(Color.red.opacity(isActive ? 0.4 : 0.15), lineWidth: 10)
                .frame(width: arcRadius * 2, height: arcRadius)

            ArcShape(startAngle: .degrees(31.5), endAngle: .degrees(0), clockwise: false)
                .stroke(Color.red.opacity(isActive ? 0.4 : 0.15), lineWidth: 10)
                .frame(width: arcRadius * 2, height: arcRadius)

            // Yellow zones (±30¢ to ±50¢ ... inner bands)
            ArcShape(startAngle: .degrees(148.5), endAngle: .degrees(131.5), clockwise: false)
                .stroke(Color.yellow.opacity(isActive ? 0.5 : 0.15), lineWidth: 10)
                .frame(width: arcRadius * 2, height: arcRadius)

            ArcShape(startAngle: .degrees(48.5), endAngle: .degrees(31.5), clockwise: false)
                .stroke(Color.yellow.opacity(isActive ? 0.5 : 0.15), lineWidth: 10)
                .frame(width: arcRadius * 2, height: arcRadius)

            // Green zone (center ±30¢ = ±51°)
            ArcShape(startAngle: .degrees(131.5), endAngle: .degrees(48.5), clockwise: false)
                .stroke(Color.green.opacity(isActive ? 0.5 : 0.15), lineWidth: 10)
                .frame(width: arcRadius * 2, height: arcRadius)

            // Tick marks
            ForEach([-50, -40, -30, -20, -10, 0, 10, 20, 30, 40, 50], id: \.self) { cent in
                TickMark(cents: Double(cent), arcRadius: arcRadius)
                    .opacity(isActive ? 1 : 0.4)
            }

            // Needle
            if isActive {
                Rectangle()
                    .fill(needleColor)
                    .frame(width: 3, height: needleLength)
                    .offset(y: -needleLength / 2)
                    .rotationEffect(needleAngle, anchor: .bottom)
                    .animation(.spring(response: 0.12, dampingFraction: 0.55), value: centsDeviation)
                    .offset(y: -(needleLength / 2) + 10)
            }

            // Pivot dot
            Circle()
                .fill(isActive ? needleColor : Color.secondary)
                .frame(width: 12, height: 12)
                .offset(y: -(needleLength / 2) + needleLength / 2)
                .animation(.spring(response: 0.12, dampingFraction: 0.55), value: needleColor)

            // Labels
            HStack {
                Text("-50¢")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("0")
                    .font(.caption2.bold())
                    .foregroundStyle(.secondary)
                Spacer()
                Text("+50¢")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(width: arcRadius * 2 + 20)
            .offset(y: 20)
        }
        .frame(width: arcRadius * 2 + 20, height: arcRadius + 40)
    }
}

// MARK: - Supporting Shapes

private struct ArcShape: Shape {
    var startAngle: Angle
    var endAngle: Angle
    var clockwise: Bool

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.maxY)
        let radius = min(rect.width, rect.height * 2) / 2
        path.addArc(center: center,
                    radius: radius,
                    startAngle: startAngle,
                    endAngle: endAngle,
                    clockwise: clockwise)
        return path
    }
}

private struct TickMark: View {
    let cents: Double
    let arcRadius: CGFloat

    // cents ∈ [-50, 50] → angle ∈ [180°, 0°] linearly
    private var angle: Double {
        180.0 - (cents + 50.0) / 100.0 * 180.0
    }

    var body: some View {
        let isCenter = cents == 0
        let tickLength: CGFloat = isCenter ? 14 : 8

        Rectangle()
            .fill(isCenter ? Color.primary : Color.secondary)
            .frame(width: isCenter ? 2 : 1, height: tickLength)
            .offset(y: -(arcRadius - tickLength / 2 - 4))
            .rotationEffect(.degrees(angle - 90), anchor: .center)
            .offset(y: -(arcRadius / 2) + 5)
    }
}

#Preview {
    VStack(spacing: 24) {
        TunerGaugeView(centsDeviation: 0, isActive: true)
        TunerGaugeView(centsDeviation: -35, isActive: true)
        TunerGaugeView(centsDeviation: 48, isActive: true)
        TunerGaugeView(centsDeviation: 0, isActive: false)
    }
    .padding()
}
