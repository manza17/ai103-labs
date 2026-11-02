# Lab 06: Agente con herramientas personalizadas (function calling)

**Módulo de Microsoft Learn:** [Integrate custom tools into your agent](https://learn.microsoft.com/es-es/training/modules/build-agent-with-custom-tools/)
**Instrucciones:** [02-agent-custom-tools.md](https://github.com/MicrosoftLearning/mslearn-ai-agents/blob/main/Instructions/Exercises/02-agent-custom-tools.md)
**Fecha:** 02/11/2026
**Grupo de recursos:** `rg-ai103-lab06` (East US 2)

## Checklist Disciplinado

- [x] Grupo de recursos propio del lab (`rg-ai103-lab06`)
- [x] Modelo **mini** en **Global Standard** (`gpt-5-mini`; el lab pedía `gpt-5`)
- [x] AI Search en tier **Free** (no aplica)
- [x] Agente con **basic setup** (creado por código y borrado al salir con `delete_version`)
- [x] `scripts\cleanup.ps1` ejecutado y grupo verificado como borrado (el recurso quedó en soft-delete, sin costo)

## Archivos

- `agent.py`: crea el agente por código con 3 `FunctionTool` y procesa las llamadas a funciones.
- `functions.py`: funciones locales (eventos astronómicos, costo del telescopio, reporte).
- `data/`: eventos, tarifas y multiplicadores de prioridad.
- `.env.example`: copiar a `.env` y completar `PROJECT_ENDPOINT` (el `.env` no se sube). Los `report_*.txt` generados tampoco se suben.

## Qué hice

1. **Proyecto y modelo desde VS Code** (Foundry Toolkit): proyecto `astronomy-agent-project` en el recurso `ia103-lab06-resource` (el nombre con `ai103` estaba ocupado: los nombres son únicos a nivel global). `gpt-5-mini` en Global Standard.
2. Completé `next_visible_event` en `functions.py` y `agent.py`:
   - 3 `FunctionTool` con `name`, `description`, JSON Schema, `additionalProperties: False` y `strict=True`.
   - `agents.create_version(... PromptAgentDefinition ...)` para crear el agente por código.
   - Conversación, detección de `function_call`, ejecución local y `FunctionCallOutput` con el mismo `call_id`.
3. **Pruebas:**
   - Un solo prompt pidió dos datos → el agente llamó **dos funciones en el mismo turno** sin que las nombrara.
   - "Generate that information in a report" → `generate_observation_report` creó el archivo del reporte.
   - Tier inexistente (`ultra`) → la función devolvió un error en JSON y el agente se lo explicó al usuario.
   - `quit` → "Deleted agent." (`delete_version`).

## Lo que aprendí para el examen

- **Diseño declarativo:** el agente elige la función por su `name` y `description`; no hay código que decida cuándo llamarla.
- **Function calling = la ejecuta mi app.** Ciclo: `function_call` → ejecutar → `function_call_output` con el **mismo `call_id`** → volver a llamar al agente **en la misma conversación**. Con `previous_response_id`, el mensaje siguiente falla con *"No tool output found for function call"*.
- **`strict=True` asegura la forma** de los argumentos (campos requeridos, sin campos extra, tipos correctos; exige `additionalProperties: False`). **No valida reglas de negocio:** eso lo hace mi función (tier inexistente → error).
- **Las otras opciones de herramienta personalizada:**
  - **Azure Functions:** el agente escribe en una cola de entrada que dispara la función; el resultado vuelve por una cola de salida. Trigger = cuándo; binding = con qué datos.
  - **OpenAPI 3.0:** el servicio llama a la API. Autenticación anónima, por API key o con identidad administrada.
  - **Logic Apps:** low-code / no-code, con conectores.
- El agente **agrega conocimiento propio** a lo que devuelven las funciones (fechas pico, consejos). Para limitarlo, las instrucciones tienen que decir que responda solo con datos de las herramientas.
- El agente **ofrece acciones para las que no tiene herramienta** (reservar). Para ejecutarlas hace falta agregar la herramienta.
- El código del lab procesa **una sola ronda** de llamadas por turno. En producción se usa un bucle mientras la respuesta traiga `function_call`.
- **Grounding with Bing** (web search del playground de modelos): tiene costo adicional y **los datos salen del límite de cumplimiento de Azure**.

## Problemas y cómo los resolví

- **404 Resource not found** en `create_version` → `PROJECT_ENDPOINT` no era el del proyecto. El correcto es `https://<recurso>.services.ai.azure.com/api/projects/<proyecto>` (Overview del proyecto en el portal).
- **El playground del modelo trae Web search activado por defecto** → desactivado para no generar costo de Bing.
- **`az login` pidió elegir tenant y suscripción** → opción 1, la única suscripción (comportamiento de versiones nuevas de Azure CLI).
