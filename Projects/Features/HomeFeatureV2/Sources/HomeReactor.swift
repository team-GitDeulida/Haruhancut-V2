//
//  HomeReactor.swift
//  HomeFeatureV2
//
//  Created by 김동현 on 4/19/26.
//

import ReactorKit
import HomeFeatureV2Interface
import Domain
import Data
import Foundation

final class HomeReactor: Reactor, HomeReactorType {
    var onImageTapped: ((Domain.Post) -> Void)?
    var onMemberTapped: (() -> Void)?
    var onProfileTapped: (() -> Void)?
    var onCameraTapped: ((HomeFeatureV2Interface.CameraSource) -> Void)?
    var onCalendarImageTapped: (([Domain.Post], Date) -> Void)?
    
    let initialState = State()
    
    enum Action {
        
    }
    
    struct State {
        var components: [SimpleTextComponent] = [
            SimpleTextComponent(
                content: .init(
                    title: "CarbonListKit 시작하기",
                    subtitle: "간단한 텍스트는 이렇게 바로 표현할 수 있어요."
                )),
            SimpleTextComponent(
                content: .init(
                    title: "CarbonListKit 시작하기",
                    subtitle: "간단한 텍스트는 이렇게 바로 표현할 수 있어요."
                )),
            SimpleTextComponent(
                content: .init(
                    title: "Component 하나만으로도 가능",
                    subtitle: "샘플, 프로토타입, 고정 UI에 적합합니다."
                )),
            SimpleTextComponent(
                content: .init(
                    title: "하지만 실전은 분리 추천",
                    subtitle: "도메인 모델과 UI 책임을 나누면 유지보수가 쉬워집니다."
                )),
        ]
    }
}
