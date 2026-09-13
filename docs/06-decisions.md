# Decision Records — ZPURE001

บันทึกการตัดสินใจเชิงสถาปัตยกรรมที่ **ผ่านการถกเถียงแล้ว** พร้อมเหตุผล
เพื่อไม่ต้องกลับมาคิดใหม่ทุกครั้งที่เปิด session — ถ้าจะเปลี่ยน ต้องมีข้อมูลใหม่ที่หักล้างเหตุผลข้างล่างได้

---

## D1 — แยก service ระหว่าง UI กับ FDP (2026-09-10)

**ตัดสินใจ** `ZUI_PURE001` (list report) กับ `ZAPI_PURE001_FDP` (form data) เป็นคนละ service definition
คนละ entity

**เหตุผล** demo ใช้ entity เดียวทำทั้งสองอย่าง ทำให้ query ตอนแสดง list ต้องลาก logo / text ยาว ๆ
มาด้วยโดยไม่จำเป็น · แยกแล้ว list เบา และ data interface ของฟอร์มเป็นสัญญาที่แก้ได้อิสระ

---

## D2 — Phase 1 ไม่ใช้ CDS view entity ล้วน แต่เป็น hybrid (2026-09-11)

**ตัดสินใจ** `ZI_PURE001_HEADER` (view entity) ทำ data logic ทั้งหมด → `ZR_PURE001` (custom entity)
ครอบชั้นบน → `ZCL_PURE001_QUERY` ทำเฉพาะสิ่งที่ CDS ทำไม่ได้

**ทางที่พิจารณาแล้วตัดทิ้ง**

| ทาง | ทำไมไม่เอา |
|---|---|
| Custom entity ล้วน (ตาม demo) | logic ทั้งหมดอยู่ใน ABAP SQL ยาว ทดสอบยาก · ยึด demo โดยไม่ได้ทบทวน |
| CDS view entity ล้วน | ทำ 11/13 filter + 9/9 column ได้ แต่ **filter Material/Plant ระดับ item ทำไม่ได้** — CDS ไม่มี `EXISTS` (semi-join) และไม่มี `STRING_AGG` (ต่อชื่อ material ทุก item บนแถว header) |
| CDS + virtual element | แสดง list ได้ (`IF_SADL_EXIT_CALC_ELEMENT_READ` released C1) แต่ **กรองไม่ได้** — `IF_SADL_EXIT_FILTER_TRANSFORM` ไม่ released บน tenant (เช็คแล้ว 2026-09-11) |
| CDS view with parameters | กรองได้แต่ค่าเดียว ใส่ช่วง/หลายค่าไม่ได้ Fiori บังคับกรอก — UX แย่กว่า standard |
| ตัด Material/Plant ออก | functional ยืนยันว่าต้องมี โดยอ้างอิง standard app Manage Purchase Orders |

**requirement ที่ทำให้ต้องเลือกแบบนี้** (จาก functional, อ้างอิง standard app)
- filter Material/Plant → ได้ PO ที่มี item ตรงเงื่อนไข **อย่างน้อย 1 รายการ** (semi-join)
- แถว header แสดง Material ของ **ทุก item** ต่อกัน `ชื่อ (รหัส), ชื่อ (รหัส), …` (string aggregation)

**สิ่งที่ hybrid ทำได้ดีกว่า custom entity ล้วน**
- data logic อยู่ใน CDS → เปิด Data Preview ทดสอบได้โดยไม่ต้องรัน app
- sort / paging / count push ลง DB (`ORDER BY (dynamic)`, `UP TO … OFFSET`, `SELECT COUNT(*)`)
  ไม่ดึงทั้งตารางมาตัดใน memory
- Search box ใช้ `$search` จริงผ่าน `get_search_expression( )`

---

## D3 — ตัด filter "Editing Status" ออก (2026-09-10)

**ตัดสินใจ** เหลือ 13 filter

**เหตุผล** ค่าใน dropdown (All / Own Draft / Locked by Another User / …) เป็น draft filter ที่
Fiori Elements generate ให้ entity ที่เปิด draft handling ไม่ใช่ field ใน CDS · entity เรา read-only
ไม่มี draft และ `I_PurchaseOrderAPI01` คืนเฉพาะ PO ที่ active · PO ที่เป็น draft ไม่ควรถูกพิมพ์อยู่แล้ว

---

## D4 — ปุ่ม Print ทำทั้ง RAP action และ HTTP service (2026-09-10)

