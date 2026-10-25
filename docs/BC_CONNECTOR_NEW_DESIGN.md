# WizCommerce Business Central Connector — New Architecture (Implementation Design)

**Audience:** engineers implementing the connector.
**Scope:** the *new* connector only. One codebase, config-driven, every tenant behaves differently through **configuration, not code branches**.
**Ground rule:** standard Microsoft BC APIs where they suffice; custom AL API pages (publisher `wizcommerce`, group `connector`) only for fields/behavior standard APIs don't expose. No invented endpoints.

---

## 1. SOLID Architecture

One connector, five layers. Each has a single responsibility and is swappable.

```
          ┌──────────────────────────────────────────────┐
          │              SyncOrchestrator                 │  (what to sync, in what order)
          └───────────────┬──────────────────────────────┘
                          │ drives
          ┌───────────────▼──────────────┐
          │        EntityService<T>       │  buyer / address / product / price /
          │  fetch→map→resolve→upsert     │  inventory / dimension / order ...
          └───┬───────────┬───────────┬───┘
     uses     │           │           │     uses
   ┌──────────▼──┐  ┌──────▼─────┐  ┌──▼────────────┐
   │ BcApiClient │  │  Mapper    │  │ ConfigProvider│
   │ (HTTP+OAuth)│  │ (Kaiba)    │  │ (per-tenant)  │
   └──────┬──────┘  └────────────┘  └───────────────┘
          │ uses
   ┌──────▼──────┐   ┌─────────────────┐
   │ AuthProvider│   │ StateStore       │ watermark, cursors, ref-ids, idempotency
   │ (token cache)│  └─────────────────┘
   └─────────────┘
```

| Layer | Responsibility | Key interface | SOLID |
|---|---|---|---|
| **AuthProvider** | acquire/cache/refresh OAuth token per tenant | `get_token(tenant) -> Token` | SRP; token cache swappable (DB/redis) |
| **BcApiClient** | authenticated HTTP: GET/POST/PATCH, pagination, retry, throttling | `get(path,params)`, `paginate(...)`, `post/patch(...)` | OCP: standard vs custom endpoints are data, not subclasses |
| **ConfigProvider** | resolve merged tenant config (env, company, entities, mappings, filters, flags) | `config(tenant) -> ConnectorConfig` | DIP: services depend on config abstraction |
| **Mapper** | transform BC payload ↔ WizCommerce shape via declarative mapping | `map(payload, mapping) -> dict` | SRP; no hardcoded fields |
| **EntityService<T>** | one entity's pull/push: fetch→map→resolve ids→upsert→persist state | `sync(tenant, window)` / `push(tenant, id)` | LSP: all entities share the same contract |
| **SyncOrchestrator** | select enabled entities, order by dependency, isolate failures | `run(tenant, request)` | SRP; adding an entity = new service + registry row |

**Extensibility rule:** adding an entity = implement `EntityService` + register it. Adding a tenant = insert a config row. **No new branches in shared code.**

---

## 2. Connector Configuration

A tenant is fully described by one config object (stored in DB; secrets in a separate secret store). Precedence: **global defaults → connector defaults → tenant overrides**. Missing key → default (safe republish, see §6).

What a tenant configures:

- **Environment & company** — BC environment name (e.g. `Production`), `company_id` (GUID), BC AAD tenant.
- **Authentication** — OAuth2 client-credentials: `client_id`, `client_secret` (secret store), token URL, scope `https://api.businesscentral.dynamics.com/.default`.
- **API strategy** — `odata_version` (`v2.0`), optional `custom_namespace` for AL APIs, per-entity `endpoint` + `has_custom_endpoint`.
- **Enabled entities + direction** — per entity: `pull`, `push_create`, `push_update`, `push_cancel`.
- **Field mappings** — declarative mapping (Kaiba) per entity+direction.
- **Filters** — OData filter clauses (e.g. `sellOnWebsite eq 'Yes'`), `date_filter_field`, `reference_id_field`.
- **Feature flags** — address sync on/off, archive orders, pricing strategy, inventory strategy, image sync.
- **Reliability knobs** — `page_size`, `pagination.style`, `concurrency.max_parallel`, `retry`, `incremental.overlap_seconds`.

See §8 for a complete JSON example.

---

## 3. End-to-End API Flow

