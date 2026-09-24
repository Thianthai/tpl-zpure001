# Open Questions — รอ functional สรุป

| # | ประเด็น | สถานะ | ผลกระทบ |
|---|---|---|---|
| 1 | **"Setting View" ใน prerequisite ข้อ 3 หมายถึงอะไร** เก็บ config อะไรบ้าง ใครเป็นคน maintain | 🔴 รอผู้ใช้คุยกับ functional | Phase 6 — ยังตัดสินใจไม่ได้ว่าจะทำเป็น Z table เฉย ๆ, RAP CRUD app หรือ Custom Business Configuration (MDO) |
| 2 | **ที่มาของฟิลด์นอกมาตรฐาน PO** | 🟡 **มีเบาะแส** (2026-09-12): หน้า PO ใน Manage PO มี section *Custom Fields* — Performance Bond, Bank Guarantee, Retention, Framework Start/End Date, Email, Start Date → น่าจะเป็น custom field (extensibility) ที่ตรงกับช่องหลักประกัน/BG/วันที่สัญญาในฟอร์ม → Phase 2 ดึงผ่าน CDS extension ได้ · ต้องให้ functional ยืนยัน mapping | Phase 2/6 |
| 2.1 | ☐ หลักประกันการดำเนินงาน / ☐ เงินค้ำประกัน / ☐ BG | ✅ **ปิดแล้ว 09-25** — custom field `YY1_*` ใน `I_PurchaseOrderAPI01` (D19) | |
| 2.2 | ☐ กรมธรรม์ประกันภัย · ☐ หลักประกันผลงาน | ✅ **ปิดแล้ว 09-25** — custom field `YY1_*` (D19) | |
| 2.3 | วันที่เริ่มสัญญา / วันที่สิ้นสุดสัญญา | ✅ **ปิดแล้ว 09-25** — `YY1_FrameworkStartDate/EndDate_PDH` (D19) | |
| 2.4 | จัดส่งโดย / Ship Via (`Truck`) | 🔴 | |
| 2.5 | นามผู้รับสินค้า + เบอร์โทร | ✅ **ปิดแล้ว 09-25** — `zcl_get_other_detail` (D19) | |
| 2.6 | ผู้อนุมัติ (ชื่อ / ตำแหน่ง / วันที่ / รูปลายเซ็น) | ✅ **ปิดแล้ว 09-25** — `zcl_get_approval_name` ให้ทั้งชื่อ ตำแหน่ง และวันที่ (D19) · เหลือรูปลายเซ็นที่ยังต้องใช้ตารางรูปภาพ | |
| 2.7 | ส่วนลด/Discount (ค่าใช้จ่ายอื่นๆ) | ✅ **ปิดแล้ว 09-25** — `zcl_get_other_detail` คืน `SumOtherExpense` (D19) | |
| 3 | **Output Management** — spec §2.5 แสดง Form Template `ZPURF001` ผูกกับ output type `PURCHASE_ORDER` ในแท็บ Output Management ของ Manage PO อยู่ด้วย ตกลงขอบเขตงานนี้รวมการตั้ง output type ด้วยไหม หรือทำแค่ RAP UI แยกอีกจอ | 🟡 ต้องยืนยัน | ถ้ารวม จะเพิ่มงาน config output determination ซึ่งไม่ใช่ ABAP object |
| 4 | **ช่อง Search (filter ที่ 1)** | ✅ **แก้แล้ว** — `@Search.searchable` บน custom entity activate ผ่าน, query class รับ `$search` ผ่าน `get_search_expression( )` (ผลจริงรอทดสอบ preview) | Phase 1 |
| 5 | **"Editing Status" (filter ที่ 2)** | ✅ **ตัดออกแล้ว** (ผู้ใช้ confirm 2026-09-10) — ยังควรแจ้ง functional ให้ทราบ | Phase 1 |
| 6 | **ภาษาของฟอร์ม** — ฟอร์มเป็นไทย/อังกฤษคู่กัน ต้องรองรับ PO ของ supplier ต่างชาติที่เป็นอังกฤษล้วนด้วยไหม | 🟡 ต้องยืนยัน | Phase 2/4 |
| 7 | **สกุลเงินอื่นที่ไม่ใช่ THB** — จำนวนเงินตัวอักษรจะทำยังไง (`บาทถ้วน` ใช้ไม่ได้) | 🟡 ต้องยืนยัน | Phase 4 |

