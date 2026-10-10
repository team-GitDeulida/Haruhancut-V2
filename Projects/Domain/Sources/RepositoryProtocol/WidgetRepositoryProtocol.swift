import Foundation
import RxSwift

/// 홈 화면 위젯이 읽는 저장소입니다.
///
/// 사진은 날짜 폴더별로 저장합니다. 폴더 이름과 파일 이름 규칙은 구현이 정합니다.
public protocol WidgetRepositoryProtocol {
    /// 위젯이 그룹을 찾을 때 쓰는 사용자를 저장합니다.
    func saveUser(
        _ user: User
    )

    /// `date`가 속한 날짜 폴더에 저장된 사진의 게시물 식별자입니다.
    func photoIdentifiers(
        groupId: String,
        date: Date
    ) -> [String]

    /// 저장하는 시각의 날짜 폴더에 사진을 저장합니다.
    func savePhoto(
        _ data: Data,
        groupId: String,
        identifier: String
    ) throws

    /// `date`가 속한 날짜 폴더에서 사진을 지웁니다.
    func deletePhoto(
        groupId: String,
        date: Date,
        identifier: String
    )

    /// 게시물 이미지를 내려받습니다.
    func fetchImageData(
        from url: URL
    ) -> Single<Data>

    /// 위젯에 저장소를 다시 읽으라고 요청합니다.
    func reloadWidget()
}
