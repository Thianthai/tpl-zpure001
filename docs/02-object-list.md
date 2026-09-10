# Object List — ZPURE001

**สถานะ**
`⬜ ยังไม่เริ่ม` · `📝 Claude ร่างเสร็จ (อยู่ใน chat/docs)` · `🔨 ผู้ใช้สร้างบน tenant แล้ว` · `✅ push ขึ้น Git แล้ว`

**Confirmed** = ผู้ใช้ยืนยันชื่อ object ของเฟสนั้นแล้ว (ตามข้อตกลงใน `CLAUDE.md` ข้อ 8)
— ยังไม่ confirm = ห้ามเริ่ม implement

---

## Phase 0 — Foundation

| Object | Type | หน้าที่ | Confirmed | Status |
|---|---|---|---|---|
| `ZPURE001` | Package | package หลัก · SW component `ZLOCAL` · ABAP for Cloud Development | ✅ 2026-09-10 | ⬜ |

## Phase 1 — RAP UI (list report)

| Object | Type | หน้าที่ | Confirmed | Status |
|---|---|---|---|---|
| `ZR_PURE001` | Custom entity (root) | entity ของ list report — **13 filter** / 9 column | ✅ 2026-09-10 | ⬜ |
| `ZCL_PURE001_QUERY` | Class | `if_rap_query_provider` ของ `ZR_PURE001` | ✅ 2026-09-10 | ⬜ |
| `ZUI_PURE001` | Service definition | expose `ZR_PURE001` as `PurchaseOrder` | ✅ 2026-09-10 | ⬜ |
| `ZUI_PURE001_O4` | Service binding | OData V4 — UI | ✅ 2026-09-10 | ⬜ |

> ⚠️ ชื่อของ **Phase 2 เป็นต้นไปยังเป็นแค่ข้อเสนอ** — ต้องสรุปให้ผู้ใช้รีวิวและ confirm
> ตอนขึ้นเฟสนั้นจริง ๆ อีกครั้ง ตาม `CLAUDE.md` ข้อ 8

## Phase 2 — FDP data interface

| Object | Type | หน้าที่ | Confirmed | Status |
|---|---|---|---|---|
| `ZR_PURE001_FDP` | Custom entity (root) | form header | ⬜ | ⬜ |
| `ZI_PURE001_FDP_ITEM` | Custom entity | form item | ⬜ | ⬜ |
| `ZI_PURE001_FDP_ITXT` | Custom entity | บรรทัดข้อความใต้รายการ | ⬜ | ⬜ |
| `ZCL_PURE001_FDP` | Class | `if_rap_query_provider` ของ 3 entity ข้างบน | ⬜ | ⬜ |
| `ZAPI_PURE001_FDP` | Service definition | **ชื่อที่ส่งให้ `cl_fp_fdp_services=>get_instance( )`** | ⬜ | ⬜ |
| `ZPURF001` | Form object | layout XDP — **ผู้ใช้ทำเองจาก LiveCycle Designer** | ⬜ | ⬜ |

## Phase 3 — Print output

| Object | Type | หน้าที่ | Confirmed | Status |
|---|---|---|---|---|
| `ZA_PURE001_FILE` | Abstract entity | โครงผลลัพธ์ของ action (base64 PDF) | ⬜ | ⬜ |
| `ZR_PURE001` (bdef) | Behavior definition | `unmanaged` + `action PrintPOForm result[1] ZA_PURE001_FILE` | ⬜ | ⬜ |
| `ZBP_R_PURE001` | Behavior pool | `lhc_ZR_PURE001` — implement action | ⬜ | ⬜ |
| `ZCL_PURE001_PRINT` | Class | logic render PDF ที่ใช้ร่วมกันระหว่าง action กับ HTTP service | ⬜ | ⬜ |
| `ZCL_PURE001_HTTP` | Class | `if_http_service_extension` — preview/download | ⬜ | ⬜ |
| `ZHS_PURE001` | HTTP service | endpoint `/sap/bc/http/sap/ZHS_PURE001` | ⬜ | ⬜ |

## Phase 4 — Utility & master data

| Object | Type | หน้าที่ | Confirmed | Status |
|---|---|---|---|---|
| `ZPURE001_GRPH` | Table | เก็บ logo / ลายเซ็น (rawstring) | ⬜ | ⬜ |
| `ZE_PURE001_GRAPHIC_NAME` | Data element | ชื่อ graphic | ⬜ | ⬜ |
| `ZCL_PURE001_UTIL` | Class | `to_thai_date( )` · `amount_in_words_th( )` · `get_graphic( )` | ⬜ | ⬜ |

## Phase 5 — Fiori launchpad & authorization

| Object | Type | หน้าที่ | Confirmed | Status |
|---|---|---|---|---|
| `ZIAM_PURE001` | IAM app (`sia6`) | ผูก service binding กับสิทธิ์ | ⬜ | ⬜ |
| `ZBC_PURE001` | Business catalog (`sia1`) | catalog สำหรับ role Procurement | ⬜ | ⬜ |
| `ZPURE001_FLP` | FLP app descriptor (`uiad.json`) | tile "Print Purchase Order" | ⬜ | ⬜ |

## Phase 6 — Setting / extra fields (รอ functional)

| Object | Type | หน้าที่ | Confirmed | Status |
|---|---|---|---|---|
| `ZPURE001_CFG` | Table | ⏸ Setting View — ยังไม่สรุปขอบเขต | ⬜ | ⬜ |
| *(TBD)* | | ที่มาของฟิลด์นอกมาตรฐาน PO | ⬜ | ⬜ |

---

## หมายเหตุเรื่องชื่อ

- **ทุก object ใช้ prefix `Z`** ตามที่ผู้ใช้สั่ง (override global rule ที่บังคับ `Y`)
- custom entity ใช้ `ZR_` (root) / `ZI_` (child) ตามบทบาท **ไม่ใช้ `ZQ_`**
  ถึงกฎ global จะมี category `YQ_` สำหรับ custom entity อยู่ก็ตาม — ผู้ใช้ตัดสินใจแล้ว
- ชื่อ table ต้อง ≤ 16 ตัวอักษร → `ZPURE001_GRPH` (13) และ `ZPURE001_CFG` (12) ผ่าน
- ชื่อ CDS / class / data element ต้อง ≤ 30 ตัวอักษร → ยาวสุดคือ
  `ZE_PURE001_GRAPHIC_NAME` (23) ผ่าน
- Adobe Form object ใช้ชื่อ `ZPURF001` ตามที่ spec §2.5 ระบุไว้ในภาพ Output Management
