import Foundation
import Testing

@testable import Muxy

@Suite("MuxyAPI project management permissions")
struct MuxyAPIProjectManagementPermissionTests {
    @Test("management verbs require projects:write", arguments: [
        "projects.add",
        "projects.rename",
        "projects.setColor",
        "projects.setIcon",
        "projects.setLogo",
        "projects.reorder",
    ])
    func managementVerbsRequireProjectsWrite(verb: String) {
        #expect(MuxyAPI.Permissions.required(for: verb) == .projectsWrite)
        #expect(MuxyAPI.Permissions.verbNames.contains(verb))
    }

    @Test("projects.changed event requires projects:read")
    func changedEventRequiresProjectsRead() {
        #expect(MuxyAPI.Permissions.required(forEvent: ExtensionEventName.projectsChanged) == .projectsRead)
    }
}

@Suite("MuxyAPI project management routing")
@MainActor
struct MuxyAPIProjectManagementRoutingTests {
    @Test("rename mutates the resolved project and persists")
    func renameMutatesProject() {
        let project = Project(name: "Repo", path: "/tmp/muxy-rename-\(UUID().uuidString)")
        let store = ProjectStore(persistence: ProjectManagementPersistenceStub(initial: [project]))

        let result = MuxyAPI.Projects.rename(identifier: project.id.uuidString, name: "Renamed", projectStore: store)

        #expect(isSuccess(result))
        #expect(store.storedProjects.first { $0.id == project.id }?.name == "Renamed")
    }

    @Test("setColor / setIcon / setLogo mutate the resolved project")
    func metadataMutatesProject() {
        let project = Project(name: "Repo", path: "/tmp/muxy-meta-\(UUID().uuidString)")
        let store = ProjectStore(persistence: ProjectManagementPersistenceStub(initial: [project]))
        let id = project.id.uuidString

        #expect(isSuccess(MuxyAPI.Projects.setColor(identifier: id, color: "#E5484D", projectStore: store)))
        #expect(isSuccess(MuxyAPI.Projects.setIcon(identifier: id, icon: "star.fill", projectStore: store)))
        #expect(isSuccess(MuxyAPI.Projects.setLogo(identifier: id, logo: "logo-token", projectStore: store)))

        let stored = store.storedProjects.first { $0.id == project.id }
        #expect(stored?.iconColor == "#E5484D")
        #expect(stored?.icon == "star.fill")
        #expect(stored?.logo == "logo-token")
    }

    @Test("setColor with nil clears the color")
    func setColorNilClears() {
        var project = Project(name: "Repo", path: "/tmp/muxy-clear-\(UUID().uuidString)")
        project.iconColor = "#E5484D"
        let store = ProjectStore(persistence: ProjectManagementPersistenceStub(initial: [project]))

        #expect(isSuccess(MuxyAPI.Projects.setColor(identifier: project.id.uuidString, color: nil, projectStore: store)))
        #expect(store.storedProjects.first { $0.id == project.id }?.iconColor == nil)
    }

    @Test("reorder reindexes sortOrder to match the given identifier order")
    func reorderReindexes() {
        let first = Project(name: "A", path: "/tmp/a", sortOrder: 0)
        let second = Project(name: "B", path: "/tmp/b", sortOrder: 1)
        let third = Project(name: "C", path: "/tmp/c", sortOrder: 2)
        let store = ProjectStore(persistence: ProjectManagementPersistenceStub(initial: [first, second, third]))

        let result = MuxyAPI.Projects.reorder(
            identifiers: [third.id.uuidString, first.id.uuidString, second.id.uuidString],
            projectStore: store
        )

        #expect(isSuccess(result))
        #expect(store.storedProjects.map(\.id) == [third.id, first.id, second.id])
        #expect(store.storedProjects.map(\.sortOrder) == [0, 1, 2])
    }

    @Test("home project cannot be modified")
    func homeProjectRejected() {
        let store = ProjectStore(persistence: ProjectManagementPersistenceStub(initial: []))
        let result = MuxyAPI.Projects.rename(identifier: Project.homeID.uuidString, name: "Nope", projectStore: store)

        guard case .failure(.invalidArguments) = result else {
            Issue.record("expected invalidArguments for the home project")
            return
        }
    }

