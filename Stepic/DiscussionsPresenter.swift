import Foundation
import PromiseKit

protocol DiscussionsPresenterProtocol: class {
    var discussionProxyID: DiscussionProxy.IdType { get }
    var stepID: Step.IdType { get }

    func refresh()
    func selectViewData(_ viewData: DiscussionsViewData)
    func writeComment(_ comment: Comment)
    func likeComment(_ comment: Comment)
    func abuseComment(_ comment: Comment)
}

final class DiscussionsPresenter: DiscussionsPresenterProtocol {
    private static let discussionsLoadingInterval = 20
    private static let repliesLoadingInterval = 20

    weak var view: DiscussionsView?

    let discussionProxyID: DiscussionProxy.IdType
    let stepID: Step.IdType

    private let discussionProxiesNetworkService: DiscussionProxiesNetworkServiceProtocol
    private let commentsNetworkService: CommentsNetworkServiceProtocol
    private let votesNetworkService: VotesNetworkServiceProtocol
    private let stepsPersistenceService: StepsPersistenceServiceProtocol

    private var discussionsIDs = DiscussionsIDs()
    private var discussions = [Comment]()
    private var replies = Replies()

    /// A Boolean value that determines whether the refresh is in progress.
    private var isReloading = false
    /// A Boolean value that determines whether the fetch of the discussions is in progress (load more discussions).
    private var isFetchingMoreDiscussions = false
    /// A Boolean value that determines whether the fetch of the replies for root discussion is in progress.
    private var discussionsFetchingRepliesIds: Set<Comment.IdType> = []

    init(
        view: DiscussionsView?,
        discussionProxyID: DiscussionProxy.IdType,
        stepID: Step.IdType,
        discussionProxiesNetworkService: DiscussionProxiesNetworkServiceProtocol,
        commentsNetworkService: CommentsNetworkServiceProtocol,
        votesNetworkService: VotesNetworkServiceProtocol,
        stepsPersistenceService: StepsPersistenceServiceProtocol
    ) {
        self.view = view
        self.discussionProxyID = discussionProxyID
        self.stepID = stepID
        self.discussionProxiesNetworkService = discussionProxiesNetworkService
        self.commentsNetworkService = commentsNetworkService
        self.votesNetworkService = votesNetworkService
        self.stepsPersistenceService = stepsPersistenceService
    }

    func refresh() {
        if self.isReloading {
            return
        }
        self.isReloading = true

        self.discussionsIDs = DiscussionsIDs()
        self.replies = Replies()
        self.discussions = [Comment]()

        let queue = DispatchQueue.global(qos: .userInitiated)

        queue.promise {
            self.discussionProxiesNetworkService.fetch(id: self.discussionProxyID)
        }.then(on: queue) { discussionProxy -> Promise<[Comment.IdType]> in
            self.discussionsIDs.all = discussionProxy.discussionsIDs
            return .value(self.getNextDiscussionsIDsToLoad())
        }.then(on: queue) { ids in
            self.fetchComments(ids: ids)
        }.done {
            self.reloadViewData()
        }.ensure {
            self.isReloading = false
        }.catch { error in
            print("DiscussionsPresenter :: error :: \(error)")
            self.view?.displayError(error)
        }
    }

    func writeComment(_ comment: Comment) {
        if let parentId = comment.parentID {
            if let parentIdx = self.discussions.index(where: { $0.id == parentId }) {
                self.discussions[parentIdx].repliesIDs += [comment.id]
                self.replies.loaded[parentId, default: []] += [comment]
            }
        } else {
            self.discussionsIDs.all.insert(comment.id, at: 0)
            self.discussionsIDs.loaded.insert(comment.id, at: 0)
            self.discussions.insert(comment, at: 0)
            self.incrementStepDiscussionsCount()
        }
        self.reloadViewData()
    }

