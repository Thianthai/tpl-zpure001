"! <p class="shorttext synchronized">Print Purchase Order - Render PDF</p>
"! ตัวกลาง render PDF ที่ปุ่มใน list report และ HTTP service ใช้ร่วมกัน
CLASS zcl_pure001_print DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    "! รายการเลขที่ใบสั่งซื้อที่จะพิมพ์
    TYPES tt_purchase_order TYPE STANDARD TABLE OF zr_pure001-PurchaseOrder WITH EMPTY KEY.

    "! สร้าง PDF จากฟอร์ม ZPURF002 ตามเลขที่ใบสั่งซื้อที่ส่งมา
    "! หลายใบจะถูกรวมเป็นไฟล์เดียว เรียงตามลำดับที่ส่งเข้ามา
    "! ev_message มีค่าเมื่อ render ไม่สำเร็จ ผู้เรียกต้องเช็คก่อนใช้ ev_pdf
    "! @parameter it_purchase_order | เลขที่ใบสั่งซื้อ อย่างน้อย 1 ใบ
    "! @parameter ev_pdf | ไฟล์ PDF
    "! @parameter ev_message | ข้อความ error ว่างเมื่อสำเร็จ
    METHODS render
      IMPORTING it_purchase_order TYPE tt_purchase_order
      EXPORTING ev_pdf            TYPE xstring
                ev_message        TYPE string.

    "! ชื่อไฟล์ PDF พร้อมนามสกุล
    "! ใบเดียวขึ้นต้นด้วยเลขที่ใบสั่งซื้อแบบตัดศูนย์นำหน้า
    "! หลายใบมีแต่วันเวลา เพราะระบุเลขที่ใบใดใบหนึ่งไม่ได้
    "! วันเวลาเป็นเวลาประเทศไทย ไม่ใช่เวลาของ system
    "! @parameter it_purchase_order | เลขที่ใบสั่งซื้อชุดเดียวกับที่ส่งให้ render
    "! @parameter rv_file_name | เช่น 99680042_20260923_143015.pdf
    METHODS get_file_name
      IMPORTING it_purchase_order   TYPE tt_purchase_order
      RETURNING VALUE(rv_file_name) TYPE string.

  PROTECTED SECTION.
  PRIVATE SECTION.

    CONSTANTS:
      "! ชื่อ object ที่ใช้เรียก framework ของ Adobe Forms
      BEGIN OF gc_form,
        "! ชื่อ service definition ของ form data provider ไม่ใช่ชื่อ entity
        data_provider TYPE c LENGTH 40 VALUE 'ZAPI_PURE001_FDP',

        "! ชื่อ form object ที่เก็บ layout XDP
        form_object   TYPE c LENGTH 30 VALUE 'ZPURF002',

        "! key ที่ get_keys คืนมาเป็นตัวพิมพ์ใหญ่เสมอ
        key_name      TYPE c LENGTH 40 VALUE 'PURCHASEORDER',

        "! locale ของ ADS มีผลกับรูปแบบตัวเลขเท่านั้น ข้อความไทยแปลงมาจาก ABAP แล้ว
        locale        TYPE c LENGTH 10 VALUE 'en_US',
      END OF gc_form.

    "! เวลาประเทศไทย ใช้กับ CONVERT UTCLONG
    CONSTANTS gc_time_zone TYPE c LENGTH 6 VALUE 'UTC+7'.

    "! render PDF ของใบสั่งซื้อใบเดียว
    "! @parameter iv_purchase_order | เลขที่ใบสั่งซื้อ
    "! @parameter rv_pdf | ไฟล์ PDF ของใบนั้น
    METHODS render_single
      IMPORTING iv_purchase_order TYPE zr_pure001-PurchaseOrder
      RETURNING VALUE(rv_pdf)     TYPE xstring
      RAISING   cx_root.

ENDCLASS.


CLASS zcl_pure001_print IMPLEMENTATION.


  METHOD render.

    CLEAR: ev_pdf, ev_message.

    IF it_purchase_order IS INITIAL.
      ev_message = 'No purchase order selected'.
      RETURN.
    ENDIF.

    TRY.
        " ใบเดียวไม่ต้องผ่าน merger เพื่อให้ได้ไฟล์ที่ ADS สร้างมาตรง ๆ
        IF lines( it_purchase_order ) = 1.
          ev_pdf = render_single( it_purchase_order[ 1 ] ).
          RETURN.
        ENDIF.

        DATA(lo_merger) = cl_rspo_pdf_merger=>create_instance( ).

        LOOP AT it_purchase_order INTO DATA(lv_purchase_order).
          lo_merger->add_document( render_single( lv_purchase_order ) ).
        ENDLOOP.

        ev_pdf = lo_merger->merge_documents( ).

      CATCH cx_root INTO DATA(lx_error).
        CLEAR ev_pdf.
        ev_message = lx_error->get_text( ).
    ENDTRY.

  ENDMETHOD.


  METHOD render_single.

    DATA(lo_fdp) = cl_fp_fdp_services=>get_instance( gc_form-data_provider ).

    DATA(lt_key) = lo_fdp->get_keys( ).

    LOOP AT lt_key ASSIGNING FIELD-SYMBOL(<lfs_key>) WHERE name = gc_form-key_name.
      <lfs_key>-value = iv_purchase_order.
    ENDLOOP.

    DATA(lv_xml) = lo_fdp->read_to_xml_v2( lt_key ).

    DATA(lo_reader) = cl_fp_form_reader=>create_form_reader( gc_form-form_object ).

    cl_fp_ads_util=>render_pdf(
      EXPORTING iv_xml_data   = lv_xml
                iv_xdp_layout = lo_reader->get_layout( )
                iv_locale     = CONV #( gc_form-locale )
      IMPORTING ev_pdf        = rv_pdf ).

  ENDMETHOD.


  METHOD get_file_name.

    DATA lv_date TYPE d.
    DATA lv_time TYPE t.

    CONVERT UTCLONG utclong_current( )
      INTO DATE lv_date
           TIME lv_time
      TIME ZONE gc_time_zone.

    DATA(lv_stamp) = |{ lv_date DATE = RAW }_{ lv_time TIME = RAW }|.

    IF lines( it_purchase_order ) = 1.
      rv_file_name = |{ condense( |{ it_purchase_order[ 1 ] ALPHA = OUT }| ) }_{ lv_stamp }.pdf|.
    ELSE.
      rv_file_name = |{ lv_stamp }.pdf|.
    ENDIF.

  ENDMETHOD.

ENDCLASS.
