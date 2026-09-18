import SwiftUI
import AppKit

@MainActor
public struct MainView: View {
    @ObservedObject public var viewModel: AppViewModel
    @ObservedObject private var langManager = LanguageManager.shared
    @State private var refreshRotation: Double = 0
    @FocusState private var isSearchFocused: Bool

    public init(viewModel: AppViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Header Bar
            headerBar

            // Tab Selector (Custom Glass Pill Bar)
            tabSelector
                .padding(.horizontal, 14)
                .padding(.top, 4)
                .padding(.bottom, 8)

            // Search and Filter Bar (visible when on Simulators tab)
            if viewModel.selectedTab == .simulators {
                searchAndFilterBar
                    .padding(.horizontal, 14)
                    .padding(.bottom, 10)
            }

            Divider()
                .opacity(0.4)

            // Main Content Area
            Group {
                switch viewModel.selectedTab {
                case .simulators:
                    SimulatorListView(viewModel: viewModel)
                case .physicalDevices:
                    PhysicalDevicesView(viewModel: viewModel)
                case .tools:
                    QuickToolsView(viewModel: viewModel)
                case .settings:
                    SettingsView(viewModel: viewModel)
                }
            }
            .frame(maxHeight: .infinity)

            Divider()
                .opacity(0.4)

            // Bottom Toast / Status Bar & Footer
            footerBar
        }
        .frame(width: 448, height: 590)
        .background(
            ZStack {
                Color(NSColor.windowBackgroundColor)
                Rectangle()
                    .fill(.ultraThinMaterial)

                // Invisible Keyboard Shortcuts Handler
                Group {
                    Button("") {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                            viewModel.selectedTab = .simulators
                        }
                    }
                    .keyboardShortcut("1", modifiers: .command)

                    Button("") {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                            viewModel.selectedTab = .physicalDevices
                        }
                    }
                    .keyboardShortcut("2", modifiers: .command)

                    Button("") {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                            viewModel.selectedTab = .tools
                        }
                    }
                    .keyboardShortcut("3", modifiers: .command)

