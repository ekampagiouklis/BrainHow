import SwiftUI

struct SettingsSectionContainer<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.headline).foregroundColor(Color.themeCream).padding(.leading, 10)
            VStack(spacing: 0) { content }
                .padding(15)
                .background(ZStack {
                    Rectangle().fill(.ultraThinMaterial)
                    Rectangle().fill(Color.themeCream.opacity(0.05))
                })
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
    }
}

struct SettingsToggleRow: View {
    let title: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(spacing: 15) {
            Text(title).font(.body.weight(.medium)).foregroundColor(Color.themeCream)
            Spacer()
            Toggle("", isOn: $isOn).tint(Color.themeLightBlue).labelsHidden()
        }.padding(.vertical, 8)
    }
}

struct SettingsPickerRow: View {
    let title: String
    let options: [String]
    @Binding var selection: String
    
    var body: some View {
        HStack {
            Text(title).font(.body.weight(.medium)).foregroundColor(Color.themeCream)
            Spacer()
            Picker("", selection: $selection) {
                ForEach(options, id: \.self) { Text($0) }
            }.tint(Color.themeLightBlue)
        }.padding(.vertical, 8)
    }
}
