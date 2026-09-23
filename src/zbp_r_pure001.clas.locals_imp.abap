CLASS lhc_zr_pure001 DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    " สิทธิ์คุมที่ business catalog ของ service binding แล้ว ไม่ตรวจซ้ำที่นี่
    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      keys REQUEST requested_authorizations FOR zr_pure001 RESULT result.

    " ข้อมูลอ่านผ่าน query provider ไม่ผ่าน EML
    METHODS read FOR READ
       keys FOR READ zr_pure001 RESULT result.

    " ไม่มีการแก้ข้อมูล จึงไม่ต้อง lock จริง
    METHODS lock FOR LOCK
       keys FOR LOCK zr_pure001.

    " สร้าง PDF จากใบที่ผู้ใช้เลือก เลือกหลายใบจะได้ไฟล์เดียว
    METHODS printpoform FOR MODIFY
       keys FOR ACTION zr_pure001~printpoform RESULT result.

ENDCLASS.

CLASS lhc_zr_pure001 IMPLEMENTATION.

  METHOD get_instance_authorizations.
  ENDMETHOD.

  METHOD read.
  ENDMETHOD.

  METHOD lock.
  ENDMETHOD.

  METHOD printpoform.

    DATA(lt_purchase_order) = VALUE zcl_pure001_print=>tt_purchase_order( FOR ls_key IN keys
                                                                          ( ls_key-PurchaseOrder )
                                                                        ).

    " ลำดับในฟอร์มให้เรียงตามเลขที่ใบสั่งซื้อ ไม่ใช่ลำดับที่ผู้ใช้คลิกเลือก
    SORT lt_purchase_order BY table_line.

    DATA(lo_print) = NEW zcl_pure001_print( ).

    lo_print->render(
      EXPORTING it_purchase_order = lt_purchase_order
      IMPORTING ev_pdf            = DATA(lv_pdf)
                ev_message        = DATA(lv_message) ).

    IF lv_message IS NOT INITIAL.
      APPEND VALUE #( %tky = keys[ 1 ]-%tky
                      %msg = new_message_with_text(
                               severity = if_abap_behv_message=>severity-error
                               text     = lv_message )
                    ) TO reported-zr_pure001.
      RETURN.
    ENDIF.

    " Fiori รับไฟล์เป็น base64 ผ่าน result ของ action
    DATA(lv_content) = cl_web_http_utility=>encode_x_base64( lv_pdf ).

    TRY.
        DATA(lv_file_id) = cl_system_uuid=>create_uuid_x16_static( ).
      CATCH cx_uuid_error ##NO_HANDLER.
        " ไม่มี uuid ก็ยังส่งไฟล์ได้ FileId เป็นแค่ key ของ abstract entity
    ENDTRY.

    APPEND VALUE #( %tky   = keys[ 1 ]-%tky
                    %param = VALUE za_pure001_file(
                               FileId        = lv_file_id
                               FileName      = lo_print->get_file_name( lt_purchase_order )
                               FileExtension = 'pdf'
                               MimeType      = 'application/pdf'
                               FileContent   = lv_content ) ) TO result.

  ENDMETHOD.

ENDCLASS.

CLASS lsc_zr_pure001 DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.

    METHODS finalize REDEFINITION.

    METHODS check_before_save REDEFINITION.

    METHODS save REDEFINITION.

    METHODS cleanup REDEFINITION.

    METHODS cleanup_finalize REDEFINITION.

ENDCLASS.

CLASS lsc_zr_pure001 IMPLEMENTATION.

  METHOD finalize.
  ENDMETHOD.

  METHOD check_before_save.
  ENDMETHOD.

  METHOD save.
  ENDMETHOD.

  METHOD cleanup.
  ENDMETHOD.

  METHOD cleanup_finalize.
  ENDMETHOD.

ENDCLASS.
