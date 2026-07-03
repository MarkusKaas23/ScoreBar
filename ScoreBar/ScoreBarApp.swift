import SwiftUI

@main
struct ScoreBarApp: App {
    @State private var engine = ScoreEngine()

    var body: some Scene {
        MenuBarExtra {
            PopoverView()
                .environment(engine)
                .frame(width: 300)
        } label: {
            Text("\(engine.markusScore) – \(engine.marcusScore)")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
        }
        .menuBarExtraStyle(.window)
        .onChange(of: engine.markusScore) { old, new in
            if new > old { FullScreenConfettiPanel.shared.show() }
        }
    }
}
