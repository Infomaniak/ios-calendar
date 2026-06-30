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

import DesignSystem
import UIKit

final class PlanningDayHeaderView: UICollectionReusableView {
    private static let weekdayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("EEE")
        return formatter
    }()

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("d")
        return formatter
    }()

    private let weekdayLabel = UILabel()
    private let dayLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpView()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(date: Date) {
        weekdayLabel.text = Self.weekdayFormatter.string(from: date).uppercased()
        dayLabel.text = Self.dayFormatter.string(from: date)

        if Calendar.current.isDateInToday(date) {
            weekdayLabel.font = .preferredFont(forTextStyle: .caption1) // TODO: Should be bolder
            weekdayLabel.textColor = .tintColor

            dayLabel.font = .preferredFont(forTextStyle: .title2) // TODO: Should be bolder
            dayLabel.textColor = .tintColor
        } else {
            weekdayLabel.font = .preferredFont(forTextStyle: .caption1)
            weekdayLabel.textColor = .secondaryLabel

            dayLabel.font = .preferredFont(forTextStyle: .title2)
            dayLabel.textColor = .label
        }
    }

    private func setUpView() {
        weekdayLabel.adjustsFontForContentSizeCategory = true
        dayLabel.adjustsFontForContentSizeCategory = true

        let stack = UIStackView(arrangedSubviews: [weekdayLabel, dayLabel])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = IKPadding.micro
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: IKPadding.mini),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: IKPadding.mini),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor)
        ])
    }
}
