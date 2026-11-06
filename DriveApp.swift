import SwiftUI

struct Traffic { var x: CGFloat; var y: CGFloat; var v: CGFloat }

final class Game {
    var carX: CGFloat = 0.5
    var speed: CGFloat = 0
    var steer: CGFloat = 0
    var gas = false
    var braking = false
    var traffic: [Traffic] = []
    var dist: CGFloat = 0
    var dash: CGFloat = 0
    var over = false
    var last: TimeInterval = 0

    func reset() {
        carX = 0.5; speed = 0; traffic = []; dist = 0; over = false
    }

    func step(_ now: TimeInterval, _ size: CGSize) {
        let dt = last == 0 ? 0 : min(CGFloat(now - last), 0.05)
        last = now
        if over { return }
        if gas { speed = min(1, speed + 0.4 * dt) }
        else if braking { speed = max(0, speed - 1.0 * dt) }
        else { speed = max(0, speed - 0.15 * dt) }
        carX = min(0.85, max(0.15, carX + steer * (0.2 + speed) * 0.6 * dt))
        dist += speed * 40 * dt
        dash += speed * 1.2 * dt
        if traffic.count < 5 && CGFloat.random(in: 0...1) < 0.03 {
            traffic.append(Traffic(x: .random(in: 0.15...0.85), y: -0.1, v: .random(in: 0.1...0.4)))
        }
        for i in traffic.indices {
            traffic[i].y += (speed - traffic[i].v) * 0.8 * dt
        }
        traffic.removeAll { $0.y > 1.2 || $0.y < -0.3 }
        let w = size.width * 0.12
        let h = w * 1.8
        for t in traffic where abs(t.x - carX) * size.width < w && abs(t.y - 0.78) * size.height < h {
            over = true
        }
    }

    func draw(_ ctx: GraphicsContext, _ size: CGSize) {
        let W = size.width, H = size.height
        ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(.green))
        ctx.fill(Path(CGRect(x: W * 0.05, y: 0, width: W * 0.9, height: H)), with: .color(.gray))
        let gap = H / 8
        let off = (dash * H).truncatingRemainder(dividingBy: gap)
        for k in -1..<9 {
            ctx.fill(Path(CGRect(x: W * 0.5 - 3, y: CGFloat(k) * gap + off, width: 6, height: gap * 0.5)), with: .color(.white))
        }
        let w = W * 0.12, h = w * 1.8
        for t in traffic {
            ctx.fill(Path(roundedRect: CGRect(x: t.x * W - w / 2, y: t.y * H - h / 2, width: w, height: h), cornerRadius: 8), with: .color(.red))
        }
        ctx.fill(Path(roundedRect: CGRect(x: carX * W - w / 2, y: 0.78 * H - h / 2, width: w, height: h), cornerRadius: 8), with: .color(.blue))
        ctx.draw(Text("\(Int(dist)) m").font(.title.bold()).foregroundColor(.white), at: CGPoint(x: 70, y: 90))
        if over {
            ctx.draw(Text("Crash! Tap to restart").font(.title.bold()).foregroundColor(.white), at: CGPoint(x: W / 2, y: H / 2))
        }
    }
}

struct HoldButton: View {
    let label: String
    let color: Color
    let down: () -> Void
    let up: () -> Void
    var body: some View {
        Text(label)
            .font(.headline)
            .minimumScaleFactor(0.5)
            .foregroundColor(.white)
            .frame(width: 80, height: 80)
            .background(color.opacity(0.7))
            .clipShape(Circle())
            .gesture(DragGesture(minimumDistance: 0)
                .onChanged { _ in down() }
                .onEnded { _ in up() })
    }
}

struct ContentView: View {
    @State private var game = Game()
    var body: some View {
        ZStack {
            TimelineView(.animation) { tl in
                Canvas { ctx, size in
                    game.step(tl.date.timeIntervalSinceReferenceDate, size)
                    game.draw(ctx, size)
                }
            }
            .ignoresSafeArea()
            .onTapGesture { if game.over { game.reset() } }
            VStack {
                Spacer()
                HStack {
                    HoldButton(label: "◀", color: .black, down: { game.steer = -1 }, up: { game.steer = 0 })
                    HoldButton(label: "▶", color: .black, down: { game.steer = 1 }, up: { game.steer = 0 })
                    Spacer()
                    HoldButton(label: "BRAKE", color: .red, down: { game.braking = true }, up: { game.braking = false })
                    HoldButton(label: "GAS", color: .orange, down: { game.gas = true }, up: { game.gas = false })
                }
                .padding()
            }
        }
    }
}

@main
struct DriveApp: App {
    var body: some Scene {
        WindowGroup { ContentView() }
    }
}
