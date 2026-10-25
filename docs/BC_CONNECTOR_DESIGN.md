# WizCommerce ↔ Microsoft Dynamics 365 Business Central Connector — Engineering Design & Tenant Audit

**Status:** Analysis / design (no production changes made)
**Scope:** `temp/` Python backend (`api/integrations/business_central/**`, `api/integrations/art_studios/**`, base framework, services, models) + both AL extensions (`business-central-app-connector/` current, `temp/business-central-app-connector/` original).
**Tenant audit source:** Redash `redash-p.sourcerer.tech`, data source `pgsql-p-ultron-01-replica2` (id 1), tables `integration_workflows`, `integration_auth_details`. Queried live; **secrets never printed**.
**Evidence legend:** ✅ Verified in code · 🗄️ Verified in config/DB (Redash) · 🧪 Verified by test · ❓ Inferred, not verified · ⛔ Missing / not found.

---

## 1. Executive Summary

WizCommerce integrates with Business Central through **three parallel code paths**, not one connector:

1. **`business_central` (V1)** — `api/integrations/business_central/v1/**` ✅. Pull-only, hardcoded standard BC OData endpoints, no per-tenant config engine. **Effectively retired**: Redash shows only *base/template* workflows active, **no real customer** on V1 🗄️.
2. **`business_centralv2` (V2)** — `api/integrations/business_central/v2/**` ✅. Pull + on-demand push, driven entirely by a per-tenant JSON config (`integration_workflows.data` + `.config`). **This carries all real BC customers**: 8 active workflows incl. **Browne Prod, ELK Home (= "Atlas"), BMC, Jovi Sports** 🗄️.
3. **`art_studios`** — `api/integrations/art_studios/v1/**` ✅. A **hard fork** of the BC connector bespoke to Art Studios (AAD tenant `charlesproducts.com`, AL namespace `api/CharlesProductsInc/WizCommerce/v2.0`), with its own config shape 🗄️.

**Each BC customer also runs its own bespoke AL extension inside their BC tenant**, with a *different* API namespace: Browne = `/api/BrowneGroupIncAPI/...`, Atlas/ELK = `/api/atlas/atlas/v1.0/...`, Art Studios = `/api/CharlesProductsInc/WizCommerce/v2.0/...` 🗄️. The generic V2 Python client adapts to each via the `data` config (endpoint templates, filters, date fields, sub-entities). **The `WZC`/`WIZ` AL app in this repo is a new standardization effort** to replace those per-tenant AL extensions with one shared `/api/wizcommerce/connector/v1.0/` surface ✅.

**Biggest risks today (all verified in code):**

- **Order-push duplication** on worker crash: `export()` creates the BC order, then `update_document_reference_id()` persists the ref in a *separate* step — a crash between them re-CREATEs on retry (`base/v2/exporters/order.py:539`, `base/v2/exporters/base.py:456`) ✅.
- **Incremental watermark can skip records**: filter is strict `gt lastModifiedDateTime` with **no overlap window**; records sharing the last timestamp are lost (`v2/api_client.py:496`) ✅.
- **Inventory is computed client-side by pulling *all* sales + *all* purchase orders unfiltered** every run (`v2/api_client.py:703-709`) — O(orders) cost per inventory sync ✅.
- **Skip-based pagination (`$top/$skip`) is the default** — drifts under concurrent writes (`v2/api_client.py:570`) ✅.
- **No 429/5xx retry or backoff** anywhere; only an auth-error token refresh (`v2/api_client.py:108`) ✅.
- **Three divergent code paths** (V1, V2, art_studios) + per-tenant AL extensions = high maintenance surface.

**Recommendation:** Keep V2's config-driven architecture as the foundation. Retire V1. Fold `art_studios` into V2 as a config profile. Standardize every tenant onto the shared `WZC` AL app. Add: idempotent order push, safe watermark with overlap, bounded concurrency + retry, and a typed/validated config schema. Details in §15.

> **Tenant-ID correction (important):** The task names Artstudio as `67cacc34-3702-432c-88f8-f43119b9b5b2`. **That tenant_id has no integration workflow of any type** 🗄️. The real Art Studios workflow is tenant **`dc09a1a8-44ec-46ec-bc2f-7cdfd8ef3a0e`**, `integration_type = art_studios`. The audit below uses the real tenant and flags the discrepancy.

---

## 2. Scope & Assumptions

- **In scope:** code behavior of V1/V2/art_studios connectors; the base importer/exporter/controller framework; config & reference-id storage model; the AL API surface; verified per-tenant config (Browne, Atlas/ELK, Art Studios).
- **Assumptions:** `integration_workflows`/`integration_auth_details` on `pgsql-p-ultron-01-replica2` are authoritative for runtime config (confirmed: `BusinessCentralControllerV2.set_api_client` reads auth from `integration_auth_details.data`, config from `integration_workflows.data`) ✅🗄️.
- **Not done:** no production changes; no secret values recorded; latency not instrumented (no traces available → marked `NOT MEASURED`).
- **BC API version:** standard calls use OData **`/api/v2.0`** ✅. Custom AL APIs use each publisher's own version segment 🗄️.

---

## 3. Repository Inventory

### 3.1 Python connector (`temp/api/integrations/`)

| Component | V1 impl | V2 impl | Shared | Current behavior | Recommended action | Evidence |
|---|---|---|---|---|---|---|
| Entry router | `v2/business_central.py` | `v2/business_central_v2.py` | — | `/sync`, `/sync/id`, `/background_sync`, `/push` | Keep V2 routes; deprecate V1 route | ✅ |
| Sync controller | `business_central/v1/controller.py` (`BusinessCentralSyncController`) | `business_central/v2/controller.py` (`BusinessCentralSyncControllerV2`) | `base/v2/controller.py` (`BaseControllerV2.sync_entity`) | Pull orchestration, per-entity enablement, watermark | Unify on V2 | ✅ |
| API client | `v1/api_client.py` (`BusinessCentralOAuthClient`) | `v2/api_client.py` (`BusinessCentralOAuthClientV2`, 1278 LOC) | `base/v2/api_client.py` (`BaseAPIClient`) | OAuth client-creds, OData calls | Refactor to shared client w/ retry+backoff | ✅ |
| Config engine | ⛔ none (hardcoded) | `v2/sub_entity_manager.py` (`EntityConfigManager`, `SubEntityEnricher`) | — | Parses `data` into per-entity config + enrichment | Keep; add schema validation | ✅ |
| Importers (pull→stage→core) | `v1/importers/*` (buyer, product, inventory, category, collection, document, transformer) | `v2/importers/*` (buyer, product, inventory, invoice, order, shipment, transformer) | `base/v2/importers/*` | Transform staged data into WizCommerce | Keep; converge transformers | ✅ |
| Exporters (push→BC) | `v1/exporters/*` | `v2/exporters/*` (buyer, document, payment, exporters) | `base/v2/exporters/{base,order,buyer,payment}.py` | Kaiba-mapped create/update to BC | Add idempotency (§13) | ✅ |
| Staging store | — | — | `services/integration_manager.py` (`IntegrationManager`) | Upserts normalized rows into `integration_*` tables by `(tenant_id, type, reference_id)` | Keep | ✅ |
| Sync state/history | — | — | `base/v2/controller.py`, `services/sync_history/**`, `services/entity_sync_logs/**` | `sync_details` watermark in Settings; `sync_history_logs`, `integration_sync_logs` | Keep; add cursor/overlap | ✅ |
| Mapping/ref-id | — | — | `services/entity_mapping_service.py`, `workflow/services/entity_reference_id_map.py` | internal↔external id resolution, defaults | Keep | ✅ |
| Push-failure notify | `notify_v1_push_failure` | via `BaseExporterV2._send_push_failure_notification` | `services/push_failure_notification.py` | Pub/Sub → AI explanation → Google Sheet audit → sales-rep email; auto-push only | Keep | ✅ |
| Art Studios fork | — | — | `art_studios/v1/**` (client, controller, importers, exporters) | Bespoke BC connector for `charlesproducts.com` | Fold into V2 config | ✅ |

