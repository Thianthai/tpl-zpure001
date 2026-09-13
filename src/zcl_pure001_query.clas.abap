CLASS zcl_pure001_query DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES if_rap_query_provider .

  PROTECTED SECTION.
  PRIVATE SECTION.

    TYPES tt_result TYPE STANDARD TABLE OF zr_pure001 WITH EMPTY KEY.

    CONSTANTS gc_entity_id TYPE string VALUE 'ZR_PURE001'.

    DATA:
      go_data             TYPE REF TO zcl_pure001_data,
      gs_selection        TYPE zcl_pure001_data=>ty_selection,
      gv_search           TYPE string,
      gr_po_status        TYPE RANGE OF zr_pure001-PurchaseOrderStatus,
      gr_approval_status  TYPE RANGE OF zr_pure001-ApprovalStatus.

    "! แปลง $filter / $search จาก request เป็นเงื่อนไข
    METHODS prepare_filter
      IMPORTING io_request TYPE REF TO if_rap_query_request
      RAISING   cx_rap_query_provider.

    "! สร้าง pattern ค้น item text จาก filter Material (contains, ไม่สนตัวพิมพ์)
    METHODS prepare_item_text_patterns.

    "! กรองด้วย field ที่ derive ใน ABAP (Status / Approval Status) และ $search
    METHODS apply_memory_filters
      CHANGING ct_header TYPE zcl_pure001_data=>tt_header.

    METHODS apply_sorting
      IMPORTING io_request TYPE REF TO if_rap_query_request
      CHANGING  ct_header  TYPE zcl_pure001_data=>tt_header.

    METHODS apply_paging
      IMPORTING io_request TYPE REF TO if_rap_query_request
      CHANGING  ct_header  TYPE zcl_pure001_data=>tt_header.

    "! ประกอบ MaterialList / PlantList — เรียกหลัง paging เท่านั้น
    METHODS add_item_lists
      CHANGING ct_result TYPE tt_result.

ENDCLASS.


