---
name: "Tech Spec"
about: "복잡한 기능이나 구조 변경을 구현하기 전에 기술 설계를 제안하고 검토합니다"
title: "[Tech Spec] "
labels: ""
assignees: ""
---

<!--
언제 사용하나요?
- 여러 모듈이나 계층에 영향을 주는 기능 또는 리팩터링
- 기술 선택, 데이터 흐름, 마이그레이션처럼 구현 전 합의가 필요한 작업
- 여러 PR로 나뉘거나 위험과 롤백 계획을 먼저 검토해야 하는 작업

작성 원칙
- 구현 전에 초안을 만들고, 리뷰에서 결정이 바뀌면 이 문서도 함께 갱신해 주세요.
- 독자가 배경지식 없이도 문제와 선택의 근거를 이해할 수 있게 작성해 주세요.
- 작업 규모에 비례해 필요한 만큼만 작성하고, 해당하지 않는 항목은 삭제해도 됩니다.
-->

**작성자**: @GitHub-ID
**상태**: 초안 / 리뷰 중 / 승인 / 구현 완료
**리뷰어**: @GitHub-ID
**관련 문서**: <!-- PRD, 디자인, 상위 이슈 등의 링크 -->

## 요약 (Summary)

<!-- 누가, 무엇을, 왜 변경하는지 1~2문장으로 요약해 주세요. -->

## 배경 (Background)

<!-- 현재 동작과 문제, 이 작업이 필요한 이유, 이전 시도가 있다면 함께 적어 주세요. -->

## 목표 (Goals)

<!-- 이 작업으로 달성할 결과를 검증 가능한 문장으로 적어 주세요. -->

-

## 목표가 아닌 것 (Non-goals)

<!-- 관련 있어 보이지만 이번 작업에서 의도적으로 다루지 않을 범위를 적어 주세요. -->

-

## 기술 설계 (Technical Design)

<!--
제안하는 구조와 동작을 설명해 주세요. 필요한 항목만 선택해 작성하면 됩니다.
- 현재 구조와 변경 후 구조
- 주요 컴포넌트의 책임과 데이터 흐름
- 인터페이스, API, 데이터 모델 또는 의사 코드
- 오류 처리, 동시성, 캐시와 상태 관리
- 하위 호환성, 마이그레이션과 의존성
복잡한 흐름은 다이어그램을 첨부해 주세요.
-->

## 대안과 트레이드오프 (Alternatives and Trade-offs)

<!-- 검토한 대안, 장단점, 선택하거나 제외한 이유를 기록해 주세요. -->

| 대안 | 장점 | 단점 | 결정 |
| --- | --- | --- | --- |
|  |  |  |  |

## 영향 범위와 고려 사항 (Impact and Considerations)

<!-- 성능, 보안·개인정보, 접근성, 운영, 비용, 분석, 다른 기능에 미치는 영향을 점검해 주세요. -->

-

## 위험과 대응 (Risks and Mitigations)

| 위험 | 영향 | 대응 |
| --- | --- | --- |
|  |  |  |

## 검증 계획 (Validation Plan)

<!-- 단위·통합 테스트, 수동 QA, 성능 측정 등 목표 달성을 확인할 방법을 적어 주세요. -->

- [ ]

## 출시와 롤백 계획 (Rollout and Rollback Plan)

<!-- 단계적 적용, 기능 플래그, 모니터링 지표, 실패 판단 기준과 복구 방법을 적어 주세요. -->

## 마일스톤 (Milestones)

<!-- 작업을 리뷰 가능한 단위로 나누고, 필요하면 하위 이슈나 PR을 연결해 주세요. -->

| 단계 | 산출물 | 관련 이슈/PR | 완료 조건 |
| --- | --- | --- | --- |
|  |  |  |  |

## 예상 Q&A와 미해결 질문 (Expected Q&A and Open Questions)

<!-- 리뷰에서 나올 질문에 미리 답하고, 아직 결정되지 않은 항목은 담당자와 결정 시점을 적어 주세요. -->

- Q.
  - A.

## 참고 자료 (References)

<!-- 관련 코드, 문서, 이슈, 장애 기록이나 외부 자료를 링크해 주세요. -->

-

<!--
템플릿 설계 참고 자료
- https://engineering.ab180.co/stories/how-engineering-team-works-to-make-robust-product
- https://eng.lyft.com/awesome-tech-specs-86eea8e45bb9
- https://blog.banksalad.com/tech/we-work-by-tech-spec/
- https://velog.io/@aufcl4858/%ED%9A%A8%EA%B3%BC%EC%A0%81%EC%9D%B8-%EA%B0%9C%EB%B0%9C-%ED%94%84%EB%A1%9C%EC%84%B8%EC%8A%A4%EB%A5%BC-%EC%9C%84%ED%95%9C-%ED%85%8C%ED%81%AC-%EC%8A%A4%ED%8E%99Tech-Spec-%EA%B0%80%EC%9D%B4%EB%93%9C
- https://garden-ying.tistory.com/38
- https://helloworld.kurly.com/blog/tech-spec-adoption-with-ai-automation/
-->
