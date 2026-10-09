import XCTest
@testable import ProfileFeatureV2

final class ProfileGridImagePrefetchQueueTests:
    XCTestCase
{
    func testQueueProcessesRequestsInBoundedSequentialBatches() {
        let queue = ProfileGridImagePrefetchQueue(
            batchSize: 2
        )
        queue.enqueue(
            [
                request(id: "one"),
                request(id: "two"),
                request(id: "three"),
            ]
        )

        XCTAssertEqual(
            queue.nextBatch().map(\.postID),
            [
                "one",
                "two",
            ]
        )
        XCTAssertTrue(
            queue.nextBatch().isEmpty
        )

        queue.finishActiveBatch()

        XCTAssertEqual(
            queue.nextBatch().map(\.postID),
            ["three"]
        )
    }

    func testQueueRemovesCancelledPendingRequests() {
        let queue = ProfileGridImagePrefetchQueue(
            batchSize: 1
        )
        queue.enqueue(
            [
                request(id: "one"),
                request(id: "two"),
                request(id: "three"),
            ]
        )
        _ = queue.nextBatch()

        XCTAssertTrue(
            queue.cancel(
                postIDs: ["two"]
            )
        )

        queue.finishActiveBatch()

        XCTAssertEqual(
            queue.nextBatch().map(\.postID),
            ["three"]
        )
    }

    func testQueueSignalsWhenAllActiveRequestsAreCancelled() {
        let queue = ProfileGridImagePrefetchQueue()
        queue.enqueue(
            [request(id: "one")]
        )
        _ = queue.nextBatch()

        XCTAssertFalse(
            queue.cancel(
                postIDs: ["one"]
            )
        )
    }

    private func request(
        id: String
    ) -> ProfileGridImagePrefetchRequest {
        ProfileGridImagePrefetchRequest(
            postID: id,
            imageURL: URL(
                string: "https://example.com/\(id).jpg"
            )!
        )
    }
}
