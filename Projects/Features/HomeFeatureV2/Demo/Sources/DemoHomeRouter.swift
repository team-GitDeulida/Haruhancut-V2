//
//  DemoHomeRouter.swift
//  HomeFeatureV2Demo
//
//  Created by 김동현 on 7/27/26.
//

import Core
import Domain
import Foundation
import HomeFeatureV2
import HomeFeatureV2Interface
import RxSwift
import UIKit

final class DemoHomeRouter:
    NSObject,
    HomeRouteTrigger
{
    var onImageTapped:
        ((Post) -> Void)?
    var onMemberTapped:
        (() -> Void)?
    var onProfileTapped:
        (() -> Void)?
    var onCameraTapped:
        ((CameraSource) -> Void)?
    var onCalendarImageTapped:
        (([Post], Date) -> Void)?

    private weak var navigationController:
        UINavigationController?
    @Dependency private var groupUsecase:
        GroupUsecaseProtocol
    private let disposeBag = DisposeBag()

    init(
        navigationController:
            UINavigationController
    ) {
        self.navigationController =
            navigationController
        super.init()
        configureRoutes()
    }

    func attachNavigationItems(
        to homeViewController:
            UIViewController
    ) {
        homeViewController
            .loadViewIfNeeded()
        homeViewController
            .navigationItem
            .leftBarButtonItem?
            .target = self
        homeViewController
            .navigationItem
            .leftBarButtonItem?
            .action =
                #selector(didTapMember)
        homeViewController
            .navigationItem
            .rightBarButtonItem?
            .target = self
        homeViewController
            .navigationItem
            .rightBarButtonItem?
            .action =
                #selector(didTapProfile)
    }

    private func configureRoutes() {
        onImageTapped = {
            [weak self] post in
            self?.showFeedDetail(post)
        }
        onCalendarImageTapped = {
            [weak self] posts, date in
            self?.showCalendarDetail(
                posts: posts,
                selectedDate: date
            )
        }
        onCameraTapped = {
            [weak self] source in
            switch source {
            case .camera:
                self?.presentImagePicker(
                    sourceType: .camera
                )
            case .album:
                self?.presentImagePicker(
                    sourceType: .photoLibrary
                )
            }
        }
        onMemberTapped = {
            [weak self] in
            self?.showDemoNotice(
                title: "멤버"
            )
        }
        onProfileTapped = {
            [weak self] in
            self?.showDemoNotice(
                title: "프로필"
            )
        }
    }

    private func showFeedDetail(
        _ post: Post
    ) {
        let builder = FeedDetailBuilder()
        var detail =
            builder.makeFeed(post: post)
        let viewController = detail.vc

        detail.vm.onCommentTapped = {
            [weak viewController] post in
            guard let viewController
            else {
                return
            }
            let commentViewController =
                builder.makeComment(
                    post: post,
                    onDismiss: {
                        [weak viewController] in
                        viewController?
                            .refresh()
                    }
                )
            commentViewController
                .modalPresentationStyle =
                    .pageSheet
            viewController.present(
                commentViewController,
                animated: true
            )
        }
        detail.vm.onImagePreviewTapped = {
            [weak self] imageURL in
            self?.showImagePreview(
                imageURL
            )
        }

        navigationController?
            .pushViewController(
                viewController,
                animated: true
            )
    }

    private func showCalendarDetail(
        posts: [Post],
        selectedDate: Date
    ) {
        let builder =
            CalendarDetailBuilder()
        var detail =
            builder.makeCalendarDetail(
                posts: posts,
                selectedDate: selectedDate
            )
        let viewController = detail.vc

        detail.vm.onCommentTapped = {
            [weak viewController] post in
            guard let viewController
            else {
                return
            }
            let commentViewController =
                builder.makeComment(
                    post: post,
                    onDismiss: {
                        [weak viewController] in
                        viewController?
                            .refresh()
                    }
                )
            commentViewController
                .modalPresentationStyle =
                    .pageSheet
            viewController.present(
                commentViewController,
                animated: true
            )
        }
        detail.vm.onImagePreviewTapped = {
            [weak self] imageURL in
            self?.showImagePreview(
                imageURL
            )
        }

        navigationController?
            .pushViewController(
                viewController,
                animated: true
            )
    }

    private func showImagePreview(
        _ imageURL: String
    ) {
        guard
            let url = URL(
                string: imageURL
            )
        else {
            return
        }

        navigationController?
            .pushViewController(
                DemoImagePreviewViewController(
                    imageURL: url
                ),
                animated: true
            )
    }

    private func showDemoNotice(
        title: String
    ) {
        let alert =
            UIAlertController(
                title: title,
                message:
                    "HomeFeatureV2 Demo에서는 홈 화면 흐름만 확인합니다.",
                preferredStyle: .alert
            )
        alert.addAction(
            UIAlertAction(
                title: "확인",
                style: .default
            )
        )
        navigationController?
            .visibleViewController?
            .present(
                alert,
                animated: true
            )
    }

    private func presentImagePicker(
        sourceType:
            UIImagePickerController.SourceType
    ) {
        guard
            UIImagePickerController
                .isSourceTypeAvailable(
                    sourceType
                )
        else {
            showDemoNotice(
                title:
                    "이 기기에서는 사용할 수 없습니다."
            )
            return
        }

        let picker =
            UIImagePickerController()
        picker.sourceType = sourceType
        picker.allowsEditing = false
        picker.delegate = self
        navigationController?
            .present(
                picker,
                animated: true
            )
    }

    @objc
    private func didTapMember() {
        onMemberTapped?()
    }

    @objc
    private func didTapProfile() {
        onProfileTapped?()
    }
}