    func selectViewData(_ viewData: DiscussionsViewData) {
        if let comment = viewData.comment {
            self.view?.displayDiscussionAlert(comment: comment)
        } else if let loadRepliesFor = viewData.fetchRepliesFor {
            if self.discussionsFetchingRepliesIds.contains(loadRepliesFor.id) {
                return
            }

            self.discussionsFetchingRepliesIds.insert(loadRepliesFor.id)
            self.reloadViewData()

            let idsToLoad = self.getNextReplyIDsToLoad(discussion: loadRepliesFor)
            self.fetchComments(ids: idsToLoad).done {
                self.discussionsFetchingRepliesIds.remove(loadRepliesFor.id)
                self.reloadViewData()
            }.catch { _ in
                self.discussionsFetchingRepliesIds.remove(loadRepliesFor.id)
                self.reloadViewData()
                self.displayErrorAlert()
            }
        } else if viewData.needFetchDiscussions {
            if self.isFetchingMoreDiscussions {
                return
            }

            self.isFetchingMoreDiscussions = true
            self.reloadViewData()

            let idsToLoad = self.getNextDiscussionsIDsToLoad()
            self.fetchComments(ids: idsToLoad).done {
                self.isFetchingMoreDiscussions = false
                self.reloadViewData()
            }.catch { _ in
                self.isFetchingMoreDiscussions = false
                self.reloadViewData()
                self.displayErrorAlert()
            }
        }
    }

    func likeComment(_ comment: Comment) {
        if let voteValue = comment.vote.value {
            let voteValueToSet: VoteValue? = voteValue == .epic ? nil : .epic
            let vote = Vote(id: comment.vote.id, value: voteValueToSet)

            self.votesNetworkService.update(vote: vote).done { [weak self] vote in
                comment.vote = vote
                switch voteValue {
                case .abuse:
                    AnalyticsReporter.reportEvent(AnalyticsEvents.Discussion.liked)
                    comment.abuseCount -= 1
                    comment.epicCount += 1
                case .epic:
                    AnalyticsReporter.reportEvent(AnalyticsEvents.Discussion.unliked)
                    comment.epicCount -= 1
                }
                self?.reloadViewData()
            }.catch { _ in
                self.displayErrorAlert()
            }
        } else {
            let vote = Vote(id: comment.vote.id, value: .epic)
            self.votesNetworkService.update(vote: vote).done { [weak self] vote in
                AnalyticsReporter.reportEvent(AnalyticsEvents.Discussion.liked)
                comment.vote = vote
                comment.epicCount += 1
                self?.reloadViewData()
            }.catch { _ in
                self.displayErrorAlert()
            }
        }
    }

    func abuseComment(_ comment: Comment) {
        if let voteValue = comment.vote.value {
            let vote = Vote(id: comment.vote.id, value: .abuse)
            self.votesNetworkService.update(vote: vote).done { [weak self] vote in
                comment.vote = vote
                switch voteValue {
                case .abuse:
                    break
                case .epic:
                    AnalyticsReporter.reportEvent(AnalyticsEvents.Discussion.abused)
                    comment.epicCount -= 1
                    comment.abuseCount += 1
                    self?.reloadViewData()
                }
            }.catch { _ in
                self.displayErrorAlert()
            }
        } else {
            let vote = Vote(id: comment.vote.id, value: .abuse)
            self.votesNetworkService.update(vote: vote).done { vote in
                AnalyticsReporter.reportEvent(AnalyticsEvents.Discussion.abused, parameters: nil)
                comment.vote = vote
                comment.abuseCount += 1
            }.catch { _ in
                self.displayErrorAlert()
            }
        }
    }

    private func getNextDiscussionsIDsToLoad() -> [Int] {
        let startIndex = self.discussionsIDs.loaded.count
        let offset = min(self.discussionsIDs.leftToLoad, DiscussionsPresenter.discussionsLoadingInterval)
        return Array(self.discussionsIDs.all[startIndex..<startIndex + offset])
    }

