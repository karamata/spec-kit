---
description: "Implementation plan template for feature development"
scripts:
  sh: scripts/bash/update-agent-context.sh __AGENT__
  ps: scripts/powershell/update-agent-context.ps1 -AgentType __AGENT__
---

# Implementation Plan: [FEATURE]

**Branch**: `[###-feature-name]` | **Date**: [DATE] | **Spec**: [link]
**Input**: Feature specification from `/specs/[###-feature-name]/spec.md`

## Execution Flow (/plan command scope)
```
1. Load feature spec from Input path
   → If not found: ERROR "No feature spec at {path}"
2. Fill Technical Context (scan for NEEDS CLARIFICATION)
   → Detect Project Type from file system structure or context (web=frontend+backend, mobile=app+api)
   → Set Structure Decision based on project type
3. Fill the Constitution Check section based on the content of the constitution document.
4. Evaluate Constitution Check section below
   → If violations exist: Document in Complexity Tracking
   → If no justification possible: ERROR "Simplify approach first"
   → Update Progress Tracking: Initial Constitution Check
5. Execute Phase 0 → research.md
   → If NEEDS CLARIFICATION remain: ERROR "Resolve unknowns"
6. Execute Phase 1 → architecture.md, component-design.md, ui-ux-mockup.md (if frontend), error-handling.md, contracts/, data-model.md, quickstart.md, agent-specific template file (e.g., `CLAUDE.md` for Claude Code, `.github/copilot-instructions.md` for GitHub Copilot, `GEMINI.md` for Gemini CLI, `QWEN.md` for Qwen Code or `AGENTS.md` for opencode).
7. Re-evaluate Constitution Check section
   → If new violations: Refactor design, return to Phase 1
   → Update Progress Tracking: Post-Design Constitution Check
8. Plan Phase 2 → Describe task generation approach (DO NOT create tasks.md)
9. STOP - Ready for /tasks command
```

**IMPORTANT**: The /plan command STOPS at step 7. Phases 2-4 are executed by other commands:
- Phase 2: /tasks command creates tasks.md
- Phase 3-4: Implementation execution (manual or via tools)

## Summary
[Extract from feature spec: primary requirement + technical approach from research]

## Technical Context
**Language/Version**: [e.g., Python 3.11, Swift 5.9, Rust 1.75 or NEEDS CLARIFICATION]  
**Primary Dependencies**: [e.g., FastAPI, UIKit, LLVM or NEEDS CLARIFICATION]  
**Storage**: [if applicable, e.g., PostgreSQL, CoreData, files or N/A]  
**Testing**: [e.g., pytest, XCTest, cargo test or NEEDS CLARIFICATION]  
**Target Platform**: [e.g., Linux server, iOS 15+, WASM or NEEDS CLARIFICATION]
**Project Type**: [single/web/mobile - determines source structure]  
**Performance Goals**: [domain-specific, e.g., 1000 req/s, 10k lines/sec, 60 fps or NEEDS CLARIFICATION]  
**Constraints**: [domain-specific, e.g., <200ms p95, <100MB memory, offline-capable or NEEDS CLARIFICATION]  
**Scale/Scope**: [domain-specific, e.g., 10k users, 1M LOC, 50 screens or NEEDS CLARIFICATION]

## Constitution Check
*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

[Gates determined based on constitution file]

## Project Structure

### Documentation (this feature)
```
specs/[###-feature]/
├── plan.md              # This file (/plan command output)
├── research.md          # Phase 0 output (/plan command)
├── architecture.md      # Phase 1 output (/plan command) - Overall system architecture
├── component-design.md  # Phase 1 output (/plan command) - Component design with sequence diagrams
├── ui-ux-mockup.md     # Phase 1 output (/plan command) - UI/UX mockups (if frontend/extension/mobile)
├── error-handling.md    # Phase 1 output (/plan command) - Error handling strategy
├── data-model.md        # Phase 1 output (/plan command)
├── quickstart.md        # Phase 1 output (/plan command)
├── contracts/           # Phase 1 output (/plan command)
└── tasks.md             # Phase 2 output (/tasks command - NOT created by /plan)
```

