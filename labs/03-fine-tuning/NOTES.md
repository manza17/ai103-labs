# Lab 03: Ajuste fino (fine-tuning) de un modelo de lenguaje

**Módulo de Microsoft Learn:** [Optimizar el rendimiento de modelos de IA generativa](https://learn.microsoft.com/es-es/training/modules/optimize-generative-ai-model-performance/)
**Fecha:** 26/10/2026
**Estado:** lab oficial **no ejecutado** (decisión de costos). Práctica real de fine-tuning hecha antes, en *Generative AI for Beginners* (ver abajo).

## Decisión: por qué no ejecuté el lab oficial

El lab de Microsoft hace fine-tuning de **`gpt-5`** (modelo completo), lo despliega como **Developer** y estima 90 minutos o más de espera. Choca con la regla de costos del repo (escenario Disciplinado: modelos mini, nada de fine-tuning en labs de estudio).

Para el examen importa saber **cuándo** conviene el fine-tuning y **cómo** se arma, no esperar el entrenamiento. Por eso analicé el dataset y el flujo del lab, y me apoyo en un fine-tuning real que ya había hecho con un modelo más barato.

## Práctica real: fine-tuning de `gpt-4.1-nano` (Generative AI for Beginners, lección 18)

Código, datos y notas completas: [manza17/generative-ai-for-beginners · aprendizaje/leccion-18](https://github.com/manza17/generative-ai-for-beginners/tree/main/aprendizaje/leccion-18)

- **Modelo base:** `gpt-4.1-nano-2025-04-14`, el más barato con fine-tuning. Entrenamiento `developerTier` (capacidad ociosa, sin SLA).
- **Técnica:** SFT (supervisado) para enseñar un **formato**: responder sobre elementos químicos con un *limerick* de 5 versos separados por ` - `.
- **Datos:** 10 ejemplos de entrenamiento y 5 de validación en JSONL, con el mismo mensaje del sistema en todos. 8000 tokens facturados.
- **Flujo:** `files.create(purpose="fine-tune")` → esperar `processed` → `fine_tuning.jobs.create` → monitorear eventos → elegir checkpoint → desplegar → probar con la Responses API.
- **Métricas:** `train_loss` cayó a ~0 mientras `full_valid_loss` subió (2,10 en el step 50 → 2,68 en el 100): **sobreajuste** (*overfitting*) por pocos ejemplos.
- **Checkpoint elegido:** `ckpt-step-80`, el de menor `full_valid_loss` entre los disponibles (Azure guarda solo los 3 últimos).
- **Despliegue:** tipo **Developer** (sin cargo por hora; solo para evaluar, no para producción).
- **Resultado:** el modelo aprendió el **formato**, pero no garantiza la **calidad** (algún verso roto).

## Análisis del dataset del lab oficial (`travel-finetune.jsonl`)

- JSONL con una conversación por línea (`system` / `user` / `assistant`).
- El mismo mensaje del sistema en todos los ejemplos.
- Las respuestas del asistente tienen el estilo que se quiere enseñar (entusiasta y breve): SFT para **tono**.
- Solo 9 ejemplos de entrenamiento y 4 de validación, para que el lab sea rápido. Microsoft recomienda **cientos**.

## Lo que aprendí para el examen

- Escalera de optimización: **prompts → RAG → fine-tuning**. Simple primero; medir una línea base antes de optimizar.
- **RAG** cambia lo que el modelo **sabe**; **fine-tuning** cambia cómo **se comporta** (estilo, formato, prompts más cortos, destilación).
- Técnicas: **SFT** (pares pregunta → respuesta), **DPO** (respuesta preferida vs. no preferida), **RFT** (un calificador premia las mejores respuestas), **LoRA** (actualiza solo una parte de los parámetros).
- Datos en **JSONL**, cientos de ejemplos y el mismo mensaje del sistema en entrenamiento y producción.
- `train_loss` baja y `valid_loss` sube = sobreajuste → más datos, menos épocas o menor *learning rate*.
- Costos: entrenamiento + **hosting por hora** (excepto Developer). Un fine-tune nunca debería quedar desplegado en Standard para experimentar.