| 8 | **filter Material / Plant ระดับ item** — CDS view entity ทำไม่ได้ (ไม่มี EXISTS / STRING_AGG) และ `IF_SADL_EXIT_FILTER_TRANSFORM` ไม่ released | ✅ **แก้แล้ว** 2026-09-11 — functional ให้อ้างอิง standard app (กรองแล้วได้ PO ที่มี item ตรง ≥ 1) → ใช้ custom entity แบบ hybrid ดู [06-decisions.md](06-decisions.md) | Phase 1 |
| 10 | **Status: Sent / Not Yet Sent / Output Error รวมเป็น Released** — ไม่มี released source ของ output management (ทาง B ใช้ `C_OutputRequestItemDEX` แบบ privileged ทำได้แต่ราคาสูง ดู [06-decisions.md D7](06-decisions.md)) | 🟡 ผู้ใช้เลือกทาง A แล้ว จะ consult functional ให้รับ | Phase 1 |
| 11 | **คอลัมน์ Approver (ชื่อผู้อนุมัติ)** — standard มี เราไม่มี (spec ไม่ได้ขอ) ข้อมูลมีใน `I_WorkflowStatusDetails` ถ้าต้องการเพิ่มได้ | 🟡 แจ้ง functional | Phase 1 |
| 12 | **DCL ของ workflow view** — ทดสอบด้วย admin เท่านั้น ถ้า business user จัดซื้อเห็นว่าง Approval Status จะว่าง | 🟡 ทดสอบตอนผูก business role (Phase 5.4) | Phase 5 |
| 13 | **Editing Status / Search** — spec ลอกจาก standard; Editing Status ตัดแล้ว (ข้อ 5), Search ทำได้ (ข้อ 4) — ควรแจ้ง functional ให้รับทราบ | 🟡 | Phase 1 |
| 14 | **item บริการ `Quantity = 0` / `Unit` ว่าง** (99680019, 99680044, 99680042 item 10) แต่ `NetPriceAmount = ItemAmount` | 🟡 ทำตามฟอร์มเดิมไปก่อน (09-18): ABAP ส่ง `QuantityText = 1`, `Unit = AU` — functional ยืนยันอีกที | Phase 2 |
| 15 | **item ไม่มี tax code** (99680019 · 99680042 item 20 ในใบเดียวกับ item V1) → VAT 0 — ถูกต้องตามใบจริงไหม | 🟡 ยืนยันกับ Manage PO | Phase 2 |
| 16 | **`CostCenter` ไม่อยู่ใน `AccountAssignmentText`** — spec ตัวอย่างมีแค่ PR / Acc.Code / Order No. แต่ข้อมูลจริงมี `COM999` · field แยก `CostCenter` มีให้ bind แล้ว ต้องพิมพ์ไหม | 🟡 | Phase 2 |
| 17 | **พิมพ์ใบที่ยัง In Approval / Draft ได้ไหม** — FDP ไม่กรอง status (99680044 In Approval ออก XML ได้) นโยบายอยู่ที่ปุ่ม Print | 🟡 | Phase 3 |
| 18 | **ภาษาของ long text** — ข้อมูลจริง text ทุกใบเป็น `E` ขณะที่เราอ่านตาม `Language` ของ PO → PO ภาษาไทยจะได้ text ว่าง ควร fallback (ภาษา PO → ไม่มีก็ภาษาใดก็ได้) ไหม | 🟡 รอผู้ใช้ตัดสิน | Phase 2 |
| 19 | **หน่วยนับบนฟอร์ม** — XML ให้ ISO code (`C62` แทน `ST`) | ✅ **แก้แล้ว 2026-09-23** — ผู้ใช้เลือกพิมพ์รหัสหน่วยภายใน (`ST`, `EA`, `BX`) เหมือนฟอร์มเดิม ผ่าน field `UnitText` · ถ้าอยากได้ชื่อเต็ม (`ชิ้น`/`Piece`) ต้องอ่าน `I_UnitOfMeasureText` เพิ่ม | Phase 2 |
| 20 | **line break ใน long text** — `PlainLongText` ของ `I_*NoteTP_2` ดูเหมือนยุบหลายบรรทัดเป็น space (99680042 `1. … 2. … 3. …`) ถ้าจริง ฟอร์มจัดย่อหน้าตามต้นฉบับไม่ได้ · ทดสอบด้วย `4500000021` F02 (`HD NOTE 1` / `HD NOTE 2`) | ⏳ ยังไม่ทดสอบ | Phase 2 |
| 21 | **value help Material (`I_Product`) โหลด metadata ไม่ได้** — `CX_SADL_GW_V4_EXPOSURE_EXIT: Do not use conversion exit ATINN for property PRODCHARC1INTERNALNUMBER` | ✅ **แก้แล้ว 2026-09-23** — เปลี่ยนเป็น `I_ProductStdVH` (expose แค่ `Product` + `ProductExternalID` ไม่มี field ที่มี conversion exit ATINN) ทดสอบ F4 ผ่าน | Phase 1 |
| 22 | **สาขาผู้ขาย** | ✅ **ปิดแล้ว 09-25** — `zcl_get_name_form_bp` + `zcl_get_address_form_bp` ให้ชื่อสี่บรรทัดและสาขา (`AdditionalStreetSuffixName`) เหมือนฟอร์มมาตรฐาน (D19) | Phase 2 |
| 9 | **`ZE_BSART`** — data element ที่ใช้แทน `esart` (ไม่ released) อยู่นอก package `ZPURE001` | ✅ ผู้ใช้ยืนยัน 2026-09-11: มีอยู่บน tenant ก่อนแล้ว → บันทึกเป็น **external dependency** ใน [02-object-list.md](02-object-list.md) | Phase 1 |

