import Foundation

enum AgentStatus: String, Equatable, Codable {
    case working
    case waiting
    case idle
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
    }

    private(set) var entries: [UUID: Entry] = [:]

    private init() {}

    func update(paneID: UUID, providerID: String, status: AgentStatus, appState: AppState) {
        guard let worktreeStore = NotificationStore.shared.worktreeStore,
              let context = NotificationNavigator.resolveContext(
                  for: paneID,
                  appState: appState,
                  worktreeStore: worktreeStore
              )
        else { return }

        if let existing = entries[context.worktreeID],
           existing.status == status,
           existing.paneID == paneID,
           existing.providerID == providerID
        {
            return
        }

        let entry = Entry(
            worktreeID: context.worktreeID,
            projectID: context.projectID,
            paneID: paneID,
            providerID: providerID,
            status: status,
            updatedAt: Date()
        )
        entries[context.worktreeID] = entry
        broadcast(entry)
    }

    func removePane(_ paneID: UUID) {
        for (worktreeID, entry) in entries where entry.paneID == paneID {
            entries.removeValue(forKey: worktreeID)
            broadcast(Entry(
                worktreeID: entry.worktreeID,
                projectID: entry.projectID,
                paneID: entry.paneID,
                providerID: entry.providerID,
                status: .idle,
                updatedAt: Date()
            ))
        }
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
