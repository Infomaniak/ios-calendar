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
import Foundation
import InfomaniakDI
import MultiplatformCalendar
import Observation
import OSLog

/// The event drawn on top of the calendar while creating or moving an event.
struct EventPlaceholder: Equatable {
    enum Kind: Equatable {
        case creation
        case move(occurrenceId: String)
    }

    let kind: Kind
    let title: String
    let colors: UIEventColor
    let isAllDay: Bool
    var start: Date
    var end: Date

    var duration: TimeInterval {
        return end.timeIntervalSince(start)
    }

    func moved(to start: Date) -> EventPlaceholder {
        var placeholder = self
        placeholder.end = start.addingTimeInterval(duration)
        placeholder.start = start
        return placeholder
    }
}

struct EventFormRoute: Identifiable {
    enum Mode {
        case create(EventDraft)
        case edit(EventDraft, UIEventDetails)
    }

    let id = UUID()
    let mode: Mode
}

struct PendingEventMove: Identifiable {
    let item: EventTransferItem
    let offset: EventMoveOffset

    var id: String {
        return item.id
    }
}

struct PendingEventReply: Identifiable {
    let event: UIEventSummary
    let status: UIParticipationStatus

    var id: String {
        return event.id
    }
}

struct EventInteractionAlert: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}

/// Drop targets only get the dragged payload when the drop is performed: remember the dragged event when the drag begins.
@MainActor
enum EventDragTracker {
    private(set) static var current: UIEventSummary?

    static func begin(_ event: UIEventSummary) -> EventTransferItem {
        current = event
        return EventTransferItem(event: event)
    }
}

/// Shared state of the quick interactions (create, move, menu actions) of the calendar views of a scene.
@MainActor
@Observable
final class EventInteractionModel {
    static let snapInterval: TimeInterval = 15 * 60
    private static let hoverExitDelay = Duration.milliseconds(120)
    private static let committedPlaceholderDelay = Duration.milliseconds(700)

    private(set) var placeholder: EventPlaceholder?
    private(set) var movingOccurrenceId: String?
    private(set) var isCommittingMove = false

    var formRoute: EventFormRoute?
    var pendingMove: PendingEventMove?
    var pendingDeletion: UIEventSummary?
    var pendingReply: PendingEventReply?
    var alert: EventInteractionAlert?

    private var writableCalendars = [UICalendar]()

    @ObservationIgnored var undoManager: UndoManager?
    @ObservationIgnored private var grabOffset: TimeInterval?
    @ObservationIgnored private var hoverExitTask: Task<Void, Never>?

    var isMoving: Bool {
        return movingOccurrenceId != nil
    }

    private var defaultCalendar: UICalendar? {
        let calendarId = UserDefaults.shared.defaultCalendarId(among: writableCalendars.map(\.id))
        return writableCalendars.first { $0.id == calendarId }
    }

    func observeCalendars() async {
        @InjectService var calendarSDK: CalendarCoreGraph
        for await sections in calendarSDK.calendarManager.observeCalendars() {
            writableCalendars = sections
                .flatMap { $0.calendars }
                .map { UICalendar(calendar: $0) }
                .filter { $0.accessLevel.canWrite }
        }
    }

    // MARK: - Creation

    func beginCreation(at start: Date, isAllDay: Bool = false, calendar: Foundation.Calendar) {
        guard !isMoving else { return }

        let end: Date
        if isAllDay {
            end = calendar.date(byAdding: .day, value: 1, to: start) ?? start
        } else {
            end = start.addingTimeInterval(UserDefaults.shared.defaultEventDuration.timeInterval)
        }

        placeholder = EventPlaceholder(
            kind: .creation,
            title: CalendarResourcesStrings.newEventTitle,
            colors: UIEventColor(calendarSourceColorArgb: defaultCalendar?.sourceColorArgb),
            isAllDay: isAllDay,
            start: start,
            end: end
        )
    }

    func updateCreation(to start: Date) {
        guard let placeholder, placeholder.kind == .creation, placeholder.start != start else { return }
        self.placeholder = placeholder.moved(to: start)
    }

    func endCreation() {
        guard let placeholder, placeholder.kind == .creation else { return }

        let draft = EventDraft(
            calendarId: defaultCalendar?.id,
            allDay: placeholder.isAllDay,
            startDate: placeholder.start,
            endDate: placeholder.end
        )
        formRoute = EventFormRoute(mode: .create(draft))
    }

    func cancelCreation() {
        guard placeholder?.kind == .creation else { return }
        placeholder = nil
    }

    // MARK: - Move

