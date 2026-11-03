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
import DesignSystem
import ESDSFoundation
import ESDSSymbols
import SwiftUI

struct LocationPickerButton: View {
    @Environment(\.esdsTheme) private var theme

    @State private var isShowingLocationPickerView = false
    @State private var viewModel = LocationPickerViewModel()
    @Binding var location: EventLocation?

    let request: LocationAvailabilityRequest?

    var body: some View {
        HStack(spacing: IKPadding.small) {
            Button {
                isShowingLocationPickerView = true
            } label: {
                HStack(spacing: IKPadding.small) {
                    if case .room(let id, let name, let accountId) = location,
                       accountId == request?.accountId,
                       let room = viewModel.rooms.first(where: { $0.id == id }) {
                        MeetingRoomView(
                            roomTitle: name,
                            roomFloor: room.floor,
                            roomCapacity: room.capacity,
                            isAvailable: viewModel.availability[room.id]
                        )
                    } else {
                        Label(location?.stringValue ?? CalendarResourcesStrings.locationOrRoomLabel, symbol: ESDSSymbols.mapPin)
                            .labelStyle(.formLabel)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .sheet(isPresented: $isShowingLocationPickerView) {
                NavigationStack {
                    LocationPickerView(viewModel: viewModel, location: location) { location in
                        self.location = location
                    }
                }
            }

            if location != nil {
                Button {
                    location = nil
                } label: {
                    ESDSSymbols.cross.image
                        .font(.system(size: IKIconSize.large.rawValue))
                        .foregroundStyle(theme.color.contentSecondary)
                }
                .buttonStyle(.borderless)
                .accessibilityLabel(CalendarResourcesStrings.removeLocationLabel)
            }
        }
        .task(id: request?.accountId) {
            await viewModel.observeRooms(accountId: request?.accountId)
        }
        .task(id: request) {
            await viewModel.loadAvailability(for: request)
        }
    }
}

#Preview {
    Form {
        LocationPickerButton(location: .constant(.place(name: "Rue Eugène-Marziano 25, Geneva")), request: nil)
        LocationPickerButton(location: .constant(nil), request: nil)
    }
}
