//
//  SignInViewController.swift
//  AuthFeature
//
//  Created by 김동현 on 1/12/26.
//

import UIKit
import AuthFeatureInterface
import RxSwift
import Core

final class SignUpViewController: UIViewController {
    
    // MARK: - Properties
    let disposeBag = DisposeBag()
    private let customView = SignUpView()
    let viewModel: SignUpViewModel

    init(viewModel: SignUpViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        self.view = customView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bindViewModel()
        bindImagePicker()
        setupDatePicker()
    }
    
    private func bindViewModel() {
        let nextTap = Observable.merge(
            customView.nicknameSettingView.nextButton.rx.tap.asObservable(),
            customView.birthDaySettingView.nextButton.rx.tap.asObservable(),
            customView.profileSettingView.nextButton.rx.tap.asObservable()
        )
        
        let input = SignUpViewModel.Input(
            nicknameText: customView.nicknameSettingView.textField.rx.text.orEmpty.asObservable(),
            birthdatDate: customView.birthDaySettingView.datePicker.rx.date.asObservable(),
            profileImage: customView.profileSettingView.profileImageRelay.asObservable(),
            nextButtonTapped: nextTap)
        
        let output = self.viewModel.transform(input: input)
        
        // next + back button
        output.step
            .drive(onNext: { [weak self] step in
                switch step {
                case .nickname:
                    self?.customView.move(to: 0)

                case .birthday:
                    self?.customView.move(to: 1)

                case .profile:
                    self?.customView.move(to: 2)
                
                default: break
                }
            })
            .disposed(by: disposeBag)
        
        // update 자동 호출
        output.nickname
            .drive(onNext: { [weak self] nickname in
                self?.customView.birthDaySettingView.updateNickname(nickname: nickname)
                self?.customView.profileSettingView.updateNickname(nickname: nickname)
            })
            .disposed(by: disposeBag)
        
        // nickname 버튼 활성화
        output.isNicknameValid
            .drive(customView.nicknameSettingView.nextButton.rx.isEnabled)
            .disposed(by: disposeBag)
    }
    
    private func bindImagePicker() {
        customView.profileSettingView.onRequestPresentImagePicker = { [weak self] sourceType in
            self?.presentImagePicker(sourceType: sourceType)
        }
    }
}

// MARK: - Image Picker
extension SignUpViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    private func presentImagePicker(sourceType: UIImagePickerController.SourceType) {
        guard UIImagePickerController.isSourceTypeAvailable(sourceType) else {
            print("❌ 해당 소스타입 사용 불가")
            return
        }

        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = self
        picker.allowsEditing = false
        present(picker, animated: true)
    }

    // 이미지 선택 완료
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)

        if let image = info[.originalImage] as? UIImage {
            // 이미지 설정
            customView.profileSettingView.updateProfileImage(image)
        }
    }

    // 선택 취소
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}

// MARK: - Date Picker
extension SignUpViewController {

    private func setupDatePicker() {
        let datePicker = customView.birthDaySettingView.datePicker
        let textField  = customView.birthDaySettingView.textField

        datePicker.datePickerMode = .date
        datePicker.preferredDatePickerStyle = .wheels
        datePicker.locale = Locale(identifier: "ko-KR")

        // Date 변경 이벤트
        datePicker.addTarget(self, action: #selector(dateChange), for: .valueChanged)

        // 핵심
        textField.inputView = datePicker
        textField.inputAccessoryView = createToolbar()

        // 초기값 (2000-01-01)
        let defaultDate = Calendar.current.date(
            from: DateComponents(year: 2000, month: 1, day: 1)
        ) ?? Date()

        datePicker.date = defaultDate
        textField.text = defaultDate.toKoreanDateKey()
    }

    @objc private func dateChange() {
        let date = customView.birthDaySettingView.datePicker.date
        customView.birthDaySettingView.textField.text = date.toKoreanDateKey()
    }

    private func createToolbar() -> UIToolbar {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()

        let flexible = UIBarButtonItem(
            barButtonSystemItem: .flexibleSpace,
            target: nil,
            action: nil
        )

        let done = UIBarButtonItem(
            title: "완료",
            style: .done,
            target: self,
            action: #selector(donePressed)
        )

        toolbar.setItems([flexible, done], animated: false)
        return toolbar
    }

    @objc private func donePressed() {
        customView.birthDaySettingView.textField.resignFirstResponder()
    }
}
//#Preview {
//    SignUpViewController(viewModel: SignUpViewModel())
//}
