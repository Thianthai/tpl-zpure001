# Implementation Plan — ZPURE001 Print Purchase Order

## หลักการทำงาน

- implement **ทีละเฟส** จบเฟสหนึ่งแล้วค่อยขึ้นเฟสถัดไป
- **ก่อนเริ่มทุกเฟส** Claude สรุปชื่อ object ของเฟสนั้นให้ผู้ใช้รีวิว → **รอ confirm** → ค่อยลงมือ
- Claude ร่างโค้ดส่งเป็น code block ใน chat / ผู้ใช้สร้าง object จริงบน tenant ผ่าน ADT
- ผู้ใช้ push ABAP object ขึ้น Git → Claude อ่าน `git log`/`git diff` ตรวจ แล้ว sync เอกสาร
- Claude push เฉพาะเอกสาร และ provide commit message ให้ดูก่อนทุกครั้ง

---

## Phase 0 — Foundation

**เป้าหมาย** วางโครง repo + package แล้วให้ SAP serialize baseline ขึ้นมาเอง

| # | งาน | ใคร |
|---|---|---|
| 0.1 | สร้าง repo + เอกสาร (README / CLAUDE.md / docs) แล้ว push | Claude |
| 0.2 | สร้าง package `ZPURE001` บน tenant | ผู้ใช้ |
| 0.3 | link abapGit กับ package `ZPURE001` จาก ADT | ผู้ใช้ |
| 0.4 | push จาก ADT → ให้ SAP serialize `.abapgit.xml` + `src/package.devc.xml` เป็น baseline | ผู้ใช้ |
| 0.5 | อ่าน baseline ที่ SAP สร้าง แล้วอัปเดต path ในเอกสารให้ตรง | Claude |

✅ **เสร็จ 2026-09-11** (commit `2be05ab`) — `FOLDER_LOGIC = FULL`, `STARTING_FOLDER = /src/`
object ทุกตัวอยู่ใต้ `src/` ไม่มี subfolder

> ⚠️ **ห้าม Claude เขียน `.abapgit.xml` หรือ `package.devc.xml` เองล่วงหน้า** —
> เคยเจอปัญหาจริงที่ ZARI002: link wizard พังด้วย HTTP 500 เพราะ `FOLDER_LOGIC` ไม่ตรงกัน

**เสร็จเมื่อ** — repo มี baseline จาก SAP และ Claude ยืนยันว่า path ในเอกสารตรงกับของจริง

---

## Phase 1 — RAP UI (list report) ✅ เสร็จ 2026-09-13 (ทดสอบเทียบ standard แล้ว)

**เป้าหมาย** ได้หน้าจอ Fiori list report ที่ filter หา PO ได้ครบ 13 ช่อง แสดงคอลัมน์ตาม spec
+ Status / Approval Status เหมือน standard (ยังไม่มีปุ่มพิมพ์)

**สถาปัตยกรรม — D12 (redesign 2026-09-13): CDS ประกาศ field อย่างเดียว · logic ทั้งหมดใน ABAP**

```
ZUI_PURE001_O4 (binding)
  └─ ZUI_PURE001 (service def, alias PrintPurchaseOrder)
       └─ ZR_PURE001 (custom entity — ประกาศ field)
            └─ ZCL_PURE001_QUERY   filter Status/Approval/$search · count · sort · paging (memory) · MaterialList/PlantList
                 └─ ZCL_PURE001_DATA   ← ตัวกลาง ใช้ร่วมกับฟอร์ม
                      read_headers: I_PurchaseOrderAPI01 (+EXISTS item) · I_Supplier · I_PurchasingGroup · I_CompanyCode
                                    · I_PurchasingDocumentTypeText · ยอดรวม (item ไม่ลบ) · GR/IR follow-on
                                    · I_WorkflowStatusOverview (ล่าสุด) · derive Status / Approval / criticality
                      read_items:   I_PurchaseOrderItemAPI01 + I_Plant
       VH: ZI_PURE001_STATUS_VH · ZI_PURE001_POTYPE_VH · I_Supplier · I_PurchasingGroup · I_Product · I_Plant · I_CompanyCodeVH · I_PurchaseOrderAPI01
```

