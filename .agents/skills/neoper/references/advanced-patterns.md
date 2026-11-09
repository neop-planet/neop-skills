# Advanced Module Patterns

Patterns for modules that go beyond standard CRUD — visual builders, multi-step wizards, and complex state.

---

## 1. Multi-Step Form (Wizard) Patterns

Used by: **Broadcasts** (`useCreateBroadcastForm`, `useStep2Channel`, `useStep3Variables`, `useStep4Audience`), **Flow Builder** (`useCreateFlowForm`, `Step1BasicDetails`, `Step2OperationalSettings`, `Step4FlowBuilder`)

### Architecture

```
composables/{module}/
  useCreateFlowForm.ts          ← Parent state manager (wizard orchestrator)
  useStep1BasicDetails.ts       ← Step 1 logic
  useStep2Channel.ts            ← Step 2 logic
  useStep3Variables.ts          ← Step 3 logic
  useStep4Audience.ts           ← Step 4 logic

components/{module}/create/
  steps/
    Step1BasicDetails.vue       ← Step 1 UI
    Step2OperationalSettings.vue
    Step4FlowBuilder.vue

views/admin/{module}/
  create/
    CreateFlowView.vue          ← Wizard container
```

### Key principles

- **Parent State Manager**: A composable (e.g., `useCreateFlowForm`) holds the **global state** for the entire wizard. Each step reads and writes to this shared state.
- **Isolated Steps**: Each step is a separate component + composable pair. The composable handles validation and data transformation for its step.
- **Lazy Validation**: Validate each step independently before allowing navigation to the next. Don't run all validations upfront.
- **Step Composables Receive Parent State**: Each `useStepX` composable receives the parent form data or a subset of it.

### Pattern

```ts
// useCreateBroadcastForm.ts — wizard orchestrator
export function useCreateBroadcastForm() {
  const currentStep = ref(1)
  const formData = reactive({
    // Step 1
    name: '',
    description: '',
    // Step 2
    channel_id: null,
    template_id: null,
    // Step 3
    variable_mappings: {},
    // Step 4
    audience_filters: {},
  })

  const canProceed = computed(() => {
    // validate current step
  })

  function nextStep() { if (canProceed.value) currentStep.value++ }
  function prevStep() { currentStep.value-- }

  return { currentStep, formData, canProceed, nextStep, prevStep }
}
```

---

## 2. Deeply Nested Component Structures

Used by: **Flow Builder** (`components/flow-builder/nodes/`, `inspector/`, `inspector/fields/`, `nodes/previews/`)

### Directory Organization

Organize by domain, not by file type:

```
components/flow-builder/
  FlowCanvas.vue                    ← Main canvas
  FlowSidebar.vue                   ← Left sidebar (node palette)
  FlowContextMenu.vue               ← Right-click menu
  FlowConnectMenu.vue               ← Connection menu
  FlowSimulatorSidebar.vue          ← Simulator panel
  PublishFlowDialog.vue             ← Publish confirmation
  ValidationSummaryDialog.vue       ← Validation errors
  flow-variants.ts                  ← Status variant config

  DynamicInspector.vue              ← Right-hand property panel
  inspector/
    FieldRenderer.vue               ← Renders fields dynamically
    VariableInput.vue               ← Variable autocomplete input
    VariableInputAutocomplete.vue
    fields/
      TemplateMappingRenderer.vue   ← Template-specific field
      MediaUploadRenderer.vue       ← Media upload field
      ComplexArrayFieldsRenderer.vue

  nodes/
    FlowNode.vue                    ← Generic node component
    previews/
      StartPreview.vue              ← Start node preview
      EndPreview.vue
      SendMessagePreview.vue

  create/
    steps/
      Step1BasicDetails.vue
      Step2OperationalSettings.vue
      Step4FlowBuilder.vue
```

### Key principles

- Each subdirectory represents a **domain** (nodes, inspector, previews)
- Components in subdirectories are **only used by their parent domain**
- The parent component (e.g., `FlowCanvas.vue`) delegates logic to a composable (e.g., `useFlowCanvas`)

---

## 3. Complex Shared State Management

Used by: **Flow Builder** (`useFlowCanvas`, `useDynamicInspector`, `useFlowNode`, `useFlowContextMenu`)

### State Singleton Pattern

Instead of Vuex/Pinia stores, use composables that return the **same reactive references** across the entire module. This is achieved by declaring state **outside** the function:

```ts
// composables/flow-builder/useFlowCanvas.ts

// State lives OUTSIDE the function — singleton across module
const nodes = ref<FlowNode[]>([])
const connections = ref<Connection[]>([])
const selectedNodeId = ref<string | null>(null)
const zoom = ref(1)

export function useFlowCanvas() {
  function addNode(node: FlowNode) {
    nodes.value.push(node)
  }
  function removeNode(id: string) {
    nodes.value = nodes.value.filter(n => n.id !== id)
  }
  function selectNode(id: string | null) {
    selectedNodeId.value = id
  }

  return { nodes, connections, selectedNodeId, zoom, addNode, removeNode, selectNode }
}
```

### Key principles

- **Module-scoped state** — don't use Pinia for module-specific data. Pinia is for app-wide state (auth, workspace).
- **State singletons** — declare `ref()` outside the composable function so every caller shares the same instance.
- **Clear mutations** — expose named functions (`addNode`, `updateNodeData`) instead of raw ref access.
- **Data model vs View model** — separate the JSON data (flow definition) from visual state (x/y positions, zoom).

### Real composable map (Flow Builder)

| Composable | Purpose |
|-----------|---------|
| `useFlowBuilder` | Top-level orchestrator |
| `useFlowCanvas` | Canvas state (nodes, connections, zoom) |
| `useFlowNode` | Individual node state & config |
| `useNodeConfigEntries` | Node configuration field definitions |
| `useDynamicInspector` | Right-hand property panel state |
| `useFieldRenderer` | Dynamic field rendering logic |
| `useVariableInput` | Variable autocomplete state |
| `useFlowContextMenu` | Right-click context menu |
| `useFlowDetailView` | Detail/view page state |
| `useFlowsTab` | List page (standard useTable pattern) |
| `useFlowsList` | Flows list data management |
| `useCreateFlowForm` | Multi-step wizard orchestrator |
| `useCreateFlowLoader` | Lazy-loading resources for creation |
| `useCreateFlowApi` | API calls for flow creation |
| `useFlowBuilderApi` | API calls for flow builder operations |
| `useOperationalSettings` | Step 2 operational settings logic |

---

## 4. Canvas / Visual Builder Patterns

Used by: **Flow Builder** (Vue Flow / VueFlow library)

### Key principles

- **Separate data from visuals** — the flow JSON (node types, connections, configs) is the source of truth. The canvas (x/y positions, zoom level) is derived view state.
- **Node registry** — maintain a registry of node types with their configs, preview components, and validation rules.
- **Connection validation** — validate connections before allowing them (e.g., can't connect output to itself).
- **Serialization** — provide `toJSON()` / `fromJSON()` methods to convert between canvas state and API format.

### Entity types pattern (from real codebase)

```
types/entities/
  flow-builder.ts           ← Core flow entity (list/detail)
  flow-builder-canvas.ts    ← Canvas-specific types (nodes, edges, positions)
  flow-builder-api.ts       ← API request/response shapes
  flow-node-configs.ts      ← Node configuration schemas
```
