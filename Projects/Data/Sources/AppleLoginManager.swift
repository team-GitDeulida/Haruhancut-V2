//
//  AppleLoginManager.swift
//  Data
//
//  Created by 김동현 on 1/20/26.
//

import RxSwift

// 애플 로그인
import CryptoKit
import AuthenticationServices
import Core

public protocol AppleLoginManagerProtocol {
    func login() -> Single<(String, String)>
}

public final class AppleLoginManager: NSObject, AppleLoginManagerProtocol {

    
    public override init() {}

    // 애플 로그인 결과를 외부에 전달하기 위한 통로
    // ASAuthorizationControllerDelegate는 콜백 기반 -> Rx방식(Observable 스트림)으로 변환을 위함
    // private var loginSubject: PublishSubject<Result<(String, String), LoginError>>?
    private var singleObserver: ((SingleEvent<(String, String)>) -> Void)?
    private var currentNonce: String?
    
    /// 무작위 nonce 문자열 생성
    /// - Parameter length: 생성할 nonce 길이 (기본값: 32)
    /// - Returns: 생성된 nonce 문자열
    public func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError(
                "Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)"
            )
        }
        
        let charset: [Character] =
        Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        
        let nonce = randomBytes.map { byte in
            // Pick a random character from the set, wrapping around if needed.
            charset[Int(byte) % charset.count]
        }
        
        return String(nonce)
    }
    
    /// 입력 문자열을 SHA256 해시로 변환
    /// - Parameter input: 해싱할 입력 문자열
    /// - Returns: SHA256 해시 문자열
    public func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        
        return hashString
    }
    
    /// 애플 로그인 수행
    /// - Returns: 로그인 성공 시 AppleId 토큰 문자열, 실패 시 오류를 포함한 Observable
    public func login() -> Single<(String, String)> {
        return Single.create { [weak self] single in
            guard let self else {
                single(.failure(LoginError.invalidCredential))
                return Disposables.create()
            }
            
            self.singleObserver = single
            
            let nonce = self.randomNonceString()
            self.currentNonce = nonce
            
            let request = ASAuthorizationAppleIDProvider().createRequest()
            request.requestedScopes = [.fullName, .email]
            request.nonce = self.sha256(nonce)
            
            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            controller.performRequests()
            
            return Disposables.create {
                self.singleObserver = nil
            }
        }
    }
}

// MARK: - ASAuthorizationControllerDelegate
extension AppleLoginManager: ASAuthorizationControllerDelegate {

    public func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        guard
            let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
            let tokenData = credential.identityToken,
            let tokenString = String(data: tokenData, encoding: .utf8),
            let rawNonce = currentNonce
        else {
            singleObserver?(.failure(LoginError.invalidCredential))
            singleObserver = nil
            return
        }

        singleObserver?(.success((tokenString, rawNonce)))
        singleObserver = nil
    }

    public func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        singleObserver?(.failure(LoginError.sdkApple(error)))
        singleObserver = nil
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding
extension AppleLoginManager: ASAuthorizationControllerPresentationContextProviding {
    public func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return (UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }) ?? UIWindow()
    }
}


