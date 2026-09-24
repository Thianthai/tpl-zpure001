# Object List — ZPURE001

**สถานะ**
`⬜ ยังไม่เริ่ม` · `📝 Claude ร่างเสร็จ (อยู่ใน chat/docs)` · `🔨 ผู้ใช้สร้างบน tenant แล้ว` · `✅ push ขึ้น Git แล้ว (commit)`

**Confirmed** = ผู้ใช้ยืนยันชื่อ object ของเฟสนั้นแล้ว (ตามข้อตกลงใน `CLAUDE.md` ข้อ 8)
— ยังไม่ confirm = ห้ามเริ่ม implement

---

## Phase 0 — Foundation

| Object | Type | หน้าที่ | Confirmed | Status |
|---|---|---|---|---|
| `ZPURE001` | Package | package หลัก · SW component `ZLOCAL` · ABAP for Cloud Development | ✅ 2026-09-10 | ✅ 2be05ab |

## Phase 1 — RAP UI (list report) ✅ เสร็จ 2026-09-13 (redesign D12 ทดสอบซ้ำผ่านแล้ว)

สถาปัตยกรรม (D12): **CDS ประกาศ field อย่างเดียว · logic ทั้งหมดใน ABAP** — `ZCL_PURE001_DATA` เป็นตัวกลางที่ list และ form ใช้ร่วมกัน

| Object | Type | หน้าที่ | Confirmed | Status |
|---|---|---|---|---|
| `ZR_PURE001` | Custom entity (root) | สิ่งที่ UI เห็น — 13 filter (VH ครบ) / 11 column + `MaterialList` / `PlantList` + ปุ่ม `PrintPOFormBTN` | ✅ 09-11 | ✅ 9485c28 |
| `ZI_PURE001_STATUS_VH` | CDS view entity (VH) | dropdown Status 7 ค่า จาก `I_PurchasingDocumentStatusText` · `#XS` | ✅ 09-13 | ✅ 25c6238 |
| `ZI_PURE001_POTYPE_VH` | CDS view entity (VH) | dropdown doc type category `F` (15 ค่า) · warning search-help ปล่อยไว้ | ✅ 09-13 | ✅ 25c6238 |
| `ZCL_PURE001_DATA` | Class | **ตัวกลาง** — `read_headers( selection )` อ่าน `I_PurchaseOrderAPI01` + EXISTS item + master text + ยอดรวม (ไม่นับที่ลบ) + follow-on (GR/IR) + workflow ล่าสุด → derive `PurchaseOrderStatus` / `ApprovalStatus` / criticality · `read_items( po )` | ✅ 09-13 | ✅ 742dd06 |
| `ZCL_PURE001_QUERY` | Class | `if_rap_query_provider` ของ `ZR_PURE001` — เรียก DATA แล้ว filter Status/Approval/Search + count + sort + paging ใน memory + ต่อ string item | ✅ 09-11 | ✅ 9485c28 |
| `ZCX_PURE001_QUERY` | Exception class | สืบทอด `cx_rap_query_provider` (abstract) — ห่อ `cx_rap_query_filter_no_range` | ✅ 09-13 | ✅ 25c6238 |
| `ZUI_PURE001` | Service definition | expose `ZR_PURE001` as **`PrintPurchaseOrder`** | ✅ 09-11 | ✅ 25c6238 |
| `ZUI_PURE001_O4` | Service binding | OData V4 — UI · published · `/sap/opu/odata4/sap/zui_pure001_o4/srvd/sap/zui_pure001/0001/PrintPurchaseOrder` | ✅ 09-11 | ✅ 2be05ab |

**ลบแล้ว (742dd06)** — `ZI_PURE001_HEADER`, `ZI_PURE001_TOTAL`, `ZI_PURE001_FOLLOWON`, `ZI_PURE001_WORKFLOW` (logic ย้ายเข้า `ZCL_PURE001_DATA`)

