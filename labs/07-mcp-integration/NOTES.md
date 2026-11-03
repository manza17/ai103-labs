# Lab 07: Agentes con herramientas MCP (remoto y propio)

**Módulo de Microsoft Learn:** [Integrar herramientas de MCP con agentes de Azure AI](https://learn.microsoft.com/es-es/training/modules/connect-agent-to-mcp-tools/)
**Instrucciones:** [03-mcp-integration.md](https://github.com/MicrosoftLearning/mslearn-ai-agents/blob/main/Instructions/Exercises/03-mcp-integration.md)
**Fecha:** 03/11/2026
**Grupo de recursos:** `rg-ai103-lab07` (East US 2)

## Checklist Disciplinado

- [x] Grupo de recursos propio del lab (`rg-ai103-lab07`)
- [x] Modelo **mini** en **Global Standard** (`gpt-5-mini`; el lab pedía `gpt-5` con 150K TPM)
- [x] AI Search en tier **Free** (no aplica)
- [x] Agentes con **basic setup** (creados por código y borrados al salir con `delete_version`)
- [x] `scripts\cleanup.ps1` ejecutado y grupo verificado como borrado (el recurso quedó en soft-delete, sin costo)

## Archivos

- `agent.py`: parte A. Agente con `MCPTool` conectado al servidor MCP remoto de Microsoft Learn. Cambios míos: aprobación humana por consola (s/n) y `allowed_tools`.
- `server.py`: parte B. Servidor MCP propio, `FastMCP(name="Inventory")`, con `get_inventory_levels` y `get_weekly_sales`.
- `client.py`: parte B. Cliente MCP que levanta el servidor por stdio, descubre las herramientas y las registra como `FunctionTool`.
- `.env.example`: copiar a `.env` y completar `PROJECT_ENDPOINT` (el `.env` no se sube).

## Qué hice

### Parte A: `MCPTool` remoto (Microsoft Learn)

1. `MCPTool(server_label="api-specs", server_url="https://learn.microsoft.com/api/mcp", require_approval="always")`.
2. Primera ejecución con aprobación **automática** (código del lab): 3 pedidos de `microsoft_docs_search`, aprobados por el código sin preguntarme.
3. Cambié el código para que **yo** apruebe cada pedido (s/n), viendo la herramienta y los argumentos:
   - El agente usó 3 herramientas que **nunca definí**: `microsoft_docs_search`, `microsoft_code_sample_search` y `microsoft_docs_fetch` (descubrimiento dinámico).
   - Aprobé la primera y rechacé las otras dos: el agente respondió con lo que tenía, **sin avisar** que le faltaba información.
4. Agregué `allowed_tools=["microsoft_docs_search"]`: solo aparecieron pedidos de esa herramienta.

### Parte B: servidor y cliente MCP propios

1. `server.py`: `FastMCP` + `@mcp.tool()` en las dos funciones + `mcp.run(show_banner=False)`.
2. `client.py`: `stdio_client` + `ClientSession` + `initialize()` → `list_tools()` → función async con `call_tool()` → `FunctionTool` → agente `inventory-agent`.
3. **Pruebas:**
   - Inventario → llamó a `get_inventory_levels`.
   - Qué reponer → llamó **solo** a `get_weekly_sales`: el stock ya estaba en la conversación. Resultado: Moisturizer, Shampoo, Skin Serum.
   - Qué liquidar → **ninguna llamada**: ya tenía los dos datos. Resultado: Body Spray, Cleanser.

## Lo que aprendí para el examen

- **`require_approval="always"` no aprueba una persona: la aprobación le llega a mi app** (`mcp_approval_request`). El *human-in-the-loop* hay que programarlo. Se responde con `mcp_approval_response` + `approval_request_id` + `approve`, en un bucle porque puede haber varios pedidos.
- **`allowed_tools` filtra antes:** las herramientas no permitidas **no se exponen al modelo** y nunca llegan a la aprobación. Orden: `allowed_tools` (qué existe) → `require_approval` (si cada uso necesita aprobación).
- **Si se rechaza una herramienta, el agente sigue sin avisar.** Para evitarlo, decirlo en las instrucciones.
- **`MCPTool` (remoto)** = el servicio habla con el servidor, sin sesión ni envoltorios. **Cliente propio (local, stdio)** = mi app descubre (`list_tools`), envuelve (`call_tool`) y registra como `FunctionTool`; mi app ejecuta.
- **FastMCP** genera la definición desde la función: el nombre de la herramienta = el nombre de la función; la descripción = el docstring; los tipos = los type hints.
- **`show_banner=False`**: con stdio, cualquier texto extra en stdout corrompe el protocolo.
- **El estado de la conversación evita llamadas repetidas** (reutiliza resultados), con el riesgo de usar datos viejos si cambian entre turnos.
- El servidor MCP de Learn trae **documentación actual**: los flags de `az containerapp create` (`--system-assigned`, `--user-assigned`) estaban más actualizados que la salida de ejemplo del lab.

## Problemas y cómo los resolví

- **`agent.py` apareció vacío** después de que se escribiera desde el chat: se volvió a escribir y se verificó el tamaño en disco. Desde entonces, cada escritura se verifica.
- **Errores en el código del lab** (`client.py`): `input_list` se creaba una sola vez (reenviaba salidas viejas) y las salidas se devolvían con `previous_response_id` (el mensaje siguiente puede fallar con *"No tool output found"*). Corregido: lista nueva en cada turno y salidas a la misma conversación.
