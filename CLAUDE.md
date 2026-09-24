# ZPURE001 — Project Rules

กฎเฉพาะโปรเจกต์นี้ ใช้ทับ global rules ใน `~/.claude/CLAUDE.md` เฉพาะข้อที่ระบุไว้

## Namespace — ใช้ `Z` ไม่ใช่ `Y`

**ข้อนี้ override global rule เรื่อง customer namespace**
ผู้ใช้สั่งไว้ชัดเจนว่า ABAP object ของโปรเจกต์นี้ให้ใช้ prefix `Z*` ทั้งหมด
(global rule ที่บังคับ `Y` ไม่ใช้กับ repo นี้)

ส่วนกฎอื่นที่เหลือ — naming convention ตัวแปร (`gv_`/`lv_`/`gs_`/`lt_`/`<lfs_>` ฯลฯ),
prefix parameter (`iv_`/`ev_`/`rv_`), pattern ของ RAP object — **ยังใช้ตามเดิมทุกข้อ**
แค่เปลี่ยนตัวอักษรแรกจาก `Y` เป็น `Z`

## App code

`<APP>` ของโปรเจกต์นี้คือ **`PURE001`** — object ทุกตัวใช้รูป `Z<TYPE>_PURE001[_<SUFFIX>]`

| Object | ชื่อ | กฎที่ใช้ |
|---|---|---|
| Package | `ZPURE001` | `Y<APP>` |
| Custom entity — root | `ZR_PURE001` (UI), `ZR_PURE001_FDP` (form) | `YR_<APP>` |
| Custom entity — child | `ZI_PURE001_ITEM_FDP`, `ZI_PURE001_ITXT_FDP` | `YI_<APP>_<ENT>` |
| Value help view (code list เท่านั้น) | `ZI_PURE001_STATUS_VH`, `ZI_PURE001_POTYPE_VH` | `YI_<...>_VH` |
| Exception class | `ZCX_PURE001_QUERY` (สืบทอด `cx_rap_query_provider`) | `YCX_<APP>_<...>` |
| IAM app / Business catalog / FLP | `ZIAM_ZPURE001_EXT` / `ZBC_ZPURE001` / `ZPURE001_UI5R` | *(ผู้ใช้ตั้งเองตอน deploy — ใช้ตามนั้น)* |
| Abstract entity | `ZA_PURE001_FILE` | `YA_<...>` |
| Behavior definition | `ZR_PURE001` (= ชื่อ root entity) | = ชื่อ root view |
| Behavior pool | `ZBP_R_PURE001` | `YBP_R_<APP>` |
| Service definition | `ZUI_PURE001` (UI), `ZAPI_PURE001_FDP` (form data) | `YUI_<APP>` / `YAPI_<APP>` |
| Service binding | `ZUI_PURE001_O4` | `YUI_<APP>_O4` |
| Global class | `ZCL_PURE001_DATA` (ตัวกลาง), `ZCL_PURE001_QUERY`, `ZCL_PURE001_FDP`, `ZCL_PURE001_UTIL`, `ZCL_PURE001_PRINT`, `ZCL_PURE001_HTTP` | `YCL_<APP>_<PURPOSE>` |
| Database table | *(ยกเลิกทั้งหมดแล้ว — D20/D21)* | `Y<APP>_<SUFFIX>` |
| Data element | *(ไม่มี)* | `YE_<name>` |
| HTTP service | `ZHS_PURE001` | *(กฎยังไม่ครอบคลุม — ตกลงกันเป็น case)* |
| Adobe Form object | `ZPURF002` (ผู้ใช้สร้างเอง) | *(`ZPURF001` ใน spec §2.5 = ฟอร์ม output management ของ Manage PO — นอกขอบเขต)* |

ดูรายการเต็มที่ [docs/02-object-list.md](docs/02-object-list.md)

### หมายเหตุเรื่อง custom entity

custom entity **ไม่ใช่ view** (ไม่มี data source ข้างหลัง) กฎ global มี category
`YQ_<...>` สำหรับ custom entity (unmanaged query) อยู่ แต่ผู้ใช้ตัดสินใจแล้วว่า
**โปรเจกต์นี้ไม่ใช้ `ZQ_`** — ให้มองตามบทบาทแทน คือ root ใช้ `ZR_` และ child ใช้ `ZI_`
เหมือน view ปกติ

### case ที่กฎ global ยังไม่ครอบคลุม (ตกลงกันแล้วในโปรเจกต์นี้)

| กรณี | ที่ตกลง |
|---|---|
| Service definition ของ FDP (ไม่มี binding ไม่ใช่ทั้ง UI และ OData API) | ใช้ `ZAPI_<APP>_FDP` |
| Behavior pool ของ custom entity | ใช้ `ZBP_R_<APP>` ตามกฎ root ปกติ (ไม่แยกตัวอักษรตามชนิด entity) |