    private func getNextReplyIDsToLoad(discussion: Comment) -> [Int] {
        let loadedRepliesIDs = Set(replies.loaded[discussion.id, default: []].map { $0.id })
        var idsToLoad = [Int]()

        for replyID in discussion.repliesIDs {
            if !loadedRepliesIDs.contains(replyID) {
                idsToLoad.append(replyID)
                if idsToLoad.count == DiscussionsPresenter.repliesLoadingInterval {
                    return idsToLoad
                }
            }
        }

        return idsToLoad
    }

    private func fetchComments(ids: [Comment.IdType]) -> Promise<Void> {
        return self.commentsNetworkService.fetch(ids: ids).done(on: .global(qos: .userInitiated)) { comments in
            let fetchedDiscussions = comments.filter { $0.parentID == nil }

            self.discussionsIDs.loaded += fetchedDiscussions.map { $0.id }
            self.discussions += fetchedDiscussions.reordered(order: ids, transform: { $0.id })
            self.discussions.sort { $0.time.compare($1.time) == .orderedDescending }

            var commentsIDsWithReplies = Set<Comment.IdType>()
            for comment in comments {
                guard let parentID = comment.parentID else {
                    continue
                }

                self.replies.loaded[parentID, default: []] += [comment]
                commentsIDsWithReplies.insert(parentID)
            }

            for id in commentsIDsWithReplies {
                guard let index = self.discussions.firstIndex(where: { $0.id == id }) else {
                    continue
                }

                self.replies.loaded[id] = self.replies.loaded[id, default: []]
                    .reordered(order: self.discussions[index].repliesIDs, transform: { $0.id })
                    .sorted { $0.time.compare($1.time) == .orderedAscending }
            }
        }
    }

    private func reloadViewData() {
        var viewData = [DiscussionsViewData]()

        for discussion in self.discussions {
            viewData.append(DiscussionsViewData(comment: discussion, separatorType: .small))

            for reply in self.replies.loaded[discussion.id, default: []] {
                viewData.append(DiscussionsViewData(comment: reply, separatorType: .small))
            }

            let leftToLoad = self.replies.leftToLoad(discussion)
            if leftToLoad > 0 {
                viewData.append(
                    DiscussionsViewData(
                        fetchRepliesFor: discussion,
                        showMoreText: "\(NSLocalizedString("ShowMoreReplies", comment: "")) (\(leftToLoad))",
                        isUpdating: self.discussionsFetchingRepliesIds.contains(discussion.id)
                    )
                )
            } else {
                viewData[viewData.count - 1].separatorType = .big
            }
        }

        let leftToLoad = self.discussionsIDs.leftToLoad
        if leftToLoad > 0 {
            viewData.append(
                DiscussionsViewData(
                    needFetchDiscussions: true,
                    showMoreText: "\(NSLocalizedString("ShowMoreDiscussions", comment: "")) (\(leftToLoad))",
                    isUpdating: self.isFetchingMoreDiscussions
                )
            )
        }

        self.view?.setViewData(viewData)
    }

    private func displayErrorAlert(
        title: String = NSLocalizedString("Error", comment: ""),
        message: String = NSLocalizedString("ErrorMessage", comment: "")
    ) {
        self.view?.displayAlert(title: title, message: message)
    }

    private func incrementStepDiscussionsCount() {
        self.stepsPersistenceService.fetch(ids: [self.stepID]).done { steps in
            if let step = steps.first {
                step.discussionsCount? += 1
            }
            CoreDataHelper.instance.save()
        }.cauterize()
    }

    // MARK: Inner structs

    private struct DiscussionsIDs {
        var all: [Comment.IdType] = []
        var loaded: [Comment.IdType] = []

        var leftToLoad: Int {
            return self.all.count - self.loaded.count
        }
    }

    private struct Replies {
        var loaded: [Comment.IdType: [Comment]] = [:]

        func leftToLoad(_ comment: Comment) -> Int {
            if let loadedCount = self.loaded[comment.id]?.count {
                return comment.repliesIDs.count - loadedCount
            } else {
                return comment.repliesIDs.count
            }
        }
    }
}