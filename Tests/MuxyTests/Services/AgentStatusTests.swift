import Foundation
import Testing

@testable import Muxy

@Suite("AgentStatus")
struct AgentStatusTests {
    @Test("parses a well-formed agent_status message")
    func parsesValidMessage() {
        let paneID = UUID()
        let parsed = NotificationSocketServer.parseAgentStatusMessage("agent_status|claude_hook|\(paneID.uuidString)|working")
        #expect(parsed == NotificationSocketServer.AgentStatusMessage(
            socketType: "claude_hook",
            paneID: paneID,
            status: .working
        ))
    }

    @Test("parses every status value")
    func parsesEveryStatus() {
        let paneID = UUID()
        for status in [AgentStatus.working, .waiting, .idle] {
            let parsed = NotificationSocketServer.parseAgentStatusMessage(
                "agent_status|claude_hook|\(paneID.uuidString)|\(status.rawValue)"
            )
            #expect(parsed?.status == status)
        }
    }

    @Test("rejects an unknown status")
    func rejectsUnknownStatus() {
        let message = "agent_status|claude_hook|\(UUID().uuidString)|busy"
        #expect(NotificationSocketServer.parseAgentStatusMessage(message) == nil)
    }

    @Test("rejects a malformed pane id")
    func rejectsMalformedPaneID() {
        #expect(NotificationSocketServer.parseAgentStatusMessage("agent_status|claude_hook|not-a-uuid|idle") == nil)
    }

    @Test("rejects wrong arity and other heads")
    func rejectsWrongShape() {
        #expect(NotificationSocketServer.parseAgentStatusMessage("agent_status|claude_hook|\(UUID().uuidString)") == nil)
        #expect(NotificationSocketServer.parseAgentStatusMessage("claude_hook|\(UUID().uuidString)|Title|Body") == nil)
        #expect(NotificationSocketServer.parseAgentStatusMessage("agent_status||\(UUID().uuidString)|idle") == nil)
    }

    @Test("event payload carries the full status context")
    func eventPayloadKeys() {
        let worktreeID = UUID()
        let projectID = UUID()
        let paneID = UUID()
        let payload = AgentStatusStore.eventPayload(
            worktreeID: worktreeID,
            projectID: projectID,
            paneID: paneID,
            providerID: "claude",
            status: .waiting
        )
        #expect(payload["worktreeID"] == worktreeID.uuidString)
        #expect(payload["projectID"] == projectID.uuidString)
        #expect(payload["paneID"] == paneID.uuidString)
        #expect(payload["providerID"] == "claude")
        #expect(payload["status"] == "waiting")
    }
}
