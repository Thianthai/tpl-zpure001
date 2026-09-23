CLASS zcl_pure001_fdp DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES if_rap_query_provider .

  PROTECTED SECTION.
  PRIVATE SECTION.

    TYPES:
      tt_header TYPE STANDARD TABLE OF zr_pure001_fdp      WITH EMPTY KEY,
      tt_item   TYPE STANDARD TABLE OF zi_pure001_item_fdp WITH EMPTY KEY,
      tt_text   TYPE STANDARD TABLE OF zi_pure001_itxt_fdp WITH EMPTY KEY.

    CONSTANTS:
      BEGIN OF gc_entity,
        header TYPE string VALUE 'ZR_PURE001_FDP',
        item   TYPE string VALUE 'ZI_PURE001_ITEM_FDP',
        text   TYPE string VALUE 'ZI_PURE001_ITXT_FDP',
      END OF gc_entity,

      BEGIN OF gc_text_type,
        material_po_text TYPE c LENGTH 4 VALUE 'F03',
        item_text        TYPE c LENGTH 4 VALUE 'F01',
        delivery_text    TYPE c LENGTH 4 VALUE 'F04',
        header_text      TYPE c LENGTH 4 VALUE 'F01',
        header_note      TYPE c LENGTH 4 VALUE 'F02',
        shipping_instr   TYPE c LENGTH 4 VALUE 'F06',
      END OF gc_text_type.

    CONSTANTS gc_time_zone TYPE c LENGTH 6 VALUE 'UTC+7'.   " เวลาไทย

    CONSTANTS:
      gc_service_unit  TYPE c LENGTH 3 VALUE 'AU',
      gc_approval_note TYPE string
        VALUE 'เอกสารสั่งซื้อนี้ได้รับการอนุมัติจากผู้มีอำนาจ ผ่านระบบอิเล็กทรอนิกส์เรียบร้อยแล้ว'.

    DATA:
      go_data             TYPE REF TO zcl_pure001_data,
      gr_purchase_order   TYPE RANGE OF zr_pure001_fdp-PurchaseOrder,
      gt_header           TYPE zcl_pure001_data=>tt_header,
      gt_item             TYPE zcl_pure001_data=>tt_item,
      gt_schedule_line    TYPE zcl_pure001_data=>tt_schedule_line,
      gt_account_assgmt   TYPE zcl_pure001_data=>tt_account_assignment,
      gt_tax_rate         TYPE zcl_pure001_data=>tt_tax_rate,
      gt_header_text      TYPE zcl_pure001_data=>tt_text,
      gt_item_text        TYPE zcl_pure001_data=>tt_text,
      gt_approver         TYPE zcl_pure001_data=>tt_approver,
      gt_user_name        TYPE zcl_pure001_data=>tt_user_name.

    METHODS prepare_filter
      IMPORTING io_request TYPE REF TO if_rap_query_request
      RAISING   cx_rap_query_provider.

    "! เดิน filter tree เก็บค่า PurchaseOrder จากทุก node "PurchaseOrder = value"
    "! ใช้เมื่อ filter แปลงเป็น range ไม่ได้ (child ที่มี key หลาย field)
    METHODS collect_po_from_tree
      IMPORTING io_node TYPE REF TO if_rap_query_filter_tree_node.

    "! อ่านข้อมูลทุกชุดของ PO ที่ขอ ครั้งเดียว (ผ่าน ZCL_PURE001_DATA)
    METHODS load_data.

    METHODS build_headers
      RETURNING VALUE(rt_header) TYPE tt_header.

    METHODS build_items
      RETURNING VALUE(rt_item) TYPE tt_item.

    METHODS build_item_texts
      RETURNING VALUE(rt_text) TYPE tt_text.

    "! item ที่ไม่ลบของ PO เรียงตาม item
    METHODS get_active_items
      IMPORTING iv_purchase_order TYPE zr_pure001_fdp-PurchaseOrder
      RETURNING VALUE(rt_item)    TYPE zcl_pure001_data=>tt_item.

    METHODS get_tax_rate
      IMPORTING iv_tax_code    TYPE zi_pure001_item_fdp-TaxCode
      RETURNING VALUE(rv_rate) TYPE zi_pure001_item_fdp-TaxRate.

    METHODS get_header_text
      IMPORTING iv_purchase_order TYPE zr_pure001_fdp-PurchaseOrder
                iv_language       TYPE zr_pure001_fdp-Language
                iv_text_type      TYPE zcl_pure001_data=>ty_text-TextObjectType
      RETURNING VALUE(rv_text)    TYPE string.

    "! ต่อที่อยู่จากส่วนที่ไม่ว่าง คั่นด้วยช่องว่าง
    METHODS compose_address
      IMPORTING it_part           TYPE string_table
      RETURNING VALUE(rv_address) TYPE string.

    "! text ของ item เรียงตามฟอร์ม (F03 → F01 → F04) ภาษาของ PO เฉพาะที่มีข้อความ
    METHODS get_ordered_item_texts
      IMPORTING iv_purchase_order      TYPE clike
                iv_purchase_order_item TYPE clike
                iv_language            TYPE clike
      RETURNING VALUE(rt_text)         TYPE zcl_pure001_data=>tt_text.

    "! ช่อง "รายการ" ทั้งช่อง: description → texts → delivery → PR/Acc/Order → WBS (คั่น newline)
    METHODS compose_item_description
      IMPORTING is_item        TYPE zi_pure001_item_fdp
                iv_language    TYPE zr_pure001_fdp-Language
      RETURNING VALUE(rv_text) TYPE string.