## สถาปัตยกรรมที่ตัดสินใจแล้ว — อย่ากลับไปคิดใหม่

รายละเอียดและเหตุผลอยู่ใน [docs/06-decisions.md](docs/06-decisions.md) สรุปสั้น ๆ

- **D12 (2026-09-13, แทน D2/D11): CDS ประกาศ field อย่างเดียว · logic ทั้งหมดใน ABAP**
  · `ZCL_PURE001_DATA` = ตัวกลางอ่าน+derive ที่ list (`ZCL_PURE001_QUERY`) และ form (`ZCL_PURE001_FDP`) ใช้ร่วมกัน
  · CDS ที่ยอมให้มี = custom entity + VH view แบบ code list เท่านั้น **ห้ามสร้าง view entity ที่ join/derive** อีก
  · เหตุผล: CDS บน Public Cloud ไม่มี EXISTS/STRING_AGG · projection view เป็น source ไม่ได้ ·
    DCL inheritance ล้มเมื่อ join source ที่มี DCL หลายตัว · virtual element กรองไม่ได้
- **Phase 2 (FDP) ต้องเป็น custom entity** — SAP บังคับ ไม่ใช่ทางเลือก · ข้อมูลผ่าน `ZCL_PURE001_DATA`
- **แยก service UI (`ZUI_`) กับ FDP (`ZAPI_`)** คนละ entity
- **Status / Approval Status derive ใน `ZCL_PURE001_DATA`** (D5/D6) — status สำเร็จรูปของ SAP ไม่ released
  · output status (Sent/Not Yet Sent/Error) รวมเป็น Released · ทาง B (privileged DEX) เก็บเป็น option ใน D7
  **อย่าเสนอใช้ `WITH PRIVILEGED ACCESS` บน `C_OutputRequestItemDEX` เอง** เว้นแต่ functional สั่ง
- **`ESART` ไม่ released** → ใช้ `ZE_BSART` ที่มีบน tenant อยู่ก่อน (external dependency)
- **service alias = `PrintPurchaseOrder`** (ห้าม `PurchaseOrder` — ชน entity type `PurchaseOrderType`)
- **`@UI.hidden` ห้ามใส่บน field ที่เป็น filter** (FE V4 เอาออกจาก filter bar ด้วย)
- **item text ในฟอร์ม = แบบ B** (แยก node ต่อ text type ให้ฟอร์มจัด layout — ตาม SAP standard)
- **XML node ของ FDP = alias ใน `ZAPI_PURE001_FDP`**: `PurchaseOrderHeader` → `_Item/PurchaseOrderItem` → `_ItemText/PurchaseOrderItemText`
  · alias ห้ามซ้ำกับชื่อ property + `Type` (`PurchaseOrder` ชน `PurchaseOrderType`)
- **D13: filter ของ entity ที่ key หลาย field (ItemText) อ่านผ่าน `get_as_tree( )`** — framework ส่ง
  `(PO = x AND Item = y) OR (…)` ซึ่ง `get_as_ranges( )` โยน `cx_rap_query_filter_no_range` (ไม่ใช่ bug ของเรา)
- **FOR ALL ENTRIES คงไว้** — ผู้ใช้สั่ง (2026-09-14) ยังไม่แตะ performance ทำโปรแกรมให้ถูกก่อน อย่าเสนอ refactor เอง
- **D14: ฟอร์ม `ZPURF002` = clone ฟอร์มเดิม `YY1_MM_PUR_PURCHASE_ORDER` re-bind กับ `ZAPI_PURE001_FDP`** (master = `form/ZPURF002.xdp`,
  generate ด้วย `form/build_xdp.py`) · **ชื่อ object ในฟอร์มคงชื่อเดิม** · **script เท่าที่จำเป็น** — ค่าที่ต้อง derive/format ทำใน ABAP แล้วส่งเป็น field
  · เรียก standard FDP `FDP_EF_PURCHASE_ORDER_SRV` จาก `cl_fp_fdp_services` **ไม่ได้** (classic Gateway ไม่ใช่ SRVD)
  · Form Object สร้างใน **ADT** (ไม่ใช่ Form Templates app) แล้ว upload `.xdp` + ตั้ง Data Provider = `ZAPI_PURE001_FDP` (ชื่อ service definition)
  · **Form Object abapGit serialize ไม่ได้** (ยืนยัน 2026-09-23) — ไม่ต้องรอไฟล์ใน `src/` master คือ `form/ZPURF002.xdp`
