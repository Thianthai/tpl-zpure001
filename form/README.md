# form/ — Adobe Form `ZPURF002`

ไฟล์ฟอร์มของโปรเจกต์ (ไม่ใช่ ABAP object — abapGit ไม่ยุ่งกับโฟลเดอร์นี้)
**master คือ `ZPURF002.xdp` ในโฟลเดอร์นี้** · Form Object `ZPURF002` บน tenant = สำเนาที่ upload ไป

| ไฟล์ | คืออะไร |
|---|---|
| `ZPURF002.xdp` | template ที่ upload เข้า Form Object `ZPURF002` (ADT) — clone จาก `YY1_MM_PUR_PURCHASE_ORDER` (ฟอร์ม output management เดิมของลูกค้า) แล้ว re-bind กับ `ZAPI_PURE001_FDP` |
| `ZPURF002.xsd` | data description สำหรับ Designer (Data Connection `DataConnection` ชี้ `.\ZPURF002.xsd`) — โครงเดียวกับ XML ที่ `cl_fp_fdp_services=>read_to_xml_v2( )` คาย |
| `sample/0099680042.xml` | XML จริงจาก tenant 100 (3 รายการ, service item, text 3 ชนิด, WBS) — ใช้เป็น Preview Data ใน Designer |
| `sample/99680056_multipage.xml` | XML สังเคราะห์ 25 รายการ + เติม approver / checkbox / Ship Via / Valid from-to — ทดสอบหลายหน้า |
| `sample/0099680042_newfields.xml` | ชุดเดียวกับ 0099680042 แต่เติม Reference / Our Reference / Delivery Date / Ship Via / Valid from-to — ทดสอบ field ที่เพิ่ม 2026-09-23 |
| `sample/99680056_multipage_newfields.xml` | ชุด 25 รายการ + Our Reference + Delivery Date |
| `sample/0099680042_not_approved.xml` | ใบที่ยังไม่อนุมัติ (`ApprovalNoteText` ว่าง) — ใช้ดูว่าโลโก้กับที่อยู่บริษัทถูกซ่อน |
| `sample/0099680042_usd_long_words.xml` | ใบเดิมแต่เป็น USD และ amount in words ยาวสุดที่คาดว่าจะเจอ — ใช้ดูว่าช่อง Amount in words ตัดขึ้นบรรทัดที่ 2 ครบ (2026-11-25) |
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

## ถ้าฟอร์มต้นทางเปลี่ยน

ฟอร์ม output management เดิมของลูกค้าถูกแก้ layout ได้เรื่อย ๆ (เช่น 2026-09-23 เพิ่ม Our Reference กับ Delivery Date
ลดฟอนต์กรอบขวาเป็น 6.9pt แล้วขยับตำแหน่ง) วิธี apply เข้ามาที่ `ZPURF002.xdp` คือ **rerun `build_xdp.py`** กับไฟล์ใหม่
ไม่ใช่ไล่แก้มือใน Designer เพราะ script คง binding ของ FDP เราไว้ครบ
field ที่ต้นทางเพิ่มใหม่ ให้เติม 1 บรรทัดใน `ref_map` ก่อนรัน

**ข้อควรระวังที่เจอจริง (2026-09-24)** — ถ้าฟอร์มต้นทางเปลี่ยน field จาก binding เป็น calculate script
(เช่น `DeliveryDate` ที่ต้องแปลงวันที่ไทยเอง) `ref_map` จะจับไม่ได้ และ script ก็ถูกถอดตามกฎ
ผลคือช่องนั้น**ว่างเงียบ ๆ** ต้อง bind ตรงด้วย `edit_field( )` ในขั้นตอนที่ 4 แทน
· ทุกครั้งที่ rerun ให้ไล่ดู log ว่าบรรทัด `ref ... -> ...` ครบเท่าเดิมไหม

**สิ่งที่ script จัดการให้แล้ว**
- ลบ `<calculate>` ทุกอัน และลบ `<event>` ที่ script อ้าง `PurchaseOrderNode` (data model ของ standard)
- ใส่ script คุม presence ของ `Image1` กับ `CompAddress` ที่ field `PurchaseOrderNumber` (ซ่อนเมื่อยังไม่อนุมัติ)

## 2026-11-25 — Amount in words สองบรรทัด (ขั้นตอนที่ 12 ใน `build_xdp.py`)

functional แจ้งว่าใบสกุลต่างประเทศ ข้อความ Amount in words ยาวจนชื่อสกุลเงินถูกตัด จึงขยายช่องเป็น 2 บรรทัด

- footer **ขยายขึ้นด้านบน** 3.3 มม. ไม่ได้ดันลง เพราะด้านล่างไม่มีที่ว่าง
  (`EndOfPage` จบที่ 282.8 มม. และ `CompAddress` เริ่มที่ 283.5 มม.) — ผู้ใช้เลือกทางนี้
- ตารางรายการ (`Rectangle1`–`6`) และ `contentArea` สั้นลง 3.3 มม. · ช่องยอดเงิน `Total`–`NetAmt` และ `Footer` ยกขึ้น 3.3 มม.
- `AmtInWord` สูง 8.985 มม. เปิด multi-line · font เท่ากับ caption (Tahoma 7.5pt ย่อแนวนอน 98%) · caption และค่าจัดกลางแนวตั้ง
- ช่อง สุทธิ/Net Amount (`Text8`, `NetAmt`) สูงขึ้นเท่ากันให้เส้นกรอบตรงกัน · ตั้งแต่ `EndOfPage` ลงไปไม่ขยับ

