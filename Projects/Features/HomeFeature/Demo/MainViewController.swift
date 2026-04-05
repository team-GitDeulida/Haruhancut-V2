//
//  MainViewController.swift
//  HomeDemo
//
//  Created by 김동현 on
//

import UIKit
import RxSwift
import RxCocoa
import TurboListKit
import DSKit

/*
 final class MainViewController: UIViewController {
 
 private let disposeBag = DisposeBag()
 
 private let label = UILabel()
 private let button = UIButton(type: .system)
 
 override func viewDidLoad() {
 super.viewDidLoad()
 view.backgroundColor = .systemBackground
 setupUI()
 bind()
 }
 
 private func setupUI() {
 
 label.text = "Tap Button"
 label.font = .systemFont(ofSize: 24, weight: .bold)
 label.textAlignment = .center
 
 button.setTitle("Tap", for: .normal)
 
 label.translatesAutoresizingMaskIntoConstraints = false
 button.translatesAutoresizingMaskIntoConstraints = false
 
 view.addSubview(label)
 view.addSubview(button)
 
 NSLayoutConstraint.activate([
 label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
 label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
 
 button.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 20),
 button.centerXAnchor.constraint(equalTo: view.centerXAnchor)
 ])
 }
 
 private func bind() {
 
 // ControlEvent → Observable
 let tap = button.rx.tap
 
 // Observable → Driver
 let textDriver = tap
 .map { "Tapped at \(Date())" }
 .asDriver(onErrorJustReturn: "Error")
 
 // Driver → Binder
 textDriver
 .drive(label.rx.text)
 .disposed(by: disposeBag)
 }
 }
 */

final class MainViewController: UIViewController {
    
    private var items = TObservable(Array(0..<4))
    
    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        let cv = UICollectionView(
            frame: .zero,
            collectionViewLayout: layout
        )
        cv.showsVerticalScrollIndicator = false
        cv.showsHorizontalScrollIndicator = false
        return cv
    }()
    
    private lazy var adapter = TurboListAdapter(collectionView: collectionView)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupUpdate()
        setupDelayedUpdate()
        setupRefresh()
    }
    
    private func setupUI() {
        view.backgroundColor = .background
        collectionView.backgroundColor = .background
        
        view.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 0),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    func setupUpdate() {
        typealias Section = TurboSection
        adapter.bind(items) { items in
            Section("id1") {
                Header(title: "header")
                for idx in items {
                    CellComponent(number: idx)
                }
            }
            .padding(.horizontal, 10)
            .grid(columns: 2, vSpacing: 15, hSpacing: 10)
        }
    }
    
    func setupRefresh() {
        adapter
            .refreshTitle("로딩중...")
            .refreshTintColor(.mainWhite)
            .refreshTintColor(.mainWhite)
            .onRefresh { done in
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    done()
                }
            }
    }
    
    // 3초 뒤 데이터 변경
    private func setupDelayedUpdate() {
        
        // 1️⃣ 3초 뒤 → 추가
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            guard let self else { return }
            
            self.items.value.append(self.items.value.count)
            // self.setupUpdate()
            
            // 2️⃣ 그 다음 3초 뒤 → 짝수 제거
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
                guard let self else { return }
                
                self.items.value = self.items.value.filter { $0 % 2 != 0 } // ⭐️ 짝수 제거
                // self.setupUpdate()
            }
        }
    }
}

#Preview {
    MainViewController()
}


import SwiftUI

struct MainView: View {
    var body: some View {
        VStack {
            Text("Hello Turbo!")
            NumberComponent(number: 1)
            NumberComponent(number: 1)
        }
        .padding(.horizontal, 20)
    }
}



#Preview {
    MainView()
}
