//
//  OnboardingViewController.swift
//  OnboardingFeature
//
//  Created by 김동현 on 3/5/26.
//

import UIKit
import DSKit

final class OnboardingViewController: UIPageViewController {
    
    let viewModel: OnboardingViewModel

    // MARK: - property
    private var pages: [UIViewController] = []
    private lazy var pageControl: UIPageControl = {
        let pc = UIPageControl()
        pc.currentPageIndicatorTintColor = .black
        pc.pageIndicatorTintColor = .lightGray
        return pc
    }()
    
    private lazy var nextButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(LocalizationKey.commonNext.localized, for: .normal)
        button.tintColor = .white
        button.backgroundColor = .black
        button.layer.cornerRadius = 20
        button.titleLabel?.font = .hcFont(.medium, size: 18)
        button.addTarget(self, action: #selector(didTapNext), for: .touchUpInside)
        return button
    }()
    
    private lazy var hStack: UIStackView = {
        let sv = UIStackView(arrangedSubviews: [pageControl, nextButton])
        sv.axis = .vertical
        sv.spacing = 10.scaled
        sv.alignment = .center
        return sv
    }()
    
    init(viewModel: OnboardingViewModel) {
        self.viewModel = viewModel
        super.init(
            transitionStyle: .scroll,
            navigationOrientation: .horizontal,
            options: nil
        )
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        makeUI()
        constraints()
    }
    
    // MARK: - UI Setting
    private func makeUI() {
        view.backgroundColor = .white
        let page1 = PageContentsViewController(image: DSImage.onboarding1,
                                               title: LocalizationKey.onboardingPage1Title.localized,
                                               subTitle: LocalizationKey.onboardingPage1Subtitle.localized)
        let page2 = PageContentsViewController(image: DSImage.onboarding3,
                                               title: LocalizationKey.onboardingPage2Title.localized,
                                               subTitle: LocalizationKey.onboardingPage2Subtitle.localized)
        let page3 = PageContentsViewController(image: DSImage.onboarding4,
                                               title: LocalizationKey.onboardingPage3Title.localized,
                                               subTitle: LocalizationKey.onboardingPage3Subtitle.localized)
        
        let page4 = PageContentsViewController(image: DSImage.onboarding5,
                                               title: LocalizationKey.onboardingPage4Title.localized,
                                               subTitle: LocalizationKey.onboardingPage4Subtitle.localized)
        pages.append(contentsOf: [page1, page2, page3, page4])
        
        // dataSource 화면에 보여질 뷰컨트롤러들을 관리
        self.dataSource = self
        self.delegate = self
        
        // UIPageViewController에서 처음 보여질 뷰컨트롤러 설정(첫 page)
        self.setViewControllers([pages[0]], direction: .forward, animated: true)
        
        view.addSubview(hStack)
        hStack.translatesAutoresizingMaskIntoConstraints = false
        pageControl.numberOfPages = pages.count
    }
    
    private func constraints() {
        NSLayoutConstraint.activate([
            hStack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10.scaled),
            hStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            nextButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 105.scaled),
            nextButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -105.scaled),
            nextButton.heightAnchor.constraint(equalToConstant: 50.scaled)
        ])
    }

    @objc private func didTapNext() {
        guard let currentVC = viewControllers?.first,
              let currentIndex = pages.firstIndex(of: currentVC) else { return }

        let nextIndex = currentIndex + 1

        if nextIndex < pages.count {
            // 다음 페이지로 이동
            setViewControllers([pages[nextIndex]], direction: .forward, animated: true)
            pageControl.currentPage = nextIndex
            
            // 버튼 텍스트 업데이트
            if nextIndex == pages.count - 1 {
                nextButton.setTitle(LocalizationKey.commonDone.localized, for: .normal)
            } else {
                nextButton.setTitle(LocalizationKey.commonNext.localized, for: .normal)
            }
            
        } else {
            viewModel.onEndButtonTapped?()
        }
    }
}

extension OnboardingViewController: UIPageViewControllerDataSource {
    // 이전 뷰 컨트롤러 리턴(우측 -> 좌측 슬라이드 제스처)
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        // 현재 vc 인덱스 구하기
        guard let currentIndex = pages.firstIndex(of: viewController) else { return nil }
        
        // 현재 인덱스가 0보다 크다면 다음 줄로 이동
        guard currentIndex > 0 else { return nil }
        return pages[currentIndex - 1]
    }
    
    // 다음 뷰 컨트롤러 화면(좌측 -> 우측 슬라이드 제스처)
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        // 현재 vc 인덱스 구하기
        guard let currentIndex = pages.firstIndex(of: viewController) else { return nil }
        
        // 현재 인덱스가 마지막 인덱스보다 작을 때만 다음줄로 이동
        guard currentIndex < (pages.count - 1) else { return nil }
        return pages[currentIndex + 1]
    }
}

extension OnboardingViewController: UIPageViewControllerDelegate {
    
    func pageViewController(_ pageViewController: UIPageViewController,
                                didFinishAnimating finished: Bool,
                                previousViewControllers: [UIViewController],
                                transitionCompleted completed: Bool) {
            guard completed,
                  let currentVC = viewControllers?.first,
                  let index = pages.firstIndex(of: currentVC) else { return }
            pageControl.currentPage = index
        
        
            if index == pages.count - 1 {
                nextButton.setTitle(LocalizationKey.commonDone.localized, for: .normal)
            } else {
                nextButton.setTitle(LocalizationKey.commonNext.localized, for: .normal)
            }
        }
}

//#Preview {
//    OnboardingViewController(transitionStyle: .scroll, navigationOrientation: .horizontal)
//}
