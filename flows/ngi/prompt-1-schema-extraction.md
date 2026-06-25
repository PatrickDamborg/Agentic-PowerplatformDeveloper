# AI Builder Prompt 1 — Schema Extraction (PDF → JSON)

**Purpose:** Extract structured sales order data from a PDF document and return it as a JSON object (the "schema dump"). This is Stage 1 of the two-stage pipeline; the output feeds directly into Prompt 2.

**Where to create:** AI Builder portal → Prompts → New prompt  
**Input type:** File (PDF) — in the prompt instructions, insert an input, select **Image or document**, rename it to `file_content`  
**Model:** GPT-4o (recommended for document understanding) or any available model  
**Output format:** Set to **JSON** (top-right dropdown in the prompt builder) — this makes the flow's `Parse_Schema_Dump` step reliable  
**Input variable name:** `file_content` (must match the `body/inputs/file_content` parameter key in the flow JSON)

> **Note on `operationId`:** The flow JSON uses `"operationId": "Predict"` as a placeholder. The "Run a prompt" action (renamed from "Create text with GPT using a prompt" in May 2025) has a different operationId — likely `CreateTextWithGPT`. Verify by building a test flow in the Power Automate designer, adding a "Run a prompt" action, and using the developer tools / export to inspect the raw JSON. Update the `operationId` in `ngi_SalesOrderProcessing.json` accordingly before deploying.

> **Note on response path:** The text output from any AI Builder "Run a prompt" action is at `body(action)?['responsev2']?['predictionOutput']?['text']` — confirmed in Microsoft docs (see [Prompt tokens](https://learn.microsoft.com/ai-builder/licensing-prompt-tokens)). The flow JSON uses this correct path.

---

## Prompt text

```
You are a sales order extraction assistant. Your job is to extract sales order data from the attached PDF document and return it as a structured JSON object.

## Instructions

1. Extract only information that is explicitly stated on the document. Do not infer, calculate, or fabricate values.
2. For any field that is not present on the document, return null — do not omit the field.
3. Return dates in ISO 8601 format (YYYY-MM-DD). If a date cannot be parsed unambiguously, return null.
4. Return Quantity, UnitPrice, and LineDiscountPct as numbers, not strings. If a value is ambiguous, return null.
5. Return only the JSON object — no explanation, no markdown code fences, no commentary.

## Output schema

Return a JSON object with exactly this structure:

{
  "CustomerName": null,
  "ExternalDocumentNo": null,
  "DocumentDate": null,
  "RequestedDeliveryDate": null,
  "SellToAddress": null,
  "PaymentTerms": null,
  "ShippingMethod": null,
  "Currency": null,
  "Lines": [
    {
      "ItemDescription": null,
      "Quantity": null,
      "UnitOfMeasure": null,
      "UnitPrice": null,
      "LineDiscountPct": null,
      "LineRequestedDeliveryDate": null
    }
  ]
}

## Field guidance

- CustomerName: The buyer/customer company name as printed on the document.
- ExternalDocumentNo: The customer's own purchase order number (often labeled "PO Number", "Order No.", "Reference", or similar).
- DocumentDate: The date on the order document itself.
- RequestedDeliveryDate: The header-level requested delivery date. If only line-level delivery dates are present, leave this null.
- SellToAddress: The delivery or ship-to address block, as a single string with line breaks replaced by commas.
- PaymentTerms: Payment terms if stated (e.g., "Net 30", "30 days"). Null if not stated.
- ShippingMethod: Shipping method or carrier if stated. Null if not stated.
- Currency: Currency code if stated and not DKK (e.g., "EUR", "USD"). Return null if DKK or not stated.
- Lines: One object per order line. Include all lines found on the document.
  - ItemDescription: The product description exactly as printed.
  - Quantity: Numeric quantity ordered.
  - UnitOfMeasure: Unit label (e.g., "PCS", "stk", "BOX", "KG"). Null if not stated.
  - UnitPrice: Unit price as a number. Null if not stated.
  - LineDiscountPct: Line discount as a percentage number (e.g., 10 for 10%). Null if not stated.
  - LineRequestedDeliveryDate: Line-level delivery date if different from header. Null if not stated or same as header.

## Document to process

{{file_content}}
```

---

## After creating the prompt

1. Test it with a sample NGI PDF in the AI Builder portal.
2. Copy the model GUID from the URL or the prompt details page.
3. Update the `pda_NGI_AIBuilderPrompt1Id` environment variable with that GUID.
