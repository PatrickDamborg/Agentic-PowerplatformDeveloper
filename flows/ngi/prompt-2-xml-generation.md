# AI Builder Prompt 2 — XML Generation with Confidence (Claude)

**Purpose:** Take the JSON schema dump from Prompt 1 and generate a fully structured SalesOrder XML file with per-field confidence scores. This is Stage 2 of the two-stage pipeline.

**Where to create:** AI Builder portal → Prompts → New prompt  
**Input type:** Text — in the prompt instructions, insert an input, select **Text**, rename it to `text_input`  
**Model:** Claude (select from the model picker — use the most capable Claude model available, e.g., Claude 3.7 Sonnet)  
**Output format:** Leave as **Text** (do NOT set to JSON — this prompt returns XML, not JSON)  
**Input variable name:** `text_input` (must match the `body/inputs/text_input` parameter key in the flow JSON)

> **Note on `operationId`:** Same as Prompt 1 — verify the correct operationId for "Run a prompt" in the designer and update `ngi_SalesOrderProcessing.json` before deploying. See the note in `prompt-1-schema-extraction.md`.

> **Note on response path:** XML output is at `body('AI_Builder_XML_Generation')?['responsev2']?['predictionOutput']?['text']` — confirmed correct per Microsoft docs.

---

## Prompt text

```
You are an XML generation assistant for sales order processing. You receive structured sales order data in JSON format and produce a SalesOrder XML document with per-field confidence scores.

## Confidence scoring rules

Assign a confidence score (integer 0–100) to every field based on how certain you are that the value is correct:

- 95–100: Value is unambiguous, clearly and explicitly stated on the source document
- 75–94: Value is present but required interpretation (e.g., date format conversion, abbreviation expansion)
- 50–74: Value was inferred from context rather than directly stated
- 1–49: Value is uncertain or partially matched
- 0: Field was not found in the input data — set the element content to empty and add a null="true" attribute

Compute OverallConfidence as the arithmetic average of all non-zero field confidence scores, rounded to the nearest integer. If all fields are null, set OverallConfidence to 0.

## Output rules

- Return only the XML — no explanation, no markdown fences, no commentary before or after the XML.
- Do not add fields not in the schema below.
- Do not modify field values from the input — if the input says "50 PCS", Quantity is 50 and UnitOfMeasure is "PCS".
- ItemNo is always null="true" confidence="0" — item matching is handled downstream, not by this prompt.
- Generate sequential LineNo values starting from 1.

## Input JSON

{{text_input}}

## Required output format

<?xml version="1.0" encoding="UTF-8"?>
<SalesOrder>
  <Header>
    <CustomerName confidence="[0-100]">[value or empty]</CustomerName>
    <ExternalDocumentNo confidence="[0-100]">[value or empty]</ExternalDocumentNo>
    <DocumentDate confidence="[0-100]">[YYYY-MM-DD or empty]</DocumentDate>
    <RequestedDeliveryDate confidence="[0-100]">[YYYY-MM-DD or empty]</RequestedDeliveryDate>
    <SellToAddress confidence="[0-100]">[value or empty]</SellToAddress>
    <PaymentTerms confidence="[0-100]">[value or empty]</PaymentTerms>
    <ShippingMethod confidence="[0-100]">[value or empty]</ShippingMethod>
    <Currency confidence="[0-100]">[value or empty]</Currency>
  </Header>
  <Lines>
    [Repeat Line block for each line in the input]
    <Line lineNo="[N]">
      <ItemDescription confidence="[0-100]">[value]</ItemDescription>
      <ItemNo confidence="0" null="true"/>
      <Quantity confidence="[0-100]">[number]</Quantity>
      <UnitOfMeasure confidence="[0-100]">[value or empty]</UnitOfMeasure>
      <UnitPrice confidence="[0-100]">[number or empty]</UnitPrice>
      <LineDiscountPct confidence="[0-100]">[number or empty]</LineDiscountPct>
      <RequestedDeliveryDate confidence="[0-100]">[YYYY-MM-DD or empty]</RequestedDeliveryDate>
    </Line>
  </Lines>
  <Metadata>
    <ModelUsed>claude</ModelUsed>
    <OverallConfidence>[integer average of non-zero field scores]</OverallConfidence>
  </Metadata>
</SalesOrder>
```

---

## After creating the prompt

1. Test it by pasting a sample JSON object from a real extraction run (output of Prompt 1).
2. Verify the XML output is well-formed and all confidence attributes are integers 0–100.
3. Copy the model GUID from the AI Builder portal.
4. Update the `pda_NGI_AIBuilderPrompt2Id` environment variable with that GUID.

---

## Example input / expected output

**Input JSON:**
```json
{
  "CustomerName": "Acme Widgets A/S",
  "ExternalDocumentNo": "PO-2026-00812",
  "DocumentDate": "2026-04-22",
  "RequestedDeliveryDate": "2026-05-10",
  "SellToAddress": "Industriparken 4, 2750 Ballerup",
  "PaymentTerms": null,
  "ShippingMethod": null,
  "Currency": null,
  "Lines": [
    { "ItemDescription": "Blue Widget Type B", "Quantity": 50, "UnitOfMeasure": "PCS", "UnitPrice": 24.50, "LineDiscountPct": null, "LineRequestedDeliveryDate": null }
  ]
}
```

**Expected XML output:**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<SalesOrder>
  <Header>
    <CustomerName confidence="98">Acme Widgets A/S</CustomerName>
    <ExternalDocumentNo confidence="99">PO-2026-00812</ExternalDocumentNo>
    <DocumentDate confidence="97">2026-04-22</DocumentDate>
    <RequestedDeliveryDate confidence="85">2026-05-10</RequestedDeliveryDate>
    <SellToAddress confidence="92">Industriparken 4, 2750 Ballerup</SellToAddress>
    <PaymentTerms confidence="0" null="true"/>
    <ShippingMethod confidence="0" null="true"/>
    <Currency confidence="0" null="true"/>
  </Header>
  <Lines>
    <Line lineNo="1">
      <ItemDescription confidence="97">Blue Widget Type B</ItemDescription>
      <ItemNo confidence="0" null="true"/>
      <Quantity confidence="99">50</Quantity>
      <UnitOfMeasure confidence="94">PCS</UnitOfMeasure>
      <UnitPrice confidence="91">24.50</UnitPrice>
      <LineDiscountPct confidence="0" null="true"/>
      <RequestedDeliveryDate confidence="0" null="true"/>
    </Line>
  </Lines>
  <Metadata>
    <ModelUsed>claude</ModelUsed>
    <OverallConfidence>94</OverallConfidence>
  </Metadata>
</SalesOrder>
```
