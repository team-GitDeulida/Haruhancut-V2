//
//  SampleVC.swift
//  HomeFeature
//
//  Created by 김동현 on 4/18/26.
//

import UIKit
import CarbonListKit
import ReactorKit

final class SampleVC: UIViewController {
    
    private let collectionView = UICollectionView(
        frame: .zero,
        collectionViewLayout: UICollectionViewLayout()
    )
    
    private lazy var adapter = ListAdapter(collectionView: collectionView)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "SampleVC"
        view.backgroundColor = .systemBackground
        
        setupCollectionView()
        render()
    }
    
    private func setupCollectionView() {
        collectionView.backgroundColor = .systemBackground
        collectionView.alwaysBounceVertical = true
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func render() {
        adapter.apply(updateStrategy: .animated) {
            Section(id: "simple-components") {
              Row(
                id: "section-title-2",
                component: SimpleTextComponent(
                    content: .init(
                    title: "심플 버전",
                    subtitle: "Model / 전용 View 없이 Component 하나에서 바로 렌더링"
                  )
                )
              )
              
              Row(
                id: "simple-1",
                component: SimpleTextComponent(
                    content: .init(
                    title: "CarbonListKit 시작하기",
                    subtitle: "간단한 텍스트는 이렇게 바로 표현할 수 있어요."
                  )
                )
              )
              
              Row(
                id: "simple-2",
                component: SimpleTextComponent(
                    content: .init(
                    title: "Component 하나만으로도 가능",
                    subtitle: "샘플, 프로토타입, 고정 UI에 적합합니다."
                  )
                )
              )

              Row(
                id: "simple-3",
                component: SimpleTextComponent(
                    content: .init(
                    title: "하지만 실전은 분리 추천",
                    subtitle: "도메인 모델과 UI 책임을 나누면 유지보수가 쉬워집니다."
                  )
                )
              )
            }
            .layout(.vertical(spacing: 12))
            .contentInsets(.init(top: 0, leading: 16, bottom: 24, trailing: 16))
        }
    }
}

#Preview {
    SampleVC()
}

// MARK: - 심플 버전
struct SimpleTextComponent: ListComponent {

  struct Content: Equatable {
    let title: String
    let subtitle: String
  }

  let content: Content

  func makeView(context: ListComponentContext<Void>) -> SimpleTextRowView {
    SimpleTextRowView()
  }

  func updateView(_ view: SimpleTextRowView, context: ListComponentContext<Void>) {
    view.configure(
      title: content.title,
      subtitle: content.subtitle
    )
  }
}

final class SimpleTextRowView: UIView {
  private let titleLabel = UILabel()
  private let subtitleLabel = UILabel()

  override init(frame: CGRect) {
    super.init(frame: frame)
    setupUI()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func setupUI() {
    // backgroundColor = .tertiarySystemBackground
    backgroundColor = .secondarySystemBackground
    layer.cornerRadius = 12

    titleLabel.font = .systemFont(ofSize: 15, weight: .semibold)
    titleLabel.numberOfLines = 0

    subtitleLabel.font = .systemFont(ofSize: 13)
    subtitleLabel.textColor = .secondaryLabel
    subtitleLabel.numberOfLines = 0

    let stack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
    stack.axis = .vertical
    stack.spacing = 6

    addSubview(stack)
    stack.translatesAutoresizingMaskIntoConstraints = false

    NSLayoutConstraint.activate([
      stack.topAnchor.constraint(equalTo: topAnchor, constant: 16),
      stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
      stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
      stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16)
    ])
  }

  func configure(title: String, subtitle: String) {
    titleLabel.text = title
    subtitleLabel.text = subtitle
  }
}
