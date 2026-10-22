# business-central-app-connector

WizCommerce Business Central Connector `.app` — custom OData APIs that fill gaps Microsoft’s standard `/api/v2.0` does not expose.

Used with existing **Business Central V2** via `workflow.data` only. No V1 changes. No new integration type.

## API contract (locked)

| Property | Value |
|---|---|
| APIPublisher | `wizcommerce` |
| APIGroup | `connector` |
| APIVersion | `v1.0` |

Base path:

```
/api/wizcommerce/connector/v1.0/companies({companyId})/
```

## Endpoints

| Entity set | Source | Ops |
|---|---|---|
| `wizShipToAddresses` | Ship-to Address (curated field set) | GET, POST, PATCH |
| `wizShipToAddressesFull` | Ship-to Address (every standard field) | GET, POST, PATCH |
| `wizShipToAttributes` | WZC Ship-to Attribute (tenant-defined custom fields) | GET, POST, PATCH, DELETE |
| `wizShipmentTrackings` | Sales Shipment Header | GET |
| `wizCustomerPrices` | Price List Line | GET |
| `wizItemAvailabilities` | Item (incl. Global Dimension 1/2 Code) | GET |

Every endpoint above calls `WZC Setup Mgt.EnforceApiAccess(...)` on open — this
enables/disables the API **and** enforces its per-hour rate limit, both configured
per company in **WZC Api Config**. See [Tenant-wise configuration](#tenant-wise-configuration-per-install) below.

## Project layout

```
├── app.json
├── .vscode/launch.json
├── src/
│   ├── Tables/
│   │   ├── WZCConnectorSetup.Table.al        (50110) — per-company data filters (Location, Price List)
│   │   ├── WZCApiConfig.Table.al             (50112) — per-API enable + rate limit, self-registering
│   │   ├── WZCShipToAttribute.Table.al       (50113) — tenant-defined custom attribute values
│   │   ├── WZCAttributeMapping.Table.al      (50117) — "WZC Attribute Setup" config: name, type, default, required, sync direction, storage mode
│   │   └── WZCAttributeChangeLog.Table.al    (50118) — audit trail: config changes + sync errors
│   ├── TableExtensions/
│   │   └── WZCShipToAddressExt.TableExt.al   (50110) — adds the one "real field" example: WZC Create Address
│   ├── Enums/
│   │   ├── WZCAttributeDataType.Enum.al      (50110) — Text/Number/Date/Boolean
│   │   ├── WZCAttributeSyncDirection.Enum.al (50111) — Pull/Push/Both
│   │   └── WZCAttributeStorageMode.Enum.al   (50112) — Flexible/RealField
│   ├── Codeunits/
│   │   ├── WZCSetupMgt.Codeunit.al           (50110) — EnforceApiAccess (enable check + rate limit)
│   │   ├── WZCInstall.Codeunit.al            (50111) — seeds WZC Api Config + example attribute mapping
│   │   ├── WZCAttributeMgt.Codeunit.al       (50112) — validation, ownership check, auto-discovery, logging
│   │   └── WZCAttributeTests.Codeunit.al     (50113) — Subtype=Test, self-contained automated tests
│   ├── Pages/
│   │   ├── WIZShipToAddressAPI.al            (50100) "WZC Ship-to Address API"
│   │   ├── WIZShipmentTrackingAPI.al         (50101) "WZC Shipment Tracking API"
│   │   ├── WIZCustomerPriceAPI.al            (50102) "WZC Customer Price API"
│   │   ├── WIZItemAvailabilityAPI.al         (50103) "WZC Item Availability"
│   │   ├── WZCShipToAddressFullAPI.al        (50104) "WZC Ship-to Address Full API" (incl. wzCreateAddress)
│   │   ├── WZCShipToAttributeAPI.al          (50114) "WZC Ship-to Attribute API" (idempotent POST)
│   │   ├── WZCConnectorSetupCard.Page.al     (50111) — admin UI: data filters, links to the others below
│   │   ├── WZCShipToAttributeList.Page.al    (50115) — admin UI: browse/edit raw attribute values
│   │   ├── WZCApiConfigList.Page.al          (50116) — admin UI: enable + rate limit per API
│   │   ├── WZCAttributeSetup.Page.al         (50119) — admin UI: the attribute configuration list
│   │   ├── WZCAttributeSetupWizard.Page.al   (50120) — guided New Attribute → Configure → Validate → Activate
│   │   └── WZCAttributeChangeLogPage.Page.al (50121) — admin UI: audit trail viewer
│   └── PermissionSets/
│       └── WIZConnector.PermissionSet.al     (50100) "WZC CONNECTOR"
└── examples/
    ├── workflow.data.connector.json
    ├── workflow.data.ship-to.json
    ├── postman-connector.http
    └── postman-ship-to.http
```

## Tenant-wise configuration (per install)

This is one `.app`, installed once per customer's Business Central environment —
there is no multi-tenant key inside this extension, because **the BC environment
itself is the tenant boundary**. Each install configures its own behavior in two
admin pages (open via Tell Me, or from **WizCommerce Connector Setup**'s action bar):

### WZC Api Config (Tell Me → "WizCommerce Connector API Configuration")

One row per API, auto-created on install/upgrade (or click **Refresh API List** if a
row is missing after an upgrade):

| Field | Effect |
|---|---|
| Enabled | Off = that API errors instead of returning data. |
| Rate Limit Per Hour | 0 = unlimited. Otherwise a fixed-window (resets every rolling hour) per-company cap, enforced inside AL — independent of, and typically well below, Microsoft's own platform-level API throttling (which is tenant-wide and not configurable). This is how you give Tenant A 500/hr and Tenant B 600/hr on the *same* extension. |
| Type *(read-only)* | Which Sync Entity this API maps to (Product / Ship-to Address / Price), blank if none. |
| Filter *(read-only)* | At-a-glance filter status: `None configured`, `N profile(s), none active`, `Active (N)`, or `Not wired yet` for entities the filter engine doesn't support yet. |

Click **Configure Filter** on a row to drill into (or create) the sync profile for
that API — see [WZC API Filter & Sync](#wzc-api-filter--sync-phase-1-products-only) below.

The runtime rate-limit counters (`Window Start`/`Call Count`) now live in a
**separate internal table**, `WZC Api Rate State` — never shown on any page. The old
fields are kept on `WZC Api Config` as `ObsoleteState = Pending` (required — they
were already live in a published version, so they can't just be deleted).

**Root cause of the `"The date is not valid"` error (confirmed via the AL call
stack, not guessed):** it fired from `WZC Setup Mgt.CheckAndIncrementRateLimit`,
triggered by an actual API call once Rate Limit Per Hour was non-zero (`0` exits
the procedure immediately, which is why `0` always "worked" - it never reached the
buggy line). The code was:
```al
if (RateState."Window Start" = 0DT) or (CurrentDateTime() - RateState."Window Start" > WindowLengthMs) then
```
AL's `or` does not reliably short-circuit, so the subtraction on the right side was
being evaluated even when `Window Start` was blank (`0DT`) - subtracting from an
uninitialized DateTime is what the platform rejects as "not a valid date." Fixed by
restructuring into nested `if`/`else` so the subtraction can only execute once
`Window Start` is already confirmed non-blank:
```al
if RateState."Window Start" = 0DT then
    ...
else
    if CurrentDateTime() - RateState."Window Start" > WindowLengthMs then
        ...
```
The identical pattern existed in `WZC Checkpoint Mgt.StartRun`'s stale-run check and
was fixed the same way. Moving the fields to a separate table (the previous attempt)
didn't address this - it was never about *where* the field lived, only about the
arithmetic being unconditionally evaluated.

### WZC Connector Setup (Tell Me → "WizCommerce Connector Setup")

| Field | Effect |
|---|---|
| Location Filter | Scopes `wizItemAvailabilities` (`Inventory`, `Qty. on Purch./Sales Order`) to a single location via BC's standard `Item."Location Filter"` FlowFilter. Blank = all locations. |
| Price List Filter | Scopes `wizCustomerPrices` to one `Price List Code`. Blank = all price lists. |

### What still lives on the WizCommerce backend, not here

Cross-tenant field-name mapping for dynamic fields (resolving *which* attribute name
a given tenant calls something — the attribute **values** themselves are now stored
here, see below), archived-orders toggle (not part of this connector — Microsoft
APIv2 exposes sales order archives directly), and chain-wise entity dependencies
(e.g. contact depends on buyer). Those live in the tenant's `integration_workflow.data`
config on the backend, since the backend is the one system with a `tenant_id`
spanning every customer's BC environment.

## Global Dimension codes on Item Availability

`wizItemAvailabilities` now includes `dimension1Code` / `dimension2Code`, sourced
directly from Item's standard `Global Dimension 1 Code` / `Global Dimension 2 Code`
fields. This is the real, native BC "Dimension Code" concept — every tenant's Chart
of Dimensions is their own; one tenant might use Global Dimension 1 for "Product
Line", another for "Territory". We don't interpret the value, just pass through
whatever each tenant has configured — resolving what a given code *means* for a
specific tenant is a backend-side, per-tenant mapping concern (same pattern as the
custom-attribute name mapping below), not something this AL extension can know.

## Tenant-wise custom attributes on Ship-to Address (fetch + push)

**The problem:** different tenants have different custom fields on their Ship-to
Addresses (one calls it "GST Number", another "Delivery Window"), and we can't
redeploy this extension per tenant just to add a field.

**The fix — two storage paths, chosen per attribute in the ERP UI:**

| Mode | Where the value lives | When to use |
|---|---|---|
| **Flexible** | Generic key-value row in `WZC Ship-to Attribute` | Any attribute. Zero AL, zero redeploy — the default. |
| **Real Field** | An actual AL table-extension field on Ship-to Address | Only for attributes that ship with this extension's code (currently one: `CreateAddress`, backed by the real `WZC Create Address` Boolean field, exposed on `wizShipToAddressesFull`). A genuinely *new* real field always requires an AL change + redeploy — no configuration can create a compiled table field at runtime. |

### Administrator guide

**Initial setup (once per company, after installing/upgrading the extension):**
1. Tell Me → **"WizCommerce Attribute Setup"**
2. On install, one example mapping is pre-seeded: `CreateAddress` → tenant name
   `WizCommerce_Create_Address`, Boolean, Storage Mode = Real Field, Enabled — this
   is the worked example of the real-field path.

**Adding a new attribute (no AL, guided):**
1. From WZC Attribute Setup, click **New Attribute (Guided)**
2. **Step 1 – New Attribute:** enter a Logical Name (stable, internal — WizCommerce's
   key) and the Attribute Name this company wants to use (what gets sent over the API)
3. **Step 2 – Configure:** Data Type, Default Value, Required, Sync Direction, Storage
   Mode (pick Flexible unless you know this logical name has a real field)
4. **Step 3 – Validate:** runs type/consistency checks against what you entered;
   must say `OK` before you can continue
5. **Step 4 – Activate:** choose whether to enable it immediately, then **Activate**

**Troubleshooting:**
- *"Attribute is disabled"* on write → check Enabled on WZC Attribute Setup for that
  Logical Name.
- *"This attribute is backed by a real field"* on write to `wizShipToAttributes` →
  use `wizShipToAddressesFull` instead for that one field; the error names which field.
- A mapping appears with **Auto Discovered** = Yes and Enabled = No → a value arrived
  for an attribute name nobody configured yet. The write still succeeded (so pushes
  aren't blocked by missing config), but review and explicitly enable it once you're
  sure it's intentional.
- Check **WZC Attribute Change Log** (action on WZC Attribute Setup) for a full audit
  trail of every mapping create/modify/delete, plus any sync errors logged via
  `WZC Attribute Mgt.LogSyncError`.

**Upgrades:** adding a new *Flexible* attribute never requires an extension upgrade.
Adding a new *Real Field* attribute does — follow the same table-extension pattern as
`WZC Ship-to Address Ext` / `WZC Create Address`, then teach `WZC Attribute Mgt`'s
`IsRealFieldSupported` about the new logical name.

### Fetch (WizCommerce backend reads it)

```
GET /api/wizcommerce/connector/v1.0/companies({companyId})/wizShipToAttributes
    ?$filter=customerNumber eq '10000' and shipToCode eq 'MAIN'
```
Returns every attribute row for that address, plus a read-only `logicalName` column
resolved from WZC Attribute Setup (blank if nobody's configured a mapping for that
name yet).

### Push (WizCommerce backend writes it)

```
POST /api/wizcommerce/connector/v1.0/companies({companyId})/wizShipToAttributes
{
  "customerNumber": "10000",
  "shipToCode": "MAIN",
  "attributeName": "GST Number",
  "attributeValue": "27AAAAA0000A1Z5",
  "dataType": "Text"
}
```
POST is **idempotent** — posting the same `(customerNumber, shipToCode,
attributeName)` key again updates the existing row instead of erroring on a
duplicate key, so safe to retry. `PATCH` the same URL + key to update explicitly;
`DELETE` to remove an attribute entirely.

**Validated on every write:** the target Ship-to Address must exist (company-scoped
ownership check), the value must parse as the attribute's declared Data Type, blank
is only accepted when the attribute isn't marked Required, and a Boolean value
normalizes to lowercase `true`/`false` regardless of what case was sent.

### Where the "same canonical field, different name per tenant" resolution happens

Now **inside this extension**, not just on the backend: `WZC Attribute Setup`'s
Logical Name field is exactly that mapping, configured per company through the ERP
UI as requested — no backend-side name table needed for this piece anymore. The
backend can resolve a tenant's own naming by reading `logicalName` off
`wizShipToAttributes`, or by calling `WZC Attribute Setup` directly if it wants the
full mapping list up front.

### Automated tests

`WZC Attribute Tests` (Subtype = Test, compiles clean, self-contained — creates its
own test Customer/Ship-to, no external test-library dependency) covers: required-blank
rejection, invalid Number/Boolean values, Boolean case-normalization, duplicate
tenant-attribute-name rejection, unsupported real-field logical names, writes rejected
for real-field-backed attributes, auto-discovery of undeclared attribute names,
disabled-attribute rejection, and ownership validation against unknown Ship-to
Addresses. Run via BC's **Test Tool** page in your Sandbox (not run by this local
compile — only compiled and verified to compile here).

## Publish to a BC sandbox

1. Open this folder in VS Code with the **AL Language** extension.
2. Set `environmentName` in `.vscode/launch.json`.
3. **AL: Download Symbols**
4. `Ctrl+Shift+B` (compile)
5. `Ctrl+F5` (publish / install)

## Configure access

1. In BC → **Microsoft Entra Applications**
2. Open the app registration used by V2
3. Assign permission set **WZC CONNECTOR**

## Test

Use `examples/postman-connector.http` with the same OAuth as V2:

- Scope: `https://api.businesscentral.dynamics.com/.default`
- Grant: `client_credentials`

## Connect to Business Central V2

Merge `examples/workflow.data.connector.json` into the V2 workflow `data` (keep auth secrets).

Customers / orders / invoices stay on Microsoft standard APIs. Only gap entities use the connector URLs.

## Proof path (start here)

1. Publish extension  
2. Assign **WZC CONNECTOR**  
3. `GET .../wizShipToAddresses?$top=1`  
4. Point buyer `shipping_addresses` at the connector URL  
5. Run buyer pull → addresses on meta  

Object IDs `50100–55099` reserved (5,000 IDs, pending Microsoft's final partner-range
confirmation for the `WZC` affix). Microsoft has confirmed `WZC` as the registered
affix for publisher `WizCommerce`.

---

## WZC API Filter & Sync (Products + Ship-to Addresses wired; Prices deferred)

Configuration-driven filtering and incremental sync, configured entirely through the
ERP UI - no AL or JSON edits per rule. **Products (Item) and Ship-to Addresses are
wired.** Prices is explicitly **not yet wired** - see
[What's deferred](#whats-deferred) below. Do not assume Prices works; it doesn't yet.

### Default-vs-configured behavior (tenant-wise)

This is the core governance model, stated explicitly since it's easy to assume
either direction:

- **No enabled profile for an API** → the code default applies: **every record is
  returned**, unfiltered. This is true the moment the extension installs - nothing
  to configure to get full data.
- **An enabled profile with rules exists** → that tenant's specific filter is
  enforced on every call, server-side, regardless of what the caller requests.
- **To deliberately go back to "everything"** without losing the rules you built,
  use the **Fetch All (Disable Filter)** action on the profile card - it just sets
  `Enabled = false`, which is exactly the same state as "no profile configured," but
  keeps every rule intact for later. This is the explicit, named version of the
  implicit default, for when you want to *consciously* turn filtering off rather
  than rely on absence-of-config.

Per-company, this means: Tenant A with no profile (or a disabled one) gets every
record; Tenant B with an active profile gets only what matches. Same `.app`, same
code, different outcome per install - exactly the tenant-wise model this whole
extension is built around.

### New objects

No separate "Filter & Sync" hub page - **filter configuration lives directly on
WZC Api Config** (the same screen where you already enable APIs and set rate
limits), via a **Configure Filter** action per row. Fewer pages, one entry point.

| Object | ID | Purpose |
|---|---|---|
| `WZC Sync Profile` (table) | 50114 | Header: entity, Api Operation, direction, sync mode, overlap, config version |
| `WZC Sync Filter Rule` (table) | 50115 | Lines: field, operator, value, group (OR within a group, AND across groups) |
| `WZC Sync Checkpoint` (table) | 50116 | One row per profile: watermark, run-in-progress lock, last success |
| `WZC Sync Run Log` (table) | 50119 | Audit trail of every run: window, status, records, errors |
| `WZC Sync Filter Engine` (codeunit) | 50114 | Allowlist + typed validation + Mark-based AND/OR evaluation |
| `WZC Checkpoint Mgt` (codeunit) | 50115 | Window calculation, concurrency guard, advance-only-on-success |
| `WZC Sync Profile Card` (page) | 50106 | Reached via **Configure Filter** on WZC Api Config - Validate / Preview Records / Activate / Clone Profile / Reset Checkpoint / View Checkpoint / View Run Log |
| `WZC Sync Filter Rule Subpage` (page) | 50107 | Rule editor with Move Up/Down, embedded in the card |
| `WZC Sync Checkpoint List` / `WZC Sync Run Log List` (pages) | 50108 / 50109 | Diagnostics, reached from the profile card (scoped to that profile) or independently via Tell Me |
| `WZC Sync Tests` (codeunit) | 50116 | Subtype=Test, see [Automated vs. manual verification](#automated-vs-manual-verification) |

### Administrator guide

**Initial setup:** Tell Me → **"WizCommerce Connector API Configuration"** (the same
page from [Tenant-wise configuration](#tenant-wise-configuration-per-install) above).
Three templates are pre-seeded on install (`Is Template = Yes`, disabled by default,
not shown on this list - find them by opening **Configure Filter** on the
`WZC Item Availability` row, or searching `WZC Sync Profile Card` for `TPL_FULL_SYNC`
/ `TPL_INCREMENTAL` / `TPL_ACTIVE_PRODUCTS`):

| Profile No. | What it does |
|---|---|
| `TPL_FULL_SYNC` | Every Product, every run, no filters |
| `TPL_INCREMENTAL` | Every Product, incremental (only changed since last checkpoint) |
| `TPL_ACTIVE_PRODUCTS` | `Blocked = false` AND `Sales Blocked = false`, incremental |

**Creating a new profile:** on `WZC Api Config`, click **Configure Filter** on the
row for the API you want to filter (e.g. `WZC Item Availability`). If no profile
exists yet for that API, you'll be offered to create one on the spot (starts
disabled, Full Sync); if one already exists, it opens directly. Then, on the card:
1. Set Direction, Sync Mode (Entity and Api Operation are pre-filled from which row
   you clicked)
2. Add filter rules on the subpage - allowlisted fields only, enforced live as you type
3. **Validate** - checks every rule's field/operator/value against the allowlist
4. **Preview Records** - shows how many current records match (business rules only,
   no time window) and a sample of item numbers
5. **Activate** - re-validates, then enables the profile

Clicking **Configure Filter** again later goes straight back to that same profile -
no need to remember a `Profile No.`.

**How filtering actually gets applied:** an enabled profile with
`Api Operation = ITEMAVAIL` and `Direction` in (Pull, Both) is picked up automatically
by `wizItemAvailabilities`' `OnOpenPage` trigger on every call - the business filter
rules apply live, composed with (not replacing) the existing Location Filter from
`WZC Connector Setup`. The incremental **time window** is a separate concern: this
extension's Checkpoint/Run Log tables exist for admin visibility and for a future
scheduled-task-driven run loop, but the OData page itself doesn't currently consult
the checkpoint on every live call - the WizCommerce backend's existing `last_sync_date`
parameter remains how incremental pulls are actually time-bounded today. Business
filters and the incremental watermark are deliberately kept as separate concerns.

**Example - fetching only records changed since your last sync (incremental, by
`last_sync_time`):**

`wizItemAvailabilities` exposes `lastModifiedDateTime` (= Item's `SystemModifiedAt`,
the same value `WZC Checkpoint Mgt` uses internally as the watermark). The backend
drives incremental pulls by passing this as a standard OData `$filter` - no AL change
needed, this already works today:

```
GET /api/wizcommerce/connector/v1.0/companies({companyId})/wizItemAvailabilities
    ?$filter=lastModifiedDateTime gt 2026-10-20T00:00:00Z
```

Try it concretely against your Sandbox:

1. Note the current time, then wait a moment and modify any Item (e.g. change its
   Description) so its `SystemModifiedAt` updates.
2. Run the request above with a `$filter` timestamp from just *before* step 1 - the
   modified item should be the only (or most recent) row returned.
3. Run it again with a timestamp from *after* step 1 - it should no longer appear.

That round-trip is exactly what "fetch based on last_sync_time" means here: the
backend remembers the timestamp of its last successful pull, uses it as the lower
bound on the next call (with a small overlap for safety, same as `Overlap Seconds`
on a Sync Profile), and advances it only after that pull succeeds - same
advance-only-on-success principle `WZC Checkpoint Mgt` enforces for sync profiles,
just driven by the backend's own `last_sync_date` parameter rather than this
extension's checkpoint table for this particular endpoint.

**Allowlisted fields:**

| Entity | Fields |
|---|---|
| Product (Item) | No., Description, Type, Blocked, Sales Blocked, Item Category Code, Base Unit of Measure, Inventory, Vendor No., Global Dimension 1/2 Code |
| Ship-to Address | Customer No., Code, Name, City, County, Post Code, Country/Region Code, Location Code |

Example - filter `wizShipToAddresses` to one city, server-side: `Configure Filter` on
the `WZC Ship-to Address API` row → add rule `City Equals Cheltenham` → Validate →
Activate. Every call to `wizShipToAddresses` now returns only Cheltenham addresses
for this company, regardless of what the caller requests - a caller's own
`?$filter=city eq 'Cheltenham'` does the same thing for a single request, but only
this profile makes it a standing, tenant-persistent rule enforced server-side on
every call.

## WZC Field Visibility - tenant-wise response field control

**Different from row filtering above.** Row filters control *which records* come
back. This controls *which fields* appear in the response, per tenant, per API -
e.g. Tenant A gets `country` + `county` populated, Tenant B gets more fields, Tenant
C gets everything (default).

**A real platform constraint, stated honestly:** AL cannot remove a field from an
API page's schema at runtime - the field set is fixed when the extension compiles.
What *is* achievable, and what this builds: the field stays present in the JSON, but
its **value is blanked** for a tenant not granted it - genuinely server-enforced
(a caller can't override it by asking for the field anyway, same governance
principle as the row filters), just not a true "field absent" the way `$select`
would be caller-side.

**New objects:** `WZC Field Visibility` (table, 50121) - `Api Operation` + `Field
Name` + `Visible`; `WZC Field Visibility Mgt` (codeunit, 50117) - one function,
`IsFieldVisible`; `WZC Field Visibility List` (page, 50122) - admin UI, reached via
**Configure Fields** on the `WZC Api Config` row for the API you want to control.

**Default-vs-configured, same pattern as row filters:**
- **No rows at all for an Api Operation** → every field shown (code default) - this
  is "Tenant C: nothing configured" from the original request.
- **Any row exists for that Api Operation** → it becomes a whitelist: only fields
  explicitly marked `Visible = true` are shown; every other optional field for that
  API is blanked, regardless of what the caller asks for.

**Wired today: `wizShipToAddresses` only** (`SHIPTOADDR`), with the **full field set**
(same fields as `WZC Ship-to Address Full API`, minus the duplicate `id`/`code`/
metadata columns) - matches the stated direction of eventually retiring the separate
Full API in favor of one configurable Address API. Optional, visibility-controllable
fields: `name`, `name2`, `address`, `address2`, `city`, `contact`, `phoneNo`,
`faxNo`, `email`, `homePage`, `postalCode`, `county`, `country`, `locationCode`,
`shipmentMethodCode`, `shippingAgentCode`, `shippingAgentServiceCode`, `gln`,
`taxAreaCode`, `taxLiable`, `wzCreateAddress`. `id`, `customerNumber`, `code`, and
`lastModifiedDateTime` are always shown - they're identity/metadata, not optional
detail. Every one of these is pulled **live from the real Ship-to Address record**
on every call - there is no manual value entry anywhere in this path; that manual,
per-row entry only applies to `WZC Ship-to Attribute` (the generic table for
attributes that have no corresponding real BC field at all - see the section above).
A note on the original city/state example: there's no literal `Region` field on
Business Central's Ship-to Address table (verified via the compiler, not assumed) -
the closest real fields are `country` (`Country/Region Code`) and `county`
(captioned "State" in US-localized environments). Built against the real schema
rather than inventing a field that doesn't exist.

**Important: Field Name values are `Code` type, auto-uppercased by the platform.**
If you type `gln` in the Field Visibility grid it's stored as `GLN` - this is fine
and automatic (the lookup normalizes the same way on the read side), not something
you need to match case-exactly yourself.

**Example matching "Tenant A needs Address 2 and Contact":** Configure Fields on
`WZC Ship-to Address API` → add two rows, `(SHIPTOADDR, address2, Visible=true)` and
`(SHIPTOADDR, contact, Visible=true)`. No data entry anywhere - `wizShipToAddresses`
now returns Tenant A's real `Address 2` and `Contact` values on every call. Every
other optional field above comes back blank for this company until explicitly added.
- *Tenant B wants more*: same pattern, more rows in their own, separate company.
- *Tenant C does nothing*: no rows for `SHIPTOADDR` at all → every field comes back
  populated, same as before this feature existed.

**Extending to other APIs:** every other WZC API page (`WZC Customer Price API`,
`WZC Shipment Tracking API`, `WZC Item Availability`, `WZC Ship-to Address Full
API`, `WZC Ship-to Attribute API`) still returns every field unconditionally - the
redaction pattern isn't wired into them yet. The pattern is now proven end-to-end on
one API; extending it to another means, for that page: convert each optional field
from `field(x; Rec.Y)` to `field(x; BufferY)` with an `OnValidate` that writes
`Rec.Y := BufferY` (so POST/PATCH keeps working), and an `OnAfterGetRecord` that
populates `BufferY` from `Rec.Y` only when `FieldVisibility.IsFieldVisible(apiName,
'y')` is true. Mechanical, but real work per API - not claiming it's done anywhere
it hasn't been verified.

**Troubleshooting:**
- *"Field is not in the allowlist"* → check the field name against the allowlist
  table above (`WZC Sync Filter Engine.TryGetFieldInfo`).
- *"already has a sync run in progress"* → either wait, or if you're sure it's
  stuck (crashed mid-run), **Reset Checkpoint** - or wait 2 hours, after which the
  concurrency guard treats the lock as stale and lets a new run take over automatically.
- *A profile's Config Version keeps climbing on every save* → only `Entity`,
  `Api Operation`, `Direction`, and `Sync Mode` bump the version; renaming
  `Description` does not.

**Deployment/rollback:** same as every other version of this extension - publish via
VS Code (`AL: Publish`), or roll back by republishing the previous `.app` from the
repo root. The Sync Profile/Filter Rule/Checkpoint/Run Log tables are additive in
this version (new tables only, nothing removed) - no obsoletion staging needed for
this particular upgrade. If a profile's filter rules ever need a hard reset,
disabling the profile is non-destructive and instant; deleting a profile cascades to
its filter rules and checkpoint (see `WZC Sync Profile`'s `OnDelete` trigger).

### What's deferred

- **Ship-to Addresses full API / attribute API**: `WZC Ship-to Address API`
  (`wizShipToAddresses`, `SHIPTOADDR`) is wired. `WZC Ship-to Address Full API`
  (`SHIPTOADDRFULL`) and `WZC Ship-to Attribute API` (`SHIPTOATTR`) map to the same
  `ShipToAddress` entity and can use the same allowlist, but each needs its own
  profile created (profiles are keyed per `Api Operation`, not per entity) and its
  own `OnOpenPage` wiring - not done yet for those two specifically, only for the
  curated `wizShipToAddresses` endpoint.
- **No "All Ship-to Addresses" template seeded** - unlike the three Product
  templates, nothing is pre-seeded for Ship-to Address yet (not a technical
  limitation now that the entity is wired, just not built in this pass).
- **Prices entity**: not wired. When it is, the allowlist must hard-code
  `Amount Type = Price` and `Asset Type = Item` as non-removable defaults, since this
  session's schema inspection found `Price List Line` also carries Discount lines and
  non-Item assets in the same table - the **existing** `WZC Customer Price API`
  (`wizCustomerPrices`) doesn't filter these out today either, which is a pre-existing
  gap this phase surfaced but did not fix (fixing it is bundled into the Prices phase).
- **Page-level checkpoint resumption mid-run**: checkpoints advance per-run, not
  per-page. A crashed run simply doesn't advance the watermark; the next run
  reprocesses the same window (with overlap). True multi-page resumable cursors
  would need a background task/job-queue orchestration layer, which doesn't exist in
  this AL extension - real pagination already happens via standard OData `$top`/
  `nextLink` (platform-guaranteed stable ordering by key), driven by the backend's
  existing `batch_size`/`page_size` loop, not by anything new here.
- **Deletion reconciliation**: no dedicated mechanism yet. The documented pattern for
  now is: run `TPL_FULL_SYNC` periodically and diff the returned key set against what
  the backend already has stored: anything missing from a full pull that still exists
  backend-side is a deletion candidate. A dedicated lightweight reconciliation
  endpoint (return only keys, cheaply) is a natural next addition but isn't built yet.

### Automated vs. manual verification

`WZC Sync Tests` (Subtype = Test, compiles clean, self-contained) actually covers:
disallowed field rejection, disallowed operator rejection, cross-field AND/OR
grouping correctness (Product), City-filter matching correctness (Ship-to Address),
checkpoint NOT advancing on a failed run, checkpoint advancing on a successful run,
the concurrency guard rejecting a second concurrent `StartRun`, Reset Checkpoint
clearing the watermark, Full Sync mode ignoring any existing checkpoint, and Config
Version bumping only on meaningful field changes.

**Deliberately not claimed as automated** (per the instruction not to claim things
work until verified against the real system) - these need manual Sandbox
verification or are backend-side concerns outside this AL extension entirely:
pagination across real HTTP `$top`/`nextLink` calls, real-time-window rate limiting
behavior (covered structurally by `WZC Api Config`, but not re-tested here),
request timeouts, actual price changes propagating (blocked on the Prices phase not
being wired yet), deletion detection (no mechanism built yet, see above), and
extension upgrade behavior beyond "new tables only, nothing removed" (verify with a
real publish over an existing 1.0.0.6 install, same as every version before it).
# bussiness-central-app-connector-v2