Order is driven by data dependencies. Each step's output feeds the next.

| # | Step | API (standard unless noted) | Why / how response is used |
|---|---|---|---|
| 1 | **Authenticate** | `POST {tokenUrl}` (client credentials) | Bearer token cached until expiry; attached to all calls |
| 2 | **Company discovery** | `GET /api/v2.0/companies` | Validate/resolve `company_id`; all later paths are `companies({id})/...` |
| 3 | **Dimensions** | `GET …/dimensions`, `…/dimensionValues` | Reference catalog cached first; later used to resolve customer/item/order dims |
| 4 | **Customers (Buyer)** | `GET …/customers?$expand=defaultDimensions` (+contacts) | Upsert buyers; capture `number`/`id` as reference id; default dims mapped |
| 5 | **Ship-to addresses** | **custom** `…/wizShipToAddresses?$filter=customerNumber in (...)` | Linked to buyer by `customerNumber`; address `code` stored as address ref (§4) |
| 6 | **Products / items** | `GET …/items?$expand=defaultDimensions` (or custom item API) | Upsert products; capture item number; feeds pricing + inventory |
| 7 | **Pricing** | **custom** `…/wizCustomerPrices?$filter=…` (or `priceListLines`) | Customer/qty/date-aware prices; attached to product+customer (§ pricing) |
| 8 | **Inventory / availability** | **custom** `…/wizItemAvailabilities` (or `items.inventory`) | ATP per item/location without scanning all orders |
| 9 | **Orders (pull)** | `GET …/salesOrders?$expand=salesOrderLines($expand=item)` | Linked to buyer + items by reference ids |
| 10 | **Orders (push)** | `POST …/salesOrders` (+ dims) | Create in BC; persist returned `number` as order ref (idempotent, §7) |

Rules: pull reference data (dims) before entities that reference them; customers before addresses/orders; products before pricing/inventory. Each entity is independently enabled — disabled steps are skipped.

---

## 4. Buyer API & Shipping Addresses

**Buyer/Customer (standard):** `GET companies({id})/customers`. Identity = BC customer `number` (stable) — stored as the buyer's `reference_id`. Create/update decided by presence of that ref: **no ref → POST create; has ref → PATCH update.** Contacts via `$expand=contactsInformation($expand=contact)`; default dimensions via `$expand=defaultDimensions`.

**Ship-to addresses (proposed custom AL — standard v2.0 has no first-class ship-to API):**
Expose `wizShipToAddresses` (SourceTable *Ship-to Address*, keys `customerNumber`+`code`) so we can also carry tenant-defined attributes (e.g. delivery instructions).

- **Fetch:** `GET …/wizShipToAddresses?$filter=customerNumber eq '<n>'` — batch many customers with `customerNumber in (...)` to avoid N+1.
- **Link:** join to the buyer by `customerNumber`; one buyer → many addresses.
- **Store address id:** persist BC address **`code`** (unique per customer) as the address `reference_id`, so updates PATCH the right row and we never duplicate.
- **Create/push:** `POST …/wizShipToAddresses` with `customerNumber` + address fields; returned `code` stored back.
- **Enable/disable per tenant:** feature flag `entities.address.pull` / `push_create`. If off, the step is simply skipped — no code change.

Null/empty semantics: absent/null = leave unchanged; empty string = explicit clear; `code` never cleared.

---

## 5. Standard vs Custom APIs

| Entity | Standard BC v2.0 API | Use custom AL when… | Proposed custom (WZC) |
|---|---|---|---|
| Companies | `companies` | — | — |
| Customers | `customers` (+expand contacts, defaultDimensions) | extra BC fields not exposed | — |
| **Ship-to addresses** | *none first-class* | always (and for tenant attributes) | **`wizShipToAddresses`** |
| Products/items | `items` (+expand) | custom item fields / matrix | item-extended API if needed |
| **Customer pricing** | partial (base `unitPrice`; price list lines not fully exposed) | customer/qty/date pricing needed | **`wizCustomerPrices`** (SourceTable *Price List Line*) |
| **Availability/ATP** | `items.inventory` (global only) | per-location / future ATP | **`wizItemAvailabilities`** (query) |
| Dimensions / values | `dimensions`, `dimensionValues`, `defaultDimensions` | — | — |
| Sales orders | `salesOrders(+Lines)` | order write-back/notes fields | optional write API |
| Shipments | `salesShipments` | tracking numbers | **`wizShipmentTrackings`** |
| Invoices | `salesInvoices(+Lines)` | — | — |
| Payments | `customerPayments` | — | — |