ENDCLASS.



CLASS ZCL_PURE001_FDP IMPLEMENTATION.


  METHOD if_rap_query_provider~select.

    go_data = NEW #( ).
    prepare_filter( io_request ).
    load_data( ).

    CASE io_request->get_entity_id( ).

      WHEN gc_entity-header.
        DATA(lt_header) = build_headers( ).
        IF io_request->is_total_numb_of_rec_requested( ).
          io_response->set_total_number_of_records( lines( lt_header ) ).
        ENDIF.
        IF io_request->is_data_requested( ).
          io_response->set_data( lt_header ).
        ENDIF.

      WHEN gc_entity-item.
        DATA(lt_item) = build_items( ).
        IF io_request->is_total_numb_of_rec_requested( ).
          io_response->set_total_number_of_records( lines( lt_item ) ).
        ENDIF.
        IF io_request->is_data_requested( ).
          io_response->set_data( lt_item ).
        ENDIF.

      WHEN gc_entity-text.
        DATA(lt_text) = build_item_texts( ).
        IF io_request->is_total_numb_of_rec_requested( ).
          io_response->set_total_number_of_records( lines( lt_text ) ).
        ENDIF.
        IF io_request->is_data_requested( ).
          io_response->set_data( lt_text ).
        ENDIF.

    ENDCASE.

  ENDMETHOD.


  METHOD prepare_filter.

