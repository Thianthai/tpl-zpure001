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
