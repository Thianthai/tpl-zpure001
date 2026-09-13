CLASS zcl_pure001_query DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES if_rap_query_provider .

  PROTECTED SECTION.
  PRIVATE SECTION.

    TYPES tt_result        TYPE STANDARD TABLE OF zr_pure001 WITH EMPTY KEY.
    TYPES ty_text_pattern  TYPE c LENGTH 80.

    CONSTANTS gc_entity_id TYPE string VALUE 'ZR_PURE001'.

    DATA:
      gv_search_pattern   TYPE string VALUE '%',
      gr_purchase_order   TYPE RANGE OF zr_pure001-PurchaseOrder,
      gr_po_type          TYPE RANGE OF zr_pure001-PurchaseOrderType,
      gr_supplier         TYPE RANGE OF zr_pure001-Supplier,
      gr_company_code     TYPE RANGE OF zr_pure001-CompanyCode,
      gr_purchasing_group TYPE RANGE OF zr_pure001-PurchasingGroup,
      gr_material         TYPE RANGE OF zr_pure001-Material,
      gr_item_text        TYPE RANGE OF ty_text_pattern,
      gr_plant            TYPE RANGE OF zr_pure001-Plant,
      gr_po_date          TYPE RANGE OF zr_pure001-PurchaseOrderDate,
      gr_creation_date    TYPE RANGE OF zr_pure001-CreationDate,
      gr_internal_ref     TYPE RANGE OF zr_pure001-InternalReference,
      gr_external_ref     TYPE RANGE OF zr_pure001-ExternalReference,
      gr_po_status        TYPE RANGE OF zr_pure001-PurchaseOrderStatus,
      gr_approval_status  TYPE RANGE OF zr_pure001-ApprovalStatus.

    "! แปลง $filter และ $search จาก request เป็น range / pattern
    METHODS prepare_filter
      IMPORTING io_request TYPE REF TO if_rap_query_request
      RAISING   cx_rap_query_provider.

    "! สร้าง pattern ค้น item text จาก filter Material (contains, ไม่สนตัวพิมพ์)
    METHODS prepare_item_text_patterns.

    "! นับจำนวนทั้งหมดบน DB โดยไม่ดึงแถว (สำหรับ $count)
    METHODS count_purchase_orders
      RETURNING VALUE(rv_count) TYPE int8.

    "! ดึงเฉพาะหน้าที่ขอ — sort และ paging push ลง DB ทั้งหมด
    METHODS select_purchase_orders
      IMPORTING io_request       TYPE REF TO if_rap_query_request
      RETURNING VALUE(rt_result) TYPE tt_result.

    "! แปลง sort element จาก request เป็น ORDER BY แบบ dynamic
    METHODS build_order_by
      IMPORTING io_request         TYPE REF TO if_rap_query_request
      RETURNING VALUE(rv_order_by) TYPE string.

    "! ประกอบ MaterialList / PlantList จาก item ของแต่ละ PO — เรียกหลัง paging เท่านั้น
    METHODS add_item_lists
      CHANGING ct_result TYPE tt_result.

ENDCLASS.


