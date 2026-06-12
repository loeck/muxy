# Worktrees

`muxy.worktrees` lists and switches the git worktrees of a project. Reads require
`worktrees:read`; switching requires `worktrees:write`.

```js
const worktrees = await muxy.worktrees.list(projectIdOrNameOrPath);
//   [{ id, name, path, branch, isActive }]
await muxy.worktrees.switchTo(idOrNameOrPath, projectIdOrNameOrPath);
await muxy.worktrees.refresh(projectIdOrNameOrPath);   // rescan from git
```

`list` defaults to the active project when no project is given.

## `isActive`

`isActive` is **scoped to the listed project**: it marks that project's currently selected
worktree, independent of whether the project is the globally active one. Use
`muxy.projects.list()` (`ProjectInfo.isActive`) to know which project is globally active.

This lets an extension show each project's active worktree (e.g. a sidebar listing several
projects) without it depending on which project currently has focus.
