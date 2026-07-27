@testable import HomeFeatureV2
import Core
import Domain
import Foundation
import RxSwift
import XCTest

final class AdminPreviewDetailTests:
    XCTestCase
{
    private var disposeBag:
        DisposeBag!

    override func setUp() {
        super.setUp()
        disposeBag =
            DisposeBag()
    }

    func testFeedDetailReloadUsesInjectedPreviewGroup() {
        let initialPost =
            makePost(
                id: "post",
                imageURL: "initial"
            )
        let previewPost =
            makePost(
                id: "post",
                imageURL: "preview"
            )
        let previewGroup =
            makeGroup(
                postsByDate: [
                    "2026-07-27": [
                        previewPost,
                    ],
                ]
            )
        let viewModel =
            FeedDetailViewModel(
                loadGroup: {
                    .just(
                        previewGroup
                    )
                },
                post: initialPost
            )
        let reload =
            PublishSubject<Void>()
        let output =
            viewModel.transform(
                input:
                    FeedDetailViewModel
                        .Input(
                            imageTapped:
                                .never(),
                            commentButtonTapped:
                                .never(),
                            reload:
                                reload
                        )
            )
        let expectation =
            expectation(
                description:
                    "선택 그룹 피드 상세 갱신"
            )

        output.post
            .skip(1)
            .drive(
                onNext: {
                    post in
                    XCTAssertEqual(
                        post.imageURL,
                        previewPost.imageURL
                    )
                    expectation
                        .fulfill()
                }
            )
            .disposed(
                by: disposeBag
            )

        reload.onNext(())

        wait(
            for: [expectation],
            timeout: 1
        )
    }

    func testCalendarDetailReloadUsesInjectedPreviewGroup() {
        let selectedDate =
            Date(
                timeIntervalSince1970:
                    1_785_110_400
            )
        let initialPost =
            makePost(
                id: "initial",
                imageURL: "initial"
            )
        let previewPost =
            makePost(
                id: "preview",
                imageURL: "preview"
            )
        let previewGroup =
            makeGroup(
                postsByDate: [
                    selectedDate
                        .toDateKey(): [
                            previewPost,
                        ],
                ]
            )
        let viewModel =
            CalendarDetailViewModel(
                loadGroup: {
                    .just(
                        previewGroup
                    )
                },
                posts: [
                    initialPost,
                ],
                selectedDate:
                    selectedDate
            )
        let reload =
            PublishSubject<Void>()
        let output =
            viewModel.transform(
                input:
                    CalendarDetailViewModel
                        .Input(
                            imageTapped:
                                .never(),
                            commentButtonTapped:
                                .never(),
                            currentIndex:
                                .just(0),
                            reload:
                                reload
                        )
            )
        let expectation =
            expectation(
                description:
                    "선택 그룹 캘린더 상세 갱신"
            )

        output.posts
            .skip(1)
            .drive(
                onNext: {
                    posts in
                    XCTAssertEqual(
                        posts.map(
                            \.postId
                        ),
                        [
                            previewPost
                                .postId,
                        ]
                    )
                    expectation
                        .fulfill()
                }
            )
            .disposed(
                by: disposeBag
            )

        reload.onNext(())

        wait(
            for: [expectation],
            timeout: 1
        )
    }

    private func makeGroup(
        postsByDate:
            [String: [Post]]
    ) -> HCGroup {
        HCGroup(
            groupId: "preview-group",
            groupName: "관리 대상 가족",
            createdAt: .now,
            hostUserId: "owner",
            inviteCode: "CODE",
            members: [
                "owner": "joined",
            ],
            postsByDate:
                postsByDate
        )
    }

    private func makePost(
        id: String,
        imageURL: String
    ) -> Post {
        Post(
            postId: id,
            userId: "user",
            nickname: "사용자",
            profileImageURL: nil,
            imageURL: imageURL,
            createdAt: .now,
            likeCount: 0,
            comments: [:]
        )
    }
}
