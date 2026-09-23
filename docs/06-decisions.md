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

## D2 — Phase 1 ไม่ใช้ CDS view entity ล้วน แต่เป็น hybrid (2026-09-11) — **ถูกแทนด้วย D12**

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

## D11 — กติกาแบ่งชั้น CDS ↔ ABAP (2026-09-13) — **ถูกแทนด้วย D12**

ผู้ใช้ตั้งข้อสังเกตว่า logic เริ่มกระจาย 2 ที่ · ตัดสินใจ**คง hybrid** แต่ล็อกกติกาว่าอะไรอยู่ชั้นไหน
— **CDS = "ข้อมูลอยู่ไหน" · ABAP = "เอามาประกอบยังไง"** ไม่ใช่ "ติดอะไรก็ย้ายไป ABAP"

| อยู่ใน CDS view entity | อยู่ใน ABAP class |
|---|---|
| join / derive จาก **view entity** ที่ released (header, item, master data, workflow, tax rate) | อ่าน **projection view** (`*TP_2` / `*TP_3`) — texts, BP address, account assignment TP |
| field ที่เป็น 1 แถวต่อ key | รวมหลายแถวเป็น string (Material list, text หลาย type / หลายบรรทัด) |
| ยอดรวม / status ที่หน้า list กับฟอร์มต้องตรงกัน (`ZI_PURE001_HEADER` reuse ทั้ง 2 ที่) | format — วันที่ไทย, amount in words, quantity (`ZCL_PURE001_UTIL`) |
| | คำนวณข้าม node (ภาษีรวมจาก item → header) |
| | ประกอบ node ของ FDP / RAP query (filter, paging, count) |

**เหตุผลที่ไม่ย้ายทั้งหมดไป ABAP** — Data Preview ทดสอบได้โดยไม่ต้องรัน FDP (Phase 1 จับบั๊ก Net Order Value / status ได้ด้วยวิธีนี้)
· `FORM_HEADER` reuse `ZI_PURE001_HEADER` ทำให้ list กับฟอร์มตรงกันแน่นอน · join 8–10 view ใน CDS อ่านง่ายกว่า ABAP SQL

**ข้อจำกัดที่ทำให้ต้องมีฝั่ง ABAP** — `I_PurchaseOrderNoteTP_2`, `I_PurchaseOrderItemNoteTP_2`,
`I_BusinessPartnerAddressTP_3`, `I_PurOrdAccountAssignmentTP_2` เป็น **projection view** → ใช้เป็น data source ของ
view entity ไม่ได้ (error "Projection Views are not allowed as base object") แต่ SELECT ใน ABAP SQL ได้

---

## D12 — Redesign: CDS ประกาศ field อย่างเดียว · logic ทั้งหมดใน ABAP (2026-09-13) — **แทน D2 และ D11**

**ตัดสินใจโดยผู้ใช้** หลังเจอข้อจำกัดของ CDS บน Public Cloud ติดกัน 4 เรื่องภายใน 3 วัน
และประเมินว่า hybrid จะสร้าง technical debt (ข้อยกเว้นเฉพาะ object) มากขึ้นเรื่อย ๆ

| ข้อจำกัดที่เจอ | ผลกับ hybrid |
|---|---|
| CDS ไม่มี `EXISTS` / `STRING_AGG` | filter ระดับ item + Material list ต้องอยู่ ABAP อยู่แล้ว |
| `IF_SADL_EXIT_FILTER_TRANSFORM` ไม่ released | virtual element กรองไม่ได้ |
| **projection view (`*TP_2/_3`) ใช้เป็น data source ของ view entity ไม่ได้** | texts / BP address / account assignment TP ต้องอ่านใน ABAP |
| **DCL inheritance ล้มเมื่อ view join source ที่มี DCL หลายตัว** ("No authorization to view data" ทั้งที่ Data Preview แต่ละ source ผ่าน) | `ZI_PURE001_FORM_HEADER` / `_FORM_ITEM` / `_FORM_APPROVER` ใช้ไม่ได้เลย |

**โครงใหม่**

```
CDS  = ประกาศ field อย่างเดียว: custom entity (ZR_PURE001, ZR_PURE001_FDP …) + VH view แบบ code list
ABAP = ZCL_PURE001_DATA   ตัวกลาง — อ่าน view มาตรฐานทีละตัว (DCL ตรวจต่อ statement) + derive
       ZCL_PURE001_QUERY  list report — filter/search/count/sort/paging ใน memory + item list
       ZCL_PURE001_FDP    form — ประกอบ 3 node + ภาษี/format (Phase 2)
       ZCL_PURE001_UTIL   format · ZCX_PURE001_QUERY exception
```

