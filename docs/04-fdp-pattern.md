# FDP Pattern — สรุปจาก demo `demo-ydmofdp`

เอกสารนี้สรุป pattern การ implement **Form Data Provider + call Adobe Form** บน
S/4HANA Cloud Public Edition ที่แกะมาจาก repo ตัวอย่าง
<https://github.com/Thianthai/demo-ydmofdp> เพื่อใช้เป็นแม่แบบของ ZPURE001

> โฟกัสที่ *วิธีทำ* ไม่ใช่คุณภาพโค้ด — demo เขียนแบบเร็ว ๆ หลายจุดไม่ตรง best practice
> และเราไม่ลอกมาทั้งดุ้น

---

## 1. องค์ประกอบทั้งหมดใน demo

| Object | ประเภท | หน้าที่ |
|---|---|---|
| `YI_DMOFDP` | root custom entity | FDP header + เป็น entity ของ list report ไปในตัว |
| `YI_DMOFDP_ITEM` | custom entity | FDP item (`association to parent`) |
| `YI_DMOFDP_FILE` | abstract entity | โครงผลลัพธ์ของ action (ไฟล์ base64) |
| `YCL_DMOFDP` | class | implements `if_rap_query_provider` |
| `YI_DMOFDP` (bdef) | behavior definition | `unmanaged` + `action PrintJournal result[1] YI_DMOFDP_FILE` |
| `YBP_I_DMOFDP` | behavior pool | `lhc_YI_DMOFDP` implement action |
| `YSD_DMOFDP` | service definition | **ชื่อนี้คือ FDP service** |
| `YSB_DMOFDP` | service binding | OData V4 → Fiori Elements list report |
| `YHS_DMOFDP` + `YCL_HTTP_SERVICE` | HTTP service | preview/download PDF ผ่าน URL |
| `YF_DMOFDP` | Form object | layout XDP ที่ทำจาก Adobe LiveCycle Designer |
| `ytbc_graphic` | table | เก็บ logo / ลายเซ็น เป็น rawstring |
| `YBC_DMOFDP` / `YIAM_DMOFDP_EXT` / `ydmofdp_flp.uiad.json` | BC / IAM / FLP | สิทธิ์ + tile บน launchpad |

---

## 2. Custom entity — ประกาศตัวเองเป็น FDP

```abap
@EndUserText.label: 'Demo Form Data Provider'
@ObjectModel.query.implementedBy: 'ABAP:YCL_DMOFDP'
@ObjectModel.supportedCapabilities: [ #OUTPUT_FORM_DATA_PROVIDER ]
define root custom entity YI_DMOFDP
{
  key CompanyCode  : bukrs;
  key JournalEntry : belnr_d;
  key FiscalYear   : gjahr;
  ...
  _item : composition of exact one to many YI_DMOFDP_ITEM;
}
```

จุดที่ต้องจำ

- annotation **สองตัวนี้ต้องอยู่ครบ** ทั้ง root และ child ทุกตัว มิฉะนั้น FDP มองไม่เห็น node
- child ผูกกลับด้วย `association to parent ... on _item.Key = $projection.Key`
- ไฟล์/รูปส่งเป็น `abap.rawstring( 0 )` + `@Semantics.largeObject`
  (คู่กับ field `MimeType` / `FileName` ที่มี `@Semantics.mimeType: true`)
- field ที่จะให้ list report ใช้เป็น filter ใส่ `@UI.selectionField`
  ส่วนคอลัมน์ใส่ `@UI.lineItem`

---

## 3. Query class — `if_rap_query_provider`

โครงที่ demo ใช้ (และเราจะใช้ตาม แต่จัดระเบียบใหม่)

```abap
METHOD if_rap_query_provider~select.
  CASE io_request->get_entity_id( ).
    WHEN 'YI_DMOFDP'.
      prepare_filter( io_request ).      " get_filter( )->get_as_ranges( )
      prepare_data_header( ).
      handle_record( ... ).              " is_total_numb_of_rec_requested( )
      handle_sort( ... ).                " get_sort_elements( )
      handle_paging( ... ).              " get_paging( )->get_offset/get_page_size
      io_response->set_data( gt_output ).
    WHEN 'YI_DMOFDP_ITEM'.
      ...
  ENDCASE.
ENDMETHOD.
```

- `get_as_ranges( )` คืน `if_rap_query_filter=>tt_name_range_pairs` — **`name` เป็นตัวพิมพ์ใหญ่**
- ตอนถูกเรียกจาก FDP ค่า key ที่ map ไว้จะมาถึงที่ query ในรูปของ filter ตัวนี้เช่นกัน
  → query class เดียวเสิร์ฟทั้ง list report และ form ได้
- `handle_paging` ของ demo ตัด `gt_output` ตรง ๆ ทำให้ item table ไม่ถูกตัดตาม
  → **ของเราแยก method ต่อ entity ไม่ให้พลาดแบบนี้**

---

## 4. หัวใจ — เรียก FDP แล้ว render PDF

โค้ดชุดนี้เหมือนกันทั้งใน RAP action และใน HTTP service

