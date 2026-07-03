import SwiftUI

struct PopoverView: View {
    @Environment(ScoreEngine.self) var engine
    @State private var confettiTrigger = 0

    var body: some View {
        VStack(spacing: 0) {

            // ── Header ────────────────────────────────────────────────
            HStack {
                Text("⚽ ScoreBar")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                Spacer()
                HStack(spacing: 4) {
                    Circle()
                        .fill(engine.isConnected ? Color.green : Color.orange)
                        .frame(width: 6, height: 6)
                    Text(engine.isConnected ? engine.connectedPeerName : "Looking…")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            Divider()

            // ── Score ─────────────────────────────────────────────────
            HStack(spacing: 0) {
                PlayerColumn(
                    name: "Markus",
                    score: engine.markusScore,
                    color: .red,
                    onIncrement: { engine.incrementMarkus() },
                    onDecrement: { engine.decrementMarkus() }
                )

                Text("–")
                    .font(.system(size: 44, weight: .black))
                    .foregroundColor(.secondary)
                    .frame(width: 36)

                PlayerColumn(
                    name: "Marcus",
                    score: engine.marcusScore,
                    color: .blue,
                    onIncrement: { engine.incrementMarcus() },
                    onDecrement: { engine.decrementMarcus() }
                )
            }
            .padding(.vertical, 16)

            Divider()

            // ── Foosball table ────────────────────────────────────────
            FoosballView()
                .frame(height: 120)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)

            Divider()

            // ── Reset ─────────────────────────────────────────────────
            Button { engine.reset() } label: {
                Text("Reset Score")
                    .font(.system(size: 12))
                    .foregroundColor(.red.opacity(0.8))
            }
            .buttonStyle(.plain)
            .padding(.vertical, 10)
        }
        .background(.regularMaterial)
        .overlay { ConfettiView(trigger: confettiTrigger) }
        .onChange(of: engine.markusScore) { old, new in
            if new > old { confettiTrigger += 1 }
        }
        .onChange(of: engine.marcusScore) { old, new in
            if new > old { confettiTrigger += 1 }
        }
    }
}

// MARK: - Player column
private struct PlayerColumn: View {
    let name:        String
    let score:       Int
    let color:       Color
    let onIncrement: () -> Void
    let onDecrement: () -> Void

    var body: some View {
        VStack(spacing: 6) {
            Text(name)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(color)

            Text("\(score)")
                .font(.system(size: 52, weight: .black, design: .rounded))
                .foregroundColor(.primary)
                .frame(minWidth: 60)
                .contentTransition(.numericText())
                .animation(.spring(response: 0.3), value: score)

            HStack(spacing: 8) {
                ScoreButton(label: "–", color: color.opacity(0.12), foreground: color,  action: onDecrement)
                ScoreButton(label: "+", color: color,                foreground: .white, action: onIncrement)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Score button
private struct ScoreButton: View {
    let label:      String
    let color:      Color
    let foreground: Color
    let action:     () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 20, weight: .bold))
                .frame(width: 38, height: 38)
                .background(color)
                .foregroundColor(foreground)
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }
}