**ทำไมต้องมี `ZCL_PURE001_DATA` ตัวกลาง** — Status / Approval Status / ยอดรวม / follow-on ต้องออกมาเหมือนกันทั้ง list และฟอร์ม
ถ้าแยก QUERY/FDP ตรง ๆ logic ถูกเขียน 2 ครั้ง

**สิ่งที่แลก (รับไว้แล้ว)**
- filter Status / sort / paging / count ของ list ทำใน **memory** หลังดึง PO ที่ตรง filter พื้นฐานจาก DB
  (284 ใบไม่รู้สึก · หลักหมื่นใบต่อ company code จะเริ่มช้า → ค่อยเพิ่ม push-down บางส่วนทีหลังได้)
- ทดสอบผ่าน Data Preview ไม่ได้อีก → ต้องรัน app หรือเขียน ABAP Unit ให้ `ZCL_PURE001_DATA` (ดีกว่าในระยะยาว)

**พิสูจน์แล้ว** — ทดสอบซ้ำบน tenant 100 ทั้ง 6 PO ตัวแทน + Material filter + Status dropdown + Search + sort → ผลเหมือนตอน hybrid ทุกข้อ

**object ที่ลบ** — `ZI_PURE001_HEADER`, `ZI_PURE001_TOTAL`, `ZI_PURE001_FOLLOWON`, `ZI_PURE001_WORKFLOW`
(และ `ZI_PURE001_FORM_HEADER` / `_FORM_ITEM` / `_FORM_APPROVER` ที่ยังไม่เคย push)

---

## D13 — filter ของ FDP child ที่ key หลาย field อ่านผ่าน filter tree (2026-09-14)

**ปัญหา** — FDP อ่าน 3 ชั้นด้วย `PurchaseOrderHeader(PurchaseOrder='…')?$expand=_Item($expand=_ItemText)`
แล้วเรียก `if_rap_query_provider~select` แยกต่อ entity · root/item ได้ filter `PurchaseOrder = x` (range ได้)
แต่ **`ZI_PURE001_ITXT_FDP` ได้ `( PO = x AND Item = 00010 ) OR ( PO = x AND Item = 00020 ) …`**
→ `get_as_ranges( )` โยน `cx_rap_query_filter_no_range` (range แยกต่อ field ผูกคู่กันไม่ได้ — ไม่ใช่ bug)
· demo `YCL_DMOFDP` ไม่เจอเพราะมี 2 ชั้นและลูกใช้ key ชุดเดียวกับ header (และ `CATCH … ##NO_HANDLER` กลืน exception)

**ทางเลือก** — A: regex บน `get_as_sql_string( )` (ง่าย แต่ parse text) · **B: เดิน `get_as_tree( )`** (ทาง SAP)

**ตัดสินใจ (ผู้ใช้เลือก B)** — `ZCL_PURE001_FDP->prepare_filter`: `get_as_ranges` ก่อน ถ้าโยน no_range →
`get_as_tree( )->get_root_node( )` แล้ว `collect_po_from_tree( )` เดินทุก node เก็บค่าจาก node `equals`
ที่ลูกเป็น identifier `PURCHASEORDER` (ลำดับลูกไม่การันตี · identifier case ไม่การันตี → `to_upper`) → range EQ + dedupe
· ส่ง text ของ **item ที่ไม่ลบทั้งหมด**ของ PO กลับ ซึ่งตรงกับชุด key ที่ framework ขอ (ไม่ต้องกรองระดับ item)

API ที่ใช้ (source บน tenant): `if_rap_query_filter_tree->get_root_node( )` · `if_rap_query_filter_tree_node->get_type( ) / get_children( ) / get_value( )` (REF TO data)
· enum `if_rap_query_filter_tree_types=>node_types-identifier / value / equals / logical_and / logical_or / logical_not / is_null / matches_pattern / less_than / greater_than`

---

## D14 — ฟอร์มใหม่ `ZPURF002` clone จากฟอร์มเดิม re-bind กับ FDP ของเรา · script เท่าที่จำเป็น (2026-09-18)

