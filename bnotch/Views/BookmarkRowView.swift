import SwiftUI

struct BookmarkRowView: View {
    let bookmark: Bookmark
    let onOpen: () -> Void
    let onClose: (() -> Void)?
    let onEdit: () -> Void
    let onDelete: () -> Void

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 10) {
            // Favicon
            if let data = bookmark.faviconData,
               let nsImage = NSImage(data: data) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 18, height: 18)
                    .cornerRadius(4)
            } else {
                Image(systemName: "globe")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.5))
                    .frame(width: 18, height: 18)
            }

            // Name
            Text(bookmark.name.isEmpty ? bookmark.url : bookmark.name)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white)
                .lineLimit(1)
                .truncationMode(.tail)

            Spacer(minLength: 0)

            // Browser icon
            if let browser = BrowserDetector.shared.effectiveBrowser(for: bookmark.browserBundleID),
               let icon = browser.icon {
                Image(nsImage: icon)
                    .resizable()
                    .interpolation(.high)
                    .frame(width: 14, height: 14)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isHovered ? Color.blue.opacity(0.25) : Color.clear)
        )
        .onHover { isHovered = $0 }
        .onTapGesture { onOpen(); onClose?() }
        .contextMenu {
            Button(L10n.open) { onOpen() }
            Button(L10n.edit) { onEdit() }
            Divider()
            Button(L10n.delete, role: .destructive) { onDelete() }
        }
    }
}