### Source Code (repository root)
<!--
  ACTION REQUIRED: Replace the placeholder tree below with the concrete layout
  for this feature. Delete unused options and expand the chosen structure with
  real paths (e.g., apps/admin, packages/something). The delivered plan must
  not include Option labels.
-->
```
# [REMOVE IF UNUSED] Option 1: Single project (DEFAULT)
src/
├── models/
├── services/
├── cli/
└── lib/

tests/
├── contract/
├── integration/
└── unit/

# [REMOVE IF UNUSED] Option 2: Web application (when "frontend" + "backend" detected)
backend/
├── src/
│   ├── models/
│   ├── services/
│   └── api/
└── tests/

frontend/
├── src/
│   ├── components/
│   ├── pages/
│   └── services/
└── tests/

# [REMOVE IF UNUSED] Option 3: Mobile + API (when "iOS/Android" detected)
api/
└── [same as backend above]

ios/ or android/
└── [platform-specific structure: feature modules, UI flows, platform tests]
```

**Structure Decision**: [Document the selected structure and reference the real
directories captured above]

## Phase 0: Outline & Research
1. **Extract unknowns from Technical Context** above:
   - For each NEEDS CLARIFICATION → research task
   - For each dependency → best practices task
   - For each integration → patterns task

2. **Generate and dispatch research agents**:
   ```
   For each unknown in Technical Context:
     Task: "Research {unknown} for {feature context}"
   For each technology choice:
     Task: "Find best practices for {tech} in {domain}"
   ```

3. **Consolidate findings** in `research.md` using format:
   - Decision: [what was chosen]
   - Rationale: [why chosen]
   - Alternatives considered: [what else evaluated]

**Output**: research.md with all NEEDS CLARIFICATION resolved

## Phase 1: Contracts & Architecture (Contract-First)
*Prerequisites: research.md complete*

1. **Generate architecture overview** → `architecture.md`:
   - High-level system architecture for entire repository
   - Technology stack and framework choices
   - Deployment architecture and infrastructure
   - Integration patterns between components
   - **Include architecture diagram using Mermaid syntax**

2. **Generate component design** → `component-design.md`:
   - Detailed component breakdown for entire system
   - Component responsibilities and interfaces
   - Data flow between components
   - **Include sequential diagrams using Mermaid syntax**
   - Component interaction patterns

3. **Generate UI/UX mockup design** → `ui-ux-mockup.md` (if frontend/extension/mobile):
   - User interface mockups in simple markdown format
   - User experience flow diagrams
   - Screen layouts and navigation patterns
   - Visual design guidelines
   - **Skip this file if backend-only project**

4. **Generate error handling strategy** → `error-handling.md`:
   - Error handling patterns for both frontend and backend
   - Error classification and severity levels
   - Error propagation strategies
   - User-facing error messages and recovery flows
   - Logging and monitoring strategies

5. **Extract entities from feature spec** → `data-model.md`:
   - Entity name, fields, relationships
   - Validation rules from requirements
   - State transitions if applicable
   - **Generate ERD diagram using Mermaid syntax**
   - **Include TypeScript type definitions for entities**

6. **Generate API contracts** from functional requirements → `/contracts/`:
   - For each user action → endpoint
   - Use standard REST/GraphQL patterns
   - **Generate OpenAPI/GraphQL schema files**
   - **Generate TypeScript type definitions from schemas**
   - **Create mock server configurations (json-server, MSW)**
   - **Generate Pact contract templates for consumer-driven testing**

7. **Generate contract validation tools**:
   - **TypeScript type validation utilities**
   - **Schema validation middleware**
   - **Contract compliance checkers**
   - **Mock data generators based on schemas**

8. **Generate contract tests** from contracts:
   - One test file per endpoint
   - Assert request/response schemas
   - **Contract compliance tests (Pact/OpenAPI)**
   - **Type safety validation tests**
   - Tests must fail (no implementation yet)

9. **Extract test scenarios** from user stories:
   - Each story → integration test scenario
   - Quickstart test = story validation steps
   - **Contract-driven test scenarios**

