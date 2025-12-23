---
description: Generate an actionable, dependency-ordered tasks.md for the feature based on available design artifacts.
handoffs: 
  - label: Analyze For Consistency
    agent: speckit.analyze
    prompt: Run a project analysis for consistency
    send: true
  - label: Implement Project
    agent: speckit.implement
    prompt: Start the implementation in phases
    send: true
scripts:
  sh: scripts/bash/check-prerequisites.sh --json
  ps: scripts/powershell/check-prerequisites.ps1 -Json
---

## User Input

```text
$ARGUMENTS
```

1. Run `{SCRIPT}` from repo root and parse FEATURE_DIR and AVAILABLE_DOCS list. All paths must be absolute.
2. Load and analyze available design documents:
   - Always read plan.md for tech stack and libraries
   - IF EXISTS: Read architecture.md for system architecture and infrastructure
   - IF EXISTS: Read component-design.md for component breakdown and dependencies
   - IF EXISTS: Read ui-ux-mockup.md for UI/UX implementation requirements
   - IF EXISTS: Read error-handling.md for error handling patterns
   - IF EXISTS: Read data-model.md for entities
   - IF EXISTS: Read contracts/ for API endpoints
   - IF EXISTS: Read research.md for technical decisions
   - IF EXISTS: Read quickstart.md for test scenarios

   Note: Not all projects have all documents. For example:
   - CLI tools might not have contracts/ or ui-ux-mockup.md
   - Simple libraries might not need data-model.md or component-design.md
   - Backend-only projects skip ui-ux-mockup.md
   - Generate tasks based on what's available

3. Generate tasks following the **Hybrid: Contract-First + Bottom-Up** approach:
   - Use `.specify/templates/tasks-template.md` as the base
   - Replace example tasks with actual tasks based on:

   **Phase 1: Contract-First Tasks**
   * **Contract setup**: OpenAPI specs, TypeScript types, mock servers
   * **Contract validation**: Pact tests, type checking, schema validation
   * **Contract testing [P]**: One per API contract, one per type definition

   **Phase 2: Bottom-Up Implementation (Parallel Tracks)**
   * **Frontend Track [P]** (guided by contracts):
     - UI components with type safety
     - API clients with contract compliance
     - Form validation with TypeScript types
   * **Backend Track [P]** (guided by contracts):
     - Data models with contract alignment
     - Services with OpenAPI compliance
     - Endpoints with schema validation

   **Phase 3: Integration & Validation**
   * **Integration tasks**: Contract compliance verification, E2E tests
   * **Validation tasks**: Performance testing, contract testing integration

4. Hybrid task generation rules:
   - Each OpenAPI spec → contract test task marked [P]
   - Each TypeScript type → type validation task marked [P]
   - Each mock server → infrastructure setup task marked [S]
   - Each architecture component → infrastructure setup task
   - Each component in component-design → contract-compliant implementation task [P]
   - Each UI screen/flow in ui-ux-mockup → type-safe UI implementation task [P]
   - Each error handling pattern → contract-aware error handling task
   - Each entity in data-model → contract-aligned model creation task [P]
   - Each endpoint → OpenAPI spec compliance task
   - Each user story → contract-based integration test marked [P]
   - Different files = can be parallel [P]
   - Same file = sequential (no [P])

5. Order tasks by **Hybrid Contract-First + Bottom-Up** dependencies:
   **Phase 1: Contract-First (Sequential)**
   - Contract setup (OpenAPI specs, TypeScript types)
   - Mock server infrastructure
   - Contract validation tools
   - Contract tests [P]

   **Phase 2: Bottom-Up Implementation (Parallel Tracks)**
   - **Frontend Track [P]**: UI components → API clients → Forms/Validation
   - **Backend Track [P]**: Models → Services → Endpoints
   - Both tracks guided by contracts from Phase 1

   **Phase 3: Integration & Validation (Sequential)**
   - Contract compliance verification
   - End-to-end integration tests
   - Performance validation
   - Polish and documentation

   **Cross-Phase Dependencies**:
   - Setup before everything
   - Contracts before implementation
   - Mock servers before parallel implementation
   - Core implementation before integration
   - Integration before validation