**ตัดสินใจ** action `PrintPOForm` (เลือกหลายใบ → merge → download) + HTTP service `ZHS_PURE001`
(preview inline ทีละใบ) — ตาม demo ที่พิสูจน์แล้วทั้ง 2 ทาง

---

## D5 — Status (filter) derive เองจาก PO + follow-on docs (2026-09-13)

**ตัดสินใจ** field `PurchaseOrderStatus` ใน `ZI_PURE001_HEADER` derive เป็น**รหัสเดียวกับ standard**
(`I_PurchasingDocumentStatus`) เพื่อใช้ text/VH มาตรฐานได้ · ลำดับ `case` สำคัญ

| ลำดับ | เงื่อนไข | Code | Name |
|---|---|---|---|
| 1 | `PurchasingDocumentDeletionCode = 'L'` | `10` | Deleted |
| 2 | `PurchasingCompletenessStatus = 'X'` | `01` | Draft (PO ยังไม่ Order) |
| 3 | PROCSTAT `08` | `38` | Rejected |
| 4 | PROCSTAT `03`/`04`/`26` | `02` | In Approval |
| 5 | PROCSTAT `02`/`05` + มีแถวใน `ZI_PURE001_FOLLOWON` | `05` | Follow-On Documents |
| 6 | PROCSTAT `02`/`05` | `08` | Released |
| 7 | อื่น ๆ | `27` | Created |

**เหตุผล** `PurchaseOrderStatus` สำเร็จรูปอยู่บน `I_PurchaseOrderTP` / `I_PurchaseOrderStatusValueHelp`
ซึ่ง**ไม่ released** · `I_PurchasingDocumentStatus` + `…Text` released → ใช้เป็น VH/text ได้ถ้า derive รหัสให้ตรง
· พิสูจน์กับหน้าจอ standard แล้ว 6 ใบ (4500000080/79/58, 99680198/160/044) ตรงทุกใบ

**ข้อจำกัด** Sent / Not Yet Sent / Output Error (`04`/`03`/`37`) รวมเป็น **Released** — ดู D7

**สิ่งที่เรียนรู้** PROCSTAT `02` "Active" บน tenant นี้ = PO ที่ยังไม่เคย Order (workflow ครอบทุก doc type)
แต่ใช้ `PurchasingCompletenessStatus = 'X'` เป็นตัวชี้ Draft แทน เพราะไม่ผูกกับ config workflow

---

## D6 — Approval Status (คอลัมน์) จาก PROCSTAT + workflow view (2026-09-13)

**ตัดสินใจ** derive จาก PROCSTAT ก่อน แล้วใช้ `I_WorkflowStatusOverview` (released C1) แยก
"Approved" กับ "Approved automatically" ด้วย `NmbrOfCmpltdWrkflwDialogTasks` (= 0 → automatically)
· PO มี workflow หลาย instance → `ZI_PURE001_WORKFLOW` เอา `max( WorkflowInternalID )`

| ลำดับ | เงื่อนไข | Code / Text |
|---|---|---|
| 1 | Completeness `X` | ว่าง |
| 2 | PROCSTAT `08` | `R` Rejected |
| 3 | PROCSTAT `03`/`04`/`26` | `I` In Approval (ชนะ workflow COMPLETED — พิสูจน์กับ 99680044) |
| 4 | workflow `COMPLETED` + dialog tasks = 0 | `B` Approved automatically |
| 5 | workflow `COMPLETED` + dialog tasks > 0 | `A` Approved |
| 6 | อื่น ๆ | ว่าง |

**ทางที่ตัดทิ้ง** derive จาก PROCSTAT อย่างเดียว — แยก automatically ไม่ได้ · Approver name ไม่ทำใน Phase 1
(spec ไม่ได้ขอ) แต่ Phase 2 ใช้ `I_WorkflowStatusDetails` (`WorkflowTaskProcessor` + `WrkflwTskCompletionUTCDateTime`
ของ task ที่ `RELEASED`) สำหรับช่อง "ผู้อนุมัติ/Approved By" ในฟอร์มได้

**ความเสี่ยงที่ยังไม่ได้ทดสอบ** view กลุ่ม workflow อาจมี DCL จำกัด user ทั่วไป → ต้องทดสอบด้วย business user
จัดซื้อจริงใน Phase 5 (ถ้าเห็นว่าง fallback = PROCSTAT อย่างเดียว)

---

## D7 — ไม่ใช้ `C_OutputRequestItemDEX` (privileged) สำหรับ output status — เก็บเป็น option (2026-09-13)

