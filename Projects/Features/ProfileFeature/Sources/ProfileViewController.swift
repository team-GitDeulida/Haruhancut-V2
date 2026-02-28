//
//  Empty.swift
//  Profile
//
//  Created by 김동현 on 
//

import UIKit
import ProfileFeatureInterface
import DSKit
import Core
import RxSwift
import RxCocoa
import Domain

final class ProfileViewController: UIViewController, PopableViewController {
    var onPop: (() -> Void)?
    
    let disposeBag = DisposeBag()
    private let customView: ProfileView
    let viewModel: ProfileViewModel
    var onDisappear: (() -> Void)?
    
    private lazy var settingButton = UIBarButtonItem(
        image: UIImage(systemName: "gearshape.fill"),
        style: .plain,
        target: nil,
        action: nil
    )
    
    init(viewModel: ProfileViewModel) {
        self.customView = ProfileView()
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    override func loadView() {
        self.view = customView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigation()
        setupDelegate()
        bindViewModel()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if isMovingFromParent {
            onPop?()
        }
    }
    
    // MARK: - Delegate
    private func setupDelegate() {
        customView.collectionView.rx.setDelegate(self)
                .disposed(by: disposeBag)
    }
    
    // MARK: - setupNavigation
    private func setupNavigation() {
        navigationItem.rightBarButtonItem = settingButton
        navigationItem.backButtonTitle = "프로필"
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func bindViewModel() {
        
        // MARK: - 프로필 컬렉션 셀 터치
        let onImageTapped = customView.collectionView.rx
            .modelSelected(Post.self)
            .asObservable()
        
        let onSettingButtonTapped = settingButton.rx
            .tap
            .asObservable()
        
        let reload = NotificationCenter.default.rx
            .notification(.homeCommentDidChange)
            .do(onNext: { _ in
                Logger.d("Notification: 이벤트 받음")
            })
            .mapToVoid()
            
        
        let input = ProfileViewModel.Input(onSettingButtonTapped: onSettingButtonTapped,
                                           onImageTapped: onImageTapped,
                                           reload: reload)
        let output = viewModel.transform(input: input)
        
        // MARK: - 프로필 유저 사진
        output.user
            .map(\.profileImageURL)
            .drive(with: self, onNext: { owner, urlString in
                guard let urlString,
                      let url = URL(string: urlString) else { return }
                owner.customView.profileImageView.setImage(with: url)
            })
            .disposed(by: disposeBag)
        
        // MARK: - 프로필 닉네임
        output.user
            .map(\.nickname)
            .drive(customView.nicknameLabel.rx.text)
            .disposed(by: disposeBag)
        
        // MARK: - 프로필 컬렉션 셀
        output.myPosts
            .drive(customView.collectionView.rx
                .items(cellIdentifier: ProfilePostCell.reuseIdentifier,
                       cellType: ProfilePostCell.self)
            ) { _, post, cell in
                cell.configure(post: post)
            }
            .disposed(by: disposeBag)
    }
    
    // MARK: - 셀 사이즈
    private func itemSize(for collectionView: UICollectionView) -> CGSize {
        let spacing: CGFloat = 1
        let columns: CGFloat = 3
        let totalSpacing = (columns - 1) * spacing
        let width = (collectionView.bounds.width - totalSpacing) / columns
        return CGSize(width: width, height: width * 1.5)
    }
}

extension ProfileViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        return itemSize(for: collectionView)
    }
}









/*
private func setupUI() {
    view.backgroundColor = .background
    
    let label = UILabel()
    label.text = "Profile Demo"
    label.font = .systemFont(ofSize: 24, weight: .bold)
    label.textAlignment = .center
    label.translatesAutoresizingMaskIntoConstraints = false

    view.addSubview(label)

    NSLayoutConstraint.activate([
        label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
    ])
}
 */



