//
//  UITestID.swift
//  AppUITests
//
//  Created by 김동현 on 3/1/26.
//

import Foundation

public enum UITestID {
    public enum Feed {
        public static let collectionView = "feed_collectionView"
        public static let cameraButton = "feed_camera_button"
        public static let uploadButton = "feed_upload_button"
    }
    
    public enum FeedDetail {
        public static let commentButton = "feedDetail_comment_button"
    }
    
    public enum Comment {
        public static let inputTextView = "comment_inputTextView"
        public static let sendButton = "comment_send_button"
        public static let tableView = "comment_tableView"
    }
    
    public enum ActionSheet {
        public static let album = "앨범에서 선택"
        public static let camera = "카메라로 찍기"
    }
}
