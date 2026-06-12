# Projects

`muxy.projects` lists the projects shown in the sidebar and lets an extension switch between
them and manage them. Reads require `projects:read`; everything that mutates requires
`projects:write`.

## Read

```js
const projects = await muxy.projects.list();
//   [{ id, name, path, isActive }]
await muxy.projects.switchTo(idOrNameOrPath);   // selects the project (and its active worktree)
```

## Manage (`projects:write`)

```js
await muxy.projects.add("/path/to/repo");        // open a folder as a project (same as muxy://open)
await muxy.projects.rename(id, "New name");
await muxy.projects.remove(id);                  // the Home project cannot be removed
await muxy.projects.setColor(id, "violet");      // palette id (see below), or null to reset
await muxy.projects.setIcon(id, "star.fill");    // SF Symbol name, or null to clear
await muxy.projects.setWorktreesEnabled(id, true);
await muxy.projects.reorder([idA, idB, idC]);    // full ordered list of project ids
```

`id` is the `id` returned by `list()`. Unknown ids reject; the Home project rejects on any
mutation. `add` validates that the path is an existing directory.

### Colors

`setColor` accepts a palette id: `red`, `orange`, `amber`, `yellow`, `lime`, `green`, `teal`,
`cyan`, `blue`, `indigo`, `violet`, `pink` (or `null` to reset to the default). A hex value
matching a palette entry is also accepted.