### 3.2 Config & data model (`temp/api/workflow/models/workflow.py`, `api/integrations/models/integrations.py`) ✅

| Table | Role |
|---|---|
| `integration_workflows` | Per-tenant connector: `integration_type`, `is_active`, `is_primary`, `auth_details_id`, **`data`** (endpoint/entity config), **`config`** (entity enablement per action), `settings` |
| `integration_auth_details` | OAuth secrets + `environment`, `company_id`, BC AAD `tenant_id`, token URL (`url_id`/`access_token_url`) |
| `entity_workflows` + `kaiba_configs` | Per-entity+action field-mapping config (Kaiba engine) |
| `integration_entity_mappings` / `integration_entity_defaults` | internal↔ERP code mapping (sales reps, catalogs) + direction defaults |
| `entity_reference_id_map` | external ref-id per (entity, entity_id, workflow) for non-primary integrations |
| `integration_*` (products, customers, orders, inventory, invoices, shipments, …) | Staging store between ERP and WizCommerce core, keyed by `(tenant_id, type, reference_id)` |
| `sync_history_logs`, `integration_sync_logs`, `integration_logs` | Observability |

### 3.3 AL extensions (two generations, **same app id** `f47ac10b-58cc-4372-a567-0e02b2c3d479`) ✅

| | `temp/business-central-app-connector` (original) | `business-central-app-connector` (current workdir) |
|---|---|---|
| name / version | `WizCommerce Connector` / `1.0.0.0` | `WizCommerce for Business Central` / `1.0.0.19` |
| affix | `WIZ` | `WZC` |
| objects | 5: pages `WIZ Ship-to Address API`, `WIZ Shipment Tracking API`, `WIZ Customer Price API`; query `WIZ Item Availability`; permissionset | ~50: generic attribute framework (`WZC Attribute Mapping/Setup/Change Log`), sync profiles + filter engine (`WZC Sync Profile/Filter Rule/Checkpoint/Run Log`), field visibility, API config, ship-to attribute K/V, + the 4 original APIs |
| API route | `/api/wizcommerce/connector/v1.0/` | same publisher/group/version |

Both expose `wizShipToAddresses`, `wizCustomerPrices` (SourceTable `Price List Line`), `wizItemAvailabilities`, `wizShipmentTrackings` under `wizcommerce/connector/v1.0` ✅. The current app adds a **tenant-defined custom-attribute framework** (no AL redeploy to add a field).

---

## 4. V1 vs V2 vs Art Studios Comparison

| Dimension | V1 (`business_central`) | V2 (`business_centralv2`) | Art Studios (`art_studios`) |
|---|---|---|---|
| Direction | Pull only ✅ | Pull + on-demand push ✅ | Pull + push (incl. `push_cancel`) 🗄️ |
| Config engine | ⛔ hardcoded endpoints | ✅ `EntityConfigManager` from `data` | ❓ bespoke `data` shape (different keys) |
| Entities | category, collection, product, inventory, buyer, order(=salesOrders+salesInvoices merged) ✅ | buyer, inventory, order(+sales_archive variant), invoice, shipment, product; push: buyer, order, payment ✅ | buyer, order, payment, product, category, shipment, inventory 🗄️ |
| Custom endpoints | ⛔ no | ✅ per-entity `endpoint`, `has_custom_endpoint` | ✅ fixed namespace `CharlesProductsInc/WizCommerce` |
| Sub-entity enrichment | ⛔ no | ✅ `SubEntityEnricher` (price lists, addresses, notes, trackers) | ❓ bespoke in importers |
| Ref id | GUID (`id`) ✅ | configurable (`number`/`id`/`itemNo`…) ✅ | bespoke |
| Auth key names | `access_token_url`, BASE_URL includes `/api/v2.0` ✅ | `url_id`, BASE_URL built per-call ✅ | `access_token_url` + `base_url` + `url` 🗄️ |
| Real customers (Redash) | **0** (base/template only) 🗄️ | **BMC, Browne, ELK/Atlas, Jovi Sports** (+sandboxes) 🗄️ | **Art Studios** 🗄️ |

**Shared spine (all three):** `BaseControllerV2.sync_entity` (sync state/logs), `IntegrationManager` (staging), `BaseExporterV2` (push + Kaiba + push-failure), `base/v2/importers/*`.

---

## 5. Existing Architecture & Sync Flow

### 5.1 Pull (automated / scheduled)

```
POST /business-central/v2/sync {action:PULL, entities, sync_settings}
  → SyncService.start_sync_call(...)                      # creates sync_history row per entity; enqueues
  → (dramatiq) business_central_v2_sync queue
  → BusinessCentralSyncControllerV2.sync_business_central
      for each requested entity with a sync_id:
        BaseControllerV2.sync_entity(...):
          guard: skip if sync already COMPLETED/FAILED    # terminal-state idempotency (by sync_id)
          check config[entity].pull.allowed               # enablement
          resolve window (full / incremental / last_sync_time from Settings 'sync_details')
          controller.<entity>_controller(last_sync_date)  # PULL from BC → stage
            api_client.get_<entity>(...) → bulk_fetch (OData $top/$skip or nextLink)
            IntegrationManager.manage_<entity>(...)        # upsert integration_* by reference_id
          transformer.transform_<entity>(...)             # staging → WizCommerce core
          on success: sync_details[entity].last_sync_time = sync_start_time   # watermark
        update sync_history + integration_sync_logs
```

### 5.2 Pull by id — `POST /sync/id` → `sync_business_central_by_id` → `*_controller_by_ids` → transformer by ids ✅. Order-by-id also pulls linked invoices (`get_linked_invoice_ids_by_order_ids`) ✅.

### 5.3 Push (on-demand) — `POST /push {entity, entity_id}`

