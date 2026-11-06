# Lab 09: textos para copiar y pegar en el portal

## 1. Set variable → `Local.SupportTickets` (To value)

```
[
 "The API returns a 403 error when creating invoices, but our API key hasn't changed.",
 "Is there a way to export all invoices as a CSV?",
 "I was charged twice for the same invoice last Friday and my customer is also seeing two receipts. Can someone fix this?"]
```

## 2. For each

- Items: `Local.SupportTickets`
- Loop Value Variable: `CurrentTicket`

## 3. Triage-Agent: Details → Parameters → Text format → JSON Schema

```json
{
"name": "category_response",
"schema": {
    "type": "object",
    "properties": {
        "customer_issue": { "type": "string" },
        "category": { "type": "string" },
        "confidence": { "type": "number" }
    },
    "additionalProperties": false,
    "required": ["customer_issue", "category", "confidence"]
},
"strict": true
}
```

## 4. Triage-Agent: Instructions

```
Classify the user's problem description into exactly ONE category from the list below. Provide a confidence score from 0 to 1.

Billing
- Charges, refunds, duplicate payments
- Missing or incorrect payouts
- Subscription pricing or invoices being charged

Technical
- API errors, integrations, webhooks
- Platform bugs or unexpected behavior

General
- How-to questions
- Feature availability
- Data exports, reports, or UI navigation

Important rules
- Questions about exporting, viewing, or downloading invoices are General, not Billing
- Billing ONLY applies when money was charged, refunded, or paid incorrectly
```

Node settings:
- Input message: `Local.CurrentTicket`
- Save agent output message as: `TriageOutputText`
- Save the output json_object as: `TriageOutputJson`

## 5. If/Else #1 (confianza)

```
Local.TriageOutputJson.confidence > 0.6
```

Else → Deliver a message:

```
The support ticket classification has low confidence. Requesting more details about the issue: "{Local.CurrentTicket}"
```

## 6. If/Else #2 (categoría), dentro del If de #1

```
Local.TriageOutputJson.category = "Billing"
```

If → Deliver a message:

```
Escalate billing issue to human support team.
```

## 7. Resolution-Agent (Else de #2): Instructions

```
You are a customer support resolution assistant for ContosoPay, a B2B payments and invoicing platform.

Your task is to draft a clear, professional, and friendly support response based on the issue category and customer message.

Guidelines:
If the issue category is Technical:
Suggest 1–2 common troubleshooting steps at a high level.
Avoid asking for logs, credentials, or sensitive data.
Do not imply fault by the customer.

If the issue category is General:
Provide a concise, helpful explanation or guidance.
Keep the response under 5 sentences.

Tone:
Professional, calm, and supportive
Clear and concise
No emojis

Output:
Return only the drafted response text.
Do not include internal reasoning or analysis.
```

Node settings:
- Input message: `Local.TriageOutputText`
- Save agent output message as: `ResolutionOutputText`

## 8. Preview

```
Start processing support tickets.
```