**External dependency** — `ZR_PURE001` ใช้ data element **`ZE_BSART`** (`ESART` ไม่ released) ที่มีบน tenant ก่อนแล้ว
→ ถ้าย้าย package ไป tenant อื่น ต้องมี `ZE_BSART` ก่อน

**Object ที่ SAP สร้างให้เอง** — `997e86285e590b8e7841262ae639b7ht.sush.xml` (S_START ของ service binding)

**Object ที่ abapGit serialize ไม่ได้** — **Form Object `ZPURF002`** (ยืนยัน 2026-09-23: push แล้วไม่มีไฟล์ใน `src/`)
→ ถ้าย้าย package ไป tenant อื่น ต้องสร้าง Form Object เองแล้ว upload `form/ZPURF002.xdp` + ตั้ง Data Provider `ZAPI_PURE001_FDP`

> ⚠️ ชื่อของ **Phase 2 เป็นต้นไปยังเป็นแค่ข้อเสนอ** — ต้องสรุปให้ผู้ใช้รีวิวและ confirm
> ตอนขึ้นเฟสนั้นจริง ๆ อีกครั้ง ตาม `CLAUDE.md` ข้อ 8

## Phase 2 — FDP data interface (+ utility) — 🔨 checkpoint `c5b66b3` (2026-09-14) · XML ทดสอบผ่าน 6 PO

สัญญา XML: [03-data-interface.md](03-data-interface.md) · ข้อมูลทั้งหมดผ่าน `ZCL_PURE001_DATA` (ไม่มี view เพิ่ม)

| Object | Type | หน้าที่ | Confirmed | Status |
|---|---|---|---|---|
| `ZCL_PURE001_UTIL` | Class | `to_thai_date( )` · `format_date_dmy( )` · `amount_in_words( )` TH/EN · `format_quantity( )` | ✅ 09-13 | ✅ 742dd06 |
| `ZR_PURE001_FDP` | Custom entity (root) | form header — `#OUTPUT_FORM_DATA_PROVIDER` · XML node `PurchaseOrderHeader` · +`SupplierCodeName`, `ApprovalNoteText` (09-18) | ✅ 09-13 | ✅ 1b5205b |
| `ZI_PURE001_ITEM_FDP` | Custom entity (child) | form item · XML node `PurchaseOrderItem` (ใต้ `_Item`) · +`ItemDescriptionText` (09-18) · +`UnitText` (09-23) | ✅ 09-13 | ✅ c4577a0 |
| `ZI_PURE001_ITXT_FDP` | Custom entity (child ของ item) | ข้อความใต้รายการ 1 node/text type (แบบ B) · XML node `PurchaseOrderItemText` (ใต้ `_ItemText`) | ✅ 09-13 | ✅ c5b66b3 |
| `ZAPI_PURE001_FDP` | Service definition | **ชื่อที่ส่งให้ `cl_fp_fdp_services=>get_instance( )`** · alias `PurchaseOrderHeader` / `PurchaseOrderItem` / `PurchaseOrderItemText` (ห้าม `PurchaseOrder` — ชน entity type `PurchaseOrderType`) | ✅ 09-13 | ✅ c5b66b3 |
| `ZCL_PURE001_FDP` | Class | `if_rap_query_provider` ของ 3 entity — เรียก DATA → ประกอบ 3 node + VAT/ยอดรวม + วันที่ไทย + amount in words · filter ของ item text อ่านผ่าน **filter tree** (D13) · 09-18: `compose_item_description` / `get_ordered_item_texts` / service item `1 AU` / condense acct-assignment | ✅ 09-13 | ✅ 1b5205b |
| `ZCL_PURE001_DATA` | Class | **ขยาย** ให้ครอบข้อมูลฟอร์ม: `read_schedule_lines` · `read_account_assignments` (+WBS) · `read_tax_rates` · `read_header_texts` / `read_item_texts` (range แทน FAE — STRING column) · `read_approvers` · `read_user_names` · payment terms / company / supplier master ใน `enrich_master_texts` | ✅ | ✅ c5b66b3 |
| ~~`ZCL_PURE001_TEST_FDP`~~ | Class (ชั่วคราว) | utility dump XML ระหว่างพัฒนา — **ลบแล้ว 2026-09-23** (`c4577a0`) | — | ❌ ลบแล้ว |
| `ZPURF002` | Form object (ADT) | template `form/ZPURF002.xdp` — clone จากฟอร์ม output management เดิม `YY1_MM_PUR_PURCHASE_ORDER` re-bind กับ `ZAPI_PURE001_FDP` (D14) · Designer preview ผ่านทั้ง 1 หน้าและ 6 หน้า 2026-09-18 · Data Provider = `ZAPI_PURE001_FDP` | ✅ 09-18 | 🔨 สร้าง+activate บน tenant 09-23 · **abapGit serialize ไม่ได้** (ไม่มีใน `src/`) master = `form/ZPURF002.xdp` |