| # | งาน | Object | สถานะ |
|---|---|---|---|
| 1.1 | custom entity ของ list report | `ZR_PURE001` | ✅ |
| 1.2 | ตัวกลางอ่าน + derive | `ZCL_PURE001_DATA` | ✅ (D12) |
| 1.3 | query provider + exception | `ZCL_PURE001_QUERY`, `ZCX_PURE001_QUERY` | ✅ |
| 1.4 | service definition + binding (OData V4) | `ZUI_PURE001` / `ZUI_PURE001_O4` | ✅ published |
| 1.5 | VH dropdown Status / doc type | `ZI_PURE001_STATUS_VH`, `_POTYPE_VH` | ✅ |
| 1.6 | ทดสอบเทียบ Manage Purchase Orders บน tenant 100 | — | ✅ 6 PO ตรงทุกคอลัมน์ (ทั้งก่อนและหลัง redesign) |

**ผลทดสอบ (tenant 100, 2026-09-13)** — 284 PO · filter 13 ช่อง + VH ครบ · Company Code default `TL01`
· Status dropdown 7 ค่า · doc type dropdown 15 ค่าตรง standard · Material `C-2026-004` (item text) → 4500000080 ยอดทั้งใบ
· Status/Approval Status + icon ตรง standard ทั้ง 6 ใบตัวแทน (Draft / In Approval / Rejected / Approved / Approved automatically / Follow-On)
· Net Order Value ไม่นับ item ที่ลบ (99680044 = 870,000.25) · ทดสอบซ้ำหลัง redesign D12 ผลเหมือนเดิมทุกข้อ

**ข้อจำกัดที่รับไว้** — Sent / Not Yet Sent / Output Error รวมเป็น Released · ไม่มีคอลัมน์ Approver
· tenant 80 ไม่มี PO ทดสอบไม่ได้ ต้อง transport ไป 100

## Phase 2 — FDP data interface (+ utility) — 🔨 checkpoint `c5b66b3` 2026-09-14 (XML ผ่าน · เก็บตกก่อนปิดเฟส)

**เป้าหมาย** ได้ data interface ที่ Adobe Form `ZPURF002` ดูดข้อมูลไปใช้ได้ครบ — *นี่คือส่วนหลักที่ผู้ใช้ขอ*
· สัญญา XML: [03-data-interface.md](03-data-interface.md) (แบบ B — แยก node ต่อ text type)

| # | งาน | Object | สถานะ |
|---|---|---|---|
| 2.1 | utility: วันที่ไทย / amount in words / quantity | `ZCL_PURE001_UTIL` | ✅ 742dd06 |
| 2.2 | ขยายตัวกลางให้ครอบข้อมูลฟอร์ม (schedule, acct assignment, WBS, tax rate, texts, approver) | `ZCL_PURE001_DATA` | ✅ c5b66b3 |
| 2.3 | custom entity 3 ชั้น | `ZR_PURE001_FDP`, `ZI_PURE001_ITEM_FDP`, `ZI_PURE001_ITXT_FDP` | ✅ c5b66b3 |
| 2.4 | service definition FDP | `ZAPI_PURE001_FDP` | ✅ c5b66b3 |
| 2.5 | query provider ประกอบ 3 node | `ZCL_PURE001_FDP` | ✅ c5b66b3 |
| 2.6 | ทดสอบ `cl_fp_fdp_services=>get_instance( 'ZAPI_PURE001_FDP' )->read_to_xml_v2( )` dump XML | `ZCL_PURE001_TEST_FDP` (ไม่ push) | ✅ 6 PO ผ่าน 2026-09-14 |
| 2.8 | เก็บตกจากผล XML — ~~`AccountAssignmentText` เว้นวรรคเกิน~~ (แก้แล้ว 09-18) · เลข 0 นำหน้า PR/GL/Order (ไม่พิมพ์ดิบบนฟอร์มแล้ว — ไม่ต้องแก้) · **หน่วยออกเป็น ISO (`C62`) — โผล่บนฟอร์มแล้ว ต้องแก้ก่อน go-live** · fallback ภาษา text | `ZCL_PURE001_FDP`, `ZI_PURE001_ITEM_FDP` | ⬜ |
| 2.7 | ฟอร์ม `ZPURF002` — clone จากฟอร์มเดิม re-bind กับ FDP (D14) · เพิ่ม field `ItemDescriptionText` / `SupplierCodeName` / `ApprovalNoteText` + service item `1 AU` ให้ฟอร์มไม่ต้องมี script | `form/ZPURF002.xdp`, FDP entity/class | ✅ Designer preview ผ่าน 09-18 · ⬜ สร้าง Form Object ใน ADT + push |