**ไฟล์ต้นฉบับที่ `SRC` ชี้ไม่อยู่ในเครื่องแล้ว** — ขั้นตอนที่ 9 เป็นต้นไปอ่าน `ZPURF002.xdp` ตรง จึงรันแยกได้
ขั้นตอนที่ 12 เช็คเองว่า apply ไปแล้วหรือยัง รันซ้ำได้ไม่เพี้ยน

## 2026-11-26 — ใบปะท้าย GENERAL CONDITIONS (ขั้นตอนที่ 13 ใน `build_xdp.py`, D23)

ทุกใบสั่งซื้อมีหน้าเงื่อนไขทั่วไป 17 ข้อต่อท้าย เลียนแบบหน้า production ของ PO 99690990

- ข้อความอ่านจาก `ZPURF002_general_conditions.docx` (master ที่ผู้ใช้ตรวจแล้ว) แก้ข้อความให้แก้ไฟล์นี้แล้วรันขั้นตอนที่ 13 ใหม่
- page area ใหม่ `mstTerms` ไม่มีโลโก้ หัวฟอร์ม หรือที่อยู่บริษัท · `mstDummy` ตั้ง `occur max="-1"` ให้หน้ารายการวนใช้ page area เดิม
- subform `Terms` ต่อท้าย `Main` สั่ง `breakBefore` ไป `mstTerms`
- font ตาม production: DokChampa 7pt ตัวปกติทุกบรรทัด รวมหัวข้อ GENERAL CONDITIONS (DokChampa ไม่มีตัวหนา หน้า production ดูหนากว่าเพราะ PDF วาดเส้นขอบ 0.2pt รอบตัวอักษรทั้งหน้า) · ระยะบรรทัด 9.4pt · จัดชิดขอบสองด้าน
- เลขข้อที่ 15 มม. จากขอบซ้าย ข้อความที่ 20 มม. กว้างถึง 15 มม. จากขอบขวา
- **ไม่นับเป็นหน้าของใบสั่งซื้อ** — `xfa.layout.pageCount()` ทั้ง 13 จุดเปลี่ยนเป็น `pageCount() - 1`
  ทั้ง `Page: x/y` และ script ที่แสดงยอดเงินเฉพาะหน้าสุดท้าย

- **ขั้นตอนที่ 13b** — บรรทัดไทยทั้ง 17 บรรทัดเป็น rich text ให้เฉพาะช่องว่างใช้ Arial
  เพราะ preview รอบแรกช่องว่างระหว่างคำไทยกว้างกว่า production มาก (ช่องว่างของ DokChampa ในข้อความไทย)

- **ขั้นตอนที่ 13c** (preview รอบ 2) — ข้อ 17 ใส่ word joiner (U+2060) หลัง `SUPPLIER/` ให้ `SUPPLIER/CONTRACTOR`
  ขึ้นบรรทัดสุดท้ายทั้งคำเหมือน production · ขนาด font บรรทัดไทยปรับทีละ step ที่ตัวแปร `TH_SIZE` (รอบนี้ 6.5pt) รันซ้ำได้
  · ทาง ก. (ช่องว่างเป็น Arial) preview แล้ว **ช่องว่างไม่แคบลง** — สาเหตุไม่ได้อยู่ที่ font ของช่องว่าง

- **ผู้ใช้จูนต่อเองใน Designer (2026-11-26)** ให้ทุกบรรทัดขึ้นบรรทัดใหม่ตรงกับ production
  · ขนาด font บรรทัดไทยแยกรายข้อ: 7pt (ข้อ 1 2 5 7 11 12) · 6.8pt (13) · 6.7pt (3 4 6 9 16 17) · 6.5pt (8 10 14 15)
  · ข้อ 8 10 14 15 16 ยังเป็น rich text แบบช่องว่าง Arial (ข้อ 16 มี span 6.6pt) ข้อที่เหลือกลับเป็นข้อความธรรมดา
  · เติมช่องว่างที่จุดตัดบรรทัด: ข้อ 13 ไทย 1 ช่อง · ข้อ 16 ไทย nbsp 4 ตัว + 1 ช่อง · ข้อ 17 อังกฤษ 3 ช่องหน้า `SUPPLIER/` · ข้อ 17 ไทย 12 ช่อง + 1 ช่อง
  · word joiner ของขั้นตอนที่ 13c ถูกเอาออก · ข้อความอื่นตรงกับ `ZPURF002_general_conditions.docx` ทุกตัวอักษร
  · Designer ตัด `<occur>` ของ page area ทั้งสองตัวออกตอน save

**ตั้งแต่นี้ไฟล์หลักคือ `ZPURF002.xdp` ที่ผู้ใช้ save จาก Designer** ขั้นตอนที่ 13 ถึง 13c ใช้สร้างรอบแรกเท่านั้น
ถ้ารันซ้ำจะทับการจูนรายบรรทัดนี้ — แก้ข้อความหรือ layout ของหน้าเงื่อนไขต่อจากนี้ให้แก้ใน Designer

ขั้นตอนที่ 13 เช็คเองว่า apply ไปแล้วหรือยัง ถ้าต้องสร้างใหม่ให้ลบ page area `mstTerms` กับ subform `Terms` ออกก่อน

**ยังไม่ยืนยัน:** ADS บน tenant มี font DokChampa หรือไม่ ถ้าไม่มีจะถูกแทนด้วย font อื่น ให้ดูจาก PDF จริง