**ลบทิ้งระหว่างทาง (ไม่เคย push)** — `ZI_PURE001_FORM_HEADER`, `ZI_PURE001_FORM_ITEM`, `ZI_PURE001_FORM_APPROVER` (DCL inheritance ล้ม — D12)

**เลื่อนออกไป (ยังไม่สร้าง)**

| Object | เหตุผล |
|---|---|
| `ZPURE001_GRPH`, `ZE_PURE001_GRAPHIC_NAME` | รอเช็คว่า tenant มี table กลางเก็บ logo/ลายเซ็นอยู่แล้วไหม |
| `ZPURE001_CFG` | รอ functional confirm ว่าข้อมูลไหนต้องเป็น Setting View (ที่อยู่บริษัท/plant, โทร, เว็บ, ตำแหน่งผู้อนุมัติ) — view `I_Address*` ว่างทั้งหมด |

## Phase 3 — Print output

**ฝั่ง front-end (คนละ repo — ผู้ใช้ดูแลเอง)** — โปรเจกต์ UI5 `zpure001` (generator-fiori, List Report, `ZUI_PURE001_O4`)

| ไฟล์ | หน้าที่ | Status |
|---|---|---|
| `webapp/manifest.json` | ผูก controller extension เข้ากับ ListReport ของ FE | ✅ 09-23 |
| `webapp/ext/controller/PrintPreview.controller.js` | ดัก action `PrintPOForm` แล้วเปิด PDF (D15) | ✅ 09-23 |
| `webapp/ext/util/PrintUtils.js` | unwrap result · base64 เป็น blob · download | ✅ 09-23 |

| Object | Type | หน้าที่ | Confirmed | Status |
|---|---|---|---|---|
| `ZA_PURE001_FILE` | Abstract entity | โครงผลลัพธ์ของ action (base64 PDF) | ✅ 09-23 | ✅ 67222b9 |
| `ZR_PURE001` (bdef) | Behavior definition | `unmanaged` บน custom entity + `action PrintPOForm result[1] ZA_PURE001_FILE` · `strict ( 2 )` | ✅ 09-23 | ✅ 67222b9 |
| `ZBP_R_PURE001` | Behavior pool | `lhc_zr_pure001` — รวม PO ที่เลือกเป็นไฟล์เดียว คืน base64 | ✅ 09-23 | ✅ 67222b9 |
| `ZCL_PURE001_PRINT` | Class | render PDF (FDP XML → ZPURF002 → ADS) · merge หลายใบ · ตั้งชื่อไฟล์ (เวลาไทย) | ✅ 09-23 | ✅ 67222b9 |
| `ZCL_PURE001_ADDRESS` | Class | ที่อยู่ plant / บริษัท จาก `I_OrganizationAddress` (privileged — D20) | ✅ 09-25 | ✅ 3a24fd6 |
| ~~`ZCL_PURE001_HTTP`~~ | Class | **ยกเลิก (D16)** — ปุ่มบน toolbar ใช้งานได้ครบแล้ว | — | ❌ ไม่ทำ |
| ~~`ZHS_PURE001`~~ | HTTP service | **ยกเลิก (D16)** | — | ❌ ไม่ทำ |

