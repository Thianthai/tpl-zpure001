# ZPURE001 — Print Purchase Order

RAP UI + Form Data Provider (FDP) สำหรับพิมพ์ใบสั่งซื้อ (Purchase Order Form)
บน SAP S/4HANA Cloud Public Edition — Thai Petroleum Pipeline Co., Ltd (Thappline)

| | |
|---|---|
| Object ID | `ZPURE001` |
| Object Name | Print Purchase Order |
| Module | MM-PU |
| FRICEW Type | Enhancement (Medium) |
| Processing | Online |
| Package | `ZPURE001` |
| Form Object | `ZPURF002` (ฟอร์มใหม่ — `ZPURF001` ใน spec คือฟอร์ม output management ของ Manage PO นอกขอบเขต) |
| Requested by | Procurement Team (08.07.2026) |
| Spec | [TPL_ZPURE001_Print Purchase Order.docx](TPL_ZPURE001_Print%20Purchase%20Order.docx) V1.0 (17.08.2026) |

## ภาพรวม

โปรแกรมประกอบด้วย 2 ส่วนที่แยกกันชัดเจน

1. **RAP UI** — Fiori list report "Print Purchase Order" ที่ให้ user filter หา PO
   แล้วกดปุ่ม **Print PO Form** เพื่อพิมพ์/preview เอกสาร
2. **Form Data Provider (FDP)** — data interface ที่ป้อนข้อมูล PO ให้ Adobe Form
   (`ZPURF002`) โดยผ่าน `cl_fp_fdp_services` → `read_to_xml_v2()` → `cl_fp_ads_util=>render_pdf()`

```
Fiori List Report (ZUI_PURE001_O4)                        Adobe Form ZPURF002 (Phase 2)
        │                                                          ▲
        ▼                                                          │ cl_fp_ads_util=>render_pdf
ZR_PURE001 (custom entity)                    ZR_PURE001_FDP ─┬─ ZI_PURE001_ITEM_FDP ─── ZI_PURE001_ITXT_FDP
        │                                     (custom entity)  │   (custom entity)        (custom entity)
        ▼                                                      ▼
ZCL_PURE001_QUERY                                    ZCL_PURE001_FDP   ◄── cl_fp_fdp_services( 'ZAPI_PURE001_FDP' )
 filter · search · count · sort · paging              ประกอบ 3 node · ภาษี · format
 MaterialList / PlantList                                      │
        │                                                      │
        └──────────────────┬───────────────────────────────────┘
                           ▼
                   ZCL_PURE001_DATA   ← ตัวกลาง: อ่าน view มาตรฐาน + derive Status / Approval / ยอดรวม
                   ZCL_PURE001_UTIL   ← วันที่ไทย · amount in words · quantity
        (CDS = ประกาศ field อย่างเดียว · logic ทั้งหมดใน ABAP — D12)

Phase 3: ปุ่ม Print PO Form (RAP action) + ZHS_PURE001 (HTTP preview) → PDF
```

**สถานะ** — Phase 0 ✅ · Phase 1 ✅ (redesign D12 2026-09-13 ทดสอบซ้ำผ่าน · ⚠️ bug VH Material ข้อ 21) · Phase 5.1–5.3 ✅ · Phase 2 🔨 XML ผ่าน 6 PO (`c5b66b3`) + **ฟอร์ม `ZPURF002` Designer preview ผ่าน 2026-09-18** (`form/`) · field ใหม่ push แล้ว `1b5205b` · Form Object `ZPURF002` สร้างบน tenant แล้ว 09-23 (abapGit serialize ไม่ได้ — master อยู่ `form/`) · **Phase 3 ชุด A พิมพ์ PDF ได้จริงแล้ว 09-23** (ต้องมี UI5 controller extension คู่ด้วย — D15) · ค้าง: HTTP service (ชุด B), หน่วย ISO

## เอกสาร

| ไฟล์ | เนื้อหา |
|---|---|
| [docs/01-implementation-plan.md](docs/01-implementation-plan.md) | แผน implement แบ่งเป็นเฟส |
| [docs/02-object-list.md](docs/02-object-list.md) | รายการ ABAP object ทั้งหมด + สถานะ |
| [docs/03-data-interface.md](docs/03-data-interface.md) | โครงสร้าง FDP node + field mapping กับฟอร์ม |
| [docs/04-fdp-pattern.md](docs/04-fdp-pattern.md) | pattern การ implement FDP + call form (สรุปจาก demo) |
| [docs/05-open-questions.md](docs/05-open-questions.md) | ประเด็นที่ยังรอ functional สรุป |
| [docs/06-decisions.md](docs/06-decisions.md) | บันทึกการตัดสินใจเชิงสถาปัตยกรรม + ข้อจำกัดของ tenant ที่ค้นพบ |

## การแบ่งงาน push

| สิ่งที่ทำ | ใคร push |
|---|---|
| ABAP object ทุกชนิด | **ผู้ใช้** ผ่าน abapGit จาก ADT |
| เอกสาร (`docs/`, `README.md`, `CLAUDE.md`) | **Claude** |
