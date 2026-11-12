/*
 Infomaniak Calendar - iOS App
 Copyright (C) 2026 Infomaniak Network SA

 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import CalendarCore
import CalendarCoreUI
import CalendarResources
import ESDSSymbols
import SwiftUI

struct LocationPickerView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var search: String

    let viewModel: LocationPickerViewModel
    let onSelect: (EventLocation) -> Void

    init(viewModel: LocationPickerViewModel, location: EventLocation?, onSelect: @escaping (EventLocation) -> Void) {
        self.viewModel = viewModel
        self.onSelect = onSelect
        if case .place(let text) = location {
            _search = State(initialValue: text)
        } else {
            _search = State(initialValue: "")
        }
    }

    var body: some View {
        List {
            LocationPlacesSection(viewModel: viewModel, query: search) { location in
                onSelect(location)
                dismiss()
            }
            LocationRoomsSection(viewModel: viewModel, query: search) { room in
                onSelect(room.location)
                dismiss()
            }
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView()
            }
        }
        .foregroundStyle(.primary)
        .searchable(text: $search)
        .navigationTitle(CalendarResourcesStrings.locationOrRoomLabel)
        .toolbarTitleDisplayMode(.inline)
        .toolbar {
            CloseToolbarItem(action: dismiss.callAsFunction)
        }
        .task(id: search) {
            await viewModel.searchPlaces(query: search)
        }
    }
}

private struct LocationPlacesSection: View {
    let viewModel: LocationPickerViewModel
    let query: String
    let onSelect: (EventLocation) -> Void

    private var input: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        if !input.isEmpty || !viewModel.places.isEmpty {
            Section(CalendarResourcesStrings.placesSectionTitle) {
                if !input.isEmpty {
                    Button {
                        onSelect(.place(text: input))
                    } label: {
                        Label(CalendarResourcesStrings.useRawLocationLabel(input), symbol: ESDSSymbols.mapPin)
                            .labelStyle(.formLabel)
                    }
                }

                ForEach(viewModel.places) { place in
                    Button {
                        onSelect(place.location)
                    } label: {
                        Label {
                            VStack(alignment: .leading) {
                                Text(place.name)

                                if !place.address.isEmpty {
                                    Text(place.address)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        } icon: {
                            ESDSSymbols.mapPin.image
                        }
                        .labelStyle(.formLabel)
                    }
                }
            }
        }
    }
}

private struct LocationRoomsSection: View {
    let viewModel: LocationPickerViewModel
    let query: String
    let onSelect: (LocationRoom) -> Void

    var body: some View {
        let rooms = viewModel.visibleRooms(query: query)
        if !rooms.isEmpty {
            Section {
                ForEach(rooms) { room in
                    Button {
                        onSelect(room)
                    } label: {
                        MeetingRoomView(
                            roomTitle: room.name,
                            roomFloor: room.floor,
                            roomCapacity: room.capacity,
                            availability: viewModel.availability(for: room.id)
                        )
                    }
                }
            } header: {
                Text(CalendarResourcesStrings.roomsSectionTitle)
            }
        }
    }
}

#Preview {
    NavigationStack {
        LocationPickerView(viewModel: LocationPickerViewModel(), location: nil) { _ in }
    }
}