**ตัดสินใจ** ทาง **A**: Status 7 ค่า ไม่แตะ DEX view · ผู้ใช้จะ consult functional ให้รับทาง A
· ทาง **B** บันทึกไว้ครบเผื่อ functional ยืนยันต้องการ

**สิ่งที่ค้นพบ (ทาง B ทำได้จริงในทางเทคนิค)**
- `C_OutputRequestItemDEX` released C1 แต่ DCL auto-generated `where false` → ABAP อ่านได้เฉพาะ `WITH PRIVILEGED ACCESS`
- field: `OutputControlApplObjectType = 'PURCHASE_ORDER'`, `OutputControlApplicationObject` = เลข PO,
  `OutputRequestItemStatus` (`1` In Preparation · `4` Completed · `5` น่าจะ Error — ยังไม่ยืนยัน), `OutputChannel`, `DispatchTime`
- mapping ที่จะได้: มี `4` → Sent (`04`) · ไม่มี `4` แต่มี `5` → Output Error (`37`) · อื่น → Not Yet Sent (`03`)
- `I_PurOrdOutputAutomnCube` (released) มีแค่ตัวนับ ไม่มีสถานะ — ใช้ไม่ได้

**ราคาของทาง B**
1. นโยบาย — อ่านข้าม DCL ที่ SAP ตั้งใจปิด (`where false`) · auditor อาจถาม · DEX view อาจเปลี่ยนพฤติกรรม
2. สถาปัตยกรรม — `WITH PRIVILEGED ACCESS` ใช้ได้เฉพาะ ABAP SQL → logic Status ต้องแยกไป `ZCL_PURE001_QUERY`
   (CTE + privileged join + **dynamic WHERE** สำหรับ filter Sent/Not Yet Sent/Error) ~+60–80 บรรทัด
   และ logic กระจาย 2 ที่ (CDS + ABAP) ซึ่งขัดกับ D2

**ถอยกลับได้** — เริ่มจาก A แล้วเพิ่ม B ทีหลังโดยโครงไม่พัง

---

## D8 — Material filter ค้นใน item text ด้วย (2026-09-12)

**ตัดสินใจ** filter Material = `X` → PO ที่มี item `Material = X` **หรือ** `PurchaseOrderItemText` มีคำ `X`
(contains, ไม่สนตัวพิมพ์: `upper( )` ทั้ง 2 ฝั่ง)

**เหตุผล** Thappline ใช้ text item (ไม่มี material master) เยอะมาก (`C-2026-004` ในตัวอย่างคือ item text)
filter แบบ standard (เทียบรหัสอย่างเดียว) จะแทบใช้ไม่ได้ · ผู้ใช้ตัดสินใจเอง

**รายละเอียด** range `gr_item_text` สร้างจาก `gr_material` (EQ → `*X*` CP, CP คงเดิม, include เท่านั้น)
· ถ้ามี filter แต่ไม่มี pattern (ใช้แต่ exclude) ใส่ `E CP *` กัน range ว่างทำให้ OR เป็นจริงเสมอ

---

## D9 — Item ที่ลบ: ตัดเฉพาะยอดเงิน แสดงใน list ตาม standard (2026-09-13)

`ZI_PURE001_TOTAL` ไม่นับ `PurchasingDocumentDeletionCode = 'L'` (พิสูจน์กับ 99680044: 870,000.25 ไม่ใช่ 1,624,130.25)
· `MaterialList` แสดงทุก item รวมที่ลบ (standard แสดง `Calculator 2025, 2026, 2027`)
· EXISTS ของ filter รวม item ที่ลบด้วยเพื่อสอดคล้อง (แก้แล้ว a15453a)

---

## D10 — บทเรียน Fiori Elements V4 (2026-09-12)

- `@UI.hidden: true` เอา field ออกจาก **filter bar ตั้งต้น** ด้วย (ยังเลือกเพิ่มได้ใน Adapt Filters)
  → field ที่เป็น filter ห้ามใส่ hidden · ใช้ `@Consumption.filter.hidden` กับ field ที่ไม่ควรเป็น filter แทน
- alias ใน service definition ห้ามชนกับ property เพราะ entity type = `<alias>Type`
  (`PurchaseOrder` → `PurchaseOrderType` ชน property) → ใช้ `PrintPurchaseOrder`
