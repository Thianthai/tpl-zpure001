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
| `ZR_PURE001` | Custom entity (root) | สิ่งที่ UI เห็น — 13 filter (VH ครบ) / 11 column + `MaterialList` / `PlantList` | ✅ 09-11 | ✅ 742dd06 |
| `ZI_PURE001_STATUS_VH` | CDS view entity (VH) | dropdown Status 7 ค่า จาก `I_PurchasingDocumentStatusText` · `#XS` | ✅ 09-13 | ✅ 25c6238 |
| `ZI_PURE001_POTYPE_VH` | CDS view entity (VH) | dropdown doc type category `F` (15 ค่า) · warning search-help ปล่อยไว้ | ✅ 09-13 | ✅ 25c6238 |
| `ZCL_PURE001_DATA` | Class | **ตัวกลาง** — `read_headers( selection )` อ่าน `I_PurchaseOrderAPI01` + EXISTS item + master text + ยอดรวม (ไม่นับที่ลบ) + follow-on (GR/IR) + workflow ล่าสุด → derive `PurchaseOrderStatus` / `ApprovalStatus` / criticality · `read_items( po )` | ✅ 09-13 | ✅ 742dd06 |
| `ZCL_PURE001_QUERY` | Class | `if_rap_query_provider` ของ `ZR_PURE001` — เรียก DATA แล้ว filter Status/Approval/Search + count + sort + paging ใน memory + ต่อ string item | ✅ 09-11 | ✅ 742dd06 |
| `ZCX_PURE001_QUERY` | Exception class | สืบทอด `cx_rap_query_provider` (abstract) — ห่อ `cx_rap_query_filter_no_range` | ✅ 09-13 | ✅ 25c6238 |
| `ZUI_PURE001` | Service definition | expose `ZR_PURE001` as **`PrintPurchaseOrder`** | ✅ 09-11 | ✅ 25c6238 |
| `ZUI_PURE001_O4` | Service binding | OData V4 — UI · published · `/sap/opu/odata4/sap/zui_pure001_o4/srvd/sap/zui_pure001/0001/PrintPurchaseOrder` | ✅ 09-11 | ✅ 2be05ab |

**ลบแล้ว (742dd06)** — `ZI_PURE001_HEADER`, `ZI_PURE001_TOTAL`, `ZI_PURE001_FOLLOWON`, `ZI_PURE001_WORKFLOW` (logic ย้ายเข้า `ZCL_PURE001_DATA`)

**External dependency** — `ZR_PURE001` ใช้ data element **`ZE_BSART`** (`ESART` ไม่ released) ที่มีบน tenant ก่อนแล้ว
→ ถ้าย้าย package ไป tenant อื่น ต้องมี `ZE_BSART` ก่อน

**Object ที่ SAP สร้างให้เอง** — `997e86285e590b8e7841262ae639b7ht.sush.xml` (S_START ของ service binding)

> ⚠️ ชื่อของ **Phase 2 เป็นต้นไปยังเป็นแค่ข้อเสนอ** — ต้องสรุปให้ผู้ใช้รีวิวและ confirm
> ตอนขึ้นเฟสนั้นจริง ๆ อีกครั้ง ตาม `CLAUDE.md` ข้อ 8

## Phase 2 — FDP data interface (+ utility) — ชื่อ confirm แล้ว 2026-09-13 · redesign D12

สัญญา XML: [03-data-interface.md](03-data-interface.md) · ข้อมูลทั้งหมดผ่าน `ZCL_PURE001_DATA` (ไม่มี view เพิ่ม)

| Object | Type | หน้าที่ | Confirmed | Status |
|---|---|---|---|---|
| `ZCL_PURE001_UTIL` | Class | `to_thai_date( )` · `format_date_dmy( )` · `amount_in_words( )` TH/EN · `format_quantity( )` | ✅ 09-13 | ✅ 742dd06 |
| `ZR_PURE001_FDP` | Custom entity (root) | form header — `#OUTPUT_FORM_DATA_PROVIDER` | ✅ 09-13 | ⬜ |
| `ZI_PURE001_ITEM_FDP` | Custom entity (child) | form item | ✅ 09-13 | ⬜ |
| `ZI_PURE001_ITXT_FDP` | Custom entity (child ของ item) | ข้อความใต้รายการ 1 node/text type (แบบ B) | ✅ 09-13 | ⬜ |
| `ZAPI_PURE001_FDP` | Service definition | **ชื่อที่ส่งให้ `cl_fp_fdp_services=>get_instance( )`** | ✅ 09-13 | ⬜ |
| `ZCL_PURE001_FDP` | Class | `if_rap_query_provider` ของ 3 entity — เรียก DATA + อ่าน texts / schedule / acct assignment / WBS / tax rate / approver → ประกอบ + คำนวณ + format | ✅ 09-13 | ⬜ |
| `ZCL_PURE001_DATA` | Class | **ขยาย** ให้ครอบข้อมูลฟอร์ม (schedule line, account assignment, WBS, tax rate, texts, approver) | ✅ | ⬜ |
| `ZPURF002` | Form object | layout XDP — **ผู้ใช้ทำเองจาก LiveCycle Designer** (ชื่ออาจเปลี่ยน) | — | ⬜ |

**ลบทิ้งระหว่างทาง (ไม่เคย push)** — `ZI_PURE001_FORM_HEADER`, `ZI_PURE001_FORM_ITEM`, `ZI_PURE001_FORM_APPROVER` (DCL inheritance ล้ม — D12)

**เลื่อนออกไป (ยังไม่สร้าง)**

| Object | เหตุผล |
|---|---|
| `ZPURE001_GRPH`, `ZE_PURE001_GRAPHIC_NAME` | รอเช็คว่า tenant มี table กลางเก็บ logo/ลายเซ็นอยู่แล้วไหม |
| `ZPURE001_CFG` | รอ functional confirm ว่าข้อมูลไหนต้องเป็น Setting View (ที่อยู่บริษัท/plant, โทร, เว็บ, ตำแหน่งผู้อนุมัติ) — view `I_Address*` ว่างทั้งหมด |

## Phase 3 — Print output

| Object | Type | หน้าที่ | Confirmed | Status |
|---|---|---|---|---|
| `ZA_PURE001_FILE` | Abstract entity | โครงผลลัพธ์ของ action (base64 PDF) | ⬜ | ⬜ |
| `ZR_PURE001` (bdef) | Behavior definition | `unmanaged` บน custom entity + `action PrintPOForm result[1] ZA_PURE001_FILE` | ⬜ | ⬜ |
| `ZBP_R_PURE001` | Behavior pool | `lhc_ZR_PURE001` — implement action | ⬜ | ⬜ |
| `ZCL_PURE001_PRINT` | Class | logic render PDF ที่ใช้ร่วมกันระหว่าง action กับ HTTP service | ⬜ | ⬜ |
| `ZCL_PURE001_HTTP` | Class | `if_http_service_extension` — preview/download | ⬜ | ⬜ |
| `ZHS_PURE001` | HTTP service | endpoint `/sap/bc/http/sap/ZHS_PURE001` | ⬜ | ⬜ |

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
- Adobe Form object ใช้ชื่อ `ZPURF001` ตามที่ spec §2.5 ระบุไว้ในภาพ Output Management
- IAM / catalog / FLP ผู้ใช้ตั้งชื่อเองตอน deploy (`ZIAM_ZPURE001_EXT`, `ZBC_ZPURE001`, `ZPURE001_UI5R`)
  — ใช้ตามนั้น ไม่ rename
