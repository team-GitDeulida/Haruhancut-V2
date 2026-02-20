//
//  CameraViewController.swift
//  ImageFeature
//
//  Created by 김동현 on 2/15/26.
//

import UIKit
import AVFoundation
import RxSwift
import RxCocoa
import DSKit

//import Core

import ImageFeatureInterface

final class CameraViewController: CameraViewControllerType {
    var onPop: (() -> Void)?
    private let cameraViewModel: CameraViewModel
    
    // MARK: - Camera
    let customView = CameraView()
    private var captureSession: AVCaptureSession?               // 카메라 세션 객체
    private var previewLayer: AVCaptureVideoPreviewLayer?       // 카메라 화면을 보여줄 레이어
    private let context = CIContext()                           // CIImage를 CGImage(실제 이미지)로 렌더링해주는 엔진
    
    // MARK: - 캡처 방식
    private let videoOutput = AVCaptureVideoDataOutput()        // 영상 프레임 출력(무음 캡처)
    private var currentImage: UIImage?                          // 가장 최근 프레임 저장용
    private var freezeImageView: UIImageView?                   // 캡처한 이미지 띄우는 용도
    
    // MARK: - 중복 카메라 설정 방지 플래그
    private var isCameraConfigured: Bool = false
    
    init(viewModel: CameraViewModel) {
        self.cameraViewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// Sets the view controller's root view to the configured `CameraView`.
    override func loadView() {
        self.view = customView
    }
    
    /// Performs a one-time camera configuration when the view becomes visible.
    /// 
    /// Calls `super.viewDidAppear(_:)`, ensures camera setup runs only once by setting `isCameraConfigured`, and schedules `setupCamera()` to execute on a background queue.
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !isCameraConfigured else { return }
        isCameraConfigured = true
        
        // 카메라 설정(백그라운드 스레드에서 실행)
        DispatchQueue.global(qos: .unspecified).async { [weak self] in
            self?.setupCamera()
        }
    }
    
    // 뷰가 메모리에 올라왔을때 && 레이아웃 계산 전
    /// Performs post-load setup for the controller's UI and bindings.
    /// 
    /// Prepares the camera preview layer and establishes bindings between the view and the view model.
    override func viewDidLoad() {
        super.viewDidLoad()
        preparePreviewLayer()
        bindViewModel()
    }
    
    /// Updates the preview layer's frame to match the camera view's bounds after layout.
    /// Ensures the video preview fills the camera view's current size.
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = customView.cameraView.bounds
    }
    
    /// Binds the camera UI to the view model by streaming the most recently captured image when the camera button is tapped.
    /// 
    /// Subscribes to the camera button tap events and forwards the latest `currentImage` as the `cameraButtonTapped` input to the view model.
    private func bindViewModel() {
        // MARK: - Tap 시점의 이미지를 꺼내서 stream으로 보낸다
        let captureImageStream = customView.cameraButton.rx.tap
            .compactMap { [weak self] _ in
                self?.currentImage
            }
        
        let input = CameraViewModel.Input(cameraButtonTapped: captureImageStream)
        let _ = cameraViewModel.transform(input: input)
    }
}

// MARK: - 비디오를 기록하고 프로세싱을 위한 비디오 프레임 접근을 제공하는 캡처 아웃풋
extension CameraViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    /// Configures and starts the device camera capture session and connects it to the preview layer.
    /// 
    /// Requests camera permission when needed. When authorized, creates an `AVCaptureSession` using the rear camera, sets its preset to `.photo`, attaches a video data output (delegate is set), stores and starts the session, and assigns the session to `previewLayer` on the main thread. If permission is denied or a camera input cannot be created, the method returns without starting a session.
    private func setupCamera() {
        // 1. 권한 체크
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            break
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if granted {
                    self?.setupCamera()
                } else {
                    DispatchQueue.main.async {
                        // self.showCameraPermissionAlert()
                    }
                }
            }
        default:
            DispatchQueue.main.async {
                // self.showCameraPermissionAlert()
            }
        }
        
        // 2. 세션 설정
        let session = AVCaptureSession()
        session.sessionPreset = .photo // 고해상도 사진 모드
        
        // 3. 후면 카메라를 입력으로 설정
        guard let camera = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: camera) else {
            // Logger.d("카메라 접근 실패")
            return
        }
        
        // 4. 세션에 입력 추가
        if session.canAddInput(input) {
            session.addInput(input)
        }
        
        // 5. 비디오 출력 설정
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
        }
        
        // 6. 세션 저장 및 시작
        self.captureSession = session
        session.startRunning()
        
        // 7. 메인스레드에서 previewLayout과 세션 연결
        DispatchQueue.main.async { [weak self] in
            self?.previewLayer?.session = session
        }
    }
    
    /// Creates and attaches an AVCaptureVideoPreviewLayer to the camera view and stores it for later use.
    /// 
    /// The preview layer's videoGravity is set to `resizeAspectFill` before it is added as a sublayer of `customView.cameraView`, and the layer is saved to `previewLayer`.
    private func preparePreviewLayer() {
        let preview = AVCaptureVideoPreviewLayer()
        preview.videoGravity = .resizeAspectFill          // 화면 채우면서 비율 유지
        // preview.frame = customView.cameraView.bounds      // 초기 프레임 설정
        customView.cameraView.layer.addSublayer(preview)  // cameraView에 layer 추가
        self.previewLayer = preview                       // 나중에 참조할 수 있도록 저장
    }
    
    /// Ensures a captured frame is available and that execution is on the main thread before further handling.
    /// 
    /// If `currentImage` is nil, logs `"현재 프레임 없음"` and returns without performing any action. Asserts that the call is made from the main thread; subsequent handling (for example, navigation or passing the image to a coordinator) occurs after this validation.
    private func captureCurrentFrame() {
        guard let image = currentImage else {
            print("현재 프레임 없음")
            return
        }
        assert(Thread.isMainThread, "❌ UI 변경은 반드시 메인 스레드에서 수행해야 합니다")
        // 코디네이터 화면전환 로직 추가예정
    }
    
    /// Presents an alert prompting the user to enable camera access in Settings.
    /// 
    /// The alert includes a "설정으로 이동" action that opens the app's Settings page and a "취소" action to dismiss the alert.
    private func showCameraPermissionAlert() {
        let settingAction = UIAlertAction(title: "설정으로 이동", style: .default) { _ in
            if let url = URL(string: UIApplication.openSettingsURLString),
               UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
        }
        
        let cancelAction = UIAlertAction(title: "취소", style: .cancel)
        let alert = AlertFactory.makeAlert(title: "카메라 접근 권한 필요",
                               message: "카메라를 사용하려면 설정 > 하루한컷에서 접근 권한을 허용해주세요.",
                               actions: [settingAction, cancelAction])
        self.present(alert, animated: true)
    }
    
    /// Receives video sample buffers and updates the controller's currentImage with the latest frame.
    ///
    /// Converts the provided `CMSampleBuffer` into a `UIImage` and assigns it to `currentImage` on the main thread.
    /// - Parameters:
    ///   - output: The capture output that provided the sample buffer.
    ///   - sampleBuffer: A `CMSampleBuffer` containing a video frame to be converted.
    ///   - connection: The capture connection from which the buffer was received.
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let ciImage = CIImage(cvImageBuffer: imageBuffer)
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return }
        let uiImage = UIImage(cgImage: cgImage,
                              scale: UIScreen.main.scale,
                              orientation: .right) // 카메라 방향 보정
        
        DispatchQueue.main.async {
            self.currentImage = uiImage
        }
    }
}
