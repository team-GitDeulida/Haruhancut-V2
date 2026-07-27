import Domain
import Foundation

struct BirthdayOccurrence:
    Equatable
{
    let nextDate: Date
    let daysRemaining: Int
}

/// 저장된 생년월일과 그룹의 달력 기준으로 다음 생일을 계산합니다.
struct BirthdayOccurrenceCalculator {
    private let timeZone: TimeZone

    init(
        timeZone: TimeZone =
            .autoupdatingCurrent
    ) {
        self.timeZone = timeZone
    }

    func nextOccurrence(
        from birthdayDate: Date,
        mode: BirthdayCalendarMode,
        referenceDate: Date = .now
    ) -> BirthdayOccurrence? {
        var gregorian =
            Calendar(
                identifier: .gregorian
            )
        gregorian.timeZone = timeZone
        let referenceDay =
            gregorian.startOfDay(
                for: referenceDate
            )

        let nextDate: Date?
        switch mode {
        case .solar:
            nextDate =
                nextSolarOccurrence(
                    from: birthdayDate,
                    referenceDay:
                        referenceDay,
                    calendar:
                        gregorian
                )
        case .lunar:
            nextDate =
                nextLunarOccurrence(
                    from: birthdayDate,
                    referenceDay:
                        referenceDay,
                    gregorian:
                        gregorian
                )
        }

        guard let nextDate else {
            return nil
        }

        let daysRemaining =
            gregorian.dateComponents(
                [.day],
                from: referenceDay,
                to: nextDate
            ).day
            ?? 0

        return BirthdayOccurrence(
            nextDate: nextDate,
            daysRemaining:
                max(0, daysRemaining)
        )
    }

    private func nextSolarOccurrence(
        from birthdayDate: Date,
        referenceDay: Date,
        calendar: Calendar
    ) -> Date? {
        let birthday =
            calendar.dateComponents(
                [.month, .day],
                from: birthdayDate
            )
        guard
            let month = birthday.month,
            let day = birthday.day
        else {
            return nil
        }

        let currentYear =
            calendar.component(
                .year,
                from: referenceDay
            )
        for year in
            currentYear...(currentYear + 2)
        {
            guard
                let candidate =
                    solarDate(
                        year: year,
                        month: month,
                        day: day,
                        calendar: calendar
                    )
            else {
                continue
            }
            if candidate >= referenceDay {
                return candidate
            }
        }
        return nil
    }

    private func solarDate(
        year: Int,
        month: Int,
        day: Int,
        calendar: Calendar
    ) -> Date? {
        if let exactDate =
            exactDate(
                year: year,
                month: month,
                day: day,
                isLeapMonth: false,
                calendar: calendar
            )
        {
            return exactDate
        }

        // 2월 29일 생일은 평년에 2월 28일로 표시합니다.
        guard
            month == 2,
            day == 29
        else {
            return nil
        }
        return exactDate(
            year: year,
            month: 2,
            day: 28,
            isLeapMonth: false,
            calendar: calendar
        )
    }

    private func nextLunarOccurrence(
        from birthdayDate: Date,
        referenceDay: Date,
        gregorian: Calendar
    ) -> Date? {
        var lunar =
            lunarCalendar()
        lunar.timeZone = timeZone

        let birthday =
            lunar.dateComponents(
                [
                    .month,
                    .day,
                    .isLeapMonth,
                ],
                from: birthdayDate
            )
        guard
            let month = birthday.month,
            let day = birthday.day
        else {
            return nil
        }

        let currentYear =
            lunar.component(
                .year,
                from: referenceDay
            )
        for year in
            currentYear...(currentYear + 3)
        {
            let candidate =
                lunarDate(
                    year: year,
                    month: month,
                    day: day,
                    prefersLeapMonth:
                        birthday
                            .isLeapMonth
                            ?? false,
                    calendar: lunar
                )
            guard
                let candidate =
                    candidate.map(
                        gregorian.startOfDay
                    )
            else {
                continue
            }
            if candidate >= referenceDay {
                return candidate
            }
        }
        return nil
    }

    private func lunarDate(
        year: Int,
        month: Int,
        day: Int,
        prefersLeapMonth: Bool,
        calendar: Calendar
    ) -> Date? {
        if
            prefersLeapMonth,
            let leapDate =
                exactDate(
                    year: year,
                    month: month,
                    day: day,
                    isLeapMonth: true,
                    calendar: calendar
                )
        {
            return leapDate
        }

        // 윤달이 없는 해에는 같은 월의 평달 생일을 사용합니다.
        return exactDate(
            year: year,
            month: month,
            day: day,
            isLeapMonth: false,
            calendar: calendar
        )
    }

    private func exactDate(
        year: Int,
        month: Int,
        day: Int,
        isLeapMonth: Bool,
        calendar: Calendar
    ) -> Date? {
        var components =
            DateComponents()
        components.calendar = calendar
        components.timeZone = timeZone
        components.year = year
        components.month = month
        components.day = day
        components.isLeapMonth =
            isLeapMonth

        guard
            let date =
                calendar.date(
                    from: components
                )
        else {
            return nil
        }

        let resolved =
            calendar.dateComponents(
                [
                    .year,
                    .month,
                    .day,
                    .isLeapMonth,
                ],
                from: date
            )
        guard
            resolved.year == year,
            resolved.month == month,
            resolved.day == day,
            (
                resolved.isLeapMonth
                    ?? false
            ) == isLeapMonth
        else {
            return nil
        }
        return date
    }

    private func lunarCalendar()
        -> Calendar
    {
        if #available(iOS 26.0, *) {
            return Calendar(
                identifier: .dangi
            )
        }
        return Calendar(
            identifier: .chinese
        )
    }
}
