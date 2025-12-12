# CLAUDE.md

Guidance for Claude Code working on this Godot Engine 4.5 visibility control addon.


## Project Overview

A Godot Engine 4.5 addon providing visibility control components for node management.
Includes callback nodes, logic circuits, and animation transitions for declarative visibility control.


## Repository Structure

- `addons/config`: Main plugin code
- `addons/gdUnit4`: Testing framework, **DO NOT EDIT**
- `tests/`: Test files


## Documentation Resources

### Context7 (Godot/GDScript API)
Query latest Godot Engine and GDScript documentation:
```
1. mcp__context7__resolve-library-id: "Godot Engine" or "GDScript 4.5"
2. mcp__context7__get-library-docs: Use resolved library ID for detailed docs
```

### DeepWiki (gdUnit4 Framework)
Query gdUnit4 testing syntax and examples:
```
mcp__deepwiki__ask_question: repo="MikeSchulze/gdUnit4" + your question
```


## Development Workflow

### Writing Tests
1. **Check syntax**: Query gdUnit4 via deepwiki before implementation
2. **Write tests**: Use `/gdscript-test-skill` in `tests/`
3. **Run tests**: Execute via `/gdscript-test-skill`

### Writing Plugin Code
1. **Verify API**: Use context7 for latest GDScript/Godot syntax
2. **Edit files**: Work in `addons/config/`
3. **Validate**: Use `/gdscript-validate-skill` after changes
4. **Run tests**: Execute via `/gdscript-test-skill`

### File Operations
Use `/gdscript-file-manager-skill` for moving, renaming, or deleting GDScript files.


## Code Guidelines

- **YAGNI**: No unnecessary features, abstractions, or configuration
- **Type Hints**: Follow Godot 4.5 GDScript style guide


## PR Guidelines
- Repository: https://github.com/minami110/godot-config
- Target branch: origin/main