```
BusinessCentralExporterV2.export_<customer|order|payment>_by_id
  → BaseExporterV2.export_entity(entity_id):
      get_data(entity_id)                                 # Wiz entity + existing reference_id
      set_entity_export_action → CREATE if no ref else UPDATE   # <-- dedup hinges on ref presence
      is_valid_export (workflow active, config[entity][create|update].allowed, condition, buyer ref)
      pre_process → transform(Kaiba) → post_process
      export(...) → api_client.create_order/update_order/... # BC call
      on success: update_document_reference_id(...)       # persist ref (SEPARATE step)
      on failure (+auto-push): _send_push_failure_notification (Pub/Sub → AI → Sheet → email)
      raise integration_sync_logs event
```

### 5.4 Sequence diagrams (as-implemented)

**Customer pull**
```
Scheduler→API: /sync {BUYER}
API→Dramatiq: enqueue
Dramatiq→CtrlV2: buyer_controller(last_sync_date)
CtrlV2→BC: GET customers?$expand=contactsInformation($expand=contact) [+ custom endpoint] &$filter=<date> gt watermark
BC→CtrlV2: value[]
CtrlV2→SubEnricher: enrich (price_list, shipping_addresses) in batches by customerNumber  # N/batch calls
CtrlV2→Staging: manage_customers (upsert integration_customers)
CtrlV2→Transformer: transform_buyer → WizCommerce core
```

**Order push**
```
WizEvent→API: /push {ORDER, document_id}
API→Exporter: export_order_by_id
Exporter→Wiz: get_data (document + reference_id?)
Exporter: action = CREATE (no ref) | UPDATE (ref)
Exporter→Kaiba: transform payload
Exporter→BC: POST salesOrders (or custom_push_endpoint)   # BC assigns number
BC→Exporter: 201 {number,id}
Exporter→Wiz: update_document_reference_id(number)          # <-- crash window before this = dup
Exporter→BC: PATCH salesOrderWs (order_notes sub-entity)   # Browne
```

**Inventory pull (computed)**
```
CtrlV2→BC: GET items?$select=id,inventory,number&$expand=defaultDimensions &$filter=<date>
CtrlV2→BC: GET salesOrders?$expand=salesOrderLines(...)    # ALL, unfiltered
CtrlV2→BC: GET purchaseOrders?$expand=purchaseOrderLines(...) # ALL, unfiltered
CtrlV2: combine_inventory_data → {inventory, shipped_quantity, purchase_quantity, purchase_details}
```
(For custom-endpoint tenants — Browne `inventoryitems`, Atlas `inventoryFeedItems?$expand=futureAvailability` — this computation is skipped and the AL API returns inventory directly 🗄️.)

---

## 6. Tenant-Wise Configuration Audit (verified via Redash 🗄️)

> Secrets (`client_id`, `client_secret`) confirmed **present** but never read into this document. Connection = OAuth2 **client credentials**, scope `https://api.businesscentral.dynamics.com/.default` for all.

### 6.1 Connection settings

| Field | Browne (`248abcbd…dd6b2`) | Atlas / "ELK Home" (`a27eb2cb…8a61`) | Art Studios (`dc09a1a8…3a0e`) |
|---|---|---|---|
| integration_type | `business_centralv2` | `business_centralv2` | `art_studios` |
| workflow name | Browne Prod | ELK Home (BusinessCentralV2Final) | Art Studios |
| is_active / is_primary / status | true / true / published | true / true / published | true / — / published |
| BC AAD tenant | `9be4805a-…-a82a2c5c30f7` | `03b82d38-…-544c94dfca57` | `charlesproducts.com` |
| company_id | `192ee795-ec91-ed11-bff5-000d3a09c56e` | `118575ce-be81-f011-a708-000d3a4ef044` | `e54dc617-f263-f011-8eed-002248ac110c` |
| environment | Production | Production | Production |
| token URL key | `url_id` (login.microsoftonline.com/<aad>/oauth2/v2.0/token) | `url_id` (same shape) | `access_token_url` (…/charlesproducts.com/…) |
| timeout | 240s | (default 60) | 120s |
| custom AL namespace | `/api/BrowneGroupIncAPI/BrowneGroupIncAPIGroup/v2.0/` | `/api/atlas/atlas/v1.0/` | `/api/CharlesProductsInc/WizCommerce/v2.0/` |
| std vs custom API | **mixed** (custom buyer/product/inventory; standard order/invoice) | **mixed** (custom product/inventory/address/pricelist; standard order/invoice) | **fully custom namespace** |

### 6.2 Entity enablement (from `config` keys per entity 🗄️)

| Entity | Browne | Atlas/ELK | Art Studios |
|---|---|---|---|
| buyer | pull, push_create, push_update | pull, push_create, push_update | pull, push_create, push_update |
| order | pull, push_create | pull, push_create | pull, push_create, push_update, **push_cancel** |
| invoice | pull | pull | ❓ (not in config keys) |
| payment | push_create | push_create | push_create, push_update |
| product | pull | pull | pull |
| category | ⛔ | ⛔ | pull |
| shipment | pull | pull | pull |
| inventory | pull | pull | pull |

### 6.3 Endpoint / mapping behavior (from `data` 🗄️)

| Aspect | Browne | Atlas/ELK |
|---|---|---|
| buyer endpoint | `customers?$expand=shipToAddresses` (filter `number`, ref `number`, date `lastDateModified`) | standard (`id`) + subs |
| buyer filters | `customerPriceGroup eq 'RTMASTER'` | — |
| buyer sub-entities | `contact_details` ← `customers?$expand=contactsInformation($expand=contact)` (pull) | `price_list` ← `customerExtended` (pull+push); `shipping_addresses` ← `customerAddresses/` (pull+push) |
| order | standard `salesOrders`; subs: `order_notes`→`salesOrderWs({ref})` (push, ref `number`), `customer_notes`←`salesOrderWs` (pull) | standard `salesOrders`; `sales_archive`←`salesorderExpandArchiveLatest?$expand=salesOrderLineArchive` (pull **enabled**) |
| product (pricing!) | `items?$expand=priceListLines` (ref `number`, date `lastDateModified`) | `itemMatrixWizCom?$expand=ItemPricing` (ref `itemNo`, date `lastUpdated`, filter `sellOnWebsite eq 'Yes'`) |
| inventory | `inventoryitems` (ref `itemNumber`, date `lastUpdated`) | `inventoryFeedItems?$expand=futureAvailability` (ref `itemNo`, date `lastUpdated`, filter `sellOnWebsite eq 'Yes'`) |
| shipment tracker | `shipments` (filter `shipmentNumber`) | `ShipmentTracking` (filter `no`) |
| invoice / payment | standard OData | standard OData |
| extra `data` keys | catalog_mapping, default_catalog, variant_settings, sales_rep_mappings, product/document_attribute_map, default_* | same + **`hinge_attribute_ids`** |
| date field quirk | **`lastDateModified`** / **`lastUpdated`** (custom) — NOT `lastModifiedDateTime` | **`lastUpdated`** (custom) |

### 6.4 Per-tenant summaries