```abap
" 1) เปิด FDP ด้วยชื่อ SERVICE DEFINITION (ไม่ใช่ชื่อ entity)
DATA(lo_fdp_api)  = cl_fp_fdp_services=>get_instance( 'YSD_DMOFDP' ).

" 2) ขอ key ที่ FDP ต้องการ แล้วเติมค่า (ชื่อ key เป็นตัวพิมพ์ใหญ่)
DATA(lt_fdp_keys) = lo_fdp_api->get_keys( ).
LOOP AT lt_fdp_keys ASSIGNING FIELD-SYMBOL(<ls_key>).
  CASE <ls_key>-name.
    WHEN 'COMPANYCODE'.  <ls_key>-value = lv_company.
    WHEN 'JOURNALENTRY'. <ls_key>-value = lv_journal.
  ENDCASE.
ENDLOOP.

" 3) ให้ FDP ไปเรียก query class แล้วคาย XML data ออกมา
DATA(lv_xml)    = lo_fdp_api->read_to_xml_v2( lt_fdp_keys ).

" 4) อ่าน layout XDP จาก form object
DATA(lo_reader) = cl_fp_form_reader=>create_form_reader( 'YF_DMOFDP' ).

" 5) ยิงเข้า ADS ได้ PDF เป็น xstring
cl_fp_ads_util=>render_pdf(
  EXPORTING iv_xml_data   = lv_xml
            iv_xdp_layout = lo_reader->get_layout( )
            iv_locale     = 'en_US'
  IMPORTING ev_pdf        = lv_pdf ).
```

---

## 5. ทางส่งออก PDF — demo ทำไว้ 2 ทาง (เราใช้ทั้งคู่)

### 5.1 RAP action → ให้ Fiori โหลดไฟล์

```abap
" bdef
unmanaged implementation in class ybp_i_dmofdp unique;
define behavior for YI_DMOFDP
lock master
authorization master ( instance )
{
  field ( readonly ) CompanyCode, JournalEntry, FiscalYear;
  action PrintJournal result[1] YI_DMOFDP_FILE;
}
```

- `lhc_*` ต้อง implement `read` / `lock` / `get_instance_authorizations` เปล่า ๆ ไว้ด้วย
  เพราะเป็น unmanaged
- เลือกหลายแถวได้ → วนทุก key, render ทีละใบ แล้วรวมด้วย
  `cl_rspo_pdf_merger=>create_instance( )` → `add_document( )` → `merge_documents( )`
- ผลลัพธ์แปลงเป็น base64 ด้วย `cl_web_http_utility=>encode_x_base64( )`
  ใส่กลับใน `%param` ของ abstract entity → Fiori เอาไปเป็นไฟล์ดาวน์โหลด
- ยังมี `cl_print_queue_utils=>create_queue_item_by_data( )` (demo comment ไว้) สำหรับ
  ส่งเข้า print queue จริง — เก็บเป็นทางเลือกไว้ก่อน

### 5.2 HTTP service → preview inline

```abap
CLASS ycl_http_service ... INTERFACES if_http_service_extension.

METHOD if_http_service_extension~handle_request.
  DATA(lv_journal) = request->get_form_field( 'JournalEntry' ).
  DATA(lv_mode)    = request->get_form_field( 'Mode' ).
  ...render PDF...
  response->set_header_field( i_name = 'Content-Type' i_value = 'application/pdf' ).
  response->set_header_field(
    i_name  = 'Content-Disposition'
    i_value = SWITCH #( lv_mode WHEN 'D' THEN |attachment; filename="{ lv_file }"|
                                         ELSE |inline; filename="{ lv_file }"| ) ).
  response->set_binary( lv_pdf ).
ENDMETHOD.
```

ฝั่ง entity เตรียม field URL ไว้ให้ list report กดได้

```abap
@UI.hidden                 : true
PrintUrl                   : abap.char(1000);

@UI.lineItem : [{ position: 50, label: 'Print', type: #WITH_URL, url: 'PrintUrl' }]
PrintUrlBTN                : abap.char(20);
```

แล้วเติมค่าใน query class

```abap
<ls_result>-PrintUrl = |/sap/bc/http/sap/YHS_DMOFDP?JournalEntry={ ... }&Mode=P|.
<ls_result>-PrintUrlBTN = 'Preview PDF'.
```

---

## 6. รูปภาพในฟอร์ม

demo เก็บ logo/ลายเซ็นในตาราง `ytbc_graphic (uuid, graphic_name, mime_type, file_name, attachment)`
แล้ว select เข้ามาใส่ field `@Semantics.largeObject` ของ FDP entity
→ ฝั่ง LiveCycle Designer bind image field กับ node นั้น

ZPURE001 จะใช้แนวเดียวกัน (ตาราง `ZPURE001_GRPH`) สำหรับโลโก้ THAPPLINE และลายเซ็นผู้อนุมัติ

---

## 7. สิ่งที่ demo ทำแล้วเราจะ **ไม่** ทำตาม

| demo | ปัญหา | ของเรา |
|---|---|---|
| entity เดียวเสิร์ฟทั้ง list report และ FDP | query ตอน list ดึง logo/text หนัก ๆ มาโดยไม่จำเป็น | แยก `ZI_PURE001` (UI) กับ `ZI_PURE001_FDP` (form) |
| `handle_paging` ตัดเฉพาะ `gt_output` | item ไม่ถูกตัดตาม / ตัวเลข count เพี้ยน | แยก paging ต่อ entity |
| `CATCH cx_root` แล้วเงียบ | error หายไปเฉย ๆ ไม่ถึง user | ส่งกลับเป็น `reported` message ทุกครั้ง |
| `FileName = 'Journal_TEST.pdf'` hardcode | ชื่อไฟล์ไม่สื่อ | ตั้งชื่อจากเลข PO จริง |
| `%tky = keys[ 1 ]-%tky` ตายตัว | ผูกผลลัพธ์ผิดแถวเวลาเลือกหลายรายการ | map ตาม key ที่เลือกจริง |
