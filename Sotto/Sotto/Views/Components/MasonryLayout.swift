import SwiftUI

struct MasonryLayout: Layout {
    var columns: Int
    var spacing: CGFloat = 16

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        let width = proposal.width ?? 0
        let colWidth = columnWidth(totalWidth: width)
        var colHeights = [CGFloat](repeating: 0, count: columns)

        for subview in subviews {
            let col = shortestColumn(colHeights)
            let size = subview.sizeThatFits(ProposedViewSize(width: colWidth, height: nil))
            if colHeights[col] > 0 {
                colHeights[col] += spacing
            }
            colHeights[col] += size.height
        }

        return CGSize(width: width, height: colHeights.max() ?? 0)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
        let colWidth = columnWidth(totalWidth: bounds.width)
        var colHeights = [CGFloat](repeating: 0, count: columns)

        for subview in subviews {
            let col = shortestColumn(colHeights)
            let size = subview.sizeThatFits(ProposedViewSize(width: colWidth, height: nil))
            let x = bounds.minX + CGFloat(col) * (colWidth + spacing)
            let y = bounds.minY + colHeights[col] + (colHeights[col] > 0 ? spacing : 0)
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(width: colWidth, height: size.height))
            colHeights[col] = y - bounds.minY + size.height
        }
    }

    private func columnWidth(totalWidth: CGFloat) -> CGFloat {
        guard columns > 0 else { return totalWidth }
        return (totalWidth - spacing * CGFloat(columns - 1)) / CGFloat(columns)
    }

    private func shortestColumn(_ heights: [CGFloat]) -> Int {
        heights.indices.min(by: { heights[$0] < heights[$1] }) ?? 0
    }
}
