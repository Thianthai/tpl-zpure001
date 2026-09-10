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
| Form Object | `ZPURF001` |
| Requested by | Procurement Team (08.07.2026) |
| Spec | [TPL_ZPURE001_Print Purchase Order.docx](TPL_ZPURE001_Print%20Purchase%20Order.docx) V1.0 (17.08.2026) |

## ภาพรวม

โปรแกรมประกอบด้วย 2 ส่วนที่แยกกันชัดเจน

1. **RAP UI** — Fiori list report "Print Purchase Order" ที่ให้ user filter หา PO
   แล้วกดปุ่ม **Print PO Form** เพื่อพิมพ์/preview เอกสาร
2. **Form Data Provider (FDP)** — data interface ที่ป้อนข้อมูล PO ให้ Adobe Form
   (`ZPURF001`) โดยผ่าน `cl_fp_fdp_services` → `read_to_xml_v2()` → `cl_fp_ads_util=>render_pdf()`

```
Fiori List Report (ZUI_PURE001_O4)
        │
        ├── ปุ่ม Print PO Form ──► RAP action PrintPOForm ──┐
        │                                                   │
        └── column Preview/Download URL ──► ZHS_PURE001 ────┤
                                            (HTTP service)  │
                                                            ▼
                                            cl_fp_fdp_services( 'ZAPI_PURE001_FDP' )
                                                            │
                                            ZR_PURE001_FDP ─┼─ ZI_PURE001_FDP_ITEM
                                            (custom entity) │        │
                                                            │        └─ ZI_PURE001_FDP_ITXT
                                                            ▼
                                            cl_fp_ads_util=>render_pdf( ZPURF001 )
                                                            │
                                                            ▼
                                                          PDF
```

## เอกสาร

| ไฟล์ | เนื้อหา |
|---|---|
| [docs/01-implementation-plan.md](docs/01-implementation-plan.md) | แผน implement แบ่งเป็นเฟส |
| [docs/02-object-list.md](docs/02-object-list.md) | รายการ ABAP object ทั้งหมด + สถานะ |
| [docs/03-data-interface.md](docs/03-data-interface.md) | โครงสร้าง FDP node + field mapping กับฟอร์ม |
| [docs/04-fdp-pattern.md](docs/04-fdp-pattern.md) | pattern การ implement FDP + call form (สรุปจาก demo) |
| [docs/05-open-questions.md](docs/05-open-questions.md) | ประเด็นที่ยังรอ functional สรุป |

## การแบ่งงาน push

| สิ่งที่ทำ | ใคร push |
|---|---|
| ABAP object ทุกชนิด | **ผู้ใช้** ผ่าน abapGit จาก ADT |
| เอกสาร (`docs/`, `README.md`, `CLAUDE.md`) | **Claude** |
