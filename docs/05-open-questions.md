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
| 4 | **ช่อง Search (filter ที่ 1)** — Fiori free-text search ใช้กับ custom entity ไม่ได้ตรง ๆ ตกลงให้ทำเป็น filter ธรรมดาที่ค้นเลข PO / ชื่อผู้ขาย ได้ไหม | 🟡 ต้องยืนยัน | Phase 1 |
| 5 | **"Editing Status" กับ "Status"** ใน filter — map กับ field ไหนของ PO มาตรฐาน | 🟡 ยืนยันบน tenant | Phase 1 |
| 6 | **ภาษาของฟอร์ม** — ฟอร์มเป็นไทย/อังกฤษคู่กัน ต้องรองรับ PO ของ supplier ต่างชาติที่เป็นอังกฤษล้วนด้วยไหม | 🟡 ต้องยืนยัน | Phase 2/4 |
| 7 | **สกุลเงินอื่นที่ไม่ใช่ THB** — จำนวนเงินตัวอักษรจะทำยังไง (`บาทถ้วน` ใช้ไม่ได้) | 🟡 ต้องยืนยัน | Phase 4 |

**สีสถานะ** 🔴 = block งานในเฟสที่เกี่ยวข้อง · 🟡 = ทำต่อได้ด้วยสมมติฐาน แต่ควรยืนยัน
