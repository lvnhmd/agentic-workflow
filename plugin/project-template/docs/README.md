# Documentation

Docs lead, code follows (see the workflow contract, "Docs Lead, Code Follows").

| Folder          | What lives here                                                              | Changes how                               |
| --------------- | ---------------------------------------------------------------------------- | ----------------------------------------- |
| `architecture/` | **Current state**: context, containers, data, deployment. "What is true now". | Edited in the same PR as the behaviour     |
| `adr/`          | **Decision log**: why things are the way they are. Immutable once accepted.  | New ADR per decision; supersede, never edit |
| `development/`  | How we build: engineering standards, quality strategy, conventions.          | Edited when a standard changes             |
| `runbooks/`     | What to do when something breaks in production.                              | Added for each top incident type           |
