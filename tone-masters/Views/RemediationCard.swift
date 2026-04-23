import SwiftUI

struct RemediationCard: View {
    let tip: RemediationTip

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: tip.icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(Color.tmAccent)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 4) {
                Text(tip.headline)
                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Color.tmInk)
                Text(tip.detail)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.tmDim)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.tmAccent.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.tmAccent.opacity(0.18), lineWidth: 1))
    }
}
