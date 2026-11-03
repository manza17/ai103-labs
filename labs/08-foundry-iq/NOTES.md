# Lab 08: Agente con Foundry IQ (base de conocimiento)

**Módulo de Microsoft Learn:** [Crear agentes de IA mejorados con conocimiento con Foundry IQ](https://learn.microsoft.com/es-es/training/modules/introduction-foundry-iq/)
**Instrucciones:** [04-integrate-agent-with-foundry-iq.md](https://github.com/MicrosoftLearning/mslearn-ai-agents/blob/main/Instructions/Exercises/04-integrate-agent-with-foundry-iq.md)
**Fecha:** 03/11/2026
**Grupo de recursos:** `rg-ai103-lab08` (Foundry en East US 2; Search y Storage en Central US)

## Checklist Disciplinado

- [x] Grupo de recursos propio del lab (`rg-ai103-lab08`)
- [x] Modelos **mini** en **Global Standard**: `gpt-5-mini` (agente y base de conocimiento; el lab pedía `gpt-5`) + `text-embedding-3-small`. Desplegados **antes** de crear el agente, para que el portal no despliegue `gpt-5` solo.
- [x] Azure AI Search en tier **Free**, creado por CLI con `--sku free` explícito (el formulario de Foundry no mostraba el tier)
- [x] Agente con **basic setup**; sin Web search
- [x] Plan gratuito de *agentic retrieval* (no activé el plan estándar)
- [x] `scripts\cleanup.ps1` ejecutado y grupo verificado como borrado (el recurso de Foundry quedó en soft-delete, sin costo)

## Archivos

- `agent_client.py`: cliente del agente `product-expert-agent`. Usa la conversación del servicio y un bucle que pide aprobación (yes/no) por cada `mcp_approval_request` de la herramienta de Foundry IQ.
- `data/`: los 3 PDF de productos de Contoso (mochilas, accesorios de camping y carpas).
- `.env.example`: copiar a `.env` y completar `PROJECT_ENDPOINT` (el `.env` no se sube).

## Qué hice

1. Proyecto `agent-iq-lab` en el New Foundry (East US 2). Modelos `gpt-5-mini` y `text-embedding-3-small` en Global Standard.
2. Agente `product-expert-agent` en el portal con `gpt-5-mini` e instrucciones de "buscar SIEMPRE en la base de conocimiento y citar".
3. AI Search: East US 2 sin capacidad → creado por CLI en **Central US** (Free). Storage LRS en la **misma región**, contenedor `contosoproducts` con los 3 PDF, Search con `aadOrApiKey` ("Both"). Todo por CLI.
4. Conexión Foundry → Search con **API Key**.
5. Base de conocimiento `kb-contosoproduct` (Minimal, Extractive data, `gpt-5-mini`) + fuente Blob `ks-contosoproduct` (extracción minimal, `text-embedding-3-small`). Indexer: success, 3 procesados, 0 errores.
6. Playground: la pregunta de carpas respondió con 9 citas a los PDF (13,829 tokens). La del clima en Bariloche no buscó, pero ofreció datos "de su conocimiento" (fuga de alcance).
7. Foundry Toolkit (VS Code): en la herramienta `kb-kb-contosoproduct-nzbu8` → **Never auto-approve tools** → Deploy.
8. `agent_client.py`:
   - Pidió aprobación de `knowledge_base_retrieve` con 3 `query_variants` por pregunta.
   - La pregunta de seguimiento ("How much do those items cost?") mantuvo el contexto.
   - Al negar la aprobación **en una conversación nueva**, el agente pidió permiso para buscar.
   - Al negarla **con la búsqueda ya hecha antes en la misma conversación**, respondió igual con los datos del contexto, sin avisar.

## Lo que aprendí para el examen

- **Los 4 componentes en Azure AI Search** (Foundry IQ los crea solo con la fuente Blob):

  | Componente | Rol |
  |---|---|
  | Data source | Dónde están los datos |
  | Indexer | Orquesta: lee, pasa por el skillset y escribe; programa y detecta cambios |
  | Skillset | **Transforma:** Text Split (*chunking*) + Embedding skill (*embeddings*) |
  | Index | **Guarda** texto y vectores; su *vectorizer* vectoriza la **pregunta** al consultar |

  Resumen: el indexer mueve, el skillset transforma y el index guarda.
- **Base de conocimiento vs fuente:** la *knowledge base* (modelo de chat, reasoning effort, output mode, retrieval instructions) agrupa una o más *knowledge sources* (Blob, índice, SharePoint, web, OneLake).
- **Retrieval reasoning effort:** *Minimal* = consulta directa sin planificación del modelo (más barato); *Low/Medium* = el modelo planifica subconsultas.
- **Output mode:** *Extractive data* = devuelve fragmentos para que el agente redacte; *Answer synthesis* = la base de conocimiento redacta con citas.
- **Foundry IQ llega al agente por MCP** (`mcp_list_tools`, herramienta `knowledge_base_retrieve`). Por eso la aprobación es un `mcp_approval_request` y se responde con `mcp_approval_response`, igual que en el lab 07.
- **Desde el portal, la herramienta de Foundry IQ NO pide aprobación por defecto.** Para exigirla: Foundry Toolkit → Configure → *Never auto-approve tools*.
- **`query_variants` = *query expansion*:** con *Minimal*, las variantes las arma el modelo del agente como argumento de la herramienta.
- **RAG *augment*:** los fragmentos recuperados entran como texto al input (13,829 tokens en una sola pregunta).
- **Negar la herramienta no borra el contexto:** si los fragmentos ya están en la conversación, el agente los reutiliza sin avisar. Para evitarlo, decirlo en las instrucciones.
- **Pruebas out-of-KB:** las instrucciones tienen que incluir un *fallback* explícito fuera del dominio. Si no, el modelo completa con su conocimiento general. En producción se mide con el *fallback rate*.
- **API Key vs Managed Identity** en la conexión: en un lab, API Key; en producción, Managed Identity (con roles RBAC sobre el Search).
- **Search Free:** uno solo por suscripción, con un límite de 3 índices y 3 indexers.

## Problemas y cómo los resolví

- **El portal despliega `gpt-5` al crear el agente** → desplegué antes los modelos mini y el agente los tomó.
- **AI Search sin capacidad en East US 2**, y el formulario de Foundry no mostraba el tier → `az search service create --sku free` probando regiones (Central US). Storage en la misma región.
- **Faltaba la base de conocimiento** (la fuente, el índice y el indexer existían, pero no se había hecho *Save knowledge base*) → lo diagnostiqué con REST (`/knowledgesources`, `/knowledgebases`, `/indexes`) y creé solo la base, sin duplicar la fuente.
- **No encontraba el Foundry Toolkit** → está en la barra lateral de VS Code (a veces aparece como AI Toolkit).