Principle: **standard first; custom AL only to fill a real gap** (ship-to, customer pricing, ATP, tracking, tenant attributes). All custom pages share `wizcommerce/connector/v1.0` and support `$filter`/`$select`/`$top`/pagination.

---

## 6. Tenant-Specific Behavior

- **Same code, different config.** Tenant A: `entities.address.pull = true`; Tenant B: `false`. The orchestrator reads the flag and includes/skips the address service. No `if tenant == …` anywhere.
- **Standard vs custom per tenant** is just the `endpoint`/`has_custom_endpoint` value — one tenant hits standard `items`, another hits a custom item API, via config.
- **Republishing a connector version must not reset tenants.** Config is stored per tenant and **merged over new defaults**: new keys get defaults, existing tenant overrides are preserved. A new feature ships **off by default**; tenants opt in. Never overwrite stored tenant config on deploy.
- **Validation on save** (typed schema) rejects bad config early; runtime always falls back to defaults for absent keys (backward compatible).

---

## 7. Sync Reliability & Performance

- **Pagination:** prefer `@odata.nextLink`; `$top` page size from config (e.g. 100). Avoid `$skip` for large sets (drifts under writes).
- **Filters:** always send `$filter` with the incremental date + tenant filters; use `$select` to shrink payloads; `$expand` to fold sub-entities into one call (avoids N+1).
- **Incremental sync:** watermark = last successful `sync_start_time` captured **before** the fetch; query `date_field gt (watermark − overlap_seconds)`. Overlap + idempotent upsert prevents boundary loss. First run (no watermark) = full pull.
- **Retries:** exponential backoff + jitter on `429` (honor `Retry-After`), `5xx`, timeouts; refresh-once on auth error; fail fast on `400/403/404`/validation.
- **Idempotency:**
  - *Pull:* upsert keyed by `(tenant, entity, reference_id)` → re-runs are safe.
  - *Push:* generate a deterministic key per (tenant, document); **search-before-create** (or send `externalDocumentNo`); persist the BC ref in the **same** step as marking success → a worker crash after BC-create never duplicates.
- **Dependency ordering:** dimensions → customers → addresses → products → pricing → inventory → orders. One entity's failure is isolated; others proceed.
- **Avoid wasted calls:** cache stable metadata (companies, dimensions, UoM); change-detect images via ETag/`lastModifiedDateTime`; never re-fetch unchanged; bounded concurrency only (never bypass BC throttling).

---

## 8. Implementation Blueprint

### 8.1 Architecture (recap)
`SyncOrchestrator → EntityService → {BcApiClient(+AuthProvider), Mapper, ConfigProvider, StateStore}`.

### 8.2 Worked example — Buyer w/ 2 ship-to addresses, then products + pricing

```
Config: tenant T, company C, address.pull=true, pricing.strategy=wizCustomerPrices

1  AuthProvider.get_token(T)                → bearer (cached)
2  GET /api/v2.0/companies                  → resolve company C
3  GET …/dimensions, …/dimensionValues      → cache dim catalog
4  GET …/customers?$filter=lastModifiedDateTime gt (W-overlap)&$expand=defaultDimensions
       → buyer BUY-1001 (reference_id = number "1001")
5  GET …/wizShipToAddresses?$filter=customerNumber eq '1001'
       → [ {code:"MAIN", ...}, {code:"WH2", ...} ]
       → link both to BUY-1001; store address refs "MAIN","WH2"
6  Mapper.map(buyer+addresses, mapping[buyer])  → WizCommerce buyer payload
7  StateStore.upsert(buyer, addresses)          → persist (idempotent by number/code)
8  GET …/items?$filter=lastModifiedDateTime gt (W-overlap)&$expand=defaultDimensions
       → products; reference_id = item number
9  GET …/wizCustomerPrices?$filter=customerNumber eq '1001'
       → price lines (qty breaks, dates, UoM) → attach to product+customer
10 Mapper.map(product+price) → upsert products + customer prices
11 advance watermark W = sync_start_time (only on success)
```