*    TRY.
*        DATA(lt_filter) = io_request->get_filter( )->get_as_ranges( ).
*      CATCH cx_rap_query_filter_no_range INTO DATA(lx_no_range).
*        " ชั่วคราว (diagnose): บอกว่า entity ไหน / filter หน้าตาอย่างไร ที่แปลงเป็น range ไม่ได้
*        DATA lv_filter_sql TYPE string.
*        TRY.
*            lv_filter_sql = io_request->get_filter( )->get_as_sql_string( ).
*          CATCH cx_root.
*            lv_filter_sql = '(no sql string)'.
*        ENDTRY.
*        RAISE EXCEPTION NEW zcx_pure001_query(
*          previous = lx_no_range
*          text     = |{ io_request->get_entity_id( ) }: { lv_filter_sql }| ).
*    ENDTRY.
*
*    " FDP ส่ง key ของ root มาเป็น filter ชื่อ PURCHASEORDER ให้ทุก entity (พิมพ์หลายใบ = หลายค่า)
*    CLEAR gr_purchase_order.
*    ASSIGN lt_filter[ name = 'PURCHASEORDER' ] TO FIELD-SYMBOL(<lfs_filter>).
*    IF sy-subrc = 0.
*      gr_purchase_order = CORRESPONDING #( <lfs_filter>-range ).
*    ENDIF.
*
*    IF gr_purchase_order IS INITIAL.
*      RAISE EXCEPTION NEW zcx_pure001_query( text = 'Purchase order key is required for form data' ).
*    ENDIF.

    CLEAR gr_purchase_order.

    TRY.
        " root / item: framework ส่ง PurchaseOrder = x (หรือ OR หลายค่า) → range ได้
        DATA(lt_filter) = io_request->get_filter( )->get_as_ranges( ).
        ASSIGN lt_filter[ name = 'PURCHASEORDER' ] TO FIELD-SYMBOL(<lfs_filter>).
        IF sy-subrc = 0.
          gr_purchase_order = CORRESPONDING #( <lfs_filter>-range ).
        ENDIF.

      CATCH cx_rap_query_filter_no_range.
        " item text (key PO+Item): framework ส่ง (PO = x AND Item = y) OR (PO = x AND Item = z) …
        " range แยกต่อ field ผูกคู่กันไม่ได้ → เดิน tree เก็บเฉพาะค่า PO (ฟอร์มต้องการแค่รายการ PO
        " และเราส่ง text ของ item ที่ไม่ลบทั้งหมดกลับไป ซึ่งตรงกับชุด key ที่ framework ขอ)
        DATA(lo_tree) = io_request->get_filter( )->get_as_tree( ).
        IF lo_tree IS BOUND.
          collect_po_from_tree( lo_tree->get_root_node( ) ).
        ENDIF.
        SORT gr_purchase_order BY low.
        DELETE ADJACENT DUPLICATES FROM gr_purchase_order COMPARING low.
    ENDTRY.

    IF gr_purchase_order IS INITIAL.
      RAISE EXCEPTION NEW zcx_pure001_query( text = 'Purchase order key is required for form data' ).
    ENDIF.

  ENDMETHOD.


  METHOD collect_po_from_tree.

    DATA lo_child      TYPE REF TO if_rap_query_filter_tree_node.
    DATA lo_identifier TYPE REF TO data.
    DATA lo_value      TYPE REF TO data.
    DATA lv_identifier TYPE string.

    CASE io_node->get_type( ).

      WHEN if_rap_query_filter_tree_types=>node_types-identifier
        OR if_rap_query_filter_tree_types=>node_types-value.
        RETURN.                                          " leaf — ประเมินที่ node equals ด้านบนแล้ว

      WHEN if_rap_query_filter_tree_types=>node_types-equals.
        " ลูก 2 ตัว ลำดับไม่การันตี → แยก identifier / value เอง
        LOOP AT io_node->get_children( ) INTO lo_child.
          CASE lo_child->get_type( ).
            WHEN if_rap_query_filter_tree_types=>node_types-identifier.
              lo_identifier = lo_child->get_value( ).
              ASSIGN lo_identifier->* TO FIELD-SYMBOL(<lfs_identifier>).
              lv_identifier = to_upper( <lfs_identifier> ).    " เอกสารบอกว่า case ไม่การันตี
            WHEN if_rap_query_filter_tree_types=>node_types-value.
              lo_value = lo_child->get_value( ).
          ENDCASE.
        ENDLOOP.

        IF lv_identifier = 'PURCHASEORDER' AND lo_value IS BOUND.
          ASSIGN lo_value->* TO FIELD-SYMBOL(<lfs_value>).
          APPEND VALUE #( sign = 'I' option = 'EQ' low = <lfs_value> ) TO gr_purchase_order.
        ENDIF.

      WHEN OTHERS.
        " logical_and / logical_or / … → ลงไปดูลูกทุกตัว (PurchaseOrderItem ข้ามไปเอง)
        LOOP AT io_node->get_children( ) INTO lo_child.
          collect_po_from_tree( lo_child ).
        ENDLOOP.

    ENDCASE.

  ENDMETHOD.


  METHOD load_data.

    gt_header = go_data->read_headers( VALUE #( purchase_order = gr_purchase_order ) ).
    IF gt_header IS INITIAL.
      RETURN.
    ENDIF.

    DATA(lt_po_key) = VALUE zcl_pure001_data=>tt_po_key( FOR ls_h IN gt_header ( PurchaseOrder = ls_h-PurchaseOrder ) ).

    gt_item           = go_data->read_items( lt_po_key ).
    gt_schedule_line  = go_data->read_schedule_lines( lt_po_key ).
    gt_account_assgmt = go_data->read_account_assignments( lt_po_key ).
    gt_header_text    = go_data->read_header_texts( lt_po_key ).
    gt_item_text      = go_data->read_item_texts( lt_po_key ).
    gt_approver       = go_data->read_approvers( gt_header ).
    gt_tax_rate       = go_data->read_tax_rates( gt_header[ 1 ]-CompanyCountry ).
    gt_user_name      = go_data->read_user_names( VALUE #( FOR ls_c IN gt_header ( UserID = ls_c-CreatedByUser ) ) ).

  ENDMETHOD.


  METHOD build_headers.

    LOOP AT gt_header ASSIGNING FIELD-SYMBOL(<lfs_src>).

      DATA(lt_active_item) = get_active_items( <lfs_src>-PurchaseOrder ).
      DATA(ls_first_item)  = VALUE #( lt_active_item[ 1 ] OPTIONAL ).

      APPEND INITIAL LINE TO rt_header ASSIGNING FIELD-SYMBOL(<lfs_out>).

      "--- Company ---------------------------------------------------------------
      <lfs_out>-PurchaseOrder    = <lfs_src>-PurchaseOrder.
      <lfs_out>-CompanyCode      = <lfs_src>-CompanyCode.
      <lfs_out>-CompanyName      = <lfs_src>-CompanyCodeName.
      <lfs_out>-CompanyTaxNumber = <lfs_src>-CompanyTaxNumber.
      " CompanyAddress* / Phone / Website / Logo = ⏸ config / graphics (ว่าง)

      "--- PO --------------------------------------------------------------------
      <lfs_out>-PurchaseOrderType     = <lfs_src>-PurchaseOrderType.
      <lfs_out>-PurchaseOrderTypeName = <lfs_src>-PurchaseOrderTypeName.
      <lfs_out>-Language              = <lfs_src>-Language.
      <lfs_out>-PurchaseOrderDate     = <lfs_src>-PurchaseOrderDate.
      <lfs_out>-PurchaseOrderDateText = zcl_pure001_util=>to_thai_date( <lfs_src>-PurchaseOrderDate ).
      <lfs_out>-ExternalReference     = <lfs_src>-ExternalReference.
      <lfs_out>-InternalReference     = <lfs_src>-InternalReference.
      <lfs_out>-PaymentTerms          = <lfs_src>-PaymentTerms.
      <lfs_out>-PaymentTermsText      = <lfs_src>-PaymentTermsText.
      <lfs_out>-ValidityStartDate     = <lfs_src>-ValidityStartDate.
      <lfs_out>-ValidityStartDateText = zcl_pure001_util=>to_thai_date( <lfs_src>-ValidityStartDate ).
      <lfs_out>-ValidityEndDate       = <lfs_src>-ValidityEndDate.
      <lfs_out>-ValidityEndDateText   = zcl_pure001_util=>to_thai_date( <lfs_src>-ValidityEndDate ).

      " วันที่ส่งสินค้า = schedule line ของ item แรก (spec ZPURF002 ข้อ 2)
      <lfs_out>-DeliveryDate = VALUE #( gt_schedule_line[ PurchaseOrder     = ls_first_item-PurchaseOrder
                                                          PurchaseOrderItem = ls_first_item-PurchaseOrderItem ]-ScheduleLineDeliveryDate OPTIONAL ).
      <lfs_out>-DeliveryDateText = zcl_pure001_util=>to_thai_date( <lfs_out>-DeliveryDate ).

      <lfs_out>-ShipVia    = get_header_text( iv_purchase_order = <lfs_src>-PurchaseOrder iv_language = <lfs_src>-Language iv_text_type = gc_text_type-shipping_instr ).
      <lfs_out>-HeaderText = get_header_text( iv_purchase_order = <lfs_src>-PurchaseOrder iv_language = <lfs_src>-Language iv_text_type = gc_text_type-header_text ).
      <lfs_out>-HeaderNote = get_header_text( iv_purchase_order = <lfs_src>-PurchaseOrder iv_language = <lfs_src>-Language iv_text_type = gc_text_type-header_note ).
      " PerfGuarantee* / InsurancePolicyFlag / WarrantyGuarantee* = ⏸ custom field YY1_* (ว่าง)

      "--- Supplier --------------------------------------------------------------
      <lfs_out>-Supplier           = <lfs_src>-Supplier.
      <lfs_out>-SupplierName       = <lfs_src>-SupplierName.
      <lfs_out>-SupplierCodeName   = condense( |{ <lfs_src>-Supplier ALPHA = OUT } { <lfs_src>-SupplierName }| ).
      <lfs_out>-SupplierTaxNumber  = <lfs_src>-SupplierTaxNumber.
      <lfs_out>-SupplierStreet     = <lfs_src>-SupplierStreet.
      <lfs_out>-SupplierDistrict   = <lfs_src>-SupplierDistrict.
      <lfs_out>-SupplierCity       = <lfs_src>-SupplierCity.
      <lfs_out>-SupplierPostalCode = <lfs_src>-SupplierPostalCode.
      <lfs_out>-SupplierAddress    = compose_address( VALUE #( ( CONV #( <lfs_src>-SupplierStreet ) )
                                                                ( CONV #( <lfs_src>-SupplierDistrict ) )
                                                                ( CONV #( <lfs_src>-SupplierCity ) )
                                                                ( CONV #( <lfs_src>-SupplierPostalCode ) ) ) ).
      <lfs_out>-SupplierContactName = <lfs_src>-SupplierRespSalesPersonName.
      <lfs_out>-SupplierPhone       = COND #( WHEN <lfs_src>-SupplierPhoneNumber IS NOT INITIAL
                                              THEN <lfs_src>-SupplierPhoneNumber
                                              ELSE <lfs_src>-SupplierMasterPhone ).
      " SupplierEmail = ⏸ custom field

      "--- Ship-to ---------------------------------------------------------------
      <lfs_out>-ShipToPlant     = ls_first_item-Plant.
      <lfs_out>-ShipToPlantName = ls_first_item-PlantName.
      <lfs_out>-ShipToName      = <lfs_src>-CompanyCodeName.            " ผู้ใช้ตัดสินใจ: ชื่อบริษัท
      ASSIGN gt_account_assgmt[ PurchaseOrder     = ls_first_item-PurchaseOrder
                                PurchaseOrderItem = ls_first_item-PurchaseOrderItem ] TO FIELD-SYMBOL(<lfs_first_aa>).
      IF sy-subrc = 0.
        <lfs_out>-GoodsRecipientName = <lfs_first_aa>-GoodsRecipientName.
        <lfs_out>-UnloadingPointName = <lfs_first_aa>-UnloadingPointName.
      ENDIF.
      " ShipToAddressLine* / GoodsRecipientPhone = ⏸ config

      "--- Totals — คำนวณจาก item ที่ส่งออกจริง (ไม่ลบ) ------------------------------
      <lfs_out>-DocumentCurrency = <lfs_src>-DocumentCurrency.
      LOOP AT lt_active_item ASSIGNING FIELD-SYMBOL(<lfs_item>).
        <lfs_out>-TotalAmount += <lfs_item>-NetAmount.
        <lfs_out>-TaxAmount   += round( val = <lfs_item>-NetAmount * get_tax_rate( <lfs_item>-TaxCode ) / 100
                                        dec = 2 ).
      ENDLOOP.
      <lfs_out>-DiscountAmount  = 0.                                      " ⏸ ไม่มี source
      <lfs_out>-AmountBeforeTax = <lfs_out>-TotalAmount - <lfs_out>-DiscountAmount.
      <lfs_out>-NetAmount       = <lfs_out>-AmountBeforeTax + <lfs_out>-TaxAmount.
      <lfs_out>-AmountInWords   = zcl_pure001_util=>amount_in_words( iv_amount   = <lfs_out>-NetAmount
                                                                     iv_currency = <lfs_out>-DocumentCurrency ).

      "--- Signature -------------------------------------------------------------
      <lfs_out>-PreparedByUser   = <lfs_src>-CreatedByUser.
      <lfs_out>-PreparedByName   = VALUE #( gt_user_name[ UserID = <lfs_src>-CreatedByUser ]-PersonFullName OPTIONAL ).
      <lfs_out>-PreparedDate     = <lfs_src>-CreationDate.
      <lfs_out>-PreparedDateText = zcl_pure001_util=>to_thai_date( <lfs_src>-CreationDate ).

      ASSIGN gt_approver[ PurchaseOrder = <lfs_src>-PurchaseOrder ] TO FIELD-SYMBOL(<lfs_approver>).
      IF sy-subrc = 0.
        <lfs_out>-ApprovedByUser = <lfs_approver>-ApprovedByUser.
        <lfs_out>-ApprovedByName = <lfs_approver>-ApprovedByName.

        " UTC timestamp (TIMESTAMPL) → วันที่ในเวลาไทย
        CONVERT TIME STAMP <lfs_approver>-ApprovedDateTime
          TIME ZONE gc_time_zone
          INTO DATE <lfs_out>-ApprovedDate.

        <lfs_out>-ApprovedDateText = zcl_pure001_util=>to_thai_date( <lfs_out>-ApprovedDate ).
      ENDIF.
      <lfs_out>-IsApprovedAutomatically = xsdbool( <lfs_src>-ApprovalStatus = zcl_pure001_data=>gc_approval-automatic ).
      <lfs_out>-ApprovalNoteText = COND #( WHEN <lfs_src>-ApprovalStatus = zcl_pure001_data=>gc_approval-approved
                                             OR <lfs_src>-ApprovalStatus = zcl_pure001_data=>gc_approval-automatic
                                           THEN gc_approval_note ).
      " ApprovedByPosition / ApprovedBySignature = ⏸ config / graphics

    ENDLOOP.

  ENDMETHOD.


  METHOD build_items.

    LOOP AT gt_header ASSIGNING FIELD-SYMBOL(<lfs_header>).

      DATA(lv_item_number) = 0.

      LOOP AT get_active_items( <lfs_header>-PurchaseOrder ) ASSIGNING FIELD-SYMBOL(<lfs_src>).

        lv_item_number += 1.
        APPEND INITIAL LINE TO rt_item ASSIGNING FIELD-SYMBOL(<lfs_out>).

        <lfs_out>-PurchaseOrder       = <lfs_src>-PurchaseOrder.
        <lfs_out>-PurchaseOrderItem   = <lfs_src>-PurchaseOrderItem.
        <lfs_out>-ItemNumber          = lv_item_number.
        <lfs_out>-Material            = <lfs_src>-Material.
        <lfs_out>-MaterialDescription = <lfs_src>-MaterialDescription.
        " บรรทัดแรกของช่องรายการ: "1000001 MA Core Switch Year 2024" (text item = description อย่างเดียว)
        <lfs_out>-ItemDescription     = COND #( WHEN <lfs_src>-Material IS INITIAL
                                                THEN <lfs_src>-MaterialDescription
                                                ELSE |{ <lfs_src>-Material } { <lfs_src>-MaterialDescription }| ).
        <lfs_out>-Quantity            = <lfs_src>-Quantity.
        <lfs_out>-QuantityText        = zcl_pure001_util=>format_quantity( <lfs_src>-Quantity ).
        <lfs_out>-Unit                = <lfs_src>-Unit.
        <lfs_out>-DocumentCurrency    = <lfs_src>-DocumentCurrency.
        <lfs_out>-NetPriceAmount      = <lfs_src>-NetPriceAmount.
        <lfs_out>-NetPriceQuantity    = <lfs_src>-NetPriceQuantity.
        <lfs_out>-ItemAmount          = <lfs_src>-NetAmount.
        <lfs_out>-TaxCode             = <lfs_src>-TaxCode.
        <lfs_out>-TaxRate             = get_tax_rate( <lfs_src>-TaxCode ).
        <lfs_out>-TaxAmount           = round( val = <lfs_src>-NetAmount * <lfs_out>-TaxRate / 100 dec = 2 ).
        <lfs_out>-Plant               = <lfs_src>-Plant.

        "--- schedule line: วันส่ง / PR / performance period ------------------------
        ASSIGN gt_schedule_line[ PurchaseOrder     = <lfs_src>-PurchaseOrder
                                 PurchaseOrderItem = <lfs_src>-PurchaseOrderItem ] TO FIELD-SYMBOL(<lfs_schedule>).
        IF sy-subrc = 0.
          <lfs_out>-DeliveryDate               = <lfs_schedule>-ScheduleLineDeliveryDate.
          <lfs_out>-PerformancePeriodStartDate = <lfs_schedule>-PerformancePeriodStartDate.
          <lfs_out>-PerformancePeriodEndDate   = <lfs_schedule>-PerformancePeriodEndDate.
          <lfs_out>-PurchaseRequisition        = <lfs_schedule>-PurchaseRequisition.
        ENDIF.
        IF <lfs_out>-PurchaseRequisition IS INITIAL.
          <lfs_out>-PurchaseRequisition = <lfs_src>-PurchaseRequisition.
        ENDIF.
        " ฟอร์มใช้ dd/mm/yyyy ค.ศ. ระดับ item (ต่างจาก header) — ตามตัวอย่างฟอร์ม
        IF <lfs_out>-DeliveryDate IS NOT INITIAL.
          <lfs_out>-DeliveryDateText = |Delivery Time : { zcl_pure001_util=>format_date_dmy( <lfs_out>-DeliveryDate ) }|.
        ENDIF.

        "--- account assignment --------------------------------------------------
        ASSIGN gt_account_assgmt[ PurchaseOrder     = <lfs_src>-PurchaseOrder
                                  PurchaseOrderItem = <lfs_src>-PurchaseOrderItem ] TO FIELD-SYMBOL(<lfs_aa>).
        IF sy-subrc = 0.
          <lfs_out>-GLAccount  = <lfs_aa>-GLAccount.
          <lfs_out>-CostCenter = <lfs_aa>-CostCenter.
          <lfs_out>-OrderID    = <lfs_aa>-OrderID.
          <lfs_out>-WBSElement = <lfs_aa>-WBSElement.
        ENDIF.

        " "PR No.: 168999  Acc.Code: 820000  Order No.: 1600000001" — ข้ามส่วนที่ว่าง (ตัด 0 นำหน้า + blank ท้ายจาก ALPHA)
        DATA lt_part TYPE string_table.
        CLEAR lt_part.
        IF <lfs_out>-PurchaseRequisition IS NOT INITIAL.
          APPEND |PR No.: { condense( |{ <lfs_out>-PurchaseRequisition ALPHA = OUT }| ) }| TO lt_part.
        ENDIF.
        IF <lfs_out>-GLAccount IS NOT INITIAL.
          APPEND |Acc.Code: { condense( |{ <lfs_out>-GLAccount ALPHA = OUT }| ) }| TO lt_part.
        ENDIF.
        IF <lfs_out>-OrderID IS NOT INITIAL.
          APPEND |Order No.: { condense( |{ <lfs_out>-OrderID ALPHA = OUT }| ) }| TO lt_part.
        ENDIF.
        <lfs_out>-AccountAssignmentText = concat_lines_of( table = lt_part sep = `  ` ).

        " item บริการ (quantity 0 / unit ว่าง) → แสดง 1 AU ตามฟอร์มเดิม (Quantity ตัวเลขคง 0 ตามจริง)
        IF <lfs_out>-Quantity IS INITIAL.
          <lfs_out>-QuantityText = '1'.
          <lfs_out>-Unit         = gc_service_unit.
        ENDIF.

        " ฟอร์มพิมพ์รหัสหน่วยภายใน ไม่ใช่รหัส ISO ที่ serializer แปลงให้ Unit
        <lfs_out>-UnitText = <lfs_out>-Unit.

        <lfs_out>-ItemDescriptionText = compose_item_description( is_item     = <lfs_out>
                                                                  iv_language = <lfs_header>-Language ).

      ENDLOOP.
    ENDLOOP.

  ENDMETHOD.


  METHOD build_item_texts.

    LOOP AT gt_header ASSIGNING FIELD-SYMBOL(<lfs_header>).
      LOOP AT get_active_items( <lfs_header>-PurchaseOrder ) ASSIGNING FIELD-SYMBOL(<lfs_item>).

        DATA(lt_text) = get_ordered_item_texts( iv_purchase_order      = <lfs_item>-PurchaseOrder
                                                iv_purchase_order_item = <lfs_item>-PurchaseOrderItem
                                                iv_language            = <lfs_header>-Language ).

        LOOP AT lt_text ASSIGNING FIELD-SYMBOL(<lfs_text>).
          APPEND VALUE #( PurchaseOrder     = <lfs_item>-PurchaseOrder
                          PurchaseOrderItem = <lfs_item>-PurchaseOrderItem
                          TextSequence      = sy-tabix
                          TextObjectType    = <lfs_text>-TextObjectType
                          TextTypeName      = SWITCH #( <lfs_text>-TextObjectType
                                                WHEN gc_text_type-material_po_text THEN 'Material PO Text'
                                                WHEN gc_text_type-item_text        THEN 'Item Text'
                                                WHEN gc_text_type-delivery_text    THEN 'Delivery Text' )
                          Text              = <lfs_text>-PlainLongText ) TO rt_text.
        ENDLOOP.

      ENDLOOP.
    ENDLOOP.

  ENDMETHOD.


  METHOD get_ordered_item_texts.

    " ลำดับตามฟอร์ม: Material PO Text → Item Text → Delivery Text · ภาษาของ PO · เฉพาะที่มีข้อความ
    DATA(lt_type_order) = VALUE string_table( ( |{ gc_text_type-material_po_text }| )
                                              ( |{ gc_text_type-item_text }| )
                                              ( |{ gc_text_type-delivery_text }| ) ).

    LOOP AT lt_type_order INTO DATA(lv_type).
      ASSIGN gt_item_text[ PurchaseOrder     = iv_purchase_order
                           PurchaseOrderItem = iv_purchase_order_item
                           TextObjectType    = lv_type
                           Language          = iv_language ] TO FIELD-SYMBOL(<lfs_text>).
      IF sy-subrc = 0 AND <lfs_text>-PlainLongText IS NOT INITIAL.
        APPEND <lfs_text> TO rt_text.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.


  METHOD compose_item_description.

    DATA lt_line TYPE string_table.

    APPEND is_item-ItemDescription TO lt_line.                       " บรรทัด 1: "C01-216-0 desc" / desc อย่างเดียว

    DATA(lt_text) = get_ordered_item_texts( iv_purchase_order      = is_item-PurchaseOrder
                                            iv_purchase_order_item = is_item-PurchaseOrderItem
                                            iv_language            = iv_language ).
    LOOP AT lt_text ASSIGNING FIELD-SYMBOL(<lfs_text>).
      APPEND <lfs_text>-PlainLongText TO lt_line.
    ENDLOOP.

    IF is_item-DeliveryDateText IS NOT INITIAL.
      APPEND is_item-DeliveryDateText TO lt_line.                    " Delivery Time : dd/mm/yyyy
    ENDIF.
    IF is_item-AccountAssignmentText IS NOT INITIAL.
      APPEND is_item-AccountAssignmentText TO lt_line.               " PR No.: …  Acc.Code: …  Order No.: …
    ENDIF.
    IF is_item-WBSElement IS NOT INITIAL.
      APPEND |WBS: { is_item-WBSElement }| TO lt_line.
    ENDIF.

    rv_text = concat_lines_of( table = lt_line sep = cl_abap_char_utilities=>newline ).

  ENDMETHOD.


  METHOD get_active_items.

    rt_item = VALUE #( FOR ls_item IN gt_item
                       WHERE ( PurchaseOrder                  = iv_purchase_order
                           AND PurchasingDocumentDeletionCode <> 'L' )
                       ( ls_item ) ).
    SORT rt_item BY PurchaseOrderItem.

  ENDMETHOD.


  METHOD get_tax_rate.
    rv_rate = VALUE #( gt_tax_rate[ TaxCode = iv_tax_code ]-TaxRate OPTIONAL ).
  ENDMETHOD.


  METHOD get_header_text.
    rv_text = VALUE #( gt_header_text[ PurchaseOrder  = iv_purchase_order
                                       TextObjectType = iv_text_type
                                       Language       = iv_language ]-PlainLongText OPTIONAL ).
  ENDMETHOD.


  METHOD compose_address.
    DATA lt_filled TYPE string_table.
    LOOP AT it_part INTO DATA(lv_part).
      IF lv_part IS NOT INITIAL.
        APPEND lv_part TO lt_filled.
      ENDIF.
    ENDLOOP.
    rv_address = concat_lines_of( table = lt_filled sep = ` ` ).
  ENDMETHOD.
ENDCLASS.