- ทดสอบต้องทำบน **tenant 100** (`my427869`) — tenant 80 ไม่มี PO · service ทดสอบด้วย
  `.../zui_pure001/0001/PrintPurchaseOrder?$count=true`

## วิธีทำงาน (ตกลงกับผู้ใช้ไว้แล้ว)

1. **implement ทีละเฟส** — จบเฟสหนึ่งแล้วค่อยขึ้นเฟสถัดไป
2. **Claude implement บน local file / ผู้ใช้ implement บน tenant จริง**
3. **Claude push เฉพาะเอกสาร** — ABAP object ผู้ใช้ push เองผ่าน abapGit จาก ADT
4. **Claude ห้ามเขียนไฟล์ ABAP ลง repo** (`*.clas.abap`, `*.ddls.asddls`, `*.asbdef`,
   `*.srvd.*`, `*.tabl.xml` ฯลฯ) → ส่งเป็น **code block ใน chat** ให้ผู้ใช้ copy ไปสร้างใน ADT
   ข้อยกเว้น: ร่าง ABAP ที่ยังไม่ขึ้น tenant เก็บได้ใน `docs/draft/` เท่านั้น
   (นามสกุล `.md` หรือ `.txt` — ห้ามใช้นามสกุลที่ abapGit รู้จัก)
5. **provide commit message ให้ผู้ใช้ดูก่อน push เสมอ**
6. หลังผู้ใช้ push object ขึ้น Git → Claude เช็ค `git log` / `git diff` เพื่อ
   ตรวจความถูกต้องและ sync code ในเอกสารให้ตรงกับของจริงบน tenant
7. **ห้ามเขียน `.abapgit.xml` หรือ `src/**/package.devc.xml` เอง** — ปล่อยให้ SAP serialize
   ขึ้นมาเป็น baseline ตอนผู้ใช้ push ครั้งแรกจาก ADT

### 3 ข้อที่ผู้ใช้ย้ำว่าซีเรียสที่สุด

ยกระดับเป็นกฎ global แล้วใน `~/.claude/CLAUDE.md` หัวข้อ "จังหวะการทำงาน" — ห้ามข้าม

8. **ก่อนเริ่มทุกเฟส ต้องสรุปชื่อ object ทั้งหมดของเฟสนั้นให้ผู้ใช้รีวิวก่อน**
   แล้ว **รอจนผู้ใช้ confirm** ถึงจะเริ่ม implement ได้
   ถึงจะเคย confirm ชื่อรวม ๆ ไว้ตอนวางแผนแล้วก็ยังต้องสรุปซ้ำทุกเฟสอยู่ดี
   (คอลัมน์ `Confirmed` ใน [docs/02-object-list.md](docs/02-object-list.md) คือตัวชี้ขาด)
9. **ถามก่อนส่ง code เสมอ** — ห้ามส่ง code block มาขัดจังหวะระหว่างที่ยังคุยกันไม่จบ
   ให้ถามว่าพร้อมรับ code แล้วหรือยัง แล้วหยุดรอคำตอบ
   ตอบคำถาม อธิบาย เสนอทางเลือก ทำได้ตามปกติ — แค่อย่าเพิ่งส่งตัว code
10. **ไม่แน่ใจ ให้ถามก่อนเสมอ** — อย่าเดาแล้วลุยต่อ อย่าเลือกทางใดทางหนึ่งเงียบ ๆ
   แล้วค่อยมาบอกทีหลัง

## ข้อควรระวังเฉพาะงาน Adobe Form บน Public Cloud

- FDP entity **ต้องเป็น custom entity** เท่านั้น + ต้องมี
  `@ObjectModel.supportedCapabilities: [ #OUTPUT_FORM_DATA_PROVIDER ]`
  และ `@ObjectModel.query.implementedBy: 'ABAP:<class>'`
- ชื่อที่ส่งให้ `cl_fp_fdp_services=>get_instance( )` คือชื่อ **service definition**
  ไม่ใช่ชื่อ entity
- key ที่ `get_keys( )` คืนมาเป็นตัวพิมพ์ใหญ่เสมอ (`'PURCHASEORDER'`)
- ค่าที่ format ยาก (วันที่ พ.ศ. เดือนภาษาไทย จำนวนเงินเป็นตัวอักษร) ให้ **แปลงใน ABAP
  แล้วส่งเป็น string** อย่าไปพึ่ง locale ของ ADS
- รูปภาพ: **โปรเจกต์นี้ไม่ส่งรูปผ่าน data เลย (D21)** โลโก้ฝังในไฟล์ `.xdp` และไม่มีรูปลายเซ็น
  · ถ้าเจอโปรเจกต์อื่นที่ต้องส่งรูป ใช้ field `@Semantics.largeObject` เป็น `abap.rawstring`
