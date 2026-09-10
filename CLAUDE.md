# ZPURE001 — Project Rules

กฎเฉพาะโปรเจกต์นี้ ใช้ทับ global rules ใน `~/.claude/CLAUDE.md` เฉพาะข้อที่ระบุไว้

## Namespace — ใช้ `Z` ไม่ใช่ `Y`

**ข้อนี้ override global rule เรื่อง customer namespace**
ผู้ใช้สั่งไว้ชัดเจนว่า ABAP object ของโปรเจกต์นี้ให้ใช้ prefix `Z*` ทั้งหมด
(global rule ที่บังคับ `Y` ไม่ใช้กับ repo นี้)

ส่วนกฎอื่นที่เหลือ — naming convention ตัวแปร (`gv_`/`lv_`/`gs_`/`lt_`/`<lfs_>` ฯลฯ),
prefix parameter (`iv_`/`ev_`/`rv_`), pattern ของ RAP object — **ยังใช้ตามเดิมทุกข้อ**
แค่เปลี่ยนตัวอักษรแรกจาก `Y` เป็น `Z`

## App code

`<APP>` ของโปรเจกต์นี้คือ **`PURE001`** — object ทุกตัวใช้รูป `Z<TYPE>_PURE001[_<SUFFIX>]`

| Object | ชื่อ |
|---|---|
| Package | `ZPURE001` |
| Custom entity (UI) | `ZI_PURE001` |
| Custom entity (FDP) | `ZI_PURE001_FDP`, `ZI_PURE001_FDP_ITEM`, `ZI_PURE001_FDP_ITXT` |
| Abstract entity | `ZI_PURE001_FILE` |
| Query class | `ZCL_PURE001_QUERY`, `ZCL_PURE001_FDP` |
| Behavior pool | `ZBP_I_PURE001` |
| Service definition | `ZSD_PURE001` (UI), `ZSD_PURE001_FDP` (form data) |
| Service binding | `ZSB_PURE001` (OData V4, UI) |
| HTTP service | `ZHS_PURE001` + handler `ZCL_PURE001_HTTP` |
| Adobe Form object | `ZPURF001` |
| Utility class | `ZCL_PURE001_UTIL` |

ดูรายการเต็มที่ [docs/02-object-list.md](docs/02-object-list.md)

## วิธีทำงาน (ตกลงกับผู้ใช้ไว้แล้ว)

1. **implement ทีละเฟส** — จบเฟสหนึ่งแล้วค่อยขึ้นเฟสถัดไป
2. **Claude implement บน local file / ผู้ใช้ implement บน tenant จริง**
3. **Claude push เฉพาะเอกสาร** — ABAP object ผู้ใช้ push เองผ่าน abapGit จาก ADT
4. **Claude ห้ามเขียนไฟล์ ABAP ลง repo** (`*.clas.abap`, `*.ddls.asddls`, `*.asbdef`,
   `*.srvd.*`, `*.tabl.xml` ฯลฯ) → ส่งเป็น **code block ใน chat** ให้ผู้ใช้ copy ไปสร้างใน ADT
   ข้อยกเว้น: ร่าง ABAP ที่ยังไม่ขึ้น tenant เก็บได้ใน `docs/draft/` เท่านั้น
   (นามสกุล `.md` หรือ `.txt` — ห้ามใช้นามสกุลที่ abapGit รู้จัก)
5. **provide commit message ให้ผู้ใช้ดูก่อน push เสมอ**
6. หลังผู้ใช้ push object ขึ้น Git → Claude เช็ค `git log` / `git diff` เพื่อ
   ตรวจความถูกต้องและ sync code ในเอกสารให้ตรงกับของจริงบน tenant
7. **ห้ามเขียน `.abapgit.xml` หรือ `src/**/package.devc.xml` เอง** — ปล่อยให้ SAP serialize
   ขึ้นมาเป็น baseline ตอนผู้ใช้ push ครั้งแรกจาก ADT
8. **ก่อนเริ่มทุกเฟส ต้องสรุปชื่อ object ทั้งหมดของเฟสนั้นให้ผู้ใช้รีวิวก่อน**
   แล้ว **รอจนผู้ใช้ confirm** ถึงจะเริ่ม implement ได้ — ห้ามเริ่มเขียนโค้ดของเฟสใด ๆ
   ก่อนได้รับ confirm ชื่อ object ของเฟสนั้น
   (ชื่อใน [docs/02-object-list.md](docs/02-object-list.md) เป็นแค่ข้อเสนอ ยังไม่ถือว่า confirm
   จนกว่าผู้ใช้จะยืนยันเป็นรายเฟส — คอลัมน์ `Confirmed` ในเอกสารนั้นคือตัวชี้ขาด)

## ข้อควรระวังเฉพาะงาน Adobe Form บน Public Cloud

- FDP entity **ต้องเป็น custom entity** เท่านั้น + ต้องมี
  `@ObjectModel.supportedCapabilities: [ #OUTPUT_FORM_DATA_PROVIDER ]`
  และ `@ObjectModel.query.implementedBy: 'ABAP:<class>'`
- ชื่อที่ส่งให้ `cl_fp_fdp_services=>get_instance( )` คือชื่อ **service definition**
  ไม่ใช่ชื่อ entity
- key ที่ `get_keys( )` คืนมาเป็นตัวพิมพ์ใหญ่เสมอ (`'PURCHASEORDER'`)
- ค่าที่ format ยาก (วันที่ พ.ศ. เดือนภาษาไทย จำนวนเงินเป็นตัวอักษร) ให้ **แปลงใน ABAP
  แล้วส่งเป็น string** อย่าไปพึ่ง locale ของ ADS
- รูปภาพ (logo / ลายเซ็น) ส่งผ่าน field `@Semantics.largeObject` เป็น `abap.rawstring`
