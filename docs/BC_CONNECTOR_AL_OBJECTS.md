# WizCommerce BC Connector — Custom API Footprint & Final AL Object Architecture

**Purpose:** (1) count the custom APIs actually in use, (2) define the **final, unified AL object structure** (object-oriented) to replace them with one shared app: publisher `wizcommerce`, group `connector`.
**Evidence:** endpoints extracted from live tenant config (`integration_workflows.data`, Redash `pgsql-p-ultron-01-replica2`). 🗄️ = verified in config.

---

## 1. How Many Custom APIs Are We Calling Today?

**12 custom endpoints in use → 11 distinct AL objects → 8 logical capabilities**, spread across **3 bespoke per-tenant namespaces** (one per customer BC tenant).

| # | Tenant | Entity | Custom endpoint (object) | Logical capability |
|---|---|---|---|---|
| 1 | Browne | buyer | `…/BrowneGroupIncAPI/…/customers?$expand=shipToAddresses` | Customer + addresses |
| 2 | Browne | product | `…/BrowneGroupIncAPI/…/items?$expand=priceListLines` | Item + customer pricing |
| 3 | Browne | inventory | `…/BrowneGroupIncAPI/…/inventoryitems` | Availability |
| 4 | Browne | order push | `…/BrowneGroupIncAPI/…/salesOrderWs` (+`({ref})`) | Order write-back / notes |
| 5 | Browne | shipment | `…/BrowneGroupIncAPI/…/shipments` | Shipment tracking |
| 6 | Atlas | buyer pricing | `…/atlas/atlas/v1.0/…/customerExtended` | Customer pricing group |
| 7 | Atlas | address | `…/atlas/atlas/v1.0/…/customerAddresses/` | Ship-to addresses |
| 8 | Atlas | product | `…/atlas/atlas/v1.0/…/itemMatrixWizCom?$expand=ItemPricing` | Item + matrix pricing |
| 9 | Atlas | inventory | `…/atlas/atlas/v1.0/…/inventoryFeedItems?$expand=futureAvailability` | Availability + future ATP |
| 10 | Atlas | shipment | `…/atlas/atlas/v1.0/…/ShipmentTracking` | Shipment tracking |
| 11 | Atlas | order archive | `…/atlas/atlas/v1.0/…/salesorderExpandArchiveLatest?$expand=salesOrderLineArchive` | Archived orders |
| — | Art Studios | all | `…/CharlesProductsInc/WizCommerce/v2.0/…` (full bespoke namespace) | all of the above |

**The 8 logical custom capabilities the unified app must provide:**
1. Customer (+ ship-to addresses, + price group)  2. Ship-to addresses  3. Customer pricing  4. Item (+ web flag, + matrix)  5. Inventory / availability (+ future ATP)  6. Shipment tracking  7. Order write/push (+ notes)  8. Archived orders.

**Goal:** collapse 3 namespaces × ~11 objects into **one** `wizcommerce/connector` surface. Standard BC v2.0 APIs cover the rest (dimensions, invoices, payments, base customers/items/orders).

---

## 2. Design Principles (object-oriented AL)

- **One app, one namespace, one version line.** `APIPublisher='wizcommerce'`, `APIGroup='connector'`, `APIVersion='v2.0'` (superset). Keep `v1.0` published for back-compat; new fields land in `v2.0`.
- **One API page per entity, superset of fields.** Tenants don't get different pages — they get the **same page** and choose which fields WizCommerce reads via the **Field Visibility** framework (already in the app). This is how one API serves Browne, Atlas, Art Studios.
- **Composition over expansion.** Sub-entities (addresses, price lines, order lines, future availability) are **API parts** (`part(...) ... SubPageLink`) so consumers get them via `$expand` in one call — replacing the per-tenant `$expand=shipToAddresses` / `priceListLines` / `ItemPricing` / `futureAvailability`.
- **Custom fields via table extensions + tenant attributes.** Real columns for known fields; the generic K/V **Attribute** framework for tenant-defined fields (no redeploy to add one).
- **Separation of concerns:** API pages = projection only; business logic in codeunits; config in setup tables; access in one permission set.

---

## 3. Final AL Object Catalog

IDs use the app's range `50100–55099`. ✅ = already exists in the app; ➕ = to build. Grouped by the architecture the user asked for: **BUYER, PRODUCT, INVENTORY, ORDER** (+ shared core).

