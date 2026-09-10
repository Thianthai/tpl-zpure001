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

| Object | ชื่อ | กฎที่ใช้ |
|---|---|---|
| Package | `ZPURE001` | `Y<APP>` |
| Custom entity — root | `ZR_PURE001` (UI), `ZR_PURE001_FDP` (form) | `YR_<APP>` |
| Custom entity — child | `ZI_PURE001_FDP_ITEM`, `ZI_PURE001_FDP_ITXT` | `YI_<APP>_<ENT>` |
| Abstract entity | `ZA_PURE001_FILE` | `YA_<...>` |
| Behavior definition | `ZR_PURE001` (= ชื่อ root entity) | = ชื่อ root view |
| Behavior pool | `ZBP_R_PURE001` | `YBP_R_<APP>` |
| Service definition | `ZUI_PURE001` (UI), `ZAPI_PURE001_FDP` (form data) | `YUI_<APP>` / `YAPI_<APP>` |
| Service binding | `ZUI_PURE001_O4` | `YUI_<APP>_O4` |
| Global class | `ZCL_PURE001_QUERY`, `ZCL_PURE001_FDP`, `ZCL_PURE001_PRINT`, `ZCL_PURE001_HTTP`, `ZCL_PURE001_UTIL` | `YCL_<APP>_<PURPOSE>` |
| Database table | `ZPURE001_GRPH`, `ZPURE001_CFG` | `Y<APP>_<SUFFIX>` |
| Data element | `ZE_PURE001_GRAPHIC_NAME` | `YE_<name>` |
| HTTP service | `ZHS_PURE001` | *(กฎยังไม่ครอบคลุม — ตกลงกันเป็น case)* |
| Adobe Form object | `ZPURF001` | *(ตาม spec §2.5)* |

ดูรายการเต็มที่ [docs/02-object-list.md](docs/02-object-list.md)

### หมายเหตุเรื่อง custom entity

custom entity **ไม่ใช่ view** (ไม่มี data source ข้างหลัง) กฎ global มี category
`YQ_<...>` สำหรับ custom entity (unmanaged query) อยู่ แต่ผู้ใช้ตัดสินใจแล้วว่า
**โปรเจกต์นี้ไม่ใช้ `ZQ_`** — ให้มองตามบทบาทแทน คือ root ใช้ `ZR_` และ child ใช้ `ZI_`
เหมือน view ปกติ

### case ที่กฎ global ยังไม่ครอบคลุม (ตกลงกันแล้วในโปรเจกต์นี้)

| กรณี | ที่ตกลง |
|---|---|
| Service definition ของ FDP (ไม่มี binding ไม่ใช่ทั้ง UI และ OData API) | ใช้ `ZAPI_<APP>_FDP` |
| Behavior pool ของ custom entity | ใช้ `ZBP_R_<APP>` ตามกฎ root ปกติ (ไม่แยกตัวอักษรตามชนิด entity) |

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

### 3 ข้อที่ผู้ใช้ย้ำว่าซีเรียสที่สุด

ยกระดับเป็นกฎ global แล้วใน `~/.claude/CLAUDE.md` หัวข้อ "จังหวะการทำงาน" — ห้ามข้าม

8. **ก่อนเริ่มทุกเฟส ต้องสรุปชื่อ object ทั้งหมดของเฟสนั้นให้ผู้ใช้รีวิวก่อน**
   แล้ว **รอจนผู้ใช้ confirm** ถึงจะเริ่ม implement ได้
   ถึงจะเคย confirm ชื่อรวม ๆ ไว้ตอนวางแผนแล้วก็ยังต้องสรุปซ้ำทุกเฟสอยู่ดี
   (คอลัมน์ `Confirmed` ใน [docs/02-object-list.md](docs/02-object-list.md) คือตัวชี้ขาด)
9. **ถามก่อนส่ง code เสมอ** — ห้ามส่ง code block มาขัดจังหวะระหว่างที่ยังคุยกันไม่จบ
   ให้ถามว่าพร้อมรับ code แล้วหรือยัง แล้วหยุดรอคำตอบ
   ตอบคำถาม อธิบาย เสนอทางเลือก ทำได้ตามปกติ — แค่อย่าเพิ่งส่งตัว code
10. **ไม่แน่ใจ ให้ถามก่อนเสมอ** — อย่าเดาแล้วลุยต่อ อย่าเลือกทางใดทางหนึ่งเงียบ ๆ
   แล้วค่อยมาบอกทีหลัง

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