extension DemoHomeRouter:
    UIImagePickerControllerDelegate,
    UINavigationControllerDelegate
{
    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info:
            [UIImagePickerController.InfoKey: Any]
    ) {
        guard
            let image =
                info[.originalImage]
                as? UIImage
        else {
            picker.dismiss(
                animated: true
            )
            return
        }

        groupUsecase
            .uploadImageAndUploadPost(
                image: image
            )
            .observe(
                on:
                    MainScheduler.instance
            )
            .subscribe(
                onNext: {
                    picker.dismiss(
                        animated: true
                    )
                },
                onError: {
                    [weak self] _ in
                    picker.dismiss(
                        animated: true
                    ) {
                        self?.showDemoNotice(
                            title:
                                "업로드에 실패했습니다."
                        )
                    }
                }
            )
            .disposed(
                by: disposeBag
            )
    }

    func imagePickerControllerDidCancel(
        _ picker: UIImagePickerController
    ) {
        picker.dismiss(
            animated: true
        )
    }
}

private final class
    DemoImagePreviewViewController:
    UIViewController
{
    private let imageURL: URL
    private let imageView =
        UIImageView()
    private let activityIndicator =
        UIActivityIndicatorView(
            style: .large
        )
    private var imageTask:
        Task<Void, Never>?

    init(imageURL: URL) {
        self.imageURL = imageURL
        super.init(
            nibName: nil,
            bundle: nil
        )
    }

    required init?(
        coder: NSCoder
    ) {
        fatalError(
            "init(coder:) has not been implemented"
        )
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "이미지 미리보기"
        view.backgroundColor =
            .systemBackground
        configureImageView()
        loadImage()
    }

    deinit {
        imageTask?.cancel()
    }

    private func configureImageView() {
        imageView.contentMode =
            .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints =
            false
        activityIndicator.translatesAutoresizingMaskIntoConstraints =
            false

        view.addSubview(imageView)
        view.addSubview(
            activityIndicator
        )
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(
                equalTo:
                    view.safeAreaLayoutGuide
                        .topAnchor
            ),
            imageView.leadingAnchor.constraint(
                equalTo: view.leadingAnchor
            ),
            imageView.trailingAnchor.constraint(
                equalTo: view.trailingAnchor
            ),
            imageView.bottomAnchor.constraint(
                equalTo:
                    view.safeAreaLayoutGuide
                        .bottomAnchor
            ),
            activityIndicator.centerXAnchor
                .constraint(
                    equalTo:
                        view.centerXAnchor
                ),
            activityIndicator.centerYAnchor
                .constraint(
                    equalTo:
                        view.centerYAnchor
                ),
        ])
    }

    private func loadImage() {
        activityIndicator
            .startAnimating()
        imageTask = Task {
            defer {
                activityIndicator
                    .stopAnimating()
            }

            do {
                let (data, _) =
                    try await URLSession
                        .shared
                        .data(
                            from: imageURL
                        )
                guard !Task.isCancelled
                else {
                    return
                }
                imageView.image =
                    UIImage(data: data)
            } catch {
                guard !Task.isCancelled
                else {
                    return
                }
                imageView.image =
                    UIImage(
                        systemName:
                            "photo.badge.exclamationmark"
                    )
            }
        }
    }
}