**Browne Group** — Mixed custom/standard. Pricing rides on `items?$expand=priceListLines`; customers filtered to price group `RTMASTER`; order notes pushed to a custom `salesOrderWs` write endpoint (keyed by GUID via `reference_id_field:id`, see `v2/api_client.py:1206`). Addresses pulled via `customers?$expand=shipToAddresses`. Push: buyer (C/U), order (C), payment (C). **Risk:** custom date field `lastDateModified` must exist & be indexed in Browne's AL API or incremental breaks. **Regression tests:** price-group filter, priceListLines→price mapping, order_notes PATCH, address expand.

**Atlas / ELK Home** — Heaviest custom surface via `/api/atlas/atlas/v1.0`. Pricing via `itemMatrixWizCom?$expand=ItemPricing`; inventory via `inventoryFeedItems?$expand=futureAvailability` (future ATP); website gating `sellOnWebsite eq 'Yes'`; **archive orders enabled**; address + price-list **push** to `customerAddresses`/`customerExtended`. Extra `hinge_attribute_ids`. Push: buyer (C/U), order (C), payment (C). **Regression tests:** sellOnWebsite filter, ItemPricing mapping, futureAvailability→ATP, archive-order merge, address/price-list push, hinge attributes.

**Art Studios** — Separate `art_studios` connector, fixed namespace `CharlesProductsInc/WizCommerce/v2.0`, AAD `charlesproducts.com`. Supports **order push_cancel** (unique) and **category pull**. Config shape is entirely different (`contact_code_id`, `ship_to_code_id`, `bill_to_customer_no`, `document_date_fields`, …). **Gap/risk:** code-forked → fixes don't propagate from V2. **Required change:** migrate to V2 config profile (custom endpoint + mapping), preserving push_cancel + category. **Note:** task's tenant_id `67cacc34…` is wrong; real is `dc09a1a8…`.

### 6.5 Configurable vs genuine differences

- **Should be config (already are, in V2):** endpoints, filters, date field, ref-id field, sub-entities, enablement, archive variant, sales-rep/catalog maps. Browne vs Atlas differ *only* in `data` — good.
- **Genuine BC/API differences:** each tenant's **AL extension namespace & custom entity shapes** (BrowneGroupIncAPI vs atlas/atlas vs CharlesProductsInc). These are real until tenants adopt the shared `WZC` AL app.
- **Genuine business differences:** Browne's `RTMASTER` price group; Atlas's `sellOnWebsite` gating & future ATP; Art Studios' cancel flow & categories.

---

## 7. Verified Differences Across Tenants

| Capability | Browne | Atlas/ELK | Art Studios | Source | Target design |
|---|---|---|---|---|---|
| Connector path | V2 | V2 | forked | 🗄️ | one V2 + profiles |
| Pricing source | `items.priceListLines` | `itemMatrixWizCom.ItemPricing` | bespoke | 🗄️ | pricing strategy per config (§8) |
| Inventory source | `inventoryitems` | `inventoryFeedItems.futureAvailability` | bespoke | 🗄️ | inventory strategy per config |
| Incremental date field | `lastDateModified` | `lastUpdated` | `document_date_fields` | 🗄️ | `date_filter_field` (exists) + watermark w/ overlap |
| Website gating | — | `sellOnWebsite eq Yes` | — | 🗄️ | config filter (exists) |
| Archive orders | off | on | n/a | 🗄️ | variant (exists) |
| Address push | — | yes (`customerAddresses`) | yes | 🗄️ | sub-entity push (exists) |
| Order write-back | `salesOrderWs` notes | — | cancel flow | 🗄️ | sub-entity push config |

---

## 8. Current Issues & Root Causes

| # | Issue | Root cause (file) | Impact |
|---|---|---|---|
| 1 | Duplicate BC orders on retry | ref persisted after create in separate step (`base/v2/exporters/order.py:539`, `base/v2/exporters/base.py:511-544`) | Double orders in BC |
| 2 | Missed records at watermark boundary | strict `gt`, no overlap (`v2/api_client.py:496`) | Silent data loss |
| 3 | Inventory pulls all SO+PO unfiltered | `get_inventories` (`v2/api_client.py:703-709`) | Slow, heavy, throttling |
| 4 | Pagination drift | `$skip` default (`v2/api_client.py:570`) | Dup/missed under writes |
| 5 | No 429/5xx retry/backoff | only auth refresh (`v2/api_client.py:108`) | Fragile under throttle |
| 6 | Token not shared across workers | in-memory per client instance (`v2/api_client.py:39`) | Excess token calls |
| 7 | `If-Match:*` on PATCH | `patch()` (`v2/api_client.py:233`) | No optimistic concurrency |
| 8 | Three code paths | V1 + V2 + art_studios | Maintenance + drift |
| 9 | No config schema/validation | `data` is free-form JSON | Silent misconfig |
| 10 | Sub-entity N/batch calls | `SubEntityEnricher` (`sub_entity_manager.py:435`) | Latency per customer page |

---

## 9. Target Architecture

Keep V2's config-driven design; harden the shared layer; collapse the three paths.

**A. Config registry** — stay on `integration_workflows.{data,config,settings}` + `integration_auth_details` (no new store). Add a **typed Pydantic schema** (`ConnectorConfig`, `EntityConfig`, `SubEntityConfig`, `AuthConfig`) validated on save and on load, merging **global defaults → connector defaults → tenant overrides**. Unknown/missing keys fall back to current defaults (back-compat). Validate endpoint placeholders (`{company_id}`, `{reference_id}`), operators, date fields.

**B. Connection/auth** — one `BusinessCentralApiClient`: client-creds OAuth; **token cache in `access_token` table** (already exists for Zoho) keyed by `(tenant_id, source)` with expiry, so workers share tokens; per-call `correlation_id`; timeout from config; **retry with jittered backoff on 429 (honor `Retry-After`) + 5xx + connect errors**; non-retryable (400/401-after-refresh/403/404) fail fast; redact secrets in logs. Standard OData and custom AL endpoints coexist via the existing `endpoint`/`has_custom_endpoint` config (no change to call sites).

**C. Entity service layer** — formalize the existing controller/transformer pattern behind an `EntityService` interface: `fetch_page`, `apply_filters`, `transform`, `resolve_external_id`, `upsert`, `persist_state`, `report_partial_failure`. Reuse `IntegrationManager`, `EntityConfigManager`, `SubEntityEnricher`.

**D. Orchestration** — keep `BaseControllerV2.sync_entity` (full/incremental/controller-only/transformer-only + terminal-state guard). Add explicit **dependency ordering** (products → pricing → inventory; customers → addresses; orders → linked invoices, already partial) and per-entity isolation (one entity's failure doesn't abort others — already per-entity try/except).

**E. State/idempotency/observability** — persist per entity: `last_sync_time` (keep), add `overlap_seconds`, optional `@odata.nextLink`/`@odata.deltaLink` cursor, `etag`/row-version where available, failed-record list, retry count, `correlation_id`, run status. Add **idempotent push** (§13).

---

