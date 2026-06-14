import Foundation

enum AgentStatus: String, Equatable, Codable {
    case working
    case waiting
    case idle

    var priority: Int {
        switch self {
        case .working: 2
        case .waiting: 1
        case .idle: 0
        }
    }
}

@MainActor
@Observable
final class AgentStatusStore {
    static let shared = AgentStatusStore()

    struct Entry: Equatable {
        let worktreeID: UUID
        let projectID: UUID
        let paneID: UUID
        let providerID: String
        let status: AgentStatus
        let updatedAt: Date

        func withStatus(_ newStatus: AgentStatus) -> Entry {
            Entry(
                worktreeID: worktreeID,
                projectID: projectID,
                paneID: paneID,
                providerID: providerID,
                status: newStatus,
                updatedAt: Date()
            )
        }
    }

    private(set) var entries: [UUID: Entry] = [:]
    private var panes: [UUID: Entry] = [:]

    private init() {}

    func update(paneID: UUID, providerID: String, status: AgentStatus, appState: AppState) {
        guard let worktreeStore = NotificationStore.shared.worktreeStore,
              let context = NotificationNavigator.resolveContext(
                  for: paneID,
                  appState: appState,
                  worktreeStore: worktreeStore
              )
        else { return }

        panes[paneID] = Entry(
            worktreeID: context.worktreeID,
            projectID: context.projectID,
            paneID: paneID,
            providerID: providerID,
            status: status,
            updatedAt: Date()
        )
        recompute(worktreeID: context.worktreeID)
    }

    func removePane(_ paneID: UUID) {
        guard let removed = panes.removeValue(forKey: paneID) else { return }
        recompute(worktreeID: removed.worktreeID)
    }

    nonisolated static func winningEntry(among candidates: [Entry]) -> Entry? {
        candidates.max { lhs, rhs in
            lhs.status.priority != rhs.status.priority
                ? lhs.status.priority < rhs.status.priority
                : lhs.updatedAt < rhs.updatedAt
        }
    }

    private func recompute(worktreeID: UUID) {
        let candidates = panes.values.filter { $0.worktreeID == worktreeID }

        guard let aggregate = Self.winningEntry(among: candidates) else {
            if let previous = entries.removeValue(forKey: worktreeID) {
                broadcast(previous.withStatus(.idle))
            }
            return
        }

        if let existing = entries[worktreeID],
           existing.status == aggregate.status,
           existing.paneID == aggregate.paneID,
           existing.providerID == aggregate.providerID
        {
            return
        }

        entries[worktreeID] = aggregate
        broadcast(aggregate)
    }

    private func broadcast(_ entry: Entry) {
        NotificationSocketServer.shared.broadcast(event: ExtensionEvent(
            name: ExtensionEventName.agentStatus,
            payload: Self.eventPayload(
                worktreeID: entry.worktreeID,
                projectID: entry.projectID,
                paneID: entry.paneID,
                providerID: entry.providerID,
                status: entry.status
            )
        ))
    }

    nonisolated static func eventPayload(
        worktreeID: UUID,
        projectID: UUID,
        paneID: UUID,
        providerID: String,
        status: AgentStatus
    ) -> [String: String] {
        [
            "worktreeID": worktreeID.uuidString,
            "projectID": projectID.uuidString,
            "paneID": paneID.uuidString,
            "providerID": providerID,
            "status": status.rawValue,
        ]
    }
}