**บริบท** — ลูกค้ามีฟอร์ม output management `YY1_MM_PUR_PURCHASE_ORDER` (customized, ใช้กับ Manage PO) ผูกกับ
standard FDP `FDP_EF_PURCHASE_ORDER_SRV` + custom field `YY1_*_PDH/_PDI` ~30 ตัว + JavaScript ในฟอร์มเยอะ
(ลำดับ, description 5 บรรทัด, amount in words ไทย, วันที่ไทย, service item → `1 AU`, ซ่อน/แสดง) · ผู้ใช้อยากใช้ฟอร์มเดียวกัน

**ทางที่ลอง** — A: เรียก standard FDP จากโปรแกรมเรา `cl_fp_fdp_services=>get_instance( 'FDP_EF_PURCHASE_ORDER_SRV' )`
→ **`CX_SADL_GW_V4_REPOSITORY: Service is not registered` (repository SRVD)** — standard FDP เป็น classic Gateway service
ไม่ใช่ service definition, API นี้มองไม่เห็น · B: ปรับ FDP เราให้คาย XML รูป standard (~50 path + `YY1_*`) — เปราะ, ไม่ clean

**ตัดสินใจ (ผู้ใช้ + functional)** — **ทำฟอร์มใหม่ `ZPURF002` หน้าตาเหมือนเดิม** bind กับ `ZAPI_PURE001_FDP` · ต่างกันปรับ case by case
- clone `.xdp` เดิมด้วย script (`form/build_xdp.py`): คง layout + **ชื่อ object เดิมทุกตัว** (ผู้ใช้ขอ) · เปลี่ยน binding 61 จุด
  · ถอด `calculate` 13 จุด + validate/presence script · ลบ `ItemLimit`, `frmHiddenGlobalFields` · checkbox on = `X`
  · ถอด data picture `date{…}` ออกจาก field วันที่ (ไม่งั้น Acrobat parse ข้อความไทยแล้วพิมพ์ `2568-11-10`) + `nullTest="error"`
  · amount in words: script `editValue` เดิมทำค่า bound หาย → ใช้ presence script แบบเดียวกับ Total
- **ค่าที่ฟอร์มเคยคำนวณเอง ย้ายมา ABAP**: `ItemDescriptionText` (ช่องรายการทั้งช่อง คั่น newline — คง node `_ItemText` แบบ B ไว้ด้วย),
  `ApprovalNoteText` (ว่าง = ไม่พิมพ์ → ไม่ต้อง script presence), `SupplierCodeName`, service item (`Quantity = 0`) → `QuantityText = 1` / `Unit = AU`
- script ที่เหลือ 14 จุด = เลขหน้า + แสดงยอดรวม/amount in words เฉพาะหน้าสุดท้าย (layout — ทำใน ABAP ไม่ได้)
- พฤติกรรมที่**คงตามฟอร์มเดิมโดยตั้งใจ**: แถวรายการแยกข้ามหน้าได้ (ไม่ใส่ `keep intact`) · ผู้จัดทำ/ผู้อนุมัติพิมพ์ทุกหน้า · label ยอดรวมพิมพ์ทุกหน้า
- ทดสอบ Designer preview: 1 หน้า (0099680042) และ 6 หน้า (25 รายการสังเคราะห์) ผ่าน 2026-09-18
- Form Object `ZPURF002` สร้างใน ADT แล้ว upload `.xdp` (ตาม demo `YF_DMOFDP`) — ไม่ผ่าน Form Templates app

---

## D15 — ปุ่มพิมพ์ต้องมี UI5 controller extension คู่กับ RAP action (2026-09-23)

**ปัญหา** — action `PrintPOForm` คืนไฟล์ผ่าน abstract entity ตาม pattern ของ demo แต่กดปุ่มบน Fiori แล้ว **ไม่เกิดอะไรขึ้น**
· Fiori Elements V4 ไม่รู้ว่าต้องเอา base64 ใน result ไปทำอะไร มันเรียก action สำเร็จแล้วจบ

**สาเหตุ** — demo ไม่ได้ทำงานด้วย RAP อย่างเดียว มี **UI5 project แยก** (generator-fiori template lrop) ที่ abapGit ไม่เห็น
ข้างในมี controller extension ผูกกับ `sap.fe.templates.ListReport.ListReportController` ที่ monkey-patch `editFlow.invokeAction`
แล้วแปลง base64 เป็น Blob URL เปิดแท็บใหม่เอง

**ที่ทำ** — โปรเจกต์ UI5 ของเรา (`sap.app.id` = `zpure001`) เพิ่ม 3 จุด