**สีสถานะ** 🔴 = block งานในเฟสที่เกี่ยวข้อง · 🟡 = ทำต่อได้ด้วยสมมติฐาน แต่ควรยืนยัน ·
✅ = ตัดสินใจแล้ว · ⏳ = รอข้อมูล

---

## ภาคผนวก — ทำไมถึงตัด "Editing Status" ออก (ข้อ 5)

ค่าใน dropdown ของหน้าจอ standard คือ

```
All · All (Hiding Drafts) · Own Draft · Locked by Another User ·
Unsaved Changes by Another User · Unchanged
```

ทั้ง 6 ค่านี้ **ไม่ใช่ field ใน CDS view** — เป็น filter ที่ Fiori Elements generate ขึ้นมาเอง
เมื่อ entity เปิด RAP draft handling ไว้ สิ่งที่มันกรองจริงคือ draft administrative data
(มี draft ค้างไหม / ใครล็อกอยู่) ไม่ใช่คอลัมน์ในตาราง PO

ใช้กับแอปนี้ไม่ได้ด้วยเหตุผล 2 ชั้น

1. `ZR_PURE001` เป็น custom entity **read-only ไม่มี draft** → ไม่มีอะไรให้กรอง
   Fiori จะไม่ generate ช่องนี้ให้ตั้งแต่แรก
2. `I_PurchaseOrderAPI01` คืนเฉพาะ PO ที่ active แล้ว → draft ของ Manage PO ไม่โผล่มาอยู่แล้ว

และในเชิงธุรกิจ PO ที่ยังเป็น draft ก็ไม่ควรถูกพิมพ์

ถ้า functional ยืนยันว่าต้องมีจริง ๆ ทางเลือกที่พอทำได้คือเปลี่ยนความหมายเป็น
"กรอง PO ที่ยัง incomplete / held ออก" ซึ่งเป็นคนละเรื่องกับ dropdown ในหน้าจอ standard
— ต้องให้ functional ระบุความหมายใหม่มาก่อน
