//
//  SettingsPageSubsection.swift
//  Onit
//
//  Created by Loyd Kim on 2/24/26.
//

import SwiftUI



struct SettingsPageSubsection<Children: View>: View {
    // MARK: - Types

    struct VerticalConfigs {
        var alignment: HorizontalAlignment = .leading
        var spacing: CGFloat = 0
    }

    struct HorizontalConfigs {
        var alignment: VerticalAlignment = .center
        var spacing: CGFloat = 0
    }

    struct HeaderConfigs {
        let title: String
        var titleSize: CGFloat = 13
        var titleWeight: Font.Weight = Font.Weight.regular
        var titleColor: Color = Color.S_0
        var subtitle: String? = nil
        var subtitleSize: CGFloat = 12
        var subtitleWeight: Font.Weight = Font.Weight.regular
        var subtitleColor: Color = Color.T_1
        var spacing: CGFloat = 4
    }

    struct SystemNameConfigs {
        let name: String
        var color: Color = Color.S_0
        var size: CGFloat = 16
        var weight: Font.Weight = Font.Weight.medium
    }

    struct ImageResourceConfigs {
        let resource: ImageResource
        var color: Color = Color.S_0
        var width: CGFloat = 16
        var height: CGFloat = 16
    }
    
    struct DropdownConfigsOption {
        let id: UUID
        let name: String
        var isSelected: Bool = false
        let action: () -> Void
    }

    struct DropdownConfigs {
        let placeholder: String
        let options: [DropdownConfigsOption]
    }

    struct MultiSelectDropdownConfigs {
        let label: String
        var dividerIndexes: [Int]? = nil
        let options: [DropdownConfigsOption]
    }
    
    // MARK: - Properties

    private let vertical: VerticalConfigs?
    private let horizontal: HorizontalConfigs
    private let header: HeaderConfigs?
    private let systemName: SystemNameConfigs?
    private let imageResource: ImageResourceConfigs?
    private let dropdown: DropdownConfigs?
    private let multiSelectDropdown: MultiSelectDropdownConfigs?
    private let isOn: Binding<Bool>?
    @ViewBuilder private let children: () -> Children

    // MARK: - Initializer

    init(
        vertical: VerticalConfigs? = nil,
        horizontal: HorizontalConfigs = .init(),
        header: HeaderConfigs? = nil,
        systemName: SystemNameConfigs? = nil,
        imageResource: ImageResourceConfigs? = nil,
        dropdown: DropdownConfigs? = nil,
        multiSelectDropdown: MultiSelectDropdownConfigs? = nil,
        isOn: Binding<Bool>? = nil,

        @ViewBuilder children: @escaping () -> Children = {
            EmptyView()
        }
    ) {
        self.vertical = vertical
        self.horizontal = horizontal
        self.header = header
        self.systemName = systemName
        self.imageResource = imageResource
        self.dropdown = dropdown
        self.multiSelectDropdown = multiSelectDropdown
        self.isOn = isOn
        self.children = children
    }
    
    // MARK: - Private Variables
    
    private var hasIcon: Bool {
        return
            systemName != nil ||
            imageResource != nil
    }
    
    // MARK: - Body
    
    var body: some View {
        if let vertical = self.vertical {
            VStack(
                alignment: vertical.alignment,
                spacing: vertical.spacing
            ) {
                contentView
            }
        } else {
            HStack(
                alignment: isOn == nil ? horizontal.alignment : .top,
                spacing: horizontal.spacing
            ) {
                contentView
            }
        }
    }
    
    // MARK: - Child Components: Content View
    
    private var contentView: some View {
        Group {
            headerView
            dropdownView
            multiSelectDropdownView
            toggleView
            children()
        }
    }
    
    // MARK: - Child Components: Header View
    
    @ViewBuilder
    private var headerView: some View {
        if let header = self.header {
            VStack(alignment: .leading, spacing: hasIcon ? 4 : 2) {
                HStack(alignment: .center, spacing: header.spacing) {
                    headerIconView
                    
                    Text(header.title)
                        .styleText(
                            size: header.titleSize,
                            weight: header.titleWeight,
                            color: header.titleColor
                        )
                }
                
                if let subtitle = header.subtitle {
                    Text(subtitle)
                        .styleText(
                            size: header.subtitleSize,
                            weight: header.subtitleWeight,
                            color: header.subtitleColor
                        )
                }
            }
            .padding(.trailing, vertical == nil ? 8 : 0)
            .frame(
                maxWidth: .infinity,
                alignment: .leading
            )
        }
    }
    
    @ViewBuilder
    private var headerIconView: some View {
        if let systemName = self.systemName {
            Image(systemName: systemName.name)
                .foregroundColor(systemName.color)
                .font(.system(
                    size: systemName.size,
                    weight: systemName.weight
                ))
        } else if let imageResource = self.imageResource {
            Image(imageResource.resource)
                .renderingMode(.template)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(
                    width: imageResource.width,
                    height: imageResource.height
                )
                .foregroundColor(imageResource.color)
        }
    }
    
    // MARK: - Child Components: Dropdown View
    
    @ViewBuilder
    private var dropdownView: some View {
        if let dropdown = self.dropdown {
            let selectedOptions = dropdown.options.filter(\.isSelected)
            let selectedOptionName = selectedOptions.count == 1
                ? selectedOptions[0].name
                : dropdown.placeholder
            
            Menu {
                ForEach(dropdown.options, id: \.id) { item in
                    Button {
                        item.action()
                    } label: {
                        if item.isSelected {
                            Label(item.name, systemImage: "checkmark")
                        } else {
                            Text(item.name)
                        }
                    }
                }
            } label: {
                Text(selectedOptionName)
            }
        }
    }
    
    // MARK: - Child Components: Multi-Select Dropdown View

    @ViewBuilder
    private var multiSelectDropdownView: some View {
        if let multiSelectDropdown = self.multiSelectDropdown {
            MultiSelectDropdownView(configs: multiSelectDropdown)
        }
    }

    // MARK: - Child Components: Toggle View

    @ViewBuilder
    private var toggleView: some View {
        if let isOn = self.isOn {
            Toggle("", isOn: isOn)
                .toggleStyle(.switch)
                .controlSize(.small)
        }
    }
}

// MARK: - Multi-Select Dropdown View

private struct MultiSelectDropdownView<Children: View>: View {
    let configs: SettingsPageSubsection<Children>.MultiSelectDropdownConfigs

    @State private var isOpen = false

    var body: some View {
        Button {
            isOpen.toggle()
        } label: {
            Text(configs.label)
        }
        .popover(isPresented: $isOpen, arrowEdge: .bottom) {
            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(Array(configs.options.enumerated()), id: \.element.id) { index, item in
                        Toggle(
                            item.name,
                            isOn: Binding(
                                get: { item.isSelected },
                                set: { _ in item.action() }
                            )
                        )
                        .toggleStyle(.checkbox)
                        
                        if let dividerIndexes = configs.dividerIndexes,
                           dividerIndexes.contains(index)
                        {
                            Divider()
                        }
                    }
                }
                .padding(12)
            }
            .frame(
                minWidth: 200,
                maxHeight: 300
            )
        }
    }
}
