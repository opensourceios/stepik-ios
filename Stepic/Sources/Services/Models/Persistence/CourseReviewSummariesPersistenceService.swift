import Foundation
import PromiseKit

protocol CourseReviewSummariesPersistenceServiceProtocol: AnyObject {
    func fetch(
        ids: [CourseReviewSummary.IdType],
        page: Int
    ) -> Promise<([CourseReviewSummary], Meta)>
    func fetch(id: CourseReviewSummary.IdType) -> Promise<CourseReviewSummary?>
}

final class CourseReviewSummariesPersistenceService: CourseReviewSummariesPersistenceServiceProtocol {
    // swiftlint:disable:next unavailable_function
    func fetch(
        ids: [CourseReviewSummary.IdType],
        page: Int = 1
    ) -> Promise<([CourseReviewSummary], Meta)> {
        fatalError("Not implemented yet")
    }

    func fetch(id: CourseReviewSummary.IdType) -> Promise<CourseReviewSummary?> {
        Promise { seal in
            CourseReviewSummary.fetchAsync(ids: [id]).done { reviewsSummary in
                seal.fulfill(reviewsSummary.first)
            }.catch { _ in
                seal.reject(Error.fetchFailed)
            }
        }
    }

    enum Error: Swift.Error {
        case fetchFailed
    }
}
