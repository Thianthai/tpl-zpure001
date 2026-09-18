# form/ — Adobe Form `ZPURF002`

ไฟล์ฟอร์มของโปรเจกต์ (ไม่ใช่ ABAP object — abapGit ไม่ยุ่งกับโฟลเดอร์นี้)
**master คือ `ZPURF002.xdp` ในโฟลเดอร์นี้** · Form Object `ZPURF002` บน tenant = สำเนาที่ upload ไป

| ไฟล์ | คืออะไร |
|---|---|
| `ZPURF002.xdp` | template ที่ upload เข้า Form Object `ZPURF002` (ADT) — clone จาก `YY1_MM_PUR_PURCHASE_ORDER` (ฟอร์ม output management เดิมของลูกค้า) แล้ว re-bind กับ `ZAPI_PURE001_FDP` |
| `ZPURF002.xsd` | data description สำหรับ Designer (Data Connection `DataConnection` ชี้ `.\ZPURF002.xsd`) — โครงเดียวกับ XML ที่ `cl_fp_fdp_services=>read_to_xml_v2( )` คาย |
| `sample/0099680042.xml` | XML จริงจาก tenant 100 (3 รายการ, service item, text 3 ชนิด, WBS) — ใช้เป็น Preview Data ใน Designer |
| `sample/99680056_multipage.xml` | XML สังเคราะห์ 25 รายการ + เติม approver / checkbox / Ship Via / Valid from-to — ทดสอบหลายหน้า |
| `build_xdp.py` | script ที่ใช้ generate `.xdp` จากฟอร์มเดิม (บันทึกว่าเปลี่ยนอะไรบ้าง: binding map, script ที่ถอด, subform ที่ลบ) — รันซ้ำได้ถ้ามีไฟล์ต้นฉบับ |

## หลักการของฟอร์มนี้ (D14)

- **ชื่อ object ในฟอร์ม (Hierarchy) = ชื่อเดิมทุกตัว** — คนที่คุ้นฟอร์มเดิมเปิดแล้วเจอโครงเดิม
- **binding = ชื่อ field ของ `ZAPI_PURE001_FDP`** (`$.PurchaseOrderHeader.…`, ตาราง `$.PurchaseOrderHeader._Item.PurchaseOrderItem[*]`)
- **script เท่าที่จำเป็น** — เหลือ 14 จุด ทั้งหมดเป็น layout (เลขหน้า, แสดงยอดรวม/amount in words เฉพาะหน้าสุดท้าย)
  · ค่าที่เคยคำนวณใน JavaScript (ลำดับ, description หลายบรรทัด, วันที่ไทย, amount in words, Ship Via, ข้อความอนุมัติ, service item `1 AU`) **มาจาก ABAP ทั้งหมด**
- checkbox on-value = `X` (flag ของ ABAP) · field วันที่เป็น text ล้วน (ไม่มี data picture)
- ลบ subform `ItemLimit` (ไม่มี limit item) และ `frmHiddenGlobalFields` (field ซ่อนที่ script เดิมใช้)

## วิธีแก้ฟอร์ม

1. เปิด `ZPURF002.xdp` ใน Adobe LiveCycle Designer (ตัวที่มากับ SAP) — ต้องมี Acrobat Reader ถึงจะมีแท็บ Preview PDF
2. Form Properties → Preview → Data File = `.\sample\0099680042.xml` (หรือ multipage)
3. แก้ → Save → **copy ไฟล์กลับมาทับที่นี่** → upload เข้า Form Object `ZPURF002` ใน ADT → push