### 3.0 Shared / Core (foundation for all entities)

| Obj | Type | Id | Name | Role |
|---|---|---|---|---|
| ✅ | permissionset | 50100 | `WZC CONNECTOR` | single least-privilege set for the integration user |
| ✅ | table | 50110 | `WZC Connector Setup` | global connector settings |
| ✅ | table | 50112 | `WZC Api Config` | per-API enable/version |
| ✅ | table | 50121 | `WZC Field Visibility` | **which fields each entity exposes per tenant** |
| ✅ | codeunit | 50117 | `WZC Field Visibility Mgt` | reads visibility → gates fields on API pages |
| ✅ | codeunit | 50110 | `WZC Setup Mgt` | setup/seed, `EnforceApiAccess` |
| ✅ | codeunit | 50111 | `WZC Install` | install/upgrade seed (preserves tenant config) |
| ✅ | table/cu | 50117/50112 | `WZC Attribute Mapping` / `WZC Attribute Mgt` | tenant-defined custom fields (K/V) |
| ➕ | codeunit | 50130 | `WZC Api Base` | shared helpers: filtering, paging hints, error shape, company scope |

**OO pattern — every API page follows the same shape:**
```al
page 5010X "WZC <Entity> API"
{
    PageType = API; APIPublisher='wizcommerce'; APIGroup='connector'; APIVersion='v2.0';
    EntityName='wiz<Entity>'; EntitySetName='wiz<Entity>s'; SourceTable="<BC Table>";
    DelayedInsert=true; Extensible=false;
    // repeater: standard fields + extension fields, each gated by WZC Field Visibility
    // part(...) for sub-entities (addresses/lines/prices/availability)
    trigger OnOpenPage() begin SetupMgt.EnforceApiAccess('<CODE>', CurrPage.Caption); end;
}
```

---

### 3.1 BUYER  (replaces: Browne `customers?$expand=shipToAddresses`, Atlas `customerExtended` + `customerAddresses`)

| Obj | Type | Id | Name | Source table | Keys | Exposes / replaces |
|---|---|---|---|---|---|---|
| ➕ | page (API) | 50105 | `WZC Customer API` | `Customer` | No. | customer + price group + default dims; `part` → addresses, `part` → contacts. Replaces Browne `customers?$expand=shipToAddresses` & Atlas `customerExtended` |
| ✅ | page (API) | 50100 | `WZC Ship-to Address API` | `Ship-to Address` | Cust.No., Code | ship-to list; replaces Atlas `customerAddresses`, Browne `shipToAddresses` |
| ✅ | page (part) | 50123 | `WZC Ship-to Attr Part` | `WZC Ship-to Attribute` | — | `$expand=shipToAttributes` inline on address |
| ➕ | page (part) | 50106 | `WZC Customer Address Part` | `Ship-to Address` | — | addresses inline under customer (`$expand=addresses`) |
| ➕ | page (part) | 50107 | `WZC Customer Contact Part` | `Contact`/`Contact Inf.` | — | contacts inline (replaces std `contactsInformation` expand) |
| ✅ | tableext | 50110 | `WZC Ship-to Address Ext` | `Ship-to Address` | — | delivery instructions + tenant attrs |
| ➕ | tableext | 50111 | `WZC Customer Ext` | `Customer` | — | web/price-group/custom flags |

**Flow:** `GET …/wizCustomers?$expand=addresses,contacts&$filter=number in (…)` → one call returns buyer + all ship-to addresses + contacts. Address id = `code`.

---

### 3.2 PRODUCT  (replaces: Browne `items?$expand=priceListLines`, Atlas `itemMatrixWizCom?$expand=ItemPricing`)

| Obj | Type | Id | Name | Source table | Keys | Exposes / replaces |
|---|---|---|---|---|---|---|
| ➕ | page (API) | 50108 | `WZC Item API` | `Item` | No. | item + UoM + web flag + default dims; `part` → prices, `part` → variants. Replaces Browne `items`, Atlas `itemMatrixWizCom` |
| ✅ | page (API) | 50102 | `WZC Customer Price API` | `Price List Line` | Price List Code, Line No. | customer/qty/date pricing. Replaces `priceListLines` / `ItemPricing` |
| ➕ | page (part) | 50109 | `WZC Item Price Part` | `Price List Line` | — | prices inline (`$expand=prices`) |
| ➕ | page (part) | 50113 | `WZC Item Variant Part` | `Item Variant` | — | variants inline (if tenant uses variants) |
| ➕ | tableext | 50112 | `WZC Item Ext` | `Item` | — | `sellOnWebsite`, matrix/custom attrs (Atlas `sellOnWebsite eq Yes`) |

