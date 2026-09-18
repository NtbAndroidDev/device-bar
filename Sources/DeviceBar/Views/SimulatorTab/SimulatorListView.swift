import SwiftUI

public struct SimulatorListView: View {
    @ObservedObject public var viewModel: AppViewModel
    @State private var selectedSegment: DevicePlatformSegment = .all

    public enum DevicePlatformSegment: String, CaseIterable {
        case all = "Tất cả"
        case ios = "iOS"
        case android = "Android"
    }

    public init(viewModel: AppViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(spacing: 8) {
            // Global Filter & Emergency Action Bar
            HStack(spacing: 8) {
                // Mini Segment Picker
                HStack(spacing: 2) {
                    ForEach(DevicePlatformSegment.allCases, id: \.self) { segment in
                        let isSelected = selectedSegment == segment
                        Button {
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                selectedSegment = segment
                            }
                        } label: {
                            Text(segment.rawValue)
                                .font(.system(size: 11, weight: isSelected ? .semibold : .regular, design: .rounded))
                                .foregroundColor(isSelected ? .white : .secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3.5)
                                .background(
                                    ZStack {
                                        if isSelected {
                                            Capsule()
                                                .fill(Color(hex: "4B5563"))
                                        }
                                    }
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(2)
                .background(
                    Capsule()
                        .fill(Color.primary.opacity(0.05))
                )

                Spacer()

                // Emergency Kill Buttons
                Menu {
                    Button(role: .destructive) {
                        Task { await viewModel.killAllSimulators() }
                    } label: {
                        Label("Tắt toàn bộ iOS Simulators", systemImage: "applelogo")
                    }

                    Button(role: .destructive) {
                        Task { await viewModel.killAllEmulators() }
                    } label: {
                        Label("Tắt toàn bộ Android AVDs", systemImage: "xmark.circle")
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "xmark.octagon")
                            .font(.system(size: 10.5))
                        Text("Tắt nhanh")
                            .font(.system(size: 10.5, weight: .medium, design: .rounded))
                    }
                    .foregroundColor(Color(hex: "F43F5E"))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3.5)
                    .background(Color(hex: "F43F5E").opacity(0.1))
                    .clipShape(Capsule())
                }
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)
                .help("Tắt toàn bộ máy ảo khi máy bị lag")
            }
            .padding(.horizontal, 14)
            .padding(.top, 4)

            // Scrollable Content
            ScrollView {
                VStack(spacing: 14) {
                    // MARK: - 1. In-Progress & Active Section (Khi ở tab "Tất cả")
                    if selectedSegment == .all && (!viewModel.activeSimulatorsList.isEmpty || !viewModel.activeAVDsList.isEmpty) {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(Color(hex: "10B981"))
                                    .frame(width: 7, height: 7)

                                Text("Đang Hoạt Động (Active / In-Progress)")
                                    .font(.system(size: 12, weight: .bold, design: .rounded))

                                Spacer()

                                Text("\(viewModel.activeSimulatorsList.count + viewModel.activeAVDsList.count) máy đang chạy")
                                    .font(.system(size: 9.5, weight: .bold, design: .rounded))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color(hex: "10B981").opacity(0.12))
                                    .foregroundColor(Color(hex: "10B981"))
                                    .clipShape(Capsule())
                            }

                            LazyVStack(spacing: 7) {
                                ForEach(viewModel.activeSimulatorsList) { sim in
                                    SimulatorItemView(device: sim, viewModel: viewModel)
                                }

                                ForEach(viewModel.activeAVDsList) { avd in
                                    AVDCardView(avd: avd, viewModel: viewModel)
                                }
                            }
                        }

                        Divider()
                            .opacity(0.3)
                    }

                    // MARK: - 2. iOS Simulators Section
                    if selectedSegment == .all || selectedSegment == .ios {
                        let simsToShow = selectedSegment == .all && (!viewModel.activeSimulatorsList.isEmpty || !viewModel.activeAVDsList.isEmpty)
                            ? viewModel.inactiveSimulatorsList
                            : viewModel.filteredSimulators

                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 6) {
                                Image(systemName: "applelogo")
                                    .font(.system(size: 12))
                                    .foregroundColor(.primary.opacity(0.7))

                                Text(selectedSegment == .all && !viewModel.activeSimulatorsList.isEmpty ? "iOS Simulators (Khác)" : "iOS Simulators")
                                    .font(.system(size: 12, weight: .bold, design: .rounded))

                                Spacer()

                                Text("\(simsToShow.count) thiết bị")
                                    .font(.system(size: 10.5, design: .rounded))
                                    .foregroundColor(.secondary)
                            }

                            if viewModel.isLoading && viewModel.simulators.isEmpty {
                                LazyVStack(spacing: 7) {
                                    SkeletonCardView()
                                    SkeletonCardView()
                                    SkeletonCardView()
                                }
                            } else if simsToShow.isEmpty {
                                VStack(spacing: 8) {
                                    Image(systemName: "iphone.slash")
                                        .font(.system(size: 22))
                                        .foregroundColor(.secondary.opacity(0.5))

                                    Text(viewModel.activeSimulatorsList.isEmpty ? "Không tìm thấy iOS Simulator phù hợp" : "Tất cả iOS Simulator đã được đưa lên mục Đang Hoạt Động")
                                        .font(.system(size: 11, weight: .medium, design: .rounded))
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                            } else {
                                LazyVStack(spacing: 7) {
                                    ForEach(simsToShow) { sim in
                                        SimulatorItemView(device: sim, viewModel: viewModel)
                                    }
                                }
                            }
                        }
                    }

                    // MARK: - 3. Android AVDs Section
                    if selectedSegment == .all || selectedSegment == .android {
                        if selectedSegment == .all && (!viewModel.activeSimulatorsList.isEmpty || !viewModel.activeAVDsList.isEmpty) {
                            // Chỉ hiện các máy AVD chưa chạy nếu đã đưa máy chạy lên đầu
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 6) {
                                    AndroidBugdroidIcon(color: Color(hex: "10B981"), size: 14)

                                    Text("Android Emulators (Khác)")
                                        .font(.system(size: 12, weight: .bold, design: .rounded))

                                    Spacer()

                                    Text("\(viewModel.inactiveAVDsList.count) máy ảo")
                                        .font(.system(size: 10.5, design: .rounded))
                                        .foregroundColor(.secondary)
                                }

                                if viewModel.inactiveAVDsList.isEmpty {
                                    Text("Tất cả Android AVD đã được đưa lên mục Đang Hoạt Động")
                                        .font(.system(size: 11, design: .rounded))
                                        .foregroundColor(.secondary)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 8)
                                } else {
                                    LazyVStack(spacing: 7) {
                                        ForEach(viewModel.inactiveAVDsList) { avd in
                                            AVDCardView(avd: avd, viewModel: viewModel)
                                        }
                                    }
                                }
                            }
                        } else {
                            AndroidAVDListView(viewModel: viewModel)
                        }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 12)
            }
        }
    }
}

