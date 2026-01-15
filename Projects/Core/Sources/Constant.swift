//
//  Constant.swift
//  Core
//
//  Created by 김동현 on 1/13/26.
//

import Foundation

// 앱 내에서 사용하는 상수들을 한 곳에서 관리
public enum Constants {

    public enum Appstore {
        // 앱스토어 등록 URL
        public static let appstoreURL = "https://apps.apple.com/kr/app/id6743386583"
        public static let appId = "6743386583"
    }
    
    public enum Firebase {
        public static let realtimeURL = "https://haruhancut-kor-default-rtdb.firebaseio.com"
    }
    
    public enum Notion {
        public static let notionURL = "https://www.notion.so/210db9e736cf80d4b3a8c7e077e6325f?source=copy_link"
        public static let privatePolicy = "https://www.notion.so/210db9e736cf81bca378c1c8a69a35f1?source=copy_link"
        public static let announce = "https://www.notion.so/210db9e736cf8197bb31dbb71ed7a39c?source=copy_link"
    }
}