**Flow:** `GET …/wizItems?$expand=prices&$filter=sellOnWebsite eq true` → item + customer-aware prices in one call. Pricing is **not** the item base price.

---

### 3.3 INVENTORY  (replaces: Browne `inventoryitems`, Atlas `inventoryFeedItems?$expand=futureAvailability`)

| Obj | Type | Id | Name | Source table | Keys | Exposes / replaces |
|---|---|---|---|---|---|---|
| ✅ | query (API) | 50103 | `WZC Item Availability` | `Item` | No. | global qty + ATP **without scanning all SO/PO**. Replaces Browne `inventoryitems` |
| ➕ | page (API) | 50114 | `WZC Inventory Feed API` | `Item` | No. | on-hand + reserved + `part` futureAvailability. Replaces Atlas `inventoryFeedItems` |
| ➕ | page (part) | 50115 | `WZC Future Availability Part` | `Item Ledger Entry`/calc | — | inbound/future ATP (`$expand=futureAvailability`) |
| ➕ | query (API) | 50116 | `WZC Inventory By Location` | `Item Ledger Entry`/`Warehouse Entry` | Item No., Location | per-location ATP |
| ➕ | codeunit | 50131 | `WZC Availability Calc` | — | ATP/reserved/future math server-side (moves it off the Python client) |

**Flow:** `GET …/wizInventoryFeed?$expand=futureAvailability&$filter=lastModifiedDateTime gt <w>` → availability computed in AL, one call per page.

---

### 3.4 ORDER  (replaces: Browne `salesOrderWs`, Atlas `salesorderExpandArchiveLatest`, shipments)

| Obj | Type | Id | Name | Source table | Keys | Exposes / replaces |
|---|---|---|---|---|---|---|
| ➕ | page (API) | 50117 | `WZC Sales Order API` | `Sales Header` | No. | read orders + `part` lines + `part` dims. (pull) |
| ➕ | page (API) | 50118 | `WZC Sales Order Write API` | `Sales Header` | No. | **push** create/update + notes; supports idempotency key (`External Document No.`). Replaces Browne `salesOrderWs` |
| ➕ | page (part) | 50119 | `WZC Sales Order Line Part` | `Sales Line` | — | lines inline (`$expand=lines`) |
| ➕ | page (API) | 50120 | `WZC Sales Order Archive API` | `Sales Header Archive` | No., Version | archived orders + lines. Replaces Atlas `salesorderExpandArchiveLatest` |
| ✅ | page (API) | 50101 | `WZC Shipment Tracking API` | `Sales Shipment Header` | No. | tracking. Replaces Browne `shipments`, Atlas `ShipmentTracking` |
| ➕ | page (part) | 50122 | `WZC Order Dimension Part` | `Dimension Set Entry` | — | header/line dimensions on push |
| ➕ | codeunit | 50132 | `WZC Order Write Mgt` | — | validate dims/combinations, set dimension set, idempotent create |

**Flow (push):** `POST …/wizSalesOrderWrite` with `externalDocumentNo=<idempotency key>` → AL checks for existing order with that key (**search-before-create**) → creates once → returns `number`. Notes/lines/dims set in the same call via parts.

---

### 3.5 Dimensions — **standard APIs, no custom objects**

Use BC standard `dimensions`, `dimensionValues`, and `$expand=defaultDimensions` on customer/item. Only the **order dimension part** (50122) is custom, to set dims on pushed orders.

---

## 4. Summary — objects to build

| Entity | Reuse (✅) | Build (➕) |
|---|---|---|
| Buyer | Ship-to Address API, Attr Part, Ship-to Ext | Customer API, Address Part, Contact Part, Customer Ext |
| Product | Customer Price API | Item API, Item Price Part, Variant Part, Item Ext |
| Inventory | Item Availability query | Inventory Feed API, Future Avail Part, By-Location query, Availability Calc cu |
| Order | Shipment Tracking API | Sales Order API, Order Write API, Line Part, Archive API, Dim Part, Order Write Mgt cu |
| Core | Permissionset, Setup/Config/Visibility/Attribute tables+cu, Install | Api Base cu |

