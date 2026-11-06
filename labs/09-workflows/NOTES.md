# Lab 09: Workflow de triage de soporte (ContosoPay)

**Módulo de Microsoft Learn:** [Get started with building agent-driven workflows using Microsoft Foundry](https://learn.microsoft.com/en-us/training/modules/build-agent-workflows-microsoft-foundry/)
**Instrucciones:** [06-build-workflow-ms-foundry.md](https://github.com/MicrosoftLearning/mslearn-ai-agents/blob/main/Instructions/Exercises/06-build-workflow-ms-foundry.md)
**Fecha:** 06/11/2026
**Grupo de recursos:** `rg-ai103-lab09` (East US 2)

> ⚠️ **Aviso del portal (06/11/2026):** *"Microsoft Foundry is retiring workflows on December 1, 2026. Build new workflows with Microsoft Agent Framework, or migrate existing ones following the Migration guide."* El examen (18/12) se basa en el study guide, que hoy incluye workflows. Revisar si se actualiza antes de rendir.

## Checklist Disciplinado

- [x] Grupo de recursos propio del lab (`rg-ai103-lab09`)
- [x] Modelo **mini** en **Global Standard** (`gpt-5-mini`), desplegado **antes** de crear los agentes. El portal **no** desplegó `gpt-5`, pero sí `text-embedding-3-small` en **Standard** (regional) al crear el primer agente: lo borré por CLI y el workflow siguió funcionando.
- [x] AI Search en tier **Free** (no aplica)
- [x] Agentes con **basic setup** (Triage-Agent y Resolution-Agent, creados desde el workflow); reasoning effort **Low**
- [x] `scripts\cleanup.ps1` ejecutado y grupo verificado como borrado (el recurso quedó en soft-delete, sin costo)

## Archivos

- `portal-snippets.md`: todos los textos del portal (array de tickets, JSON schema, instrucciones de los agentes, condiciones Power Fx y mensajes).
- `workflow.py`: cliente que invoca el workflow por nombre con streaming. Agregado propio: imprime cada `response.output_item.done` para ver el avance nodo por nodo.
- `.env.example`: copiar a `.env` y completar `PROJECT_ENDPOINT` (el `.env` no se sube).

## Qué hice

1. Proyecto `workflow-lab` en el New Foundry y `gpt-5-mini` en Global Standard (desde el portal).
2. Workflow en blanco `ContosoPay-Customer-Support-Triage`, de patrón **sequential**:

   ```
   Set variable (Local.SupportTickets, 3 tickets)
   └─ For each (Local.CurrentTicket)
      └─ Triage-Agent (JSON schema: customer_issue, category, confidence)
         └─ If/Else #1: Local.TriageOutputJson.confidence > 0.6
            ├─ If → If/Else #2: Local.TriageOutputJson.category = "Billing"
            │  ├─ If → Send message "Escalate billing issue to human support team."
            │  └─ Else → Resolution-Agent (input Local.TriageOutputText)
            └─ Else → Send message de confianza baja con "{Local.CurrentTicket}"
   ```

3. **Preview:** Technical (0.92) → respuesta; General (0.93) → respuesta; Billing (0.98) → escalado.
4. **`workflow.py`:** mismo resultado (0.90 / 0.95 / 0.95). Se vieron los eventos `workflow_action` por nodo, más `reasoning` + `message` de cada agente.

## Lo que aprendí para el examen

- **El workflow es determinista; los agentes no.** El camino fue el mismo en el Preview y en el código, pero la confianza y la redacción cambiaron.
- **La salida estructurada es lo que habilita las condiciones:** `Local.TriageOutputJson.confidence` solo existe porque el Triage-Agent tiene **JSON schema** (Details → Parameters → Text format → JSON Schema, con `strict: true` y `additionalProperties: false`).
- **Node settings del nodo Invoke:**
  - *Input message* = qué variable recibe el agente.
  - *Save agent output message as* = el texto.
  - *Save output json_object/json_schema as* = el objeto, para leer campos.
- **Pasar contexto entre agentes:** el Resolution-Agent recibe `Local.TriageOutputText` (el JSON con la **categoría**) y no `Local.CurrentTicket`, porque sus instrucciones dependen de la categoría.
- **"Automatically include agent response…"** = la respuesta del agente aparece en la conversación externa (Preview, código). `print_workflow_output` lo necesita. Desactivarlo sirve para ocultar pasos internos.
- **"Allow multi-turn conversation"** = el nodo sigue conversando en bucle hasta que se cumple una condición Power Fx. Apagado para un clasificador de un solo turno.
- **Ubicación de los nodos:** el If/Else va **dentro del bucle** (antes del ↻). Afuera correría una sola vez.
- **Variables:** el desplegable crea `Local.<nombre>`; `Local.` es el ámbito, no parte del nombre. `{Local.CurrentTicket}` inserta una variable dentro de un mensaje.
- **Versionado:** cada **Save** creó una versión nueva (1 → 2 → 3 → …). No se guarda solo.
- **Desde código:** `extra_body={"agent_reference": {"name": <workflow>, "type": "agent_reference"}}`, igual que un agente. `workflow_action` + `action_id` = el **Node ID** del editor; `response.completed` = fin.
- **Reasoning effort:** Low para clasificar (High = más tokens de razonamiento, costo y latencia). Igual aparecen eventos `reasoning`.
- **Un workflow no fundamenta las respuestas:** el Resolution-Agent inventó un menú "Invoices → Export" y una API "List Invoices" (ContosoPay es ficticia). En producción le agregaría Foundry IQ o File Search.
- **Retiro de workflows (01/12/2026)** → el reemplazo es **Microsoft Agent Framework** (módulo siguiente).

## Problemas y cómo los resolví

- **No encontraba dónde nombrar la variable** → se escribe en el desplegable *Search for a variable or type a value*. Creó `Local.Var6` y lo renombré a `Local.SupportTickets`.
- **No encontraba "Parameters"** → es el ícono de sliders, sin texto, a la derecha del selector de modelo.
- **El portal desplegó `text-embedding-3-small` en Standard** al crear el agente → lo borré después de crear los dos agentes (`az cognitiveservices account deployment delete`).
- **Cambios sin guardar** → el botón Save resaltado y la versión sin cambiar avisan que falta guardar.