4. **Generate tasks.md**: Use `templates/tasks-template.md` as structure, fill with:
   - Correct feature name from plan.md
   - Phase 1: Setup tasks (project initialization)
   - Phase 2: Foundational tasks (blocking prerequisites for all user stories)
   - Phase 3+: One phase per user story (in priority order from spec.md)
   - Each phase includes: story goal, independent test criteria, tests (if requested), implementation tasks
   - Final Phase: Polish & cross-cutting concerns
   - All tasks must follow the strict checklist format (see Task Generation Rules below)
   - Clear file paths for each task
   - Dependencies section showing story completion order
   - Parallel execution examples per story
   - Implementation strategy section (MVP first, incremental delivery)

5. **Report**: Output path to generated tasks.md and summary:
   - Total task count
   - Task count per user story
   - Parallel opportunities identified
   - Independent test criteria for each story
   - Suggested MVP scope (typically just User Story 1)
   - Format validation: Confirm ALL tasks follow the checklist format (checkbox, ID, labels, file paths)

Context for task generation: {ARGS}

The tasks.md should be immediately executable - each task must be specific enough that an LLM can complete it without additional context.

## Task Generation Rules

**CRITICAL**: Tasks MUST be organized by user story to enable independent implementation and testing.

**Tests are OPTIONAL**: Only generate test tasks if explicitly requested in the feature specification or if user requests TDD approach.

### Checklist Format (REQUIRED)

Every task MUST strictly follow this format:

```text
- [ ] [TaskID] [P?] [Story?] Description with file path
```

**Format Components**:

1. **Checkbox**: ALWAYS start with `- [ ]` (markdown checkbox)
2. **Task ID**: Sequential number (T001, T002, T003...) in execution order
3. **[P] marker**: Include ONLY if task is parallelizable (different files, no dependencies on incomplete tasks)
4. **[Story] label**: REQUIRED for user story phase tasks only
   - Format: [US1], [US2], [US3], etc. (maps to user stories from spec.md)
   - Setup phase: NO story label
   - Foundational phase: NO story label  
   - User Story phases: MUST have story label
   - Polish phase: NO story label
5. **Description**: Clear action with exact file path

**Examples**:

- ✅ CORRECT: `- [ ] T001 Create project structure per implementation plan`
- ✅ CORRECT: `- [ ] T005 [P] Implement authentication middleware in src/middleware/auth.py`
- ✅ CORRECT: `- [ ] T012 [P] [US1] Create User model in src/models/user.py`
- ✅ CORRECT: `- [ ] T014 [US1] Implement UserService in src/services/user_service.py`
- ❌ WRONG: `- [ ] Create User model` (missing ID and Story label)
- ❌ WRONG: `T001 [US1] Create model` (missing checkbox)
- ❌ WRONG: `- [ ] [US1] Create User model` (missing Task ID)
- ❌ WRONG: `- [ ] T001 [US1] Create model` (missing file path)

### Task Organization

1. **From User Stories (spec.md)** - PRIMARY ORGANIZATION:
   - Each user story (P1, P2, P3...) gets its own phase
   - Map all related components to their story:
     - Models needed for that story
     - Services needed for that story
     - Endpoints/UI needed for that story
     - If tests requested: Tests specific to that story
   - Mark story dependencies (most stories should be independent)

2. **From Contracts**:
   - Map each contract/endpoint → to the user story it serves
   - If tests requested: Each contract → contract test task [P] before implementation in that story's phase

3. **From Data Model**:
   - Map each entity to the user story(ies) that need it
   - If entity serves multiple stories: Put in earliest story or Setup phase
   - Relationships → service layer tasks in appropriate story phase

4. **From Setup/Infrastructure**:
   - Shared infrastructure → Setup phase (Phase 1)
   - Foundational/blocking tasks → Foundational phase (Phase 2)
   - Story-specific setup → within that story's phase

### Phase Structure

- **Phase 1**: Setup (project initialization)
- **Phase 2**: Foundational (blocking prerequisites - MUST complete before user stories)
- **Phase 3+**: User Stories in priority order (P1, P2, P3...)
  - Within each story: Tests (if requested) → Models → Services → Endpoints → Integration
  - Each phase should be a complete, independently testable increment
- **Final Phase**: Polish & Cross-Cutting Concerns