    /// Updates the move placeholder for a drag hovering `day`, `proposedStart` being the time under the finger.
    /// - Parameter isTimeline: Whether the target positions events by time (Day, Week) or by day only (Month).
    /// - Returns: Whether the dragged event can be dropped here.
    func hover(day: Date, proposedStart: Date, isTimeline: Bool, calendar: Foundation.Calendar) -> Bool {
        guard let event = EventDragTracker.current, event.canEdit, !isCommittingMove else { return false }
        guard !(event.isAllDay && isTimeline) else { return false }

        hoverExitTask?.cancel()
        if movingOccurrenceId != event.occurrenceId {
            movingOccurrenceId = event.occurrenceId
            grabOffset = nil
        }

        let start: Date
        if isTimeline {
            if grabOffset == nil {
                let isSourceDay = calendar.isDate(event.startDate, inSameDayAs: day)
                let offset = proposedStart.timeIntervalSince(event.startDate)
                grabOffset = isSourceDay ? min(max(offset, 0), event.endDate.timeIntervalSince(event.startDate)) : 0
            }
            start = snappedStart(proposedStart.addingTimeInterval(-(grabOffset ?? 0)), in: day, calendar: calendar)
        } else {
            start = EventMoveOffset(days: dayOffset(from: event.startDate, to: day, calendar: calendar))
                .apply(to: event.startDate, calendar: calendar)
        }

        let movedPlaceholder = EventPlaceholder(
            kind: .move(occurrenceId: event.occurrenceId),
            title: event.title,
            colors: event.colors,
            isAllDay: event.isAllDay,
            start: start,
            end: start.addingTimeInterval(event.endDate.timeIntervalSince(event.startDate))
        )
        if placeholder != movedPlaceholder {
            placeholder = movedPlaceholder
        }
        return true
    }

    /// Keeps the move alive while the drag hovers a target that doesn't position the event, like an edge paging zone.
    func keepMoveAlive() -> Bool {
        guard isMoving, !isCommittingMove else { return false }
        hoverExitTask?.cancel()
        return true
    }

    func hoverExited() {
        guard !isCommittingMove else { return }

        hoverExitTask?.cancel()
        hoverExitTask = Task { [weak self] in
            guard await (try? Task.sleep(for: Self.hoverExitDelay)) != nil else { return }
            self?.clearMove()
        }
    }

    func drop(_ itemProviders: [NSItemProvider], calendar: Foundation.Calendar) {
        guard let placeholder, case .move = placeholder.kind, let itemProvider = itemProviders.first else {
            clearMove()
            return
        }

        hoverExitTask?.cancel()
        isCommittingMove = true
        Task {
            do {
                let item = try await itemProvider.loadEventTransferItem()
                let offset = moveOffset(of: item, to: placeholder.start, calendar: calendar)
                guard item.canEdit, !offset.isZero else {
                    clearMove()
                    return
                }

                if item.isRecurring {
                    pendingMove = PendingEventMove(item: item, offset: offset)
                } else {
                    commitMove(item: item, offset: offset, scope: .thisOccurrence, calendar: calendar)
                }
            } catch {
                Logger.view.error("Failed to load dropped event: \(error.localizedDescription)")
                clearMove()
            }
        }
    }

    func commitMove(_ pendingMove: PendingEventMove, scope: RecurrenceScope, calendar: Foundation.Calendar) {
        commitMove(item: pendingMove.item, offset: pendingMove.offset, scope: scope, calendar: calendar)
    }

    func cancelPendingMove() {
        pendingMove = nil
        clearMove()
    }

    private func commitMove(
        item: EventTransferItem,
        offset: EventMoveOffset,
        scope: RecurrenceScope,
        calendar: Foundation.Calendar
    ) {
        pendingMove = nil
        Task {
            do {
                try await MoveEventUseCase().execute(
                    occurrenceId: item.occurrenceId,
                    offset: offset,
                    scope: scope,
                    calendar: calendar
                )
                if !item.isRecurring {
                    registerUndo(occurrenceId: item.occurrenceId, offset: offset.inverted, calendar: calendar)
                }
                // Keep the placeholder until the observed events reflect the new times.
                try? await Task.sleep(for: Self.committedPlaceholderDelay)
            } catch {
                Logger.view.error("Failed to move event: \(error.localizedDescription)")
                alert = EventInteractionAlert(
                    title: CalendarResourcesStrings.moveEventErrorTitle,
                    message: error.localizedDescription
                )
            }
            clearMove()
        }
    }

    private func registerUndo(occurrenceId: String, offset: EventMoveOffset, calendar: Foundation.Calendar) {
        undoManager?.registerUndo(withTarget: self) { model in
            MainActor.assumeIsolated {
                model.move(occurrenceId: occurrenceId, offset: offset, calendar: calendar)
            }
        }
    }

    /// Moves without placeholder, used to undo and redo a move.
    private func move(occurrenceId: String, offset: EventMoveOffset, calendar: Foundation.Calendar) {
        registerUndo(occurrenceId: occurrenceId, offset: offset.inverted, calendar: calendar)
        Task {
            do {
                try await MoveEventUseCase().execute(
                    occurrenceId: occurrenceId,
                    offset: offset,
                    scope: .thisOccurrence,
                    calendar: calendar
                )
            } catch {
                Logger.view.error("Failed to undo event move: \(error.localizedDescription)")
                alert = EventInteractionAlert(
                    title: CalendarResourcesStrings.moveEventErrorTitle,
                    message: error.localizedDescription
                )
            }
        }
    }

