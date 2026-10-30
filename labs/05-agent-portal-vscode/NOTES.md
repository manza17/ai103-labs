# Lab 05: Agente con el portal de Foundry y VS Code

**Módulo de Microsoft Learn:** [Develop AI agents with Microsoft Foundry and Visual Studio Code](https://learn.microsoft.com/en-us/training/modules/develop-ai-agents-azure-vs-code/)
**Instrucciones:** [01-build-agent-portal-and-vscode.md](https://github.com/MicrosoftLearning/mslearn-ai-agents/blob/main/Instructions/Exercises/01-build-agent-portal-and-vscode.md)
**Fecha:** 30/10/2026
**Grupo de recursos:** `rg-ai103-lab05` (East US 2)

## Checklist Disciplinado

- [x] Grupo de recursos propio del lab (`rg-ai103-lab05`)
- [x] Modelo **mini** en **Global Standard** (`gpt-5-mini`, versión 2025-08-07, 25K TPM). El proyecto nuevo no traía ningún modelo desplegado
- [x] AI Search en tier **Free** (no aplica: File Search usa un vector store administrado)
- [x] Agente con **basic setup** (Application Insights desactivado al crear el proyecto: el lab no lo usa)
- [x] `scripts\cleanup.ps1` ejecutado y grupo verificado como borrado (el recurso quedó en soft-delete, sin costo)

## Archivos

- `agent_with_functions.py`: cliente que usa el agente del portal (`AIProjectClient` + `conversations` + `agent_reference`).
- `data/IT_Policy.txt`: políticas de TI para File Search.
- `data/system_performance.csv`: métricas para Code Interpreter.
- `.env.example`: copiar a `.env` y completar `PROJECT_ENDPOINT` (el `.env` no se sube).

## Qué hice

1. **Proyecto** `itsupport-agent-project` en la experiencia New Foundry, con recurso `ai103-lab05-foundry`.
2. **Modelo:** el portal falló dos veces al desplegar ("An error occurred"). Lo desplegué con Azure CLI:
   `az cognitiveservices account deployment create ... --sku-name GlobalStandard --sku-capacity 25`.
3. **Agente** `it-support-agent` (prompt-based) en el portal con:
   - **File Search** con `IT_Policy.txt` (crea un vector store).
   - **Code Interpreter** con `system_performance.csv`.
4. **Pruebas en el playground del portal:**
   - Política de contraseñas: respondió con citas a `IT_Policy.txt`.
   - Análisis del CSV: **la primera vez no usó Code Interpreter** (usó File Search y dijo que no encontraba el CSV). Se resolvió agregando a las instrucciones cuándo usar cada herramienta.
   - Gráfico: lo generó, pero el link de descarga del playground no funcionó (archivo dentro del contenedor).
5. **VS Code (Foundry Toolkit):** iniciar sesión en Azure desde VS Code → **Set Foundry Project** → **Agents** → el mismo agente (v4) con las instrucciones y herramientas sincronizadas.
6. **App en Python:** chat con el agente desde código; el gráfico de memoria se descargó en `agent_outputs/`.

## Lo que aprendí para el examen

- **Cada herramienta necesita sus datos y una instrucción clara de cuándo usarla.** Si no, el agente elige mal (usó File Search para analizar un CSV). Buena práctica de la unidad 7.
- **Cada Save crea una versión nueva** del agente (llegó a v4); es lo que después se publica.
- **El código solo referencia al agente:** `responses.create(conversation=..., extra_body={"agent_reference": {"name": ..., "type": "agent_reference"}})`. Modelo, instrucciones y herramientas viven en Foundry.
- **El estado lo maneja el servicio:** `conversations.create()` + `conversations.items.create()`. No se reenvía el historial (distinto del endpoint publicado, que es sin estado).
- **Code Interpreter guarda los archivos en un sandbox** y los devuelve como `container_file_citation`. Para bajarlos: `containers.files.content.retrieve(file_id, container_id)`.
- La barra del playground muestra los **tipos de item** (`File search`, `Code interpreter`, `message`), la latencia, los tokens y el acceso a **Traces**.
- Los fragmentos recuperados por File Search **suman muchos tokens de entrada** (5.700 tokens para una pregunta corta).

## Problemas y cómo los resolví

- **El portal no desplegaba el modelo** (error genérico, dos intentos) → Azure CLI, que además muestra el error real si algo falla.
- **El agente no usaba Code Interpreter** → instrucción explícita de qué herramienta usar para cada tipo de pedido; guardar y abrir un chat nuevo.
- **El link del gráfico no funcionaba en el playground** → el archivo vive en el contenedor; el script lo descarga a `agent_outputs/`.
- **Foundry Toolkit no mostraba suscripciones** → VS Code necesita su propio inicio de sesión en Azure (el `az login` de la terminal no alcanza).
- **Nombres distintos al lab** en la extensión: *My Resources* (antes *Microsoft Foundry Resources*), *Set Foundry Project* (antes *Set Default Project*), *Agents* (antes *Prompt Agents*).
