# AI-103 Labs

Labs prácticos de la certificación **Microsoft AI-103: Azure AI Apps and Agents Developer Associate**, hechos sobre **Microsoft Foundry** con Python.

Cada lab vive en su propia carpeta dentro de `labs/`, con su entorno virtual aislado (Python 3.13) y sus notas.

## Requisitos

- [uv](https://docs.astral.sh/uv/) (maneja Python y los entornos virtuales)
- Python 3.13 instalado con uv: `uv python install 3.13`
- [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) con sesión iniciada: `az login`
- Una suscripción de Azure

## Regla de costos: escenario Disciplinado (obligatorio)

Un lab **no está terminado** hasta cumplir todo esto:

- [ ] Grupo de recursos **propio** del lab (ej. `rg-ai103-lab01`)
- [ ] Modelos **mini** con deployment **Global Standard** (nunca PTU, managed compute ni fine-tuning)
- [ ] Azure AI Search en tier **Free** (si el lab lo usa)
- [ ] Agentes con **basic setup** (nunca standard setup)
- [ ] Al terminar: `scripts\cleanup.ps1` y verificar que el grupo de recursos ya no existe

## Uso

Crear un lab nuevo:

```powershell
powershell -ExecutionPolicy Bypass -File scripts\new-lab.ps1 -Name 02-chat-tools
```

Activar el entorno de un lab:

```powershell
cd labs\01-chat-app
.venv\Scripts\activate
uv pip install -r requirements.txt
```

Limpiar al terminar (borra el grupo de recursos y verifica):

```powershell
powershell -ExecutionPolicy Bypass -File scripts\cleanup.ps1 -ResourceGroup rg-ai103-lab01
```

## Registro de labs

| # | Lab | Módulo de Microsoft Learn | Grupo de recursos | Limpieza verificada |
|---|-----|---------------------------|-------------------|---------------------|
| 01 | [Chat app](labs/01-chat-app) | [Desarrollar una app de chat de IA generativa con Foundry](https://learn.microsoft.com/es-es/training/modules/foundry-sdk/) | `rg-ai103-lab01` | ☐ |

## Seguridad

- Las claves y endpoints van en `.env`, que **no** se sube al repo (ver `.gitignore`). Usar `.env.example` como plantilla.
- Siempre que se pueda, autenticar con **Microsoft Entra ID** (`DefaultAzureCredential` + `az login`) en lugar de claves.