                    Button("") {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                            viewModel.selectedTab = .settings
                        }
                    }
                    .keyboardShortcut("4", modifiers: .command)

                    Button("") {
                        isSearchFocused = true
                    }
                    .keyboardShortcut("f", modifiers: .command)

                    Button("") {
                        withAnimation(.linear(duration: 0.8)) {
                            refreshRotation += 360
                        }
                        Task { await viewModel.refreshAll() }
                    }
                    .keyboardShortcut("r", modifiers: .command)
                }
                .frame(width: 0, height: 0)
                .opacity(0)
                .allowsHitTesting(false)
            }
        )
    }

    // MARK: - Header
    private var headerBar: some View {
        HStack(spacing: 10) {
            // Logo Icon Container
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(AppTheme.primaryGradient)
                    .frame(width: 28, height: 28)
                    .shadow(color: Color(hex: "3B82F6").opacity(0.3), radius: 4, y: 2)

                Image(systemName: "macbook.and.iphone")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 6) {
                    Text(loc("app_title"))
                        .font(.system(size: 13.5, weight: .bold, design: .rounded))

                    if viewModel.bootedSimulatorsCount > 0 {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color(hex: "10B981"))
                                .frame(width: 5, height: 5)
                            Text("\(viewModel.bootedSimulatorsCount) \(loc("booted"))")
                                .font(.system(size: 9.5, weight: .bold, design: .rounded))
                                .foregroundColor(Color(hex: "10B981"))
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(hex: "10B981").opacity(0.12))
                        .clipShape(Capsule())
                    }
                }
            }

            Spacer()

            // Refresh Button with smooth rotation
            Button {
                withAnimation(.linear(duration: 0.8)) {
                    refreshRotation += 360
                }
                Task { await viewModel.refreshAll() }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)
                    .rotationEffect(.degrees(refreshRotation))
                    .padding(6)
                    .background(Color.primary.opacity(0.04))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .help(loc("refresh_tooltip"))

            // Settings Tab Button
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                    viewModel.selectedTab = (viewModel.selectedTab == .settings) ? .simulators : .settings
                }
            } label: {
                Image(systemName: viewModel.selectedTab == .settings ? "gearshape.fill" : "gearshape")
                    .font(.system(size: 11.5, weight: .semibold))
                    .foregroundColor(viewModel.selectedTab == .settings ? Color(hex: "3B82F6") : .secondary)
                    .padding(6)
                    .background(viewModel.selectedTab == .settings ? Color(hex: "3B82F6").opacity(0.12) : Color.primary.opacity(0.04))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .help(loc("settings_tooltip"))
        }
        .padding(.horizontal, 14)
        .padding(.top, 12)
        .padding(.bottom, 6)
    }

    // MARK: - Custom Glass Pill Tab Selector
    private var tabSelector: some View {
        HStack(spacing: 4) {
            ForEach(AppViewModel.Tab.allCases, id: \.self) { tab in
                let isSelected = viewModel.selectedTab == tab
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                        viewModel.selectedTab = tab
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 10.5, weight: isSelected ? .semibold : .regular))

                        Text(tab.localizedTitle)
                            .font(.system(size: 10.5, weight: isSelected ? .semibold : .medium, design: .rounded))
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                    }
                    .foregroundColor(isSelected ? .white : .secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(
                        ZStack {
                            if isSelected {
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(AppTheme.primaryGradient)
                                    .shadow(color: Color(hex: "3B82F6").opacity(0.25), radius: 4, y: 2)
                            }
                        }
                    )
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.primary.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.06), lineWidth: 0.5)
                )
        )
    }

    // MARK: - Modern Search & Filter
    private var searchAndFilterBar: some View {
        HStack(spacing: 8) {
            // Capsule search input
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(isSearchFocused ? Color(hex: "3B82F6") : .secondary)
                    .font(.system(size: 11.5))

                TextField(loc("search_placeholder"), text: $viewModel.searchText)
                    .focused($isSearchFocused)
                    .textFieldStyle(.plain)
                    .font(.system(size: 11.5))

                if !viewModel.searchText.isEmpty {
                    Button {
                        viewModel.searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                            .font(.system(size: 11))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color(NSColor.controlBackgroundColor).opacity(0.6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .strokeBorder(isSearchFocused ? Color(hex: "3B82F6").opacity(0.6) : Color.primary.opacity(0.08), lineWidth: isSearchFocused ? 1 : 0.5)
                    )
            )

            // Pill Filter Toggle: "Booted"
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    viewModel.filterBootedOnly.toggle()
                }
            } label: {
                HStack(spacing: 4) {
                    Circle()
                        .fill(viewModel.filterBootedOnly ? Color(hex: "10B981") : Color.secondary.opacity(0.4))
                        .frame(width: 6, height: 6)
                    Text(loc("filter_booted_only"))
                        .font(.system(size: 10.5, weight: viewModel.filterBootedOnly ? .semibold : .medium, design: .rounded))
                        .foregroundColor(viewModel.filterBootedOnly ? Color(hex: "10B981") : .secondary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 5.5)
                .background(
                    Capsule()
                        .fill(viewModel.filterBootedOnly ? Color(hex: "10B981").opacity(0.14) : Color.primary.opacity(0.04))
                )
                .overlay(
                    Capsule()
                        .strokeBorder(viewModel.filterBootedOnly ? Color(hex: "10B981").opacity(0.3) : Color.primary.opacity(0.06), lineWidth: 0.5)
                )
            }
            .buttonStyle(.plain)
            .help(loc("filter_booted_tooltip"))
        }
    }

    // MARK: - Footer with Floating Toast
    private var footerBar: some View {
        HStack(spacing: 8) {
            if let message = viewModel.statusMessage {
                HStack(spacing: 6) {
                    Image(systemName: viewModel.isErrorStatus ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                        .foregroundColor(viewModel.isErrorStatus ? Color(hex: "F43F5E") : Color(hex: "10B981"))
                        .font(.system(size: 11))

                    Text(message)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(viewModel.isErrorStatus ? Color(hex: "F43F5E") : .primary)
                        .lineLimit(1)
                }
                .transition(.asymmetric(insertion: .scale(scale: 0.9).combined(with: .opacity), removal: .opacity))
            } else {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color(hex: "10B981"))
                        .frame(width: 5, height: 5)
                    Text(loc("ready_status"))
                        .font(.system(size: 10.5, design: .rounded))
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Text("v1.2.0")
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(.secondary.opacity(0.6))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
        .background(Color.primary.opacity(0.02))
    }
}

