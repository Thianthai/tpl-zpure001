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

## Phase 1 — RAP UI (list report) ✅ เสร็จ 2026-09-11

**เป้าหมาย** ได้หน้าจอ Fiori list report ที่ filter หา PO ได้ครบ 13 ช่อง แสดง 9 คอลัมน์
(ยังไม่มีปุ่มพิมพ์)

**สถาปัตยกรรมที่เลือก — hybrid** (ดู [06-decisions.md](06-decisions.md) ข้อ D1–D3)

```
ZUI_PURE001_O4 (binding)
  └─ ZUI_PURE001 (service def)
       └─ ZR_PURE001 (custom entity)  ←  ZCL_PURE001_QUERY
                                             │  EXISTS (Material/Plant) · sort/paging/count push-down
                                             │  ต่อ string MaterialList / PlantList
                                             ▼
                                        ZI_PURE001_HEADER (view entity)  ← data logic ทั้งหมด
                                             └─ ZI_PURE001_TOTAL (sum ต่อ PO)
```

| # | งาน | Object | สถานะ |
|---|---|---|---|
| 1.1 | view ยอดรวมต่อ PO | `ZI_PURE001_TOTAL` | ✅ |
| 1.2 | view header + text + derived status | `ZI_PURE001_HEADER` | ✅ |
| 1.3 | custom entity ของ list report | `ZR_PURE001` | ✅ |
| 1.4 | query provider | `ZCL_PURE001_QUERY` | ✅ |
| 1.5 | service definition + binding (OData V4) | `ZUI_PURE001` / `ZUI_PURE001_O4` | ✅ published |
| 1.6 | Preview → เช็ค filter / column / sort / paging / search | — | ⏳ รอทดสอบ |

**ยืนยันบน tenant แล้ว (2026-09-11) — activate ผ่านทั้งหมดโดยไม่ต้องแก้**

| สิ่งที่เดาไว้ | ผล |
|---|---|
| `I_PurchaseOrderAPI01` / `I_PurchaseOrderItemAPI01` | released C1 |
| `I_Supplier` / `I_PurchasingGroup` / `I_PurchasingDocumentTypeText` / `I_Plant` | ใช้ได้ |
| `NetAmount`, `DocumentCurrency` บน item view · `ReleaseIsNotCompleted` บน header | มีจริง |
| `@Search.searchable` บน custom entity + `get_search_expression( )` | activate ผ่าน (ผลจริงรอทดสอบ 1.6) |
| `cx_rap_query_filter_no_range` propagate จาก `select` | compile ผ่าน |
| `esart` | **ใช้ไม่ได้** → ใช้ `ZE_BSART` (external) แทน |
| Editing Status (filter ที่ 2) | **ตัดออก** — เป็น draft filter ของ Fiori ไม่ใช่ field ใน CDS |

**เสร็จเมื่อ** — preview แล้ว filter ครบ 13 ช่อง, กรอง Material/Plant แล้วได้ PO ที่มี item ตรง,
`$count` / `$skip` / `$top` / sort / Search ทำงานถูก

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

## Phase 5 — Fiori launchpad & authorization

**เป้าหมาย** user role Procurement เปิด tile ใช้งานได้จริง

| # | งาน | Object |
|---|---|---|
| 5.1 | สร้าง IAM app ผูก service binding | `ZIAM_PURE001` |
| 5.2 | สร้าง business catalog | `ZBC_PURE001` |
| 5.3 | สร้าง FLP app descriptor + tile | `ZPURE001_FLP` |
| 5.4 | ผูก catalog เข้า business role ของหน่วยงานจัดซื้อ | ผู้ใช้ (Fiori app มาตรฐาน) |

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
