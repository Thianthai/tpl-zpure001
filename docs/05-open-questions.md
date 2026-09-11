# Open Questions — รอ functional สรุป

| # | ประเด็น | สถานะ | ผลกระทบ |
|---|---|---|---|
| 1 | **"Setting View" ใน prerequisite ข้อ 3 หมายถึงอะไร** เก็บ config อะไรบ้าง ใครเป็นคน maintain | 🔴 รอผู้ใช้คุยกับ functional | Phase 6 — ยังตัดสินใจไม่ได้ว่าจะทำเป็น Z table เฉย ๆ, RAP CRUD app หรือ Custom Business Configuration (MDO) |
| 2 | **ที่มาของฟิลด์นอกมาตรฐาน PO** | 🔴 รอผู้ใช้คุยกับ functional | Phase 2 ประกาศ node ไว้เป็น placeholder ก่อน → เติมค่าใน Phase 6 โดยไม่ต้องแก้ layout ฟอร์ม |
| 2.1 | ☐ หลักประกันการดำเนินงาน / ☐ เงินค้ำประกัน / ☐ BG | 🔴 | |
| 2.2 | ☐ กรมธรรม์ประกันภัย · ☐ หลักประกันผลงาน | 🔴 | |
| 2.3 | วันที่เริ่มสัญญา / วันที่สิ้นสุดสัญญา (Valid from / Valid to) | 🔴 | |
| 2.4 | จัดส่งโดย / Ship Via (`Truck`) | 🔴 | |
| 2.5 | นามผู้รับสินค้า + เบอร์โทร | 🔴 | |
| 2.6 | ผู้อนุมัติ (ชื่อ / ตำแหน่ง / วันที่ / รูปลายเซ็น) — มาจาก approval workflow หรือ config | 🔴 | |
| 2.7 | ส่วนลด/Discount | 🔴 | |
| 3 | **Output Management** — spec §2.5 แสดง Form Template `ZPURF001` ผูกกับ output type `PURCHASE_ORDER` ในแท็บ Output Management ของ Manage PO อยู่ด้วย ตกลงขอบเขตงานนี้รวมการตั้ง output type ด้วยไหม หรือทำแค่ RAP UI แยกอีกจอ | 🟡 ต้องยืนยัน | ถ้ารวม จะเพิ่มงาน config output determination ซึ่งไม่ใช่ ABAP object |
| 4 | **ช่อง Search (filter ที่ 1)** | ✅ **แก้แล้ว** — `@Search.searchable` บน custom entity activate ผ่าน, query class รับ `$search` ผ่าน `get_search_expression( )` (ผลจริงรอทดสอบ preview) | Phase 1 |
| 5 | **"Editing Status" (filter ที่ 2)** | ✅ **ตัดออกแล้ว** (ผู้ใช้ confirm 2026-09-10) — ยังควรแจ้ง functional ให้ทราบ | Phase 1 |
| 6 | **ภาษาของฟอร์ม** — ฟอร์มเป็นไทย/อังกฤษคู่กัน ต้องรองรับ PO ของ supplier ต่างชาติที่เป็นอังกฤษล้วนด้วยไหม | 🟡 ต้องยืนยัน | Phase 2/4 |
| 7 | **สกุลเงินอื่นที่ไม่ใช่ THB** — จำนวนเงินตัวอักษรจะทำยังไง (`บาทถ้วน` ใช้ไม่ได้) | 🟡 ต้องยืนยัน | Phase 4 |

| 8 | **filter Material / Plant ระดับ item** — CDS view entity ทำไม่ได้ (ไม่มี EXISTS / STRING_AGG) และ `IF_SADL_EXIT_FILTER_TRANSFORM` ไม่ released | ✅ **แก้แล้ว** 2026-09-11 — functional ให้อ้างอิง standard app (กรองแล้วได้ PO ที่มี item ตรง ≥ 1) → ใช้ custom entity แบบ hybrid ดู [06-decisions.md](06-decisions.md) | Phase 1 |
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