CLASS zcl_pure001_query IMPLEMENTATION.


  METHOD if_rap_query_provider~select.

    IF io_request->get_entity_id( ) <> gc_entity_id.
      RETURN.
    ENDIF.

    go_data = NEW #( ).

    prepare_filter( io_request ).

    " อ่าน + derive ครั้งเดียว แล้วกรอง/นับ/เรียง/ตัดหน้าใน memory (D12)
    DATA(lt_header) = go_data->read_headers( gs_selection ).
    apply_memory_filters( CHANGING ct_header = lt_header ).

    " นับก่อน paging เสมอ
    IF io_request->is_total_numb_of_rec_requested( ).
      io_response->set_total_number_of_records( lines( lt_header ) ).
    ENDIF.

    IF io_request->is_data_requested( ).
      apply_sorting( EXPORTING io_request = io_request CHANGING ct_header = lt_header ).
      apply_paging(  EXPORTING io_request = io_request CHANGING ct_header = lt_header ).

      DATA(lt_result) = CORRESPONDING tt_result( lt_header ).
      add_item_lists( CHANGING ct_result = lt_result ).

      io_response->set_data( lt_result ).
    ENDIF.

  ENDMETHOD.


  METHOD prepare_filter.

    TRY.
        DATA(lt_filter) = io_request->get_filter( )->get_as_ranges( ).
      CATCH cx_rap_query_filter_no_range INTO DATA(lx_no_range).
        " filter ที่ Fiori ส่งมาแปลงเป็น range ไม่ได้ — โยนต่อให้ framework แสดงข้อความ
        RAISE EXCEPTION NEW zcx_pure001_query( previous = lx_no_range ).
    ENDTRY.

    CLEAR: gs_selection, gr_po_status, gr_approval_status.

    LOOP AT lt_filter ASSIGNING FIELD-SYMBOL(<lfs_filter>).
      CASE <lfs_filter>-name.
        WHEN 'PURCHASEORDER'.       gs_selection-purchase_order   = CORRESPONDING #( <lfs_filter>-range ).
        WHEN 'PURCHASEORDERTYPE'.   gs_selection-po_type          = CORRESPONDING #( <lfs_filter>-range ).
        WHEN 'SUPPLIER'.            gs_selection-supplier         = CORRESPONDING #( <lfs_filter>-range ).
        WHEN 'COMPANYCODE'.         gs_selection-company_code     = CORRESPONDING #( <lfs_filter>-range ).
        WHEN 'PURCHASINGGROUP'.     gs_selection-purchasing_group = CORRESPONDING #( <lfs_filter>-range ).
        WHEN 'MATERIAL'.            gs_selection-material         = CORRESPONDING #( <lfs_filter>-range ).
        WHEN 'PLANT'.               gs_selection-plant            = CORRESPONDING #( <lfs_filter>-range ).
        WHEN 'PURCHASEORDERDATE'.   gs_selection-po_date          = CORRESPONDING #( <lfs_filter>-range ).
        WHEN 'CREATIONDATE'.        gs_selection-creation_date    = CORRESPONDING #( <lfs_filter>-range ).
        WHEN 'INTERNALREFERENCE'.   gs_selection-internal_ref     = CORRESPONDING #( <lfs_filter>-range ).
        WHEN 'EXTERNALREFERENCE'.   gs_selection-external_ref     = CORRESPONDING #( <lfs_filter>-range ).
        WHEN 'PURCHASEORDERSTATUS'. gr_po_status                  = CORRESPONDING #( <lfs_filter>-range ).
        WHEN 'APPROVALSTATUS'.      gr_approval_status            = CORRESPONDING #( <lfs_filter>-range ).
      ENDCASE.
    ENDLOOP.

    prepare_item_text_patterns( ).

    gv_search = to_upper( io_request->get_search_expression( ) ).

  ENDMETHOD.


  METHOD prepare_item_text_patterns.

    " Material ค้นใน item text ด้วย (D8) — include เท่านั้น แปลงเป็น contains ตัวพิมพ์ใหญ่
    CLEAR gs_selection-item_text.

    LOOP AT gs_selection-material ASSIGNING FIELD-SYMBOL(<lfs_material>) WHERE sign = 'I'.
      CASE <lfs_material>-option.
        WHEN 'EQ'.
          APPEND VALUE #( sign = 'I' option = 'CP'
                          low  = |*{ to_upper( <lfs_material>-low ) }*| ) TO gs_selection-item_text.
        WHEN 'CP'.
          APPEND VALUE #( sign = 'I' option = 'CP'
                          low  = to_upper( <lfs_material>-low ) ) TO gs_selection-item_text.
      ENDCASE.
    ENDLOOP.

    " มี filter Material แต่ไม่มี pattern (ใช้แต่ exclude) → กัน range ว่างทำให้ OR เป็นจริงเสมอ
    IF gs_selection-material IS NOT INITIAL AND gs_selection-item_text IS INITIAL.
      gs_selection-item_text = VALUE #( ( sign = 'E' option = 'CP' low = '*' ) ).
    ENDIF.

  ENDMETHOD.


  METHOD apply_memory_filters.

    IF gr_po_status IS NOT INITIAL.
      DELETE ct_header WHERE PurchaseOrderStatus NOT IN gr_po_status.
    ENDIF.

    IF gr_approval_status IS NOT INITIAL.
      DELETE ct_header WHERE ApprovalStatus NOT IN gr_approval_status.
    ENDIF.

    " $search: เลข PO / ชื่อผู้ขาย / Our Ref / Your Ref (contains, ไม่สนตัวพิมพ์)
    IF gv_search IS NOT INITIAL.
      LOOP AT ct_header ASSIGNING FIELD-SYMBOL(<lfs_header>).
        IF     to_upper( <lfs_header>-PurchaseOrder )     NS gv_search
           AND to_upper( <lfs_header>-SupplierName )      NS gv_search
           AND to_upper( <lfs_header>-InternalReference ) NS gv_search
           AND to_upper( <lfs_header>-ExternalReference ) NS gv_search.
          DELETE ct_header.
        ENDIF.
      ENDLOOP.
    ENDIF.

  ENDMETHOD.


  METHOD apply_sorting.

    DATA lt_order TYPE abap_sortorder_tab.

    DATA(lt_sort) = io_request->get_sort_elements( ).

    LOOP AT lt_sort ASSIGNING FIELD-SYMBOL(<lfs_sort>).
      DATA(lv_element) = to_upper( <lfs_sort>-element_name ).

      " field ที่ประกอบหลัง paging / filter-only ยังไม่มีค่าตอนนี้ → ข้าม
      IF lv_element = 'MATERIALLIST' OR lv_element = 'PLANTLIST'
      OR lv_element = 'MATERIAL'     OR lv_element = 'PLANT'.
        CONTINUE.
      ENDIF.

      APPEND VALUE #( name       = lv_element
                      descending = <lfs_sort>-descending ) TO lt_order.
    ENDLOOP.

    IF lt_order IS INITIAL.
      SORT ct_header BY PurchaseOrder DESCENDING.
    ELSE.
      SORT ct_header BY (lt_order).
    ENDIF.

  ENDMETHOD.


  METHOD apply_paging.

    DATA(lo_paging) = io_request->get_paging( ).
    IF lo_paging IS NOT BOUND.
      RETURN.
    ENDIF.

    DATA(lv_offset)    = lo_paging->get_offset( ).
    DATA(lv_page_size) = lo_paging->get_page_size( ).

    IF lv_offset > 0.
      DELETE ct_header FROM 1 TO lv_offset.
    ENDIF.

    " get_page_size( ) คืน -1 เมื่อไม่จำกัด
    IF lv_page_size > 0 AND lines( ct_header ) > lv_page_size.
      DELETE ct_header FROM lv_page_size + 1 TO lines( ct_header ).
    ENDIF.

  ENDMETHOD.


  METHOD add_item_lists.

    IF ct_result IS INITIAL.
      RETURN.
    ENDIF.

    " item ทุกรายการรวมที่ลบ (standard แสดงทุก item)
    DATA(lt_item) = go_data->read_items(
      VALUE #( FOR ls_result IN ct_result ( PurchaseOrder = ls_result-PurchaseOrder ) ) ).

    LOOP AT ct_result ASSIGNING FIELD-SYMBOL(<lfs_result>).

      DATA lt_material TYPE STANDARD TABLE OF string WITH EMPTY KEY.
      DATA lt_plant    TYPE SORTED TABLE OF string WITH UNIQUE KEY table_line.
      CLEAR: lt_material, lt_plant.

      LOOP AT lt_item ASSIGNING FIELD-SYMBOL(<lfs_item>)
           WHERE PurchaseOrder = <lfs_result>-PurchaseOrder.

        " "ชื่อ (รหัส)" — text item (ไม่มี material) แสดงชื่ออย่างเดียว · string template ตัดช่องว่างท้ายให้
        DATA(lv_material) = COND string(
          WHEN <lfs_item>-Material IS INITIAL
            THEN <lfs_item>-MaterialDescription
            ELSE |{ <lfs_item>-MaterialDescription } ({ <lfs_item>-Material })| ).

        IF NOT line_exists( lt_material[ table_line = lv_material ] ).
          APPEND lv_material TO lt_material.
        ENDIF.

        INSERT COND string(
          WHEN <lfs_item>-PlantName IS INITIAL
            THEN <lfs_item>-Plant
            ELSE <lfs_item>-PlantName )
          INTO TABLE lt_plant.

      ENDLOOP.

      <lfs_result>-MaterialList = concat_lines_of( table = lt_material sep = `, ` ).
      <lfs_result>-PlantList    = concat_lines_of( table = lt_plant    sep = `, ` ).

    ENDLOOP.

  ENDMETHOD.

ENDCLASS.
