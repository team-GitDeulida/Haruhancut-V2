//
//  UICollectionViewLayout.swift
//  DSKit
//
//  Created by 김동현 on 2/9/26.
//

import UIKit

public extension UICollectionViewLayout {
    /// 컬렉션 뷰 셀 크기를 자동으로 계산해주는 함수
    /// - Parameters:
    ///   - columns: 한 행에 보여줄 셀 개수
    ///   - spacing: 셀 사이 간격 (기본값 16)
    ///   - inset: 좌우 마진 (기본값 16)
    /// - Returns: 계산된 셀 크기
    func calculateItemSize(columns: Int, spacing: CGFloat = 16, inset: CGFloat = 16) -> CGSize {
        // 📌 기기 "화면 전체" 너비
        let screenWidth = UIScreen.main.bounds.width

        // (셀 사이 간격 * (컬럼 수 - 1)) + 좌우 inset
        let totalSpacing = spacing * CGFloat(columns - 1) + inset * 2

        // 실제 셀 하나의 너비
        let itemWidth = (screenWidth - totalSpacing) / CGFloat(columns)

        // 이미지 영역은 정사각형
        let imageHeight = itemWidth

        // 하단 텍스트 영역 (nickname + spacing + bottom margin)
        let labelHeight: CGFloat = 20 + 14 + 8

        return CGSize(
            width: itemWidth,
            height: imageHeight + labelHeight
        )
    }
    
    // MARK: - ✅ 컨테이너(CollectionView) 기준 계산
    /// 컬렉션뷰가 실제로 차지하는 "컨테이너 너비"를 기준으로
    /// 셀 크기를 계산한다.
    ///
    /// - 장점:
    ///   - iPad split view
    ///   - 모달
    ///   - SafeArea / padding
    ///   - 재사용 가능한 DSKit 레이아웃 유틸
    ///
    ///
    /// - Parameters:
    ///   - containerWidth: 컬렉션뷰의 실제 너비
    ///   - columns: 한 줄에 배치할 셀 개수
    ///   - spacing: 셀 사이 간격
    ///   - inset: 좌우 여백
    ///
    /// - Returns: 계산된 셀 사이즈
    func calculateItemSize(
            containerWidth: CGFloat,
            columns: Int,
            spacing: CGFloat = 16,
            inset: CGFloat = 16
        ) -> CGSize {

            // (셀 사이 간격 * (컬럼 수 - 1)) + 좌우 inset
            let totalSpacing = spacing * CGFloat(columns - 1) + inset * 2

            // 컨테이너 기준 셀 너비 계산
            let itemWidth = (containerWidth - totalSpacing) / CGFloat(columns)

            // 이미지 영역은 정사각형
            let imageHeight = itemWidth

            // 하단 텍스트 영역
            let labelHeight: CGFloat = 20 + 14 + 8

            return CGSize(
                width: itemWidth,
                height: imageHeight + labelHeight
            )
        }

}
