//
//  AppConfiguration.swift
//  App
//
//  Created by 김동현 on 3/1/26.
//

import Kingfisher

enum AppConfiguration {

    static func configureImageCache() {
        
        // Kingfisher 메모리 캐시 총 용량 제한 (100MB)
        ImageCache.default.memoryStorage.config.totalCostLimit =
        100 * 1024 * 1024
        
        // 메모리에 저장 가능한 최대 이미지 개수 (100개)
        ImageCache.default.memoryStorage.config.countLimit = 100
        
        // 디스크 캐시 최대 용량 제한 (예: 2GB)
        ImageCache.default.diskStorage.config.sizeLimit =
        2 * 1024 * 1024 * 1024 // 2GB

        // 디스크 캐시 만료 시간 (예: 7일)
        ImageCache.default.diskStorage.config.expiration =
        .days(7)
    }
}

/*
ImageCache.default.calculateDiskStorageSize { result in
    switch result {
    case .success(let size):
        print("💾 디스크 캐시 크기:", Double(size) / 1024 / 1024, "MB")
    case .failure(let error):
        print(error)
    }
}
 */

// ============================================================
// 🔥 Kingfisher Memory Cache Policy (앱 시작 시 1회 설정)
// ============================================================
//
// Kingfisher는 다운로드한 이미지를 "디코딩된 상태(RGBA 비트맵)"로
// 메모리 캐시에 저장한다.
//
// ⚠️ 주의:
// 여기서 기준은 "JPEG 파일 크기"가 아니라
// "디코딩된 픽셀 메모리 크기"이다.
//
// 디코딩 메모리 계산 공식:
// width × height × 4 bytes (RGBA)
//
// 예시:
// 300 x 300  → 약 0.34MB
// 1000 x 1000 → 약 4MB
// 3000 x 3000 → 약 36MB
//
// ------------------------------------------------------------
// 1️⃣ totalCostLimit
// ------------------------------------------------------------
// 메모리 캐시에 저장 가능한 "총 이미지 메모리 용량 한도"
//
// 여기서는 100MB로 제한.
// 캐시된 이미지들의 디코딩 메모리 총합이 100MB를 초과하면,
// LRU(Least Recently Used) 정책에 따라
// 가장 오래 사용하지 않은 이미지부터 자동 제거된다.
//
// 예:
// 36MB 이미지 3장 → 108MB
// → 100MB 초과
// → 가장 오래된 이미지 제거
//

// ------------------------------------------------------------
// 2️⃣ countLimit
// ------------------------------------------------------------
// 메모리 캐시에 저장 가능한 "이미지 개수 한도"
//
// 최대 100개 이미지까지만 유지.
// 101번째 이미지가 들어오면 가장 오래된 이미지 제거.
//
// totalCostLimit과 countLimit 중
// 어느 하나라도 초과하면 제거 동작이 발생한다.
//
