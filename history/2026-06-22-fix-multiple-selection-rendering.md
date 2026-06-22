# Log: 2026-06-22
## Tasks Accomplished
- Fixed an issue where selecting both a parent and its children would cause duplicated elements in the generated code and preview. 
- Fixed an issue where selecting multiple sibling elements would only render the first one when the code was run (because they were returned as multiple values, which React/Roact and other frameworks process poorly).

## Architectural Decisions & Bug Fixes
- **App.luau & PreviewTab.luau**: Added a filtering logic inside `updateCode` and `PreviewTab` component. The filter loops over all selected instances and discards any instance whose parent (or ancestor) is also in the selection. This ensures that we only process the top-most selected roots, preventing the same item from being built inside its parent and as an independent root.
- **ReactConverter & RoactConverter**: Updated the code generation output when there are multiple root nodes. Instead of returning them as a tuple (e.g. `return Node1, Node2`), they are now wrapped inside a `<Fragment>` (`React.createElement(React.Fragment, ...)` or `Roact.createFragment(...)`).
- **Fusion2Converter, Fusion3Converter, LegacyConverter**: Updated code generation output for multiple root nodes to wrap them in an array/table.
- **VideConverter**: Fixed a bug where `vide.create` statements were missing the `return` statement when there was a single root, and updated the multi-root logic to wrap them in an array/table.