| ไฟล์ | ทำอะไร |
|---|---|
| `webapp/manifest.json` | เพิ่ม `sap.ui5.extends.extensions.sap.ui.controllerExtensions` ชี้ `zpure001.ext.controller.PrintPreview` |
| `webapp/ext/controller/PrintPreview.controller.js` | ดัก action ชื่อ `PrintPOForm` เปิด BusyDialog แปลง base64 เป็น blob แล้ว `URLHelper.redirect` |
| `webapp/ext/util/PrintUtils.js` | `unwrap( )` อ่าน result หลายรูปแบบ · `toBlobUrl( )` · `download( )` เผื่อต้องการชื่อไฟล์จาก ABAP |

**ผล** — ทดสอบบน tenant 100 ผ่าน 2026-09-23 ได้ PDF เปิดแท็บใหม่เหมือน demo

**สิ่งที่ต้องจำ** — ฝั่ง front-end อยู่คนละ repo กับ ABAP (`/Volumes/[C] Windows 11/Users/thianthai/projects/zpure001`)
ผู้ใช้เป็นคนแก้เองทั้งหมด Claude ส่งเป็น code block ในแชทเท่านั้น เหมือนกฎของ ABAP object

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
| **projection view** (`I_PurchaseOrderNoteTP_2`, `I_PurchaseOrderItemNoteTP_2`, `I_BusinessPartnerAddressTP_3`, `I_PurOrdAccountAssignmentTP_2`) ใช้เป็น data source ของ view entity ไม่ได้ ("Projection Views are not allowed as base object") | 2026-09-13 | อ่านใน ABAP SQL แทน (ยังต้องยืนยันตอน Phase 2 ว่า transactional_query ให้ SELECT ได้) |
| view entity ที่ join source ที่มี DCL หลายตัว (เช่น `I_Supplier`, `I_BusinessUserBasic`, `I_EnterpriseProjectElement`, `I_WorkflowStatusDetails` + `group by`) → Data Preview "No authorization to view data" ทั้งที่แต่ละ source ผ่าน | 2026-09-13 | DCL inheritance ต้องการ field ที่ DCL ใช้ผ่าน alias เดียวกัน · SAP DCL มองไม่เห็น → **ทำใน ABAP** (D12) |
| `I_EnterpriseProjectElement` released C1 = master ของ WBS (`WBSElementInternalID` → `ProjectElement`) · `I_WBSElement*` ไม่มี | 2026-09-13 | |
| `I_PurOrdAccountAssignmentAPI01.WBSElementInternalID` deprecated → ใช้ `WBSElementInternalID_2` | 2026-09-13 | |
| `I_TaxCodeRate` released — rate ต่อ tax code (`TaxType='V'` + `VATConditionType='MWVS'` → 1 แถว) · `ConditionRateRatio` ต้อง select `ConditionRateRatioUnit` คู่กัน | 2026-09-13 | |
| `I_PaymentTermsText`, `I_CompanyCode` (VATRegistration = เลขผู้เสียภาษี), `I_Plant`, `I_BusinessUserBasic`, `I_PurchaseOrderPartnerAPI01`, `I_PurOrdScheduleLineAPI01`, `I_PurchaseOrderNoteTP_2` (F01/F02/F06), `I_PurchaseOrderItemNoteTP_2` (F01/F03/F04) | 2026-09-13 | released · มี data |
| view กลุ่ม `I_Address*` (`I_Address_2`, `I_AddrOrgNamePostalAddress`, `I_AddressEmailAddress_2`, phone, website) released แต่**ว่างทั้งหมด** (DCL) → ที่อยู่/โทร/เว็บของ company & plant ต้อง config | 2026-09-13 | |
| `class_constructor` ต้องอยู่ PUBLIC SECTION · `COLLECT` ต้องมี table key เป็น char (ห้าม `EMPTY KEY`) · FAE ต้อง type/length ตรงกันเป๊ะ | 2026-09-13 | |
| **projection view (`I_PurchaseOrderNoteTP_2`, `I_PurchaseOrderItemNoteTP_2`) SELECT ใน ABAP SQL ได้** — ยืนยันแล้ว (syntax check + ข้อมูลออกจริง) | 2026-09-14 | ปิดความเสี่ยงของ D12 |
| FAE + คอลัมน์ `STRING` (`PlainLongText`) → warning "should not be used … DISTINCT semantics" | 2026-09-14 | ใช้ `WHERE PurchaseOrder IN @lr_range` แทน (พิมพ์ทีละไม่กี่ใบ) |
| inline `SELECT col … INTO TABLE @DATA(lt)` คอลัมน์เดียว → line type เป็น **structure 1 component** ไม่ใช่ elementary · `SORT` / `DELETE ADJACENT` / table expression ต้องอ้างชื่อ component ไม่ใช่ `table_line` | 2026-09-14 | warning "empty primary key" / "compatibility of EBELN with TABLE_LINE" |
| `if_rap_query_filter=>tt_name_range_pairs-range` เป็น range แบบ string → ต้อง `CORRESPONDING #( )` เข้า range ที่ type จริง | 2026-09-14 | |
| `CONVERT UTCLONG … INTO DATE d TIME ZONE tz` — parser อ่าน `TIME ZONE` เป็น `TIME <ตัวแปร ZONE>` ต้องเขียน `INTO DATE d TIME t TIME ZONE tz` · และ `I_WorkflowStatusDetails.WrkflwTskCompletionUTCDateTime` เป็น **`TZNTSTMPL` (DEC 21,7)** ไม่ใช่ utclong → ใช้ `CONVERT TIME STAMP ts TIME ZONE tz INTO DATE d` (tz = `c LENGTH 6` `'UTC+7'`) | 2026-09-14 | |
| service definition alias + `Type` ห้ามซ้ำชื่อ property (`PurchaseOrder` → `PurchaseOrderType` ชน) — เกิดกับ FDP service เหมือน UI service | 2026-09-14 | alias `PurchaseOrderHeader` |
| composition ใน custom entity derive on-condition จาก `association to parent` ของลูก → activate parent ก่อนลูก = runtime object ของ parent เสีย → `CATALOG_INCONSISTENCY [CIE-3031] Association _ITEMTEXT … has no on-condition` ตอน framework โหลด query class | 2026-09-14 | **re-activate 3 entity พร้อมกัน** แก้ได้ |
| `get_as_ranges( )` ใช้กับ filter ของ child ที่ key หลาย field ไม่ได้ (OR ของ AND) | 2026-09-14 | D13 — filter tree |
| FDP serializer: data element ที่มี conversion exit ตัด 0 (`ebeln`) · `abap.char` ออกดิบ · `abap.unit` → ISO code · `int`/`dec` มี space ท้าย · `Language` → ISO 2 ตัว | 2026-09-14 | ดู [03 §0](03-data-interface.md) |
| `I_BusinessUserBasic` (`UserID` → `PersonFullName`) · `I_WorkflowStatusDetails` (`WorkflowTaskResult = 'RELEASED'`, `WorkflowTaskExternalStatus = 'COMPLETED'`, `WorkflowTaskProcessor`) · `I_EnterpriseProjectElement` (`WBSElementInternalID` → `ProjectElement`) · `I_TaxCodeRate` (`Country`/`TaxType`/`VATConditionType`/validity) | 2026-09-14 | ใช้ได้จริง มี data |
| `cl_fp_fdp_services=>get_instance( )` รับเฉพาะ **service definition (SRVD)** — standard FDP `FDP_EF_PURCHASE_ORDER_SRV` (classic Gateway) → "Service is not registered" | 2026-09-18 | เรียก standard FDP จาก custom code ไม่ได้ (D14) |
| ฟอร์ม output management เดิมของลูกค้าใช้ custom field `YY1_*_PDH` (header) / `_PDI` (item) เติมค่าผ่าน custom logic ฝั่ง standard | 2026-09-18 | ค่าเหล่านั้นเราคำนวณเองใน `ZCL_PURE001_FDP` |
| Designer (SAP build) ไม่มีแท็บ Preview PDF ถ้าเครื่องไม่มี Acrobat Reader · "Generate Preview Data" จะเขียนทับไฟล์ data ที่ตั้งไว้ (ห้ามกดถ้าชี้ไฟล์ข้อมูลจริง) | 2026-09-18 | |
| RAP action ที่คืนไฟล์ผ่าน abstract entity ไม่ถูก Fiori Elements V4 จัดการให้ ต้องมี UI5 controller extension รับ result เอง | 2026-09-23 | D15 |
| ADT: short dump ดูที่ Runtime Error Viewer · error ของ gateway (`/IWBEP/CX_GATEWAY`) ดูที่ `/sap/bc/adt/gw/errorlog` — `ZCX_PURE001_QUERY->get_text( )` โผล่ใน Error Context ทำให้ debug filter ได้โดยไม่ต้อง trace | 2026-09-14 | |