    private func clearMove() {
        hoverExitTask?.cancel()
        isCommittingMove = false
        movingOccurrenceId = nil
        grabOffset = nil
        if case .move = placeholder?.kind {
            placeholder = nil
        }
    }

    private func snappedStart(_ date: Date, in day: Date, calendar: Foundation.Calendar) -> Date {
        let startOfDay = calendar.startOfDay(for: day)
        let startOfNextDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay
        let elapsed = (date.timeIntervalSince(startOfDay) / Self.snapInterval).rounded() * Self.snapInterval
        let latestStart = startOfNextDay.timeIntervalSince(startOfDay) - Self.snapInterval
        return startOfDay.addingTimeInterval(min(max(elapsed, 0), latestStart))
    }

    private func dayOffset(from date: Date, to day: Date, calendar: Foundation.Calendar) -> Int {
        return calendar.dateComponents([.day], from: calendar.startOfDay(for: date), to: calendar.startOfDay(for: day)).day ?? 0
    }

    private func moveOffset(of item: EventTransferItem, to start: Date, calendar: Foundation.Calendar) -> EventMoveOffset {
        guard !item.isAllDay else {
            return EventMoveOffset(days: dayOffset(from: item.startDate, to: start, calendar: calendar))
        }
        return EventMoveOffset(from: item.startDate, to: start, calendar: calendar)
    }

    // MARK: - Menu actions

    func edit(_ event: UIEventSummary, calendarAccounts: [CalendarAccount.ID: CalendarAccount]) {
        Task {
            do {
                let (occurrence, editData) = try await loadEditData(of: event)
                let email = calendarAccounts[Int(occurrence.accountIdValue)]?.user.email
                formRoute = EventFormRoute(mode: .edit(
                    EventDraft(event: occurrence, editData: editData),
                    UIEventDetails(event: occurrence, userEmail: email)
                ))
            } catch {
                Logger.view.error("Failed to load event edit data: \(error.localizedDescription)")
                alert = EventInteractionAlert(title: CalendarResourcesStrings.editEventTitle, message: error.localizedDescription)
            }
        }
    }

    func duplicate(_ event: UIEventSummary) {
        Task {
            do {
                let (occurrence, editData) = try await loadEditData(of: event)
                var draft = EventDraft(event: occurrence, editData: editData)
                draft.organizer = nil
                formRoute = EventFormRoute(mode: .create(draft))
            } catch {
                Logger.view.error("Failed to load event to duplicate: \(error.localizedDescription)")
                alert = EventInteractionAlert(
                    title: CalendarResourcesStrings.createEventTitle,
                    message: error.localizedDescription
                )
            }
        }
    }

    func delete(_ event: UIEventSummary, scope: RecurrenceScope) {
        pendingDeletion = nil
        Task {
            do {
                try await DeleteEventUseCase().execute(occurrenceId: event.occurrenceId, scope: scope)
            } catch {
                Logger.view.error("Failed to delete event: \(error.localizedDescription)")
                alert = EventInteractionAlert(
                    title: CalendarResourcesStrings.deleteEventErrorTitle,
                    message: error.localizedDescription
                )
            }
        }
    }

    func reply(_ status: UIParticipationStatus, to event: UIEventSummary) {
        if event.isRecurring {
            pendingReply = PendingEventReply(event: event, status: status)
        } else {
            reply(status, to: event, scope: .thisOccurrence)
        }
    }

    func reply(_ status: UIParticipationStatus, to event: UIEventSummary, scope: RecurrenceScope) {
        pendingReply = nil
        guard let reply = status.reply else { return }

        Task {
            do {
                try await UpdateParticipationStatusUseCase().execute(reply: reply, occurrenceId: event.occurrenceId, scope: scope)
            } catch {
                Logger.view.error("Failed to update participation status: \(error.localizedDescription)")
                alert = EventInteractionAlert(
                    title: CalendarResourcesStrings.replyEventErrorTitle,
                    message: error.localizedDescription
                )
            }
        }
    }

    private func loadEditData(of event: UIEventSummary) async throws -> (Event, EventEditData) {
        @InjectService var calendarSDK: CalendarCoreGraph
        let id = OccurrenceId.companion.parse(value: event.occurrenceId)
        guard let occurrence = try await calendarSDK.calendarManager.getOccurrence(occurrenceId: id),
              let editData = try await calendarSDK.calendarManager.getEditData(occurrenceId: id) else {
            throw CalendarError.eventOccurrenceNotFound
        }
        return (occurrence, editData)
    }
}

private extension NSItemProvider {
    @MainActor
    func loadEventTransferItem() async throws -> EventTransferItem {
        return try await withCheckedThrowingContinuation { continuation in
            _ = loadTransferable(type: EventTransferItem.self) { result in
                continuation.resume(with: result)
            }
        }
    }
}
