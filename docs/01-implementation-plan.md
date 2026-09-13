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

**สถาปัตยกรรม — hybrid** (ดู [06-decisions.md](06-decisions.md) D2, D5–D10)

```
ZUI_PURE001_O4 (binding)
  └─ ZUI_PURE001 (service def, alias PrintPurchaseOrder)
       └─ ZR_PURE001 (custom entity)  ←  ZCL_PURE001_QUERY  (+ ZCX_PURE001_QUERY)
                                             │  EXISTS Material/Plant (+ item text) · sort/paging/count push-down
                                             │  join status text · ต่อ string MaterialList / PlantList
                                             ▼
                                        ZI_PURE001_HEADER (view entity) ← data logic ทั้งหมด
                                             ├─ ZI_PURE001_TOTAL     (sum ต่อ PO, ไม่นับ item ที่ลบ)
                                             ├─ ZI_PURE001_FOLLOWON  (PO ที่มี GR/IR)
                                             ├─ ZI_PURE001_WORKFLOW  (workflow ล่าสุด) → I_WorkflowStatusOverview
                                             └─ text: I_Supplier / I_PurchasingGroup / I_PurchasingDocumentTypeText
       VH: ZI_PURE001_STATUS_VH · ZI_PURE001_POTYPE_VH · I_Supplier · I_PurchasingGroup · I_Product · I_Plant · I_CompanyCodeVH
```

| # | งาน | Object | สถานะ |
|---|---|---|---|
| 1.1 | view ยอดรวมต่อ PO | `ZI_PURE001_TOTAL` | ✅ |
| 1.2 | view header + text + derived status | `ZI_PURE001_HEADER` | ✅ |
| 1.3 | custom entity ของ list report | `ZR_PURE001` | ✅ |
| 1.4 | query provider + exception | `ZCL_PURE001_QUERY`, `ZCX_PURE001_QUERY` | ✅ |
| 1.5 | service definition + binding (OData V4) | `ZUI_PURE001` / `ZUI_PURE001_O4` | ✅ published |
| 1.6 | Status / Approval Status / VH / criticality | `ZI_PURE001_STATUS_VH`, `_POTYPE_VH`, `_WORKFLOW`, `_FOLLOWON` | ✅ |
| 1.7 | ทดสอบเทียบ Manage Purchase Orders บน tenant 100 | — | ✅ 6 PO ตรงทุกคอลัมน์ |

**ผลทดสอบ (tenant 100, 2026-09-13)** — 284 PO · filter 13 ช่อง + VH ครบ · Company Code default `TL01`
· Status dropdown 7 ค่า · doc type dropdown 15 ค่าตรง standard · Material `C-2026-004` (item text) → 4500000080 ยอดทั้งใบ
· Status/Approval Status + icon ตรง standard ทั้ง 6 ใบตัวแทน (Draft / In Approval / Rejected / Approved / Approved automatically / Follow-On)
· Net Order Value ไม่นับ item ที่ลบ (99680044 = 870,000.25)

**ข้อจำกัดที่รับไว้** — Sent / Not Yet Sent / Output Error รวมเป็น Released · ไม่มีคอลัมน์ Approver
· tenant 80 ไม่มี PO ทดสอบไม่ได้ ต้อง transport ไป 100

## Phase 2 — FDP data interface

**เป้าหมาย** ได้ data interface ที่ Adobe Form ดูดข้อมูลไปใช้ได้ครบ
— *นี่คือส่วนหลักที่ผู้ใช้ขอ*

| # | งาน | Object |
|---|---|---|
| 2.1 | สร้าง custom entity 3 ชั้น (header / item / item text) | `ZR_PURE001_FDP`, `..._ITEM`, `..._ITXT` |
| 2.2 | สร้าง query class เติมข้อมูลทั้ง 3 node | `ZCL_PURE001_FDP` |
| 2.3 | สร้าง service definition สำหรับ FDP | `ZAPI_PURE001_FDP` |
| 2.4 | ทดสอบด้วย `cl_fp_fdp_services=>get_instance( 'ZAPI_PURE001_FDP' )->read_to_xml_v2( )` แล้ว dump XML ออกมาดู | — |
| 2.5 | ส่ง XML schema ให้ผู้ใช้เอาไป bind ใน LiveCycle Designer | Claude → ผู้ใช้ |
| 2.6 | ผู้ใช้สร้าง form object `ZPURF001` + upload XDP | ผู้ใช้ |

**ฟิลด์ที่ทำเป็น placeholder ไว้ก่อน** (รอ functional สรุป — ดู [05-open-questions.md](05-open-questions.md))
— หลักประกัน/BG checkbox · วันที่เริ่ม-สิ้นสุดสัญญา · Ship Via · นามผู้รับสินค้า ·
ผู้อนุมัติ + ลายเซ็น · ส่วนลด
ประกาศ node ไว้ในสัญญาตั้งแต่ตอนนี้ แต่ยังไม่เติมค่า → เติมทีหลังโดยไม่ต้องแก้ฟอร์ม

**เสร็จเมื่อ** — dump XML ออกมาแล้วมีครบทั้ง 3 ชั้น ข้อมูลตรงกับ PO จริงบน tenant

---

## Phase 3 — Print output

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

## Phase 4 — Utility & master data

**เป้าหมาย** เติมค่าที่ format ยากให้ครบ

| # | งาน | Object |
|---|---|---|
| 4.1 | สร้างตารางเก็บรูป + data element | `ZPURE001_GRPH`, `ZE_PURE001_GRAPHIC_NAME` |
| 4.2 | `to_thai_date( )` — วันที่ พ.ศ. + ชื่อเดือนภาษาไทย (`21 พฤศจิกายน 2568`) | `ZCL_PURE001_UTIL` |
| 4.3 | `amount_in_words_th( )` — จำนวนเงินเป็นตัวอักษรไทย + `บาทถ้วน` / `สตางค์` | `ZCL_PURE001_UTIL` |
| 4.4 | `get_graphic( )` — อ่านรูปจากตาราง | `ZCL_PURE001_UTIL` |
| 4.5 | upload โลโก้ THAPPLINE เข้าตาราง | ผู้ใช้ |

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