**แหล่งข้อมูลที่ยืนยันแล้ว (2026-09-13)** ดูตารางใน [03-data-interface.md](03-data-interface.md) และ tenant findings ใน [06-decisions.md](06-decisions.md)

**placeholder ทั้งหมดปิดแล้ว 2026-09-25** — ที่อยู่ plant ผ่าน `ZCL_PURE001_ADDRESS` (D20) · custom field และตำแหน่งผู้อนุมัติผ่าน custom class (D19) · โลโก้ฝังในฟอร์ม ลายเซ็นไม่มีในฟอร์มมาตรฐาน (D21) · ที่อยู่และโทรบริษัทเป็นข้อความคงที่ในฟอร์ม

**เสร็จเมื่อ** — dump XML ออกมาแล้วมีครบทั้ง 3 ชั้น ข้อมูลตรงกับ PO จริงบน tenant 100 ✅ (ทดสอบ 99680198, 4500000080, 0099680019, 99680044, 0099680047, 0099680042 — ครอบ approved automatically / WBS / item ลบ / header text / item text 3 ชนิด) · เหลือปิด 2.8 + ลบ `ZCL_PURE001_TEST_FDP`

## Phase 3 — Print output ✅ เสร็จ 2026-09-23 (ชุด B ยกเลิกตาม D16)

**เป้าหมาย** กดปุ่มแล้วได้ PDF จริง ทั้งแบบ preview และ download

| # | งาน | Object |
|---|---|---|
| 3.1 | แยก logic render PDF เป็นคลาสกลาง (ใช้ร่วมกัน 2 ทาง) | `ZCL_PURE001_PRINT` |
| 3.2 | สร้าง abstract entity สำหรับผลลัพธ์ action | `ZA_PURE001_FILE` |
| 3.3 | สร้าง behavior definition (`unmanaged`) + action `PrintPOForm` | `ZR_PURE001` bdef |
| 3.4 | implement behavior pool — วน key, render, merge, base64 | `ZBP_R_PURE001` |
| 3.5 | สร้าง HTTP service + handler (`Mode=P` preview / `Mode=D` download) | `ZHS_PURE001` / `ZCL_PURE001_HTTP` |
| 3.6 | เติม `PrintUrl` / `DownloadUrl` ใน `ZCL_PURE001_QUERY` + คอลัมน์ `#WITH_URL` | `ZR_PURE001` |

**จุดที่ demo ทำพลาดแล้วเราจะไม่ทำตาม** — `%tky = keys[ 1 ]-%tky` ตายตัว,
`CATCH cx_root` แล้วเงียบ, ชื่อไฟล์ hardcode (ดู [04-fdp-pattern.md §7](04-fdp-pattern.md))

**เสร็จเมื่อ** — เลือก PO หลายใบแล้วกด Print PO Form ได้ PDF รวมเล่มเดียว
และคลิกลิงก์ preview เปิด PDF ใน tab ใหม่ได้

---

## Phase 4 — Utility & master data → รวมเข้า Phase 2 แล้ว (`ZCL_PURE001_UTIL` ✅) · graphics table ยกเลิก (D21)

**เป้าหมาย (เดิม)** เติมค่าที่ format ยากให้ครบ

| # | งาน | Object |
|---|---|---|
| ~~4.1~~ | ~~สร้างตารางเก็บรูป + data element~~ **ยกเลิก (D21)** — โลโก้ฝังในฟอร์ม ลายเซ็นไม่มี | — |
| 4.2 | `to_thai_date( )` — วันที่ พ.ศ. + ชื่อเดือนภาษาไทย (`21 พฤศจิกายน 2568`) | `ZCL_PURE001_UTIL` |
| 4.3 | `amount_in_words_th( )` — จำนวนเงินเป็นตัวอักษรไทย + `บาทถ้วน` / `สตางค์` | `ZCL_PURE001_UTIL` |
| ~~4.4~~ | ~~`get_graphic( )` — อ่านรูปจากตาราง~~ **ยกเลิก (D21)** | — |
| ~~4.5~~ | ~~upload โลโก้ THAPPLINE เข้าตาราง~~ **ยกเลิก (D21)** — รูปฝังใน `.xdp` แล้ว | — |