## 10. Entity Implementation Matrix

| Entity | Dir | V1 | V2 | BC endpoint/object | Deps | Tenant overrides | Required change |
|---|---|---|---|---|---|---|---|
| Companies | pull | ✅ validate | ✅ validate (`/companies`) | `companies` | — | — | keep |
| Customers | pull/push | pull ✅ | pull+push ✅ | `customers` (+`$expand contactsInformation`) / custom | catalog, sales-rep maps | Browne custom + `RTMASTER`; Atlas std | keep; dedupe push |
| Customer contacts | pull/push | via expand | via expand + `create_contacts` | `contacts` | customer | — | keep |
| Ship-to addresses | pull/push | via expand | sub-entity ✅ | `customerAddresses` / AL `wizShipToAddresses` | customer | Atlas push; Browne pull-expand | keep; avoid N+1 (§7) |
| Bill-to addresses | pull | via customer | via customer | customer fields | customer | Art Studios `bill_to_customer_no` | config-map |
| Products/items | pull | ✅ | ✅ | `items` / custom | — | Browne/Atlas custom | keep |
| Item variants | pull | ❓ | ❓ (`variant_settings`, `default_variant_code`) | `itemVariants` | item | present in `data` | verify/implement |
| Product attributes | pull | ✅ attrs | ✅ (`product_attribute_map`) | custom/expand | product | Atlas `hinge_attribute_ids` | keep |
| Product images/media | pull | ⛔ | ⛔ **not found** | `items/picture` (std) | product | — | **new** (ETag/checksum, §8) |
| Customer prices | pull | ⛔ | ✅ via product expand/sub | `priceListLines` / `ItemPricing` / AL `wizCustomerPrices` | product, customer | Browne/Atlas differ | keep; model priority (§8) |
| Price lists | pull | ⛔ | partial | `priceListLines` | — | per tenant | formalize |
| Currency | pull | ❓ | ❓ | `currencies` | — | — | verify |
| Units of measure | pull | ✅ (`$expand unitOfMeasure`) | ❓ | `itemUnitsOfMeasure` | item | — | verify |
| Inventory | pull | computed ✅ | computed or custom ✅ | items+SO+PO / `inventoryitems` / `inventoryFeedItems` | items | Browne/Atlas custom | optimize (§8,§12) |
| Inventory by location | pull | ⛔ | ⛔ | `itemLedgerEntries`/custom | item, location | — | **new if needed** |
| Locations/warehouses | pull | ⛔ | ⛔ | `locations` | — | — | **new if needed** |
| Dimensions | pull | ⛔ | ⛔ (only `defaultDimensions` expand on items) | `dimensions` | — | — | **new** (§9) |
| Dimension values | pull | ⛔ | ⛔ | `dimensionValues` | dimension | — | **new** |
| Customer default dims | pull | ⛔ | partial (expand) | `defaultDimensions` | customer | — | **new** |
| Item default dims | pull | ⛔ | via inventory expand | `defaultDimensions` | item | — | formalize |
| Sales header+lines | pull/push | pull ✅ / push ✅ | pull+push ✅ | `salesOrders(+Lines$expand item)` / custom | customer, items, prices | Browne notes; Atlas archive | idempotent push |
| Posted shipments | pull | ⛔ | ✅ | `salesShipments` / AL `wizShipmentTrackings` | order | tracker subs | keep |
| Posted invoices | pull | ✅ (merged into order) | ✅ separate | `salesInvoices(+Lines)` | order | — | keep |
| Payments | push | ⛔ | ✅ | `customerPayments` | customer, invoice | all push_create | idempotent push |
| Payment terms | pull | ⛔ | ⛔ | `paymentTerms` | — | — | **new if needed** |
| Categories | pull | ✅ | ⛔ (V1/art only) | `itemCategories` | — | Art Studios | keep in profile |
| Collections | pull | ✅ | ⛔ | `generalProductPostingGroups` | — | — | keep in profile |

---

## 11. Standard vs Custom AL API Decision Matrix

| Entity | Standard OData sufficient? | Why / gap | Recommendation |
|---|---|---|---|
| Customers | Yes (`customers`, filter/select/expand/pagination, `lastModifiedDateTime`) | std supports contacts via expand | Standard; custom only for extra fields |
| Ship-to addresses | Partial | std `customerAddresses` lacks custom fields (delivery instructions) | **AL `wizShipToAddresses`** (this repo) — now supports tenant-defined attributes via K/V |
| Products | Yes | std `items` ok | Standard; custom when pricing/attrs must be co-returned (Browne/Atlas) |
| Pricing | **No** | std item price ≠ customer price; price list lines need customer/qty/date/UoM | **Custom AL `wizCustomerPrices`** (SourceTable `Price List Line`) or `$expand` |
| Inventory (global) | Yes (`items.inventory`) | ok for simple | Standard |
| Inventory (ATP/by-location/future) | **No** | not exposed cleanly; current code pulls all SO+PO | **Custom AL `wizItemAvailabilities`** (query) / Atlas `inventoryFeedItems.futureAvailability` |
| Dimensions / values | Yes (`dimensions`, `dimensionValues`) ✅ std APIs | std exists but **unused** | Standard pull; see §9 |
| Default dimensions | Yes (`defaultDimensions` expand) | std ok | Standard expand |
| Sales orders (pull/push) | Yes (`salesOrders`) | std ok; some need write-back fields | Standard; custom AL for notes/write endpoints (Browne `salesOrderWs`) |
| Shipments | Yes (`salesShipments`) | std ok | Standard / AL `wizShipmentTrackings` for tracking |
| Invoices | Yes (`salesInvoices`) | std ok | Standard |
| Images | Yes (`items/picture` + `@odata.mediaReadLink`) | std ok but needs change detection | Standard + ETag/checksum |

**Proposed custom AL objects (align to existing `WZC` app, publisher `wizcommerce`, group `connector`, version `v1.0`):**

| Object | Type | Entity set | Source table | Keys | Purpose |
|---|---|---|---|---|---|
| `WZC Customer Price API` (exists) | Page/API | `wizCustomerPrices` | `Price List Line` | priceListCode, lineNo | customer/qty/date pricing |
| `WZC Item Availability` (exists) | Query/API | `wizItemAvailabilities` | `Item` | itemNo | ATP w/o pulling all SO/PO |
| `WZC Ship-to Address API` (exists) | Page/API | `wizShipToAddresses` | `Ship-to Address` | custNo, code | addresses + tenant attributes |
| `WZC Shipment Tracking API` (exists) | Page/API | `wizShipmentTrackings` | `Sales Shipment Header` | no | tracking |
| `WZC Dimension API` (**new**) | Page/API | `wizDimensions` | `Dimension` | code | dimension catalog |
| `WZC Dimension Value API` (**new**) | Page/API | `wizDimensionValues` | `Dimension Value` | dimCode, code | value catalog |
| `WZC Inventory By Location` (**new, if needed**) | Query/API | `wizInventoryByLocation` | `Item Ledger Entry`/`Warehouse Entry` | itemNo, locationCode | per-location ATP |

