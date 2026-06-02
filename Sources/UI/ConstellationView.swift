import SwiftUI

/// A living symbol constellation — nodes sized by how often a symbol recurs, faint links between them.
/// Free (competitors paywall their stats). Grows as the journal grows.
struct ConstellationView: View {
    let counts: [(key: String, count: Int)]   // sorted desc
    private var top: [(key: String, count: Int)] { Array(counts.prefix(7)) }
    private var maxC: Int { top.first?.count ?? 1 }

    var body: some View {
        GeometryReader { g in
            let c = CGPoint(x: g.size.width/2, y: g.size.height/2)
            let r = min(g.size.width, g.size.height) * 0.36
            ZStack {
                // links from the dominant node to the rest
                ForEach(Array(top.enumerated().dropFirst()), id: \.offset) { i, _ in
                    Path { p in p.move(to: c); p.addLine(to: pos(i, c: c, r: r)) }
                        .stroke(Theme.teal.opacity(0.18), lineWidth: 0.8)
                }
                ForEach(Array(top.enumerated()), id: \.offset) { i, item in
                    let p = i == 0 ? c : pos(i, c: c, r: r)
                    let size = 30 + 26 * CGFloat(item.count) / CGFloat(maxC)
                    VStack(spacing: 3) {
                        Circle().fill(Theme.aurora).frame(width: size, height: size)
                            .shadow(color: Theme.violet.opacity(0.5), radius: 8)
                            .overlay(Text("\(item.count)").font(.system(size: 11, weight: .bold)).foregroundStyle(Theme.bg1))
                        Text(SymbolEngine.label(item.key)).font(.system(size: 10)).foregroundStyle(Theme.textMid).lineLimit(1)
                    }.position(x: p.x, y: p.y)
                }
            }
        }.frame(height: 280)
    }
    private func pos(_ i: Int, c: CGPoint, r: CGFloat) -> CGPoint {
        let n = max(top.count - 1, 1)
        let a = (Double(i - 1) / Double(n)) * 2 * .pi - .pi/2
        return CGPoint(x: c.x + r * cos(a), y: c.y + r * sin(a))
    }
}