**Totals:** replaces **11 bespoke objects across 3 namespaces** with **~20 objects in 1 unified namespace** (6 already exist). Every tenant uses the same objects; Field Visibility + Attributes + config decide behavior.

---

## 5. Build Order (dependency-safe)

1. **Core:** `WZC Api Base`, confirm Field Visibility + Attribute + Setup (mostly ✅).
2. **Buyer:** Customer API + Address/Contact parts + Customer Ext (highest reuse value; addresses are the common pain).
3. **Product + Pricing:** Item API + Item Price Part + Item Ext (unblocks pricing correctness).
4. **Inventory:** Inventory Feed API + Availability Calc (removes all-SO/PO scan).
5. **Order:** Sales Order API + Write API (idempotent) + Archive API + Dim Part.
6. **Per tenant:** assign `WZC CONNECTOR` permission set, set Field Visibility + Attributes, point the Python config `endpoint` at `/api/wizcommerce/connector/v2.0/...`. No code per tenant.


---

## 6. As built — app version 1.1.0.0

Everything marked ➕ in §3 now exists in `src/`. The catalogue IDs in §3 were **proposals**; the app's `50105–50123` block was already occupied by setup/attribute/sync pages, so the new objects took a clean `50130+` block. Nothing in §3 changed semantically — only the numbers.

### 6.1 Object map (proposed → built)

| Entity | §3 proposal | Built object | Entity set (v2.0) | Api Operation |
|---|---|---|---|---|
| Core | cu 50130 `WZC Api Base` | codeunit 50130 `WZC Api Base` | — | — |
| Core | — | codeunit 50133 `WZC Upgrade` (seed-only, never resets tenant config) | — | — |
| Buyer | page 50105 `WZC Customer API` | page 50130 `WZC Customer API` | `wizCustomers` | `CUSTOMER` |
| Buyer | part 50106 Address | page 50131 `WZC Customer Address Part` | `…/wizCustomerAddresses` | — |
| Buyer | part 50107 Contact | page 50132 `WZC Customer Contact Part` | `…/wizCustomerContacts` | — |
| Buyer | tableext 50111 Customer Ext | tableextension 50111 `WZC Customer Ext` (`WZC External Id`, `WZC Web Customer`) | — | — |
| Product | page 50108 `WZC Item API` | page 50133 `WZC Item API` | `wizItems` | `ITEM` |
| Product | part 50109 Price | page 50134 `WZC Item Price Part` | `…/wizItemPrices` | — |
| Product | part 50113 Variant | page 50135 `WZC Item Variant Part` | `…/wizItemVariants` | — |
| Product | — | page 50136 `WZC Item UoM Part` | `…/wizItemUnitsOfMeasure` | — |
| Product | tableext 50112 Item Ext | tableextension 50112 `WZC Item Ext` (`WZC Sell On Website`, `WZC External Id`) | — | — |
| Inventory | page 50114 Inventory Feed | page 50137 `WZC Inventory Feed API` | `wizInventoryFeedItems` | `INVFEED` |
| Inventory | part 50115 Future Avail | page 50138 `WZC Future Availability Part` (open PO lines) | `…/wizFutureAvailabilities` | — |
| Inventory | query 50116 By Location | query 50130 `WZC Inventory By Location` | `wizInventoryByLocations` | `INVBYLOC` |
| Inventory | cu 50131 Availability Calc | codeunit 50131 `WZC Availability Calc` | — | — |
| Order | page 50117 Sales Order API | page 50139 `WZC Sales Order API` | `wizSalesOrders` | `SALESORDER` |
| Order | page 50118 Write API | page 50142 `WZC Sales Order Write API` | `wizSalesOrderWrites` | `SALESORDERWRITE` |
| Order | part 50119 Line | page 50140 `WZC Sales Order Line Part` (shared by read + write) | `…/wizSalesOrderLines` | — |
| Order | page 50120 Archive API | page 50143 `WZC Sales Order Archive API` | `wizSalesOrderArchives` | `SALESORDERARCH` |
| Order | — | page 50144 `WZC Sales Order Arch Line Part` | `…/wizSalesOrderArchiveLines` | — |
| Order | part 50122 Dimension | page 50141 `WZC Order Dimension Part` (read) | `…/wizSalesOrderDimensions` | — |
| Order | cu 50132 Order Write Mgt | codeunit 50132 `WZC Order Write Mgt` | — | — |
| Order | — | tableextension 50113 `WZC Sales Header Ext` / 50114 `WZC Sales Header Arch Ext` (`WZC External Id`, `WZC Order Notes`, `WZC Source`) | — | — |
| Tests | — | codeunit 50134 `WZC Entity Api Tests` | — | — |

