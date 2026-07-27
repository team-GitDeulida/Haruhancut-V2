import RxSwift

/// 관리자 전용 그룹 조회 저장소입니다.
public protocol AdminRepositoryProtocol {
    /// 모든 그룹을 관리자 목록용 통계로 조회합니다.
    func fetchGroupSummaries()
        -> Single<[AdminGroupSummary]>

    /// 지정한 그룹의 상세 데이터를 조회합니다.
    func fetchGroup(
        groupId: String
    ) -> Single<HCGroup>
}