- `criticality:` ใน `@UI.lineItem` + field int1 (0/1/2/3) = icon ✓ ✗ เหมือน standard
- Company Code mandatory ต้องมี `@Consumption.filter.defaultValue` (TL01) ไม่งั้น user ต้องกรอกก่อน Go ทุกครั้ง

---

## ข้อจำกัดของ tenant ที่ค้นพบ (ใช้อ้างอิงเฟสต่อไป)

| สิ่งที่พบ | วันที่ | ผล |
|---|---|---|
| `@Semantics.currencyCode: true` ใส่ใน view entity ไม่ได้ (ติดมากับ data element แล้ว) | 2026-09-11 | ใส่ได้เฉพาะ custom entity |
| `ESART` ไม่ released → ใช้ `ZE_BSART` ที่มีบน tenant อยู่ก่อน | 2026-09-11 | external dependency ของ package |
| `IF_SADL_EXIT_FILTER_TRANSFORM` ไม่ released C1 | 2026-09-11 | filter บน virtual element ทำไม่ได้ |
| `IF_SADL_EXIT_CALC_ELEMENT_READ` released C1 | 2026-09-11 | virtual element แบบแสดงอย่างเดียวใช้ได้ |
| `I_Supplier` / `I_PurchasingGroup` / `I_PurchasingDocumentTypeText` / `I_Plant` / `I_CompanyCodeVH` | 2026-09-11 | ใช้ได้ |
| `I_PurchaseOrderAPI01` มี `ReleaseIsNotCompleted`, `CorrespncInternalReference`, `CorrespncExternalReference` | 2026-09-11 | ใช้ได้ |
| `I_PurchaseOrderItemAPI01` มี `NetAmount`, `DocumentCurrency`, `PurchaseOrderItemText` | 2026-09-11 | ใช้ได้ |
| `I_PurchaseOrderTP`, `I_PurchaseOrderStatusValueHelp` | 2026-09-13 | **ไม่ released** — status สำเร็จรูปใช้ไม่ได้ |
| `I_PurchasingDocumentStatus` / `I_PurchasingDocumentStatusText` (33 code) | 2026-09-13 | released C1 |
| `I_PurchasingProcessingStatus` / `I_PurgProcessingStatusText` | 2026-09-13 | released C1 (PROCSTAT 01/02/03/04/05/08/11–14/26) |
| `I_WorkflowStatusOverview`, `I_WorkflowStatusDetails`, `I_WorkflowRecipients_V2` | 2026-09-13 | released C1 — โยง PO ผ่าน `SAPObjectNodeRepresentation='PurchaseOrder'` + `SAPBusinessObjectNodeKey1` |
| `I_MaterialDocumentItem_2`, `I_SuplrInvcItemPurOrdRefAPI01` (มี `PurchaseOrder`) | 2026-09-13 | released C1 |
| `I_Product` (VH material) | 2026-09-12 | released C1 |
| `I_PurchaseOrderAPI01` มี `PurchasingProcessingStatus`, `PurchasingCompletenessStatus`, `PurchasingDocumentDeletionCode`, `PurgReleaseSequenceStatus` (ว่างเสมอ) | 2026-09-13 | ใช้ได้ |
| `C_OutputRequestItemDEX` | 2026-09-13 | released C1 แต่ DCL `where false` — อ่านได้เฉพาะ privileged (D7) |
| `I_PurOrdOutputAutomnCube` | 2026-09-13 | released แต่ไม่มี field สถานะ |
| view output/PO history อื่น (`I_Output*`, `*History*`) | 2026-09-13 | ไม่ released |
| `IF_SADL_EXIT_CALC_ELEMENT_READ` released / `IF_SADL_EXIT_FILTER_TRANSFORM` ไม่ released | 2026-09-11 | virtual element กรองไม่ได้ |
| CDS view entity: `@Semantics.currencyCode: true` ห้ามใส่ · `union` ต้องมี `@Metadata.ignorePropagatedAnnotations: true` | 2026-09-11/13 | |
| `cx_rap_query_filter_no_range` **ไม่ใช่** subclass ของ `cx_rap_query_provider` และตัวหลัง**เป็น abstract** | 2026-09-13 | ต้องมี exception class เอง (`ZCX_PURE001_QUERY`) |
| ADT SQL Console: รับ statement เดียว, ไม่รับ `WITH PRIVILEGED ACCESS` (ต้องใช้ class `if_oo_adt_classrun`) | 2026-09-13 | |
| VH view จาก field ที่มี DDIC search help → warning "Search help assignment … not inherited" ปล่อยได้ | 2026-09-13 | |
