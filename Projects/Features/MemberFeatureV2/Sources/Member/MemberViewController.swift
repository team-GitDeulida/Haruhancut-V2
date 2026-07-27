import CollectionViewAdapter
import Core
import Domain
import DSKit
import Kingfisher
import RxRelay
import RxSwift
import UIKit

final class MemberViewController:
    UIViewController
{
    private enum Constant {
        static let memberSectionIdentifier =
            "members"
        static let rowHeight:
            CGFloat = 60
        static let rowSpacing:
            CGFloat = 16
    }

    private struct ActiveImagePrefetch {
        let id: UUID
        let prefetcher:
            ImagePrefetcher
    }

    private let viewModel:
        MemberViewModel
    private let customView =
        MemberView()
    private let disposeBag =
        DisposeBag()
    private let inviteTappedRelay =
        PublishRelay<Void>()
    private let memberTappedRelay =
        PublishRelay<User>()
    private var imageURLsByMemberID:
        [String: URL] = [:]
    private var activeImagePrefetches:
        [String: ActiveImagePrefetch] = [:]

    private lazy var adapter:
        CollectionViewAdapter = {
            let adapter =
                CollectionViewAdapter(
                    collectionView:
                        customView
                            .collectionView
                )
            adapter.prefetchItems = {
                [weak self] items in
                self?.prefetchImages(
                    for: items
                )
            }
            adapter.cancelPrefetchingItems = {
                [weak self] items in
                self?
                    .cancelImagePrefetching(
                        for: items
                    )
            }
            return adapter
        }()

    init(viewModel: MemberViewModel) {
        self.viewModel = viewModel
        super.init(
            nibName: nil,
            bundle: nil
        )
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError(
            "init(coder:)는 지원하지 않습니다."
        )
    }

    deinit {
        activeImagePrefetches
            .values
            .forEach {
                $0.prefetcher.stop()
            }
    }

    override func loadView() {
        view = customView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        bindViewModel()
    }

    private func bindViewModel() {
        let input =
            MemberViewModel.Input(
                inviteCellTapped:
                    inviteTappedRelay
                        .asObservable(),
                memberCellTapped:
                    memberTappedRelay
                        .asObservable()
            )
        let output =
            viewModel.transform(
                input: input
            )

        output.sortedMembers
            .drive(with: self) {
                owner, members in
                owner.render(
                    members
                )
            }
            .disposed(by: disposeBag)

        output.inviteCode
            .drive(with: self) {
                owner, inviteCode in
                owner.shareInvitation(
                    inviteCode:
                        inviteCode
                )
            }
            .disposed(by: disposeBag)
    }

    private func render(
        _ members: [User]
    ) {
        updateImageURLLookup(
            members
        )

        adapter.bind(
            SectionModels {
                LazySection(
                    identifier:
                        Constant.memberSectionIdentifier
                ) {
                    MemberRowComponent
                        .invite
                        .onTouch { [weak self] in
                            self?.inviteTappedRelay.accept(())
                        }

                    For(of: members) {
                        member in
                        MemberRowComponent(
                            user: member
                        )
                        .onTouch { [weak self] in
                            self?.memberTappedRelay.accept(member)
                        }
                    }
                }
                .withHeader(
                    MemberHeaderComponent(
                        memberCount: members.count
                    ),
                    zIndex: 1
                )
                .withSectionLayout(
                    CollectionSectionLayout
                        .verticalList(
                            estimatedRowHeight: Constant.rowHeight,
                            spacing: Constant.rowSpacing
                        )
                        .withHeaderPinToVisibleBounds(true)
                )
            },
            animatingDifferences: true
        )
    }

    private func updateImageURLLookup(
        _ members: [User]
    ) {
        imageURLsByMemberID =
            members.reduce(
                into: [:]
            ) {
                result, member in
                guard
                    let imageURL =
                        member
                            .profileImageURL,
                    let url = URL(
                        string: imageURL
                    )
                else {
                    return
                }
                result[member.uid] =
                    url
            }

        let currentMemberIDs =
            Set(
                imageURLsByMemberID
                    .keys
            )
        let removedMemberIDs =
            activeImagePrefetches
                .keys
                .filter {
                    !currentMemberIDs
                        .contains($0)
                }
        cancelImagePrefetching(
            forMemberIDs:
                removedMemberIDs
        )
    }

    private func prefetchImages(
        for items:
            [CollectionViewPrefetchItem]
    ) {
        for memberID in memberIDs(
            from: items
        ) {
            guard
                activeImagePrefetches[
                    memberID
                ] == nil,
                let imageURL =
                    imageURLsByMemberID[
                        memberID
                    ]
            else {
                continue
            }

            let requestID = UUID()
            let prefetcher =
                ImagePrefetcher(
                    urls: [imageURL],
                    options:
                        MemberProfileImageRequest
                            .options,
                    completionHandler: {
                        [weak self] _, _, _ in
                        guard
                            self?
                                .activeImagePrefetches[
                                    memberID
                                ]?.id
                                == requestID
                        else {
                            return
                        }
                        self?
                            .activeImagePrefetches[
                                memberID
                            ] = nil
                    }
                )
            activeImagePrefetches[
                memberID
            ] = ActiveImagePrefetch(
                id: requestID,
                prefetcher:
                    prefetcher
            )
            prefetcher.start()
        }
    }

    private func cancelImagePrefetching(
        for items:
            [CollectionViewPrefetchItem]
    ) {
        cancelImagePrefetching(
            forMemberIDs:
                memberIDs(
                    from: items
                )
        )
    }

    private func cancelImagePrefetching(
        forMemberIDs memberIDs:
            [String]
    ) {
        for memberID in memberIDs {
            activeImagePrefetches
                .removeValue(
                    forKey: memberID
                )?
                .prefetcher
                .stop()
        }
    }

    private func memberIDs(
        from items:
            [CollectionViewPrefetchItem]
    ) -> [String] {
        items.compactMap { item in
            guard
                item.sectionIdentifier
                    == AnyHashable(
                        Constant
                            .memberSectionIdentifier
                    ),
                let identifier =
                    item.itemIdentifier
                        .base as?
                        MemberRowIdentifier,
                case let .member(
                    memberID
                ) = identifier
            else {
                return nil
            }
            return memberID
        }
    }

    private func shareInvitation(
        inviteCode: String
    ) {
        let message = String(
            format:
                LocalizationKey
                    .memberInviteShareMessage
                    .localized,
            inviteCode,
            Constants.Notion.notionURL,
            Constants.Appstore
                .appstoreURL
        )
        let activityViewController =
            UIActivityViewController(
                activityItems: [message],
                applicationActivities: nil
            )

        if let popover =
            activityViewController
                .popoverPresentationController
        {
            popover.sourceView = view
            popover.sourceRect = CGRect(
                x: view.bounds.midX,
                y: view.bounds.midY,
                width: 0,
                height: 0
            )
            popover
                .permittedArrowDirections =
                []
        }

        present(
            activityViewController,
            animated: true
        )
    }
}