> ⚠️ FM `SPELL_AMOUNT` **ไม่ released** บน Public Cloud → ต้องเขียนตัวแปลงเอง
> และวันที่ พ.ศ. ก็ทำใน ABAP ไม่พึ่ง locale ของ ADS

**เสร็จเมื่อ** — PDF ที่ออกมามีโลโก้ วันที่ไทย และจำนวนเงินตัวอักษรถูกต้อง
(unit test ตัวแปลงจำนวนเงินอย่างน้อย: 0, 1, 21, 100, 1000, 1000000, ทศนิยม 2 ตำแหน่ง)

---

## Phase 5 — Fiori launchpad & authorization (5.1–5.3 ทำล่วงหน้าแล้ว 2026-09-12)

**เป้าหมาย** user role Procurement เปิด tile ใช้งานได้จริง

| # | งาน | Object | สถานะ |
|---|---|---|---|
| 5.1 | สร้าง IAM app ผูก service binding | `ZIAM_ZPURE001_EXT` | ✅ (ผู้ใช้สร้างตอน deploy ทดสอบ) |
| 5.2 | สร้าง business catalog | `ZBC_ZPURE001` (+ `ZBC_ZPURE001_0001`) | ✅ |
| 5.3 | สร้าง FLP app descriptor + tile | `ZPURE001_UI5R` (`ZPURE001-manage`) | ✅ |
| 5.4 | ผูก catalog เข้า business role ของหน่วยงานจัดซื้อ + **ทดสอบด้วย business user จริง** (เช็ค DCL ของ workflow view — ข้อ 12 ใน open questions) | ผู้ใช้ (Fiori app มาตรฐาน) | ⬜ |

**เสร็จเมื่อ** — user ที่มี role Procurement เห็น tile "Print Purchase Order" และกดใช้งานได้

---

## Phase 6 — Setting view & ฟิลด์นอกมาตรฐาน

**เป้าหมาย** ปิดช่องว่างที่รอ functional

| # | งาน |
|---|---|
| 6.1 | สรุปกับ functional ว่า "Setting View" คืออะไร เก็บอะไรบ้าง |
| 6.2 | สรุปที่มาของฟิลด์นอกมาตรฐาน (หลักประกัน / สัญญา / Ship Via / ผู้อนุมัติ) |
| 6.3 | สร้าง config table + app maintain (ถ้าจำเป็น) |
| 6.4 | เติมค่าลง node ที่ประกาศ placeholder ไว้ตั้งแต่ Phase 2 |

---

## Phase 7 — Testing

ตาม spec §3

| # | Description | Expected Result |
|---|---|---|
| 1 | Filter รายละเอียดต่าง ๆ ที่หน้าจอ Print Purchase Order | แสดงข้อมูลตาม filter ถูกต้องครบถ้วน |
| 2 | กดปุ่ม Print PO Form | แสดงเอกสาร Purchase Order ได้ |
| 3 | ตรวจรายละเอียดในเอกสาร | ข้อมูลในฟอร์มถูกต้องครบถ้วน |

เพิ่มเติมจากที่ spec ระบุ — เลือกหลาย PO แล้ว merge, PO ที่ item เยอะจนขึ้นหน้า 2,
PO ที่ไม่มี PR/WBS, PO สกุลเงินอื่นที่ไม่ใช่ THB

---

## ลำดับที่แนะนำ

```
Phase 0 ──► Phase 1 ──► Phase 2 ──► Phase 3 ──► Phase 5 ──► Phase 7
                            │           ▲
                            └─ Phase 4 ─┘
                                        Phase 6 (ขนานไป เมื่อ functional สรุป)
```

Phase 4 (utility) แทรกได้ระหว่าง 2–3 เพราะ FDP ต้องใช้ `to_thai_date( )` กับ
`amount_in_words_th( )` ตั้งแต่ตอนเติมข้อมูล — จะทำก่อน Phase 3 ก็ได้
