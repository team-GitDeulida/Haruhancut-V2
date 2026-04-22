//
//  HomeV2Coordinator.swift
//  Coordinator
//
//  Created by 김동현 on 4/21/26.
//

import UIKit
import HomeFeatureV2
import HomeFeatureV2Interface
import ImageFeature
import HomeFeature
import Domain
import Core

public final class HomeV2Coordinator: NSObject, Coordinator, HomeRouteTrigger {

    private let navigationController: UINavigationController
    private var homeViewController: UIViewController?
    public var parentCoordinator: Coordinator?
    public var childCoordinators: [Coordinator] = []
    public var onImageTapped: ((Post) -> Void)?
    public var onMemberTapped: (() -> Void)?
    public var onProfileTapped: (() -> Void)?
    public var onCameraTapped: ((CameraSource) -> Void)?
    public var onCalendarImageTapped: (([Post], Date) -> Void)?

    public init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    public func start() {
        let builder = HomeFeatureV2.HomeFeatureBuilder()
        let homeVC = builder.makeHome(routeTrigger: self)
        homeViewController = homeVC

        homeVC.loadViewIfNeeded()
        bindNavigationItems()

        onImageTapped = { [weak self] post in
            self?.showFeedDetail(post)
        }

        onCalendarImageTapped = { [weak self] posts, date in
            self?.showCalendarDetail(posts: posts, selectedDate: date)
        }

        onCameraTapped = { [weak self] source in
            self?.handleCameraTapped(source)
        }

        navigationController.setViewControllers([homeVC], animated: false)
    }
}

private extension HomeV2Coordinator {
    func showFeedDetail(_ post: Post) {
        let builder = FeedDetailBuilder()
        var feedDetail = builder.makeFeed(post: post)

        feedDetail.vm.onCommentTapped = { [weak self] post in
            guard let self = self else { return }
            self.presentFeedComment(post: post, builder: builder, presentingViewController: feedDetail.vc)
        }

        feedDetail.vm.onImagePreviewTapped = { [weak self] imageURL in
            guard let self = self else { return }
            self.presentFeedImagePreview(imageURL, presentingViewController: feedDetail.vc)
        }

        navigationController.pushViewController(feedDetail.vc, animated: true)
    }

    func presentFeedComment(
        post: Post,
        builder: FeedDetailBuilder,
        presentingViewController: UIViewController & RefreshableViewController
    ) {
        let commentVC = builder.makeComment(post: post, onDismiss: {
            presentingViewController.refresh()
        })
        commentVC.modalPresentationStyle = .pageSheet
        presentingViewController.present(commentVC, animated: true)
    }

    func presentFeedImagePreview(
        _ imageURL: String,
        presentingViewController: UIViewController
    ) {
        let previewCoordinator = ImagePreviewCoordinator(
            presentingViewController: presentingViewController,
            imageURL: imageURL
        )

        previewCoordinator.parentCoordinator = self
        childCoordinators.append(previewCoordinator)
        previewCoordinator.start()
    }

    func showCalendarDetail(posts: [Post], selectedDate: Date) {
        let builder = CalendarDetailBuilder()
        var calendarDetail = builder.makeCalendarDetail(posts: posts,
                                                        selectedDate: selectedDate)

        calendarDetail.vm.onCommentTapped = { [weak self] post in
            guard let self = self else { return }
            self.presentCalendarComment(post: post, builder: builder, presentingViewController: calendarDetail.vc)
        }

        calendarDetail.vm.onImagePreviewTapped = { [weak self] imageURL in
            guard let self = self else { return }
            self.presentCalendarImagePreview(imageURL, presentingViewController: calendarDetail.vc)
        }

        calendarDetail.vc.modalPresentationStyle = .fullScreen
        navigationController.present(calendarDetail.vc, animated: true)
    }

    func presentCalendarComment(
        post: Post,
        builder: CalendarDetailBuilder,
        presentingViewController: UIViewController & RefreshableViewController
    ) {
        let comment = builder.makeComment(post: post, onDismiss: {
            presentingViewController.refresh()
        })
        comment.modalPresentationStyle = .pageSheet
        presentingViewController.present(comment, animated: true)
    }

    func presentCalendarImagePreview(
        _ imageURL: String,
        presentingViewController: UIViewController
    ) {
        let previewCoordinator = ImagePreviewCoordinator(
            presentingViewController: presentingViewController,
            imageURL: imageURL
        )

        previewCoordinator.parentCoordinator = self
        previewCoordinator.start()
    }

    func handleCameraTapped(_ source: CameraSource) {
        switch source {
        case .camera:
            let cameraCoordinator = CameraCoordinator(navigationController: navigationController)
            cameraCoordinator.parentCoordinator = self
            childCoordinators.append(cameraCoordinator)
            cameraCoordinator.start()
        case .album:
            homePresentImagePicker()
        }
    }

    func bindNavigationItems() {
        guard let homeVC = homeViewController else { return }

        homeVC.navigationItem.leftBarButtonItem?.target = self
        homeVC.navigationItem.leftBarButtonItem?.action = #selector(didTapMember)

        homeVC.navigationItem.rightBarButtonItem?.target = self
        homeVC.navigationItem.rightBarButtonItem?.action = #selector(didTapProfile)
    }

    @objc func didTapMember() {
        let memberCoordinator = MemberCoordinator(navigationController: navigationController)
        memberCoordinator.parentCoordinator = self
        childCoordinators.append(memberCoordinator)
        memberCoordinator.start()
    }

    @objc func didTapProfile() {
        let profileCoordinator = ProfileCoordinator(navigationController: navigationController)
        profileCoordinator.parentCoordinator = self
        childCoordinators.append(profileCoordinator)
        profileCoordinator.start()
    }

    func homePresentImagePicker() {
        guard UIImagePickerController.isSourceTypeAvailable(.photoLibrary) else {
            return
        }

        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.allowsEditing = false
        picker.delegate = self

        if let popover = picker.popoverPresentationController {
            popover.sourceView = navigationController.view
            popover.sourceRect = CGRect(
                x: navigationController.view.bounds.midX,
                y: navigationController.view.bounds.midY,
                width: 0,
                height: 0
            )
            popover.permittedArrowDirections = []
        }
        navigationController.present(picker, animated: true)
    }
}

extension HomeV2Coordinator: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    public func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]
    ) {
        guard let image = info[.originalImage] as? UIImage else {
            picker.dismiss(animated: true)
            return
        }

        picker.dismiss(animated: true) { [weak self] in
            self?.presentImageUpload(image)
        }
    }

    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}

private extension HomeV2Coordinator {
    func presentImageUpload(_ image: UIImage) {
        let builder = ImageFeatureBuilder()
        var upload = builder.makeImageUpload(image: image)

        upload.vm.onUploadCompleted = { [weak self] in
            self?.navigationController.popViewController(animated: true)
        }

        navigationController.pushViewController(upload.vc, animated: true)
    }
}