    @Test("unknown project is rejected")
    func unknownProjectRejected() {
        let store = ProjectStore(persistence: ProjectManagementPersistenceStub(initial: []))
        let result = MuxyAPI.Projects.setIcon(identifier: "does-not-exist", icon: "star", projectStore: store)

        guard case .failure(.projectNotFound) = result else {
            Issue.record("expected projectNotFound for an unknown identifier")
            return
        }
    }

    @Test("onProjectsChanged fires once per mutation")
    func changeCallbackFires() {
        let project = Project(name: "Repo", path: "/tmp/muxy-cb-\(UUID().uuidString)")
        let store = ProjectStore(persistence: ProjectManagementPersistenceStub(initial: [project]))
        var changes = 0
        store.onProjectsChanged = { changes += 1 }

        _ = MuxyAPI.Projects.rename(identifier: project.id.uuidString, name: "Renamed", projectStore: store)

        #expect(changes == 1)
    }

    @Test("add with an invalid path returns invalidArguments")
    func addInvalidPathRejected() {
        let env = ProjectManagementEnvironment()
        let result = MuxyAPI.Projects.add(
            path: "/path/that/does/not/exist-\(UUID().uuidString)",
            context: env.context
        )

        guard case .failure(.invalidArguments) = result else {
            Issue.record("expected invalidArguments for an invalid path")
            return
        }
    }

    private func isSuccess(_ result: Result<Void, APIError>) -> Bool {
        if case .success = result { return true }
        return false
    }
}

private final class ProjectManagementPersistenceStub: ProjectPersisting {
    var projects: [Project]
    init(initial: [Project]) { projects = initial }
    func loadProjects() throws -> [Project] { projects }
    func saveProjects(_ projects: [Project]) throws { self.projects = projects }
}

@MainActor
private struct ProjectManagementEnvironment {
    let appState: AppState
    let projectStore: ProjectStore
    let worktreeStore: WorktreeStore
    let projectGroupStore: ProjectGroupStore

    init() {
        projectStore = ProjectStore(persistence: ProjectManagementPersistenceStub(initial: []))
        worktreeStore = WorktreeStore(persistence: ProjectManagementWorktreePersistenceStub(), projects: [])
        appState = AppState(
            selectionStore: ProjectManagementSelectionStoreStub(),
            terminalViews: ProjectManagementTerminalViewRemovingStub(),
            workspacePersistence: ProjectManagementWorkspacePersistenceStub()
        )
        projectGroupStore = ProjectGroupStore(
            persistence: ProjectGroupPersistenceStub(),
            remoteDeviceStore: RemoteDeviceStore(persistence: InMemoryRemoteDevicePersistence()),
            workspaceContextSink: InMemoryWorkspaceContextSink()
        )
    }

    var context: MuxyAPI.Projects.Context {
        MuxyAPI.Projects.Context(
            extensionID: "test",
            appState: appState,
            projectStore: projectStore,
            worktreeStore: worktreeStore,
            projectGroupStore: projectGroupStore
        )
    }
}

private final class ProjectManagementWorktreePersistenceStub: WorktreePersisting {
    private var storage: [UUID: [Worktree]] = [:]
    func loadWorktrees(projectID: UUID) throws -> [Worktree] { storage[projectID] ?? [] }
    func saveWorktrees(_ worktrees: [Worktree], projectID: UUID) throws { storage[projectID] = worktrees }
    func removeWorktrees(projectID: UUID) throws { storage.removeValue(forKey: projectID) }
}

private final class ProjectManagementWorkspacePersistenceStub: WorkspacePersisting {
    func loadWorkspaces() throws -> [WorkspaceSnapshot] { [] }
    func saveWorkspaces(_: [WorkspaceSnapshot]) throws {}
}

@MainActor
private final class ProjectManagementSelectionStoreStub: ActiveProjectSelectionStoring {
    func loadActiveProjectID() -> UUID? { nil }
    func saveActiveProjectID(_: UUID?) {}
    func loadActiveWorktreeIDs() -> [UUID: UUID] { [:] }
    func saveActiveWorktreeIDs(_: [UUID: UUID]) {}
}

@MainActor
private final class ProjectManagementTerminalViewRemovingStub: TerminalViewRemoving {
    func removeView(for _: UUID) {}
    func needsConfirmQuit(for _: UUID) -> Bool { false }
}