Permissions: read for pull entities; read/insert/modify for push (customers, addresses, sales orders, payments). Company-scoped (`companies({id})/...`). All testable in each tenant's BC sandbox (Browne Sandbox, Atlas Stage2 workflows exist 🗄️).

---

## 12. Customer & Address Design

**Identity & matching:** BC customer `number` (Browne/Atlas use `number`/`id` as `reference_id` per config). Primary integration → ref stored on the WizCommerce buyer; non-primary → `entity_reference_id_map`. Push action = CREATE if no ref else UPDATE (`set_entity_export_action`). ✅

**Relationships:** customer ← ship-to addresses (1:N), contacts (via `contactsInformation`). Browne pulls addresses by `customers?$expand=shipToAddresses`; Atlas via sub-entity `customerAddresses` (pull+push). ✅🗄️

**Preserve address ids:** BC `code` per ship-to; persist (reference_id or K/V). Deactivation = soft (don't hard-delete). Null/empty handling: treat empty-string as "clear", null/absent as "leave unchanged" (§8 semantics) — **standardize** (today Kaiba drops empties inconsistently).

**Avoid N+1:** sub-entity enrichment already **batches by `customerNumber`** (`SubEntityEnricher._fetch_sub_entity_data`, `batch_size` default 50) ✅ — not strict N+1, but N/50 calls per page + per sub-entity. Target: prefer **`$expand`** when the AL API supports it (Browne already expands `shipToAddresses`); keep batched filter fetch as fallback; add bounded concurrency.

**Recommended flow (pseudocode):**
```
pull customers page (filter: date gt watermark-overlap [+ tenant filters])
if sub-entities configured and not expandable:
    for batch(customerNumbers, 50): fetch price_list, addresses by $filter number in (...) concurrently (bounded)
upsert integration_customers (+ nested subs)
transform → upsert WizCommerce buyer; map addresses by code; resolve sales-rep/catalog
```

---

## 13. Product, Price, Inventory, Image Design

**Products/items:** number, description, type, UoM, blocked/active, category, attributes, variants, external id. **Value semantics (standardize):** *missing/absent* = leave unchanged; *null* = leave unchanged; *empty string* = explicit clear; *0* = real zero (price/qty); explicit clear only when mapping says so. Enforce in Kaiba config + post_process.

**Pricing (do NOT assume one item price):**
- Browne: `items?$expand=priceListLines` → price list lines (per customer price group `RTMASTER`) 🗄️.
- Atlas: `itemMatrixWizCom?$expand=ItemPricing` → matrix pricing 🗄️.
- Generic: standard `salesPrices`/`priceListLines` or AL `wizCustomerPrices`.
- Handle: customer-specific, price list + lines, currency, **quantity breaks**, start/end dates, UoM, tax in/exclusive, **priority/fallback** (customer price → price group → list → base item price), missing price (skip vs base), incremental (date field per tenant).

**Inventory:**
- Distinguish global, by-location, available (ATP), reserved/allocated, on-hand.
- Current generic path computes `inventory`, `shipped_quantity` (from SO `shipQuantity`), `purchase_quantity` + `purchase_details` (from PO) client-side by pulling **all** SO+PO ✅ — replace with AL query (`wizItemAvailabilities`) or tenant custom (`inventoryFeedItems.futureAvailability` for Atlas future ATP) to avoid O(orders) cost.

**Images/media:** ⛔ not currently synced. Add via `items` `picture`/`@odata.mediaReadLink`; **change-detect** with ETag/`lastModifiedDateTime`/checksum; never re-download unchanged. Store media id + hash in `integration_product_attributes` meta.

---

## 14. Dimensions — Complete Technical Design

**Model:** Dimension (e.g. `DEPARTMENT`) → Dimension Value (e.g. `SALES`); Default Dimension (per customer/item); Dimension Set Entry / Dimension Set Id on transactions; global vs shortcut dimensions; entity-default vs transaction dimensions.

**Current state:** ⛔ No dimension or dimension-value entity is synced. Only `defaultDimensions` is `$expand`ed on `items` within inventory (`v2/api_client.py:699`) ✅ — not stored as dimensions, just carried in item meta.

**Target:**
- Pull catalogs: `dimensions`, `dimensionValues` (standard APIs) → store as reference entities.
- Customer/item default dimensions: `$expand=defaultDimensions`.
- Transactions: on **push**, set line/header dimensions via Dimension Set or `dimensionSetLines`; validate against blocked/mandatory/combinations before posting (BC rejects invalid combos).
- If standard API gaps appear (e.g. setting dimension set on custom order endpoint), add **AL `wizDimensions`/`wizDimensionValues`** + a write helper.

**Examples/tests:** (a) customer w/ one default dim; (b) customer w/ multiple; (c) item w/ default dim; (d) order header dims; (e) order line dims; (f) invalid/blocked value → expect push failure surfaced; (g) missing required dim → expect validation error + push-failure email.

---

## 15. Filters & Incremental Sync

**Audit (current):** `$filter` (date + config filters), `$select` (inventory), `$expand` (sub-entities), `$top`/`$skip` (default) or `@odata.nextLink`. Date filter is strict `gt`, field per tenant (`lastModifiedDateTime`/`lastDateModified`/`lastUpdated`) 🗄️. **No `$count`, no delta links, no ETag conditional requests** ✅.

**Target watermark (safe):** `filter = {date_field} gt (last_sync_time − overlap)` with `overlap_seconds` (e.g. 120s); dedupe on upsert by `reference_id` (already idempotent via `IntegrationManager`). Capture `sync_start_time` **before** fetch (already done) and only advance watermark on success (already done). Handle:
- created/modified → caught by date filter + overlap.
- deactivated → map to soft status (don't delete).
- deleted → BC rarely exposes deletes on std APIs; use periodic reconcile/full resync or BC **delta** (`@odata.deltaLink`) where supported.
- same-timestamp records → overlap window + idempotent upsert.
- page failure/restart → terminal-state guard + re-run resumes; prefer `nextLink`/delta over `$skip` to avoid drift.
- never-synced → watermark null → full pull.

**Full resync:** `sync_task=FULL_SYNC` (null window) — safe because upserts are keyed; no duplicates.

---

## 16. Tenant Configuration Schema (proposed, back-compatible)

Stored in `integration_workflows.data` (endpoints), `.config` (enablement), `.settings`; validated by a Pydantic model. Example (placeholders for secrets/ids):

```jsonc
{
  "connector_type": "business_central",
  "api": { "mode": "custom|standard", "odata_version": "v2.0",
           "custom_namespace": "/api/<Publisher>/<Group>/v2.0" },
  "auth_ref": "integration_auth_details:<uuid>",   // secrets never inline
  "environment": "Production",
  "company_id": "<guid>",
  "pagination": { "style": "nextLink|skip", "page_size": 100 },
  "concurrency": { "max_parallel_subentity": 5 },
  "retry": { "max_attempts": 5, "backoff_base_ms": 500, "respect_retry_after": true },
  "incremental": { "overlap_seconds": 120 },
  "entities": {
    "buyer":   { "pull": true, "push_create": true, "push_update": true,
                 "endpoint": "/api/.../customers?$expand=shipToAddresses",
                 "reference_id_field": "number", "date_filter_field": "lastDateModified",
                 "filters": [{"field":"customerPriceGroup","operator":"eq","value":"RTMASTER"}],
                 "sub_entities": [{"name":"contact_details","endpoint":"...","pull":true,"filter_field":"number"}] },
    "product": { "pull": true, "endpoint": "/api/.../items?$expand=priceListLines",
                 "reference_id_field": "number", "date_filter_field": "lastDateModified",
                 "pricing": { "strategy": "price_list_lines", "priority": ["customer","group","list","base"] } },
    "inventory": { "pull": true, "endpoint": "/api/.../inventoryitems",
                   "reference_id_field": "itemNumber", "date_filter_field": "lastUpdated",
                   "strategy": "custom_endpoint" },
    "order":   { "pull": true, "push_create": true,
                 "sales_archive": { "pull": false, "endpoint": "" },
                 "sub_entities": [{"name":"order_notes","endpoint":".../salesOrderWs({reference_id})","push":true,"reference_id_field":"id"}] }
  }
}
```

**Tenant deltas (verified only):** Browne → buyer/product/inventory custom endpoints + `RTMASTER` + `lastDateModified`; Atlas → `itemMatrixWizCom`/`inventoryFeedItems`, `sellOnWebsite eq Yes`, `lastUpdated`, archive on, address/price-list push, `hinge_attribute_ids`; Art Studios → fixed `CharlesProductsInc/WizCommerce` namespace, category pull, order push_cancel. **Precedence:** global default → connector default → tenant override. **Absent key → current default (back-compat).** Validation errors block save, not runtime.

---

## 17. Latency & Performance Analysis

No traces/metrics available → all `NOT MEASURED`; estimates are structural (from code).

| Operation | Current API calls | Measured | Main bottleneck | Optimization | Expected effect |
|---|---|---:|---|---|---|
| Customer pull (1 page + subs) | 1 + (N/50)×subs | NOT MEASURED | sub-entity batches | prefer `$expand`; bounded concurrency | fewer round trips |
| Inventory pull | items pages + **all SO** + **all PO** | NOT MEASURED | unbounded SO/PO scan | AL `wizItemAvailabilities` / custom feed | O(orders)→O(items) |
| Product pull | items pages (+expand) | NOT MEASURED | page size 100, `$skip` | `$select`, `nextLink`, larger page | smaller payloads, no drift |
| Order push | 1 create + K sub PATCH | NOT MEASURED | serial sub-entities | batch where possible | fewer calls |
| Token | 1 per client instance | NOT MEASURED | not shared across workers | cache in `access_token` | fewer AAD calls |

**Levers:** `$select`, precise filters, `nextLink`/delta, bounded concurrency, batch requests (`$batch`) where supported, custom AL to reduce round trips, cache stable metadata (companies, dimensions, UoM), incremental everywhere, avoid repeated address/price/image fetches (change detection), DB bulk upserts (already batched 50 in `IntegrationManager`), tenant-level throttling + fairness. **Never** add unbounded concurrency or bypass BC throttling (429 + `Retry-After`).

**Benchmark plan:** wrap `make_request` with timing + `correlation_id` → `integration_logs`; record calls/entity, page counts, payload bytes, total duration per sync_id; dashboard per tenant.

---

## 18. Error Handling & Idempotency

**Classification:**
- Retryable (backoff + jitter): 429 (honor `Retry-After`), 500/502/503/504, connect/read timeout.
- Refresh-once: 401/400 auth-coded (already) → then fail.
- Non-retryable → surface: 403 (perm), 404 (missing company/record), validation (invalid dims/prices/mapping), duplicate external id.
- Config errors → block + alert (invalid endpoint/filter/mapping).

**Order-push idempotency (fixes Issue #1):**
1. Generate a deterministic **idempotency key** per (tenant, document_id, workflow) *before* the BC call; persist intent (`status=pushing`, key) in `entity_reference_id_map`/document meta.
2. On create, send the key to BC where supported (custom AL `externalDocumentNo`/`yourReference`); otherwise **search-before-create** by that key.
3. On retry: if a BC order with the key exists → treat as success, adopt its number (no second create).
4. Persist ref in the **same** transactional step as marking success; `update_document_reference_id` becomes idempotent (upsert).
This closes the create→persist crash window (`base/v2/exporters/order.py:539`).

**Partial page failure:** per-record try/except in staging; collect failed `reference_id`s to run meta; entity-level status reflects partial; next incremental re-covers via overlap. **Worker termination:** terminal-state guard (`sync_entity`) + idempotent upserts + idempotent push = safe resume.

---

## 19. Security & Permissions

- **OAuth2 client credentials**, scope `.default`; per-tenant AAD app (Browne/Atlas AAD tenants; Art Studios `charlesproducts.com`) 🗄️. Secrets in `integration_auth_details.data` — **never log/echo** (enforced here).
- **BC app (Entra) + BC "Application" user** with company access; least-privilege permission sets. Pull entities = read; push (customers, addresses, sales orders, payments) = read/insert/modify. Custom AL objects need their permission set (`WZC CONNECTOR`) assigned to the integration user.
- **Token handling:** cache w/ expiry; refresh 5 min early (already); move cache to `access_token` table for cross-worker reuse.
- **Log redaction:** `log_external_api_error` logs params — scrub secrets/tokens; never put PII/secrets in URLs.
- **Tenant isolation:** every staging/config row keyed by `tenant_id`; API clients built per tenant from that tenant's auth; no shared mutable client state across tenants.

---

## 20. Exact File-Level Implementation Plan

**Phase 1 — Baseline (no behavior change)**
- Confirm fleet/config (done 🗄️). Add timing+correlation to `v2/api_client.py:make_request`; add missing unit tests for `EntityConfigManager` (`sub_entity_manager.py`) and `combine_inventory_data`. *Risk: none. Rollback: revert.*

**Phase 2 — Shared foundation**
- `base/v2/api_client.py` (`BaseAPIClient`): add retry/backoff (429/5xx), `Retry-After`, correlation id, token cache via `access_token` table. *Tests: mocked 429/5xx/timeout. Risk: retry storms → cap attempts. Rollback: flag `retry_enabled`.*
- `v2/api_client.py`: route token through base cache; keep endpoints. *Risk: token sharing bugs → per-tenant key tests.*
- New `ConnectorConfig` Pydantic schema (new file `business_central/v2/config_schema.py`) consumed by `EntityConfigManager`; validate on load, default on missing. *Risk: strict validation rejecting live config → log-only warn first, enforce later.*
- Watermark overlap: `base/v2/controller.py` `_resolve_last_sync_window` + `v2/api_client.py:_build_entity_params` add `overlap_seconds`. *Tests: boundary timestamp. Risk: minor re-processing (idempotent).* 

**Phase 3 — Entity services**
- Pagination default → `nextLink` in `bulk_fetch` (`v2/api_client.py:570`); delta where supported. *Tests: mocked nextLink + drift. Rollback: config `pagination.style`.*
- Inventory: add AL `wizItemAvailabilities` consumption path; stop pulling all SO/PO for generic tenants. *Tests: parity vs computed. Risk: ATP mismatch → shadow-compare.*
- Customer/address: prefer `$expand`; bounded concurrency in `SubEntityEnricher`.
- Pricing: formalize priority/fallback in transformers.
- Images: new importer (change detection).
- Dimensions: new importers + AL `wizDimensions`/`wizDimensionValues` if gaps.

**Phase 4 — Tenant migration**
- Convert Art Studios → V2 config profile (new `data` for `charlesproducts.com` namespace), preserve category pull + order push_cancel; run behind `art_studios_on_v2` flag; shadow-compare; rollback = flag off.
- Standardize Browne/Atlas onto shared `WZC` AL app endpoints (optional, tenant-paced).

**Phase 5 — Prod readiness**
- Idempotent order/payment push (`base/v2/exporters/{order,base}.py`): pre-persist intent + key, search-before-create, transactional ref persist. *Tests: crash-between-create-and-persist. Highest priority.*
- Benchmarks, dashboards, alerts; permission/isolation verification.

**Priority order:** P5 idempotent push (#1) → watermark overlap (#2) → retry/backoff (#5) → inventory optimization (#3) → pagination (#4) → config schema (#9) → art_studios fold-in (#8).

---

## 21. Test Strategy & Acceptance Criteria

**Matrix:** unit (mappings/transformers, `EntityConfigManager`, `combine_inventory_data`, watermark window), api-client (mocked 429/5xx/401-refresh/timeout), pagination (skip & nextLink, drift), incremental (boundary timestamp, overlap), full sync, sync-by-id, duplicate prevention (push retry after crash), customer↔address, pricing correctness (customer/group/list/base priority), inventory (global/ATP/by-location), dimensions (§14 a–g), tenant-specific config, missing-config defaults, auth/permissions, retry/rate-limit, partial failures, worker termination resume, V1 back-compat, V2 regression, sandbox integration (Browne Sandbox, Atlas Stage2).

**Acceptance — Browne:** custom buyer/product/inventory endpoints resolve; `RTMASTER` filter applied; `priceListLines`→prices; `lastDateModified` incremental; order create + `order_notes` PATCH to `salesOrderWs`; no dup orders on retry.
**Acceptance — Atlas/ELK:** `itemMatrixWizCom.ItemPricing`→prices; `inventoryFeedItems.futureAvailability`→ATP; `sellOnWebsite eq Yes`; archive orders merged; address + price-list push to `customerExtended`/`customerAddresses`; hinge attributes mapped; no dup orders.
**Acceptance — Art Studios:** on V2 profile, category pull + buyer/order/payment push incl. order **cancel**; parity vs forked connector in shadow run.

---

## 22. Migration, Rollout, Rollback

- **V1:** no real customer (base/template only) 🗄️ → mark deprecated; remove route after confirming no traffic in `integration_sync_logs`.
- **V2:** already carries all BC customers → harden in place behind flags; shadow-compare each change per tenant; rollback = flag off (config-driven, no deploy).
- **Art Studios:** fold into V2 as profile; dual-run + diff; keep forked path until parity signed off; rollback = `art_studios_on_v2=false`.
- **AL app:** `WZC` app replaces `WIZ` (same app id) — version bump path 1.0.0.0 → 1.0.0.19; per-tenant adoption optional; keep tenant bespoke AL until migrated.
- **Back-compat rule:** missing config key = current default; no change to Kaiba configs unless explicitly migrated.

---

## 23. Open Questions & Required Evidence

1. **Artstudio tenant_id mismatch** — task says `67cacc34…` (no workflow); real is `dc09a1a8…`. Confirm which tenant the audit should target. 🗄️ flagged.
2. **BMC & Jovi Sports** also on `business_centralv2` 🗄️ — include in migration scope? (not in task's 3 but in blast radius).
3. **Kaiba configs** per entity_workflow not dumped here — need `kaiba_configs.config` per tenant to validate field-level mappings (values, defaults, empty/null handling).
4. **Images, locations, payment terms, variants, currency, UoM** — confirm business need before building new importers.
5. **Deletes** — does any tenant's AL API expose deletions / delta links? Determines reconcile strategy.
6. **Latency** — no metrics; needs instrumentation (§17) before/after.
7. **BC custom date fields** (`lastDateModified`, `lastUpdated`) — confirm indexed in each tenant's AL API.

**Access still needed:** `kaiba_configs` + `entity_workflows` rows per tenant; BC sandbox creds (Browne Sandbox, Atlas Stage2) for integration tests; any existing New Relic/log traces for latency.

---

## 24. Microsoft Documentation References

- Business Central API (v2.0) overview & endpoints — learn.microsoft.com `/dynamics365/business-central/dev-itpro/api-reference/v2.0/`
- OData query options (`$filter`, `$select`, `$expand`, `$top`, `$skip`, `@odata.nextLink`) — BC "Using filtering" / OData docs
- Delta links / change tracking — BC API "Reading changes"
- OAuth2 client credentials (service-to-service) — BC "Authenticate using Microsoft Entra"
- Custom AL API pages/queries (`APIPublisher`/`APIGroup`/`APIVersion`) — BC "Creating a custom API"
- Dimensions, Default Dimensions, Dimension Set Entries — BC dimensions documentation
- Rate limits / throttling (429, `Retry-After`) — BC "API limits"

*(Cite exact URLs/versions at implementation time per the evidence rule; BC API surface evolves per release.)*

---

### Appendix A — Verified identifiers (non-secret)

| Tenant | WizCommerce tenant_id | integration_type | BC AAD tenant | company_id | AL namespace |
|---|---|---|---|---|---|
| Browne | `248abcbd-1d7f-4254-9c81-7bd2d61dd6b2` | business_centralv2 | `9be4805a-4905-4e67-a1c4-a82a2c5c30f7` | `192ee795-ec91-ed11-bff5-000d3a09c56e` | BrowneGroupIncAPI |
| Atlas/ELK | `a27eb2cb-01c9-49ba-adba-7458018b5a61` | business_centralv2 | `03b82d38-6a9a-4da3-8e57-544c94dfca57` | `118575ce-be81-f011-a708-000d3a4ef044` | atlas/atlas |
| Art Studios | `dc09a1a8-44ec-46ec-bc2f-7cdfd8ef3a0e` *(task's `67cacc34…` invalid)* | art_studios | `charlesproducts.com` | `e54dc617-f263-f011-8eed-002248ac110c` | CharlesProductsInc/WizCommerce |

*Secrets (`client_id`/`client_secret`) confirmed present in `integration_auth_details`; intentionally not recorded.*