10. **Update agent file incrementally** (O(1) operation):
    - Run `{SCRIPT}`
      **IMPORTANT**: Execute it exactly as specified above. Do not add or remove any arguments.
    - If exists: Add only NEW tech from current plan
    - Preserve manual additions between markers
    - Update recent changes (keep last 3)
    - Keep under 150 lines for token efficiency
    - Output to repository root

**Output**: architecture.md, component-design.md, ui-ux-mockup.md (if applicable), error-handling.md, data-model.md (with TypeScript types), /contracts/* (with types, mocks, Pact templates), contract validation tools, failing contract tests, quickstart.md, agent-specific file

## Phase 2: Task Planning Approach
*This section describes what the /tasks command will do - DO NOT execute during /plan*

## Task Generation Strategy (Hybrid: Contract-First + Bottom-Up)

The `/tasks` command will generate tasks.md using the **Hybrid Contract-First + Bottom-Up** approach by analyzing:
1. **Contract definitions** from `/contracts/` (OpenAPI specs, TypeScript types)
2. **Architecture dependencies** from `architecture.md`
3. **Component implementation order** from `component-design.md`
4. **UI/UX implementation priorities** from `ui-ux-mockup.md` (if applicable)
5. **Error handling implementation** from `error-handling.md`
6. **Data model dependencies** from `data-model.md`
7. **Test scenarios** from `quickstart.md`

**Hybrid Task Generation Strategy**:

**Phase 1: Contract-First Tasks**
- Load `.specify/templates/tasks-template.md` as base
- Generate contract validation tasks from `/contracts/`
- Each OpenAPI spec → contract test task [P]
- Each TypeScript type → type validation task [P]
- Mock server setup → infrastructure task [S]
- Pact contract tests → contract verification task [P]

**Phase 2: Bottom-Up Implementation (Parallel)**
- **Frontend Track** (guided by contracts):
  - Each UI component → implementation task [P]
  - Each API client → contract-compliant implementation [P]
  - Each form/validation → type-safe implementation [P]
- **Backend Track** (guided by contracts):
  - Each entity → model creation task [P]
  - Each service → contract-compliant implementation [P]
  - Each endpoint → OpenAPI spec compliance [P]

**Phase 3: Integration & Validation**
- Contract compliance verification
- End-to-end integration tests
- Performance validation

**Ordering Strategy**:
- **Contract-First**: Contracts → Mock servers → Contract tests
- **Parallel Bottom-Up**: Frontend & Backend tracks run simultaneously
- **Integration**: Contract validation → E2E tests → Performance
- Mark [P] for parallel execution, [S] for sequential dependencies

**Estimated Output**: 25-30 numbered, ordered tasks in tasks.md

**IMPORTANT**: This phase is executed by the /tasks command, NOT by /plan

## Phase 3+: Future Implementation
*These phases are beyond the scope of the /plan command*

**Phase 3**: Task execution (/tasks command creates tasks.md)  
**Phase 4**: Implementation (execute tasks.md following constitutional principles)  
**Phase 5**: Validation (run tests, execute quickstart.md, performance validation)

## Complexity Tracking
*Fill ONLY if Constitution Check has violations that must be justified*

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| [e.g., 4th project] | [current need] | [why 3 projects insufficient] |
| [e.g., Repository pattern] | [specific problem] | [why direct DB access insufficient] |


## Progress Tracking
*This checklist is updated during execution flow*

**Phase Status**:
- [ ] Phase 0: Research complete (/plan command)
- [ ] Phase 1: Design complete (/plan command)
- [ ] Phase 2: Task planning complete (/plan command - describe approach only)
- [ ] Phase 3: Tasks generated (/tasks command)
- [ ] Phase 4: Implementation complete
- [ ] Phase 5: Validation passed

**Gate Status**:
- [ ] Initial Constitution Check: PASS
- [ ] Post-Design Constitution Check: PASS
- [ ] All NEEDS CLARIFICATION resolved
- [ ] Complexity deviations documented

---
*Based on Constitution v1.0.0 - See `/memory/constitution.md`*
