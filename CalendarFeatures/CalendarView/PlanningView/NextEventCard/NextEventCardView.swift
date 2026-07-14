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

import CalendarCoreUI
import CalendarResources
import DesignSystem
import ESDSFoundation
import InfomaniakDI
import MultiplatformCalendar
import SwiftUI

enum AnimationHelper {
    static func lerp(a: Double, b: Double, t: Double) -> Double {
        return a * (1 - t) + b * t
    }
}

@Observable @MainActor
final class NextEventCardViewModel {
    var scrollProgress = 1.0
    var size: CGSize = .zero
    var nextEvent: CalendarCoreUI.UIEvent?

    init() {
        Task {
            await observeNextEventsEveryMinute()
        }
    }

    @concurrent
    private func observeNextEventsEveryMinute() async {
        let clock = SuspendingClock()
        let calendar = Calendar.current

        var initialLaunch = true
        while !Task.isCancelled {
            guard let nextMinute = calendar.nextDate(
                after: .now,
                matching: DateComponents(second: 0),
                matchingPolicy: .nextTime
            ) else {
                return
            }

            let duration = nextMinute.timeIntervalSinceNow

            if duration > 0 && !initialLaunch {
                try? await clock.sleep(for: .seconds(duration))
            }

            guard !Task.isCancelled else { return }

            initialLaunch = false
            await observeNextEvent()
        }
    }

    @concurrent
    private func observeNextEvent() async {
        let start = Calendar.current.startOfDay(for: Date())
        guard let end = Calendar.current.date(byAdding: .day, value: 2, to: start) else { return }

        @InjectService var calendarSDK: CalendarCoreGraph
        for await events in calendarSDK.calendarManager.observeEvents(start: start.instant, end: end.instant) {
            let uiEvents = events.compactMap { CalendarCoreUI.UIEvent(event: $0, userEmail: "") }
            await updateNextEvent(from: uiEvents)
        }
    }

    @concurrent
    private func updateNextEvent(from uiEvents: [CalendarCoreUI.UIEvent]) async {
        let now = Date()
        let nextTimedEvents = uiEvents
            .filter { !$0.isAllDay && $0.endDate > now }
            .sorted { $0.startDate < $1.startDate }

        if let nextTimedEvent = nextTimedEvents.first {
            await MainActor.run {
                self.nextEvent = nextTimedEvent
            }
            return
        }

        let nextAllDayEvent = uiEvents
            .filter(\.isAllDay)
            .sorted { $0.startDate < $1.startDate }
            .first

        await MainActor.run {
            self.nextEvent = nextAllDayEvent
        }
    }
}

struct NextEventCardView: View {
    let model: NextEventCardViewModel

    var body: some View {
        if let nextEvent = model.nextEvent {
            NextEventContentCardView(event: nextEvent, progress: model.scrollProgress)
                .onGeometryChange(for: CGSize.self) {
                    $0.size
                }
                action: {
                    model.size = $0
                }
        }
    }
}

struct NextEventContentCardView: View {
    @Environment(\.esdsTheme) private var theme

    @State private var buttonSize = CGSize.zero

    let event: CalendarCoreUI.UIEvent
    let progress: Double

    enum Constants {
        static let durationFontSize = scaledFontSize(.caption2, size: 12, weight: .semibold)

        static let titleExpandedFontSize = scaledFontSize(.callout, size: 16, weight: .semibold)
        static let titleCollapsedFontSize = scaledFontSize(.footnote, size: 13, weight: .semibold)

        static let informationIconSize: CGFloat = IKIconSize.medium.rawValue
        static let informationFontSize = scaledFontSize(.caption2, size: 12, weight: .bold)

        static var informationSize: CGFloat {
            max(informationIconSize, informationFontSize)
        }

