CLASS zcx_pure001_query DEFINITION
  PUBLIC
  INHERITING FROM cx_rap_query_provider
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    METHODS constructor
      IMPORTING
        textid   LIKE if_t100_message=>t100key OPTIONAL
        previous LIKE previous OPTIONAL
        text     TYPE string OPTIONAL.

    METHODS get_text REDEFINITION.

  PROTECTED SECTION.
  PRIVATE SECTION.
    DATA gv_text TYPE string.
ENDCLASS.



CLASS ZCX_PURE001_QUERY IMPLEMENTATION.


  METHOD constructor ##ADT_SUPPRESS_GENERATION.
    super->constructor( previous = previous ).
    CLEAR me->textid.
    IF textid IS INITIAL.
      if_t100_message~t100key = if_t100_message=>default_textid.
    ELSE.
      if_t100_message~t100key = textid.
    ENDIF.
    gv_text = text.
  ENDMETHOD.


  METHOD get_text.
    " ข้อความ: ที่ส่งมาตรง ๆ > ของ exception ต้นเหตุ > ค่า default ของ framework
    result = COND #( WHEN gv_text IS NOT INITIAL     THEN gv_text
                     WHEN previous IS BOUND          THEN previous->get_text( )
                     ELSE super->get_text( ) ).
  ENDMETHOD.
ENDCLASS.
