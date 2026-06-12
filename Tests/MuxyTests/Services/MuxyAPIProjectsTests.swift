import Foundation
import Testing

@testable import Muxy

@Suite("MuxyAPI.Projects")
@MainActor
struct MuxyAPIProjectsTests {
    private func makeStore(_ projects: [Project]) -> ProjectStore {
        ProjectStore(persistence: ProjectPersistenceStub(initial: projects))
    }

    private func succeeded(_ result: Result<Void, APIError>) -> Bool {
        (try? result.get()) != nil
    }

    @Test("rename updates the project name")
    func renameSucceeds() {
        let project = Project(name: "Repo", path: "/tmp/repo")
        let store = makeStore([project])

        #expect(succeeded(MuxyAPI.Projects.rename(id: project.id.uuidString, name: "Renamed", projectStore: store)))
        #expect(store.storedProjects.first?.name == "Renamed")
    }

    @Test("rename fails for an unknown id")
    func renameUnknown() {
        let store = makeStore([])
        #expect(!succeeded(MuxyAPI.Projects.rename(id: UUID().uuidString, name: "X", projectStore: store)))
    }

    @Test("remove refuses the Home project")
    func removeHome() {
        let store = makeStore([])
        #expect(!succeeded(MuxyAPI.Projects.remove(id: Project.homeID.uuidString, projectStore: store)))
        #expect(store.projects.contains { $0.isHome })
    }

    @Test("setColor rejects an unknown color")
    func setColorInvalid() {
        let project = Project(name: "Repo", path: "/tmp/repo")
        let store = makeStore([project])
        #expect(!succeeded(MuxyAPI.Projects.setColor(id: project.id.uuidString, color: "octarine", projectStore: store)))
    }

    @Test("setColor accepts a palette color")
    func setColorValid() {
        let project = Project(name: "Repo", path: "/tmp/repo")
        let store = makeStore([project])

        #expect(succeeded(MuxyAPI.Projects.setColor(id: project.id.uuidString, color: "violet", projectStore: store)))
        #expect(store.storedProjects.first?.iconColor == "violet")
    }

    @Test("reorder applies the given order")
    func reorderApplies() {
        let a = Project(name: "A", path: "/tmp/a")
        let b = Project(name: "B", path: "/tmp/b")
        let store = makeStore([a, b])

        #expect(succeeded(MuxyAPI.Projects.reorder(ids: [b.id.uuidString, a.id.uuidString], projectStore: store)))
        #expect(store.storedProjects.map(\.name) == ["B", "A"])
    }
}

private final class ProjectPersistenceStub: ProjectPersisting {
    var projects: [Project]

    init(initial: [Project]) {
        projects = initial
    }

    func loadProjects() throws -> [Project] {
        projects
    }

    func saveProjects(_ projects: [Project]) throws {
        self.projects = projects
    }
}