        private static func scaledFontSize(
            _ textStyle: UIFont.TextStyle,
            size: CGFloat,
            weight: UIFont.Weight = .regular
        ) -> CGFloat {
            let metrics = UIFontMetrics(forTextStyle: textStyle)
            let font = metrics.scaledFont(for: .systemFont(ofSize: size, weight: weight))
            return font.pointSize
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(event.startDate, format: Date.RelativeFormatStyle(presentation: .numeric, unitsStyle: .wide))
                .textCase(.uppercase)
                .font(.system(size: Constants.durationFontSize, weight: .semibold))
                .foregroundStyle(.tint)
                .animateHide(progress: progress, fullHeight: Constants.durationFontSize)
                .padding(.bottom, lerp(a: 0, b: theme.spacing.lg))
                .padding(.trailing, lerp(a: 0, b: buttonSize.width + IKPadding.micro))
                .lineLimit(1)

            VStack(alignment: .leading, spacing: theme.spacing.sm) {
                Text(event.title)
                    .font(.system(
                        size: lerp(a: Constants.titleCollapsedFontSize, b: Constants.titleExpandedFontSize),
                        weight: .semibold
                    ))
                    .lineLimit(1)

                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: lerp(a: 0, b: theme.spacing.sm)) {
                        CalendarResourcesAsset.Images.clock.swiftUIImage
                            .resizable()
                            .scaledToFit()
                            .animateHide(progress: progress, fullHeight: Constants.informationSize)
                            .accessibilityHidden(true)

                        Text(event.startDate ..< event.endDate, format: .eventTimeBounds)
                    }

                    if let location = event.location {
                        HStack(spacing: theme.spacing.sm) {
                            CalendarResourcesAsset.Images.mapPin.swiftUIImage
                                .resizable()
                                .scaledToFit()
                                .frame(width: Constants.informationIconSize, height: Constants.informationIconSize)
                                .accessibilityHidden(true)

                            Text(location)
                        }
                        .animateHide(progress: progress, fullHeight: Constants.informationSize)
                        .padding(.top, lerp(a: 0, b: theme.spacing.sm))
                    }

                    if event.kMeetLink != nil {
                        HStack(spacing: theme.spacing.sm) {
                            CalendarResourcesAsset.Images.productKmeet.swiftUIImage
                                .resizable()
                                .scaledToFit()
                                .frame(width: Constants.informationIconSize, height: Constants.informationIconSize)
                                .accessibilityHidden(true)

                            Text(CalendarResourcesStrings.onlineLabel)
                        }
                        .animateHide(progress: progress, fullHeight: Constants.informationSize)
                        .padding(.top, lerp(a: 0, b: theme.spacing.sm))
                    }
                }
                .font(.caption2.bold())
            }
            .foregroundStyle(theme.color.textPrimary)

            HStack {
                if !event.attendees.isEmpty {
                    NextEventCardAvatarStackView(attendees: event.attendees, progression: progress)
                }

                // We keep this button in the view hierarchy to reserve space
                NextEventCardButton(event: event, progress: 0)
                    .opacity(0)
                    .accessibilityHidden(true)
                    .allowsHitTesting(false)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .animateHide(progress: progress, fullHeight: max(NextEventCardAvatarStackView.height, buttonSize.height))
            .padding(.top, lerp(a: 0, b: theme.spacing.lg))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay {
            NextEventCardButtonGeometryView(size: $buttonSize, event: event, progress: progress)
        }
        .padding(.horizontal, IKPadding.medium)
        .padding(.vertical, lerp(a: IKPadding.mini, b: IKPadding.medium))
        .cardBackground(radius: 24)
    }

    private func lerp(a: Double, b: Double) -> Double {
        return AnimationHelper.lerp(a: a, b: b, t: progress)
    }
}

private extension View {
    func animateHide(progress: Double, fullHeight: CGFloat) -> some View {
        opacity(AnimationHelper.lerp(a: 0, b: 1, t: progress))
            .frame(height: AnimationHelper.lerp(a: 0, b: fullHeight, t: progress))
            .clipped()
            .blur(radius: AnimationHelper.lerp(a: 4, b: 0, t: progress))
    }

    func cardBackground(radius: CGFloat) -> some View {
        let shape = RoundedRectangle(cornerRadius: radius)
        if #available(iOS 26.0, *) {
            return glassEffect(.regular, in: shape)
        } else {
            return background(.regularMaterial, in: shape)
        }
    }
}

@available(iOS 17.0, *)
#Preview {
    @Previewable @State var progress = 0.0

    VStack {
        NextEventContentCardView(event: .preview, progress: 0)
        NextEventContentCardView(event: .preview, progress: 0.5)
        NextEventContentCardView(event: .preview, progress: 1)

        NextEventContentCardView(event: .preview, progress: progress)
            .padding(.top, 32)

        Spacer()

        Slider(value: $progress, in: 0 ... 1)
            .padding()
    }
    .padding()
}