Base path for everything new: `/api/wizcommerce/connector/v2.0/companies({companyId})/`. The four v1.0 endpoints are untouched.

### 6.2 How "same page, different tenant" works

| Mechanism | Where it is configured in BC | Effect |
|---|---|---|
| **Enable / disable + rate limit** per API | *WZC Connector API Configuration* (rows auto-seeded: `CUSTOMER`, `ITEM`, `INVFEED`, `INVBYLOC`, `SALESORDER`, `SALESORDERWRITE`, `SALESORDERARCH`) | `EnforceApiAccess` on open |
| **Field set** per API | *WZC Field Visibility* keyed by the Api Operation above + the camelCase API field name | Writable `wizCustomers` uses buffer variables (safe for PATCH); read-only `wizItems` / `wizSalesOrders` blank hidden fields in memory via `WZC Api Base.BlankHiddenFields` |
| **Business-rule filters** (Browne `RTMASTER`, Atlas `sellOnWebsite`) | *WZC Sync Profile* (Entity = Customers / Products, Api Operation = `CUSTOMER` / `ITEM` / `INVFEED`, Direction = Pull) with Filter Rules on `Customer Price Group`, `WZC Sell On Website`, … | Applied by `WZC Api Base.ApplyPullProfileTo*` on open |
| **Location scoping** of every quantity | *WZC Connector Setup → Location Filter* | `ApplyLocationFilter` on `wizItems` / `wizInventoryFeedItems` |
| **Tenant-defined fields** | *WZC Attribute Mapping* + `wizShipToAttributes` (v1.0) | unchanged |

### 6.3 Idempotent push (closes the duplicate-order risk)

`POST …/wizSalesOrderWrites` with `externalId` = WizCommerce document id (+ `wizSalesOrderLines` deep insert + `orderNotes`):

1. `OnInsertRecord` → `WZC Order Write Mgt.FindExistingOrderByExternalId` (indexed key on `WZC External Id`). Found → the existing order is returned, nothing is created.
2. Not found → `Insert(true)` (No. Series), `ValidateDimensions` (combination + blocked/mandatory values for customer & salesperson, surfaced as a normal 400), `WriteNotesAsComments` (Sales Comment Lines, Code = `WZC`, 80-char chunks, replaced on every write, manual comments untouched).
3. The same pattern protects buyers: `POST …/wizCustomers` with `externalId` adopts an existing customer.

So a WizCommerce worker that dies between "BC created the order" and "ref persisted" simply retries the same POST and gets the same `number` back.

### 6.4 Availability without scanning orders

`wizInventoryFeedItems` returns, per item and already location-scoped:

| Field | Formula (BC FlowFields) |
|---|---|
| `availableQuantity` | `Inventory − Qty. on Sales Order` |
| `availableInventory` | `Inventory − Reserved Qty. on Inventory` (BC "Available Inventory") |
| `projectedAvailableQuantity` | `availableQuantity + Qty. on Purch. Order` |
| `wizFutureAvailabilities` | open purchase order lines: outstanding qty + expected / promised / planned receipt date |

`wizInventoryByLocations` (query) gives on-hand per item / variant / location from Item Ledger Entries.

### 6.5 Deliberate scope limits

- **Dimension lines on push** are read-only (`wizSalesOrderDimensions`); push sets `shortcutDimension1Code/2Code` on header and lines, and the dimension set is validated before acceptance. A writable dimension-line part (BC's buffer-table pattern) is a follow-up.
- `wizCustomerContacts` returns the contacts linked through *Contact Business Relation* (company contact). Person contacts of that company are not expanded.
- `WZC Sell On Website` / `WZC Web Customer` are plain Boolean columns a tenant sets in BC (or maps through the standard customer/item card); no page extension was added for them yet.
- Not runtime-tested against a sandbox in this change: compile is clean (`alc` 18.1, platform/application 29.0 symbols) and unit tests cover the filter engine, order-write idempotency, note chunking, availability math and field blanking. The API page triggers (deep insert, `OnInsertRecord` adoption) follow the patterns already proven in `wizShipToAttributes`.