Response transformation: BC JSON → `Mapper` (declarative) → normalized WizCommerce shape → `StateStore` upsert keyed by reference id. Pricing is **not** the item base price — it comes from `wizCustomerPrices` per customer.

### 8.3 Example tenant configuration JSON

```jsonc
{
  "connector_type": "business_central",
  "environment": "Production",
  "company_id": "<company-guid>",
  "auth_ref": "secret-store://bc/<tenant>",            // secrets never inline
  "api": { "odata_version": "v2.0",
           "custom_namespace": "/api/wizcommerce/connector/v1.0" },
  "pagination": { "style": "nextLink", "page_size": 100 },
  "concurrency": { "max_parallel": 5 },
  "retry": { "max_attempts": 5, "backoff_base_ms": 500, "respect_retry_after": true },
  "incremental": { "overlap_seconds": 120 },
  "entities": {
    "dimension": { "pull": true },
    "buyer":     { "pull": true, "push_create": true, "push_update": true,
                   "endpoint": "/api/v2.0/companies({company_id})/customers?$expand=defaultDimensions",
                   "reference_id_field": "number", "date_filter_field": "lastModifiedDateTime" },
    "address":   { "pull": true, "push_create": true,
                   "endpoint": "{custom_namespace}/companies({company_id})/wizShipToAddresses",
                   "filter_field": "customerNumber", "reference_id_field": "code" },
    "product":   { "pull": true,
                   "endpoint": "/api/v2.0/companies({company_id})/items?$expand=defaultDimensions",
                   "reference_id_field": "number", "date_filter_field": "lastModifiedDateTime",
                   "filters": [] },
    "price":     { "pull": true, "strategy": "wizCustomerPrices",
                   "endpoint": "{custom_namespace}/companies({company_id})/wizCustomerPrices",
                   "filter_field": "customerNumber" },
    "inventory": { "pull": true, "strategy": "wizItemAvailabilities",
                   "endpoint": "{custom_namespace}/companies({company_id})/wizItemAvailabilities",
                   "reference_id_field": "itemNumber", "date_filter_field": "lastModifiedDateTime" },
    "order":     { "pull": true, "push_create": true,
                   "endpoint": "/api/v2.0/companies({company_id})/salesOrders?$expand=salesOrderLines($expand=item)" }
  },
  "feature_flags": { "address_sync": true, "archive_orders": false, "image_sync": false }
}
```

*Another tenant simply sets `entities.address.pull=false` / `feature_flags.address_sync=false` to disable addresses — no code change.*

### 8.4 Implementation checklist

- [ ] `AuthProvider` with token cache (shared across workers) + 5-min early refresh.
- [ ] `BcApiClient`: GET/POST/PATCH, `nextLink` pagination, `$filter/$select/$expand`, retry+backoff (429/5xx), redaction.
- [ ] `ConnectorConfig` typed schema + validation on save; default-merge on load (safe republish).
- [ ] `ConfigProvider` resolving merged per-tenant config.
- [ ] `Mapper` (declarative/Kaiba) per entity+direction; explicit null/empty/zero semantics.
- [ ] `StateStore`: idempotent upsert by `(tenant, entity, reference_id)`; watermark + overlap; push idempotency key.
- [ ] `EntityService` implementations: dimension, buyer, address, product, price, inventory, order.
- [ ] `SyncOrchestrator`: enablement check + dependency ordering + per-entity failure isolation.
- [ ] Custom AL pages (publisher `wizcommerce`, group `connector`, v1.0): `wizShipToAddresses`, `wizCustomerPrices`, `wizItemAvailabilities`, `wizShipmentTrackings` (+ dimensions use standard).
- [ ] Idempotent order/payment push (search-before-create + atomic ref persist).
- [ ] Observability: per-call timing + correlation id; sync run status; failed-record list.
- [ ] Tests: pagination, incremental boundary, retry, duplicate-prevention, address link, pricing priority, tenant enable/disable, republish-preserves-config.

---

### Standard vs Proposed Custom — quick reference
- **Standard:** companies, customers, items, dimensions, dimensionValues, defaultDimensions, salesOrders, salesInvoices, salesShipments, customerPayments.
- **Proposed custom (WZC):** `wizShipToAddresses`, `wizCustomerPrices`, `wizItemAvailabilities`, `wizShipmentTrackings` — only where standard v2.0 lacks the field/behavior. No other endpoints assumed.