CLASS zcl_pure001_query IMPLEMENTATION.


  METHOD if_rap_query_provider~select.

    IF io_request->get_entity_id( ) <> gc_entity_id.
      RETURN.
    ENDIF.

    prepare_filter( io_request ).

    IF io_request->is_total_numb_of_rec_requested( ).
      io_response->set_total_number_of_records( count_purchase_orders( ) ).
    ENDIF.

    IF io_request->is_data_requested( ).
      DATA(lt_result) = select_purchase_orders( io_request ).
      add_item_lists( CHANGING ct_result = lt_result ).
      io_response->set_data( lt_result ).
    ENDIF.

  ENDMETHOD.


  METHOD prepare_filter.

    TRY.
        DATA(lt_filter) = io_request->get_filter( )->get_as_ranges( ).
      CATCH cx_rap_query_filter_no_range INTO DATA(lx_no_range).
        " filter ที่ Fiori ส่งมาแปลงเป็น range ไม่ได้ (เช่น expression ซับซ้อน)
        " ไม่กลืน error — โยนต่อให้ framework แสดงข้อความของต้นเหตุ
        RAISE EXCEPTION NEW zcx_pure001_query( previous = lx_no_range ).
    ENDTRY.

    LOOP AT lt_filter ASSIGNING FIELD-SYMBOL(<lfs_filter>).
      CASE <lfs_filter>-name.
        WHEN 'PURCHASEORDER'.       gr_purchase_order   = CORRESPONDING #( <lfs_filter>-range ).
        WHEN 'PURCHASEORDERTYPE'.   gr_po_type          = CORRESPONDING #( <lfs_filter>-range ).
        WHEN 'SUPPLIER'.            gr_supplier         = CORRESPONDING #( <lfs_filter>-range ).
        WHEN 'COMPANYCODE'.         gr_company_code     = CORRESPONDING #( <lfs_filter>-range ).
        WHEN 'PURCHASINGGROUP'.     gr_purchasing_group = CORRESPONDING #( <lfs_filter>-range ).
        WHEN 'MATERIAL'.            gr_material         = CORRESPONDING #( <lfs_filter>-range ).
        WHEN 'PLANT'.               gr_plant            = CORRESPONDING #( <lfs_filter>-range ).
        WHEN 'PURCHASEORDERDATE'.   gr_po_date          = CORRESPONDING #( <lfs_filter>-range ).
        WHEN 'CREATIONDATE'.        gr_creation_date    = CORRESPONDING #( <lfs_filter>-range ).
        WHEN 'INTERNALREFERENCE'.   gr_internal_ref     = CORRESPONDING #( <lfs_filter>-range ).
        WHEN 'EXTERNALREFERENCE'.   gr_external_ref     = CORRESPONDING #( <lfs_filter>-range ).
        WHEN 'PURCHASEORDERSTATUS'. gr_po_status        = CORRESPONDING #( <lfs_filter>-range ).
        WHEN 'APPROVALSTATUS'.      gr_approval_status  = CORRESPONDING #( <lfs_filter>-range ).
      ENDCASE.
    ENDLOOP.

    prepare_item_text_patterns( ).

    " $search จากช่อง Search → LIKE pattern (ตัวพิมพ์ใหญ่ เทียบกับ upper( ) ฝั่ง DB)
    DATA(lv_search) = io_request->get_search_expression( ).
    gv_search_pattern = COND #( WHEN lv_search IS INITIAL
                                THEN '%'
                                ELSE |%{ to_upper( lv_search ) }%| ).

  ENDMETHOD.


  METHOD prepare_item_text_patterns.

    " Material ค้นใน item text ด้วย (functional ยืนยัน 2026-09-12)
    " แปลงค่า include จาก filter เป็น pattern contains ตัวพิมพ์ใหญ่ ใช้คู่กับ upper( ) ใน EXISTS
    CLEAR gr_item_text.

    LOOP AT gr_material ASSIGNING FIELD-SYMBOL(<lfs_material>) WHERE sign = 'I'.
      CASE <lfs_material>-option.
        WHEN 'EQ'.
          APPEND VALUE #( sign   = 'I'
                          option = 'CP'
                          low    = |*{ to_upper( <lfs_material>-low ) }*| ) TO gr_item_text.
        WHEN 'CP'.
          APPEND VALUE #( sign   = 'I'
                          option = 'CP'
                          low    = to_upper( <lfs_material>-low ) ) TO gr_item_text.
        " BT / GE / LE ฯลฯ ไม่มีความหมายกับข้อความ → ไม่ค้นใน text
      ENDCASE.
    ENDLOOP.

    " ถ้ามี filter Material แต่ไม่มี pattern เลย (เช่นใช้แต่ exclude) ต้องกัน range ว่าง
    " เพราะ range ว่างใน OR = จริงเสมอ จะทำให้ filter Material หายไปทั้งก้อน
    IF gr_material IS NOT INITIAL AND gr_item_text IS INITIAL.
      gr_item_text = VALUE #( ( sign = 'E' option = 'CP' low = '*' ) ).  " = ไม่ match อะไรเลย
    ENDIF.

  ENDMETHOD.


  METHOD count_purchase_orders.

    " WHERE ต้องเหมือนกับใน select_purchase_orders ทุกบรรทัด — แก้ที่หนึ่งต้องแก้อีกที่ด้วย
    SELECT COUNT( * )
      FROM zi_pure001_header AS hdr
      WHERE hdr~PurchaseOrder       IN @gr_purchase_order
      AND   hdr~PurchaseOrderType   IN @gr_po_type
      AND   hdr~Supplier            IN @gr_supplier
      AND   hdr~CompanyCode         IN @gr_company_code
      AND   hdr~PurchasingGroup     IN @gr_purchasing_group
      AND   hdr~PurchaseOrderDate   IN @gr_po_date
      AND   hdr~CreationDate        IN @gr_creation_date
      AND   hdr~InternalReference   IN @gr_internal_ref
      AND   hdr~ExternalReference   IN @gr_external_ref
      AND   hdr~PurchaseOrderStatus IN @gr_po_status
      AND   hdr~ApprovalStatus      IN @gr_approval_status
      AND   (    upper( hdr~PurchaseOrder )     LIKE @gv_search_pattern
              OR upper( hdr~SupplierName )      LIKE @gv_search_pattern
              OR upper( hdr~InternalReference ) LIKE @gv_search_pattern
              OR upper( hdr~ExternalReference ) LIKE @gv_search_pattern )
      AND   EXISTS ( SELECT itm~PurchaseOrder
                       FROM I_PurchaseOrderItemAPI01 AS itm
                       WHERE itm~PurchaseOrder = hdr~PurchaseOrder
                       AND   (    itm~Material                       IN @gr_material
                               OR upper( itm~PurchaseOrderItemText ) IN @gr_item_text )
                       AND   itm~Plant                               IN @gr_plant )
      INTO @rv_count.

  ENDMETHOD.


  METHOD select_purchase_orders.

    DATA(lv_order_by) = build_order_by( io_request ).

    DATA lv_offset    TYPE int8.
    DATA lv_page_size TYPE int8.

    DATA(lo_paging) = io_request->get_paging( ).
    IF lo_paging IS BOUND.
      lv_offset    = lo_paging->get_offset( ).
      lv_page_size = lo_paging->get_page_size( ).
    ENDIF.

    " ไม่จำกัดจำนวน (-1) → UP TO 0 ROWS = ทุกแถว
    IF lv_page_size = if_rap_query_paging=>page_size_unlimited.
      lv_page_size = 0.
    ENDIF.

    " Material / Plant อยู่ระดับ item → EXISTS = "ใบนี้มี item ตรงเงื่อนไขอย่างน้อย 1 รายการ"
    " ไม่ join ตรง ๆ เพื่อไม่ให้แถวบาน · ถ้า range ว่าง ABAP SQL ตัดเงื่อนไขนั้นทิ้งให้เอง
    " text ของ Status join ตรงนี้ (ใน CDS join กับ field ที่ derive จาก case ไม่ได้)
    SELECT FROM zi_pure001_header AS hdr
           LEFT OUTER JOIN I_PurchasingDocumentStatusText AS sts
             ON  sts~PurchasingDocumentStatus = hdr~PurchaseOrderStatus
             AND sts~Language                 = @sy-langu
      FIELDS hdr~*,
             sts~PurchasingDocumentStatusName AS PurchaseOrderStatusName
      WHERE hdr~PurchaseOrder       IN @gr_purchase_order
      AND   hdr~PurchaseOrderType   IN @gr_po_type
      AND   hdr~Supplier            IN @gr_supplier
      AND   hdr~CompanyCode         IN @gr_company_code
      AND   hdr~PurchasingGroup     IN @gr_purchasing_group
      AND   hdr~PurchaseOrderDate   IN @gr_po_date
      AND   hdr~CreationDate        IN @gr_creation_date
      AND   hdr~InternalReference   IN @gr_internal_ref
      AND   hdr~ExternalReference   IN @gr_external_ref
      AND   hdr~PurchaseOrderStatus IN @gr_po_status
      AND   hdr~ApprovalStatus      IN @gr_approval_status
      AND   (    upper( hdr~PurchaseOrder )     LIKE @gv_search_pattern
              OR upper( hdr~SupplierName )      LIKE @gv_search_pattern
              OR upper( hdr~InternalReference ) LIKE @gv_search_pattern
              OR upper( hdr~ExternalReference ) LIKE @gv_search_pattern )
      AND   EXISTS ( SELECT itm~PurchaseOrder
                       FROM I_PurchaseOrderItemAPI01 AS itm
                       WHERE itm~PurchaseOrder = hdr~PurchaseOrder
                       AND   (    itm~Material                       IN @gr_material
                               OR upper( itm~PurchaseOrderItemText ) IN @gr_item_text )
                       AND   itm~Plant                               IN @gr_plant )
      ORDER BY (lv_order_by)
      INTO CORRESPONDING FIELDS OF TABLE @rt_result
      UP TO @lv_page_size ROWS
      OFFSET @lv_offset.

  ENDMETHOD.


  METHOD build_order_by.

    DATA(lt_sort) = io_request->get_sort_elements( ).

    LOOP AT lt_sort ASSIGNING FIELD-SYMBOL(<lfs_sort>).

      DATA(lv_element) = to_upper( <lfs_sort>-element_name ).

      " field ที่ไม่ได้อยู่ใน ZI_PURE001_HEADER ตรง ๆ (ประกอบใน ABAP / filter-only / join text)
      " sort บน DB ไม่ได้ → ข้าม
      IF lv_element = 'MATERIALLIST' OR lv_element = 'PLANTLIST'
      OR lv_element = 'MATERIAL'     OR lv_element = 'PLANT'
      OR lv_element = 'PURCHASEORDERSTATUSNAME'.
        CONTINUE.
      ENDIF.

      DATA(lv_direction) = COND string( WHEN <lfs_sort>-descending = abap_true
                                        THEN 'DESCENDING'
                                        ELSE 'ASCENDING' ).

      rv_order_by = COND #( WHEN rv_order_by IS INITIAL
                            THEN |{ lv_element } { lv_direction }|
                            ELSE |{ rv_order_by }, { lv_element } { lv_direction }| ).
    ENDLOOP.

    " OFFSET ต้องมี ORDER BY เสมอ → ถ้า UI ไม่ได้ sort ให้ใช้ค่า default
    IF rv_order_by IS INITIAL.
      rv_order_by = 'PURCHASEORDER DESCENDING'.
    ENDIF.

  ENDMETHOD.


  METHOD add_item_lists.

    IF ct_result IS INITIAL.
      RETURN.
    ENDIF.

    " ดึงเฉพาะ item ของ PO ในหน้านี้ (หลัง paging แล้ว) ไม่ใช่ทุกใบที่ตรง filter
    " รวม item ที่ลบด้วย — standard แสดงทุก item (ตัดเฉพาะยอดเงินใน ZI_PURE001_TOTAL)
    SELECT FROM I_PurchaseOrderItemAPI01 AS itm
           LEFT OUTER JOIN I_Plant AS plt
             ON plt~Plant = itm~Plant
      FIELDS itm~PurchaseOrder,
             itm~PurchaseOrderItem,
             itm~Material,
             itm~PurchaseOrderItemText,
             itm~Plant,
             plt~PlantName
      FOR ALL ENTRIES IN @ct_result
      WHERE itm~PurchaseOrder = @ct_result-PurchaseOrder
      INTO TABLE @DATA(lt_item).

    SORT lt_item BY PurchaseOrder PurchaseOrderItem.

    LOOP AT ct_result ASSIGNING FIELD-SYMBOL(<lfs_result>).

      DATA lt_material TYPE STANDARD TABLE OF string WITH EMPTY KEY.
      DATA lt_plant    TYPE SORTED TABLE OF string WITH UNIQUE KEY table_line.
      CLEAR: lt_material, lt_plant.

      LOOP AT lt_item ASSIGNING FIELD-SYMBOL(<lfs_item>)
           WHERE PurchaseOrder = <lfs_result>-PurchaseOrder.

        " "ชื่อ (รหัส)" — item ที่ไม่มีรหัส material (text item) แสดงชื่ออย่างเดียว
        " string template ตัดช่องว่างท้าย char ให้เอง (ห้ามใส่ ALPHA = OUT จะไม่ตัด)
        DATA(lv_material) = COND string(
          WHEN <lfs_item>-Material IS INITIAL
            THEN <lfs_item>-PurchaseOrderItemText
            ELSE |{ <lfs_item>-PurchaseOrderItemText } ({ <lfs_item>-Material })| ).

        " material เดียวกันหลาย item → แสดงครั้งเดียว ตามลำดับ item แรกที่เจอ
        IF NOT line_exists( lt_material[ table_line = lv_material ] ).
          APPEND lv_material TO lt_material.
        ENDIF.

        " plant ซ้ำกันหลาย item → แสดงครั้งเดียว (sorted unique ตัด duplicate ให้)
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