## Phase 4 — Utility & master data → **รวมเข้า Phase 2 แล้ว** (`ZCL_PURE001_UTIL`) · graphics table เลื่อนรอเช็ค

## Phase 5 — Fiori launchpad & authorization (ทำล่วงหน้าแล้วบางส่วน)

ผู้ใช้สร้างเองตอน deploy ทดสอบบน tenant 100 (2026-09-12) — ชื่อจริงต่างจากที่เสนอไว้

| Object | Type | หน้าที่ | Confirmed | Status |
|---|---|---|---|---|
| `ZIAM_ZPURE001_EXT` | IAM app (`sia6`) | ผูก service binding `ZUI_PURE001_O4` กับสิทธิ์ | ✅ (ผู้ใช้ตั้งเอง) | ✅ 25c6238 |
| `ZBC_ZPURE001` + `ZBC_ZPURE001_0001` | Business catalog (`sia1`) + app assignment (`sia7`) | catalog สำหรับ role Procurement | ✅ (ผู้ใช้ตั้งเอง) | ✅ 25c6238 |
| `ZPURE001_UI5R` | FLP app descriptor (`uiad.json`) | tile "Print Purchase Order" · appId `zpure001` · `ZPURE001-manage` | ✅ (ผู้ใช้ตั้งเอง) | ✅ 25c6238 |
| — | Business role | ผูก catalog เข้า role ของหน่วยงานจัดซื้อ (Fiori app มาตรฐาน) | — | ⬜ |

## Phase 6 — Setting / extra fields (รอ functional)

| Object | Type | หน้าที่ | Confirmed | Status |
|---|---|---|---|---|
| `ZPURE001_CFG` | Table | ⏸ Setting View — ยังไม่สรุปขอบเขต | ⬜ | ⬜ |
| *(TBD)* | | ที่มาของฟิลด์นอกมาตรฐาน PO — **มีเบาะแส**: PO มี custom field (Performance Bond, Bank Guarantee, Retention, Framework Start/End Date, Email) ดู [05-open-questions.md](05-open-questions.md) | ⬜ | ⬜ |

---

## หมายเหตุเรื่องชื่อ

- **ทุก object ใช้ prefix `Z`** ตามที่ผู้ใช้สั่ง (override global rule ที่บังคับ `Y`)
- custom entity ใช้ `ZR_` (root) / `ZI_` (child) ตามบทบาท **ไม่ใช้ `ZQ_`**
  ถึงกฎ global จะมี category `YQ_` สำหรับ custom entity อยู่ก็ตาม — ผู้ใช้ตัดสินใจแล้ว
- VH view ใช้ `ZI_<APP>_<ENT>_VH` · (helper view `ZI_<APP>_<ENT>` เลิกใช้แล้วตาม D12 — logic อยู่ใน class)
- ชื่อ table ต้อง ≤ 16 ตัวอักษร → `ZPURE001_GRPH` (13) และ `ZPURE001_CFG` (12) ผ่าน
- ชื่อ CDS / class / data element ต้อง ≤ 30 ตัวอักษร → ยาวสุดคือ
  `ZE_PURE001_GRAPHIC_NAME` (23) ผ่าน
- Adobe Form object ของโปรเจกต์นี้คือ **`ZPURF002`** (ฟอร์มใหม่ พิมพ์จาก ZPURE001 เท่านั้น) · `ZPURF001` ที่เห็นใน spec §2.5 คือฟอร์ม output management ของ Manage PO — **นอกขอบเขต**
- IAM / catalog / FLP ผู้ใช้ตั้งชื่อเองตอน deploy (`ZIAM_ZPURE001_EXT`, `ZBC_ZPURE001`, `ZPURE001_UI5R`)
  — ใช้ตามนั้น ไม่ rename
