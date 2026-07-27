import Domain
import XCTest
@testable import MemberFeatureV2

final class MemberFeatureV2Tests:
    XCTestCase
{
    func testHeaderComponentUsesMemberCount() {
        let component =
            MemberHeaderComponent(
                memberCount: 3
            )

        XCTAssertEqual(
            component.item.id,
            "member-count-header"
        )
        XCTAssertEqual(
            component.item.memberCount,
            3
        )
        XCTAssertFalse(
            component
                .item
                .showsBirthdaySettingsButton
        )
    }

    func testInviteComponentUsesStableIdentifier() {
        let component =
            MemberRowComponent.invite

        XCTAssertEqual(
            component.item.id,
            .invite
        )
        XCTAssertEqual(
            component.item.content,
            .invite
        )
    }

    func testMemberComponentUsesUserValues() {
        let user = makeUser()
        let component =
            MemberRowComponent(
                user: user,
                birthdayText:
                    "5월 12일 · D-18"
            )

        XCTAssertEqual(
            component.item.id,
            .member(user.uid)
        )
        XCTAssertEqual(
            component.item.content,
            .member(
                nickname: user.nickname,
                profileImageURL:
                    user.profileImageURL,
                birthdayText:
                    "5월 12일 · D-18"
            )
        )
    }

    func testSolarBirthdayUsesToday() {
        let calculator =
            BirthdayOccurrenceCalculator(
                timeZone:
                    utcTimeZone
            )
        let reference =
            date(
                year: 2026,
                month: 7,
                day: 27
            )

        let occurrence =
            calculator
                .nextOccurrence(
                    from:
                        date(
                            year: 1990,
                            month: 7,
                            day: 27
                        ),
                    mode: .solar,
                    referenceDate:
                        reference
                )

        XCTAssertEqual(
            occurrence?
                .nextDate,
            reference
        )
        XCTAssertEqual(
            occurrence?
                .daysRemaining,
            0
        )
    }

    func testSolarBirthdayMovesToNextYear() {
        let calculator =
            BirthdayOccurrenceCalculator(
                timeZone:
                    utcTimeZone
            )

        let occurrence =
            calculator
                .nextOccurrence(
                    from:
                        date(
                            year: 1990,
                            month: 1,
                            day: 2
                        ),
                    mode: .solar,
                    referenceDate:
                        date(
                            year: 2026,
                            month: 12,
                            day: 31
                        )
                )

        XCTAssertEqual(
            occurrence?
                .nextDate,
            date(
                year: 2027,
                month: 1,
                day: 2
            )
        )
        XCTAssertEqual(
            occurrence?
                .daysRemaining,
            2
        )
    }

    func testLeapDayBirthdayUsesFebruary28InCommonYear() {
        let calculator =
            BirthdayOccurrenceCalculator(
                timeZone:
                    utcTimeZone
            )

        let occurrence =
            calculator
                .nextOccurrence(
                    from:
                        date(
                            year: 2000,
                            month: 2,
                            day: 29
                        ),
                    mode: .solar,
                    referenceDate:
                        date(
                            year: 2026,
                            month: 2,
                            day: 27
                        )
                )

        XCTAssertEqual(
            occurrence?
                .nextDate,
            date(
                year: 2026,
                month: 2,
                day: 28
            )
        )
        XCTAssertEqual(
            occurrence?
                .daysRemaining,
            1
        )
    }

    func testLunarBirthdayKeepsLunarMonthAndDay() {
        var lunar =
            lunarCalendar()
        lunar.timeZone =
            utcTimeZone
        let birthday =
            date(
                year: 1990,
                month: 5,
                day: 12
            )
        let birthdayComponents =
            lunar.dateComponents(
                [.month, .day],
                from: birthday
            )
        let calculator =
            BirthdayOccurrenceCalculator(
                timeZone:
                    utcTimeZone
            )

        let occurrence =
            calculator
                .nextOccurrence(
                    from: birthday,
                    mode: .lunar,
                    referenceDate:
                        date(
                            year: 2026,
                            month: 1,
                            day: 1
                        )
                )
        let nextComponents =
            occurrence.map {
                lunar.dateComponents(
                    [.month, .day],
                    from:
                        $0.nextDate
                )
            }

        XCTAssertEqual(
            nextComponents?
                .month,
            birthdayComponents
                .month
        )
        XCTAssertEqual(
            nextComponents?
                .day,
            birthdayComponents
                .day
        )
    }

    func testGroupWithoutBirthdaySettingsUsesSolarDefaults() {
        let group =
            SessionGroup(
                groupId: "group",
                groupName: "가족",
                createdAt:
                    date(
                        year: 2026,
                        month: 1,
                        day: 1
                    ),
                hostUserId:
                    "member-id",
                inviteCode: "CODE",
                members: [:],
                postsByDate: [:]
            )

        XCTAssertEqual(
            group
                .resolvedBirthdaySettings,
            .defaultValue
        )
    }

    func testLegacyGroupSessionDecodesWithoutBirthdaySettings()
        throws
    {
        let data =
            try JSONSerialization
                .data(
                    withJSONObject: [
                        "groupId": "group",
                        "groupName": "가족",
                        "createdAt": 0,
                        "hostUserId":
                            "member-id",
                        "inviteCode": "CODE",
                        "members": [:],
                        "postsByDate": [:],
                    ]
                )

        let group =
            try JSONDecoder()
                .decode(
                    SessionGroup.self,
                    from: data
                )

        XCTAssertNil(
            group.birthdaySettings
        )
        XCTAssertEqual(
            group
                .resolvedBirthdaySettings,
            .defaultValue
        )
    }

    private func makeUser() -> User {
        User(
            uid: "member-id",
            registerDate:
                Date(
                    timeIntervalSince1970:
                        1_700_000_000
                ),
            loginPlatform: .apple,
            nickname: "하루",
            profileImageURL:
                "https://example.com/member.jpg",
            birthdayDate:
                Date(
                    timeIntervalSince1970:
                        946_684_800
                ),
            gender: .other,
            isPushEnabled: true
        )
    }

    private var utcTimeZone:
        TimeZone
    {
        TimeZone(
            secondsFromGMT: 0
        )!
    }

    private func date(
        year: Int,
        month: Int,
        day: Int
    ) -> Date {
        var calendar =
            Calendar(
                identifier: .gregorian
            )
        calendar.timeZone =
            utcTimeZone
        return calendar.date(
            from:
                DateComponents(
                    year: year,
                    month: month,
                    day: day
                )
        )!
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
