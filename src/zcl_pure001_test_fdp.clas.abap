CLASS zcl_pure001_test_fdp DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun .
ENDCLASS.



CLASS ZCL_PURE001_TEST_FDP IMPLEMENTATION.


  METHOD if_oo_adt_classrun~main.

    TRY.
        DATA(lo_fdp)  = cl_fp_fdp_services=>get_instance( 'ZAPI_PURE001_FDP' ).
        DATA(lt_keys) = lo_fdp->get_keys( ).

        LOOP AT lt_keys ASSIGNING FIELD-SYMBOL(<ls_key>).
          out->write( |key: { <ls_key>-name }| ).
          IF <ls_key>-name = 'PURCHASEORDER'.
            <ls_key>-value = '0099680042'.      " PO ที่มีผู้อนุมัติจริง
          ENDIF.
        ENDLOOP.

        DATA(lv_xml) = lo_fdp->read_to_xml_v2( lt_keys ).
        DATA(lv_text) = cl_web_http_utility=>decode_utf8( lv_xml ).   " xstring → string

        out->write( |XML length: { xstrlen( lv_xml ) }| ).
        out->write( lv_text ).

      CATCH cx_root INTO DATA(lx_error).
        out->write( |ERROR: { lx_error->get_text( ) }| ).
    ENDTRY.

  ENDMETHOD.
ENDCLASS.
