CLASS zcl_pure001_util DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    CLASS-METHODS class_constructor.

    "! วันที่ไทย พ.ศ. + ชื่อเดือนไทย เช่น 21 พฤศจิกายน 2568 · วันที่ว่าง → ''
    CLASS-METHODS to_thai_date
      IMPORTING iv_date        TYPE d
      RETURNING VALUE(rv_text) TYPE string.

    "! dd/mm/yyyy ค.ศ. เช่น 26/06/2025 · วันที่ว่าง → ''
    CLASS-METHODS format_date_dmy
      IMPORTING iv_date        TYPE d
      RETURNING VALUE(rv_text) TYPE string.

    "! จำนวนเงินเป็นตัวอักษร — THB ภาษาไทย (…บาทถ้วน / …บาท…สตางค์) · สกุลอื่นภาษาอังกฤษ
    CLASS-METHODS amount_in_words
      IMPORTING iv_amount      TYPE numeric
                iv_currency    TYPE waers
      RETURNING VALUE(rv_text) TYPE string.

    "! จำนวนแบบตัดทศนิยมท้ายที่เป็น 0 — 12.000 → 12 · 1.500 → 1.5
    CLASS-METHODS format_quantity
      IMPORTING iv_quantity    TYPE numeric
      RETURNING VALUE(rv_text) TYPE string.

  PROTECTED SECTION.
  PRIVATE SECTION.

    TYPES ty_amount TYPE p LENGTH 12 DECIMALS 2.

    CONSTANTS:
      BEGIN OF gc_thai,
        digits TYPE string VALUE 'ศูนย์,หนึ่ง,สอง,สาม,สี่,ห้า,หก,เจ็ด,แปด,เก้า',
        units  TYPE string VALUE ',สิบ,ร้อย,พัน,หมื่น,แสน',
        months TYPE string VALUE 'มกราคม,กุมภาพันธ์,มีนาคม,เมษายน,พฤษภาคม,มิถุนายน,กรกฎาคม,สิงหาคม,กันยายน,ตุลาคม,พฤศจิกายน,ธันวาคม',
      END OF gc_thai,
      BEGIN OF gc_en,
        ones TYPE string VALUE 'Zero,One,Two,Three,Four,Five,Six,Seven,Eight,Nine,Ten,Eleven,Twelve,Thirteen,Fourteen,Fifteen,Sixteen,Seventeen,Eighteen,Nineteen',
        tens TYPE string VALUE ',,Twenty,Thirty,Forty,Fifty,Sixty,Seventy,Eighty,Ninety',
      END OF gc_en.

    CLASS-DATA:
      gt_thai_digits TYPE STANDARD TABLE OF string WITH EMPTY KEY,
      gt_thai_units  TYPE STANDARD TABLE OF string WITH EMPTY KEY,
      gt_thai_months TYPE STANDARD TABLE OF string WITH EMPTY KEY,
      gt_en_ones     TYPE STANDARD TABLE OF string WITH EMPTY KEY,
      gt_en_tens     TYPE STANDARD TABLE OF string WITH EMPTY KEY.

    "! อ่านเลขจำนวนเต็มเป็นไทย (รองรับถึงหลักล้านล้าน ด้วย recursion ทีละล้าน)
    CLASS-METHODS number_to_words_th
      IMPORTING iv_number      TYPE int8
                iv_has_higher  TYPE abap_bool DEFAULT abap_false
      RETURNING VALUE(rv_text) TYPE string.

    "! อ่านเลขจำนวนเต็มเป็นอังกฤษ
    CLASS-METHODS number_to_words_en
      IMPORTING iv_number      TYPE int8
      RETURNING VALUE(rv_text) TYPE string.

ENDCLASS.



CLASS ZCL_PURE001_UTIL IMPLEMENTATION.


  METHOD class_constructor.
    SPLIT gc_thai-digits AT ',' INTO TABLE gt_thai_digits.
    SPLIT gc_thai-units  AT ',' INTO TABLE gt_thai_units.
    SPLIT gc_thai-months AT ',' INTO TABLE gt_thai_months.
    SPLIT gc_en-ones     AT ',' INTO TABLE gt_en_ones.
    SPLIT gc_en-tens     AT ',' INTO TABLE gt_en_tens.
  ENDMETHOD.


  METHOD to_thai_date.

    IF iv_date IS INITIAL.
      RETURN.
    ENDIF.

    DATA(lv_day)   = CONV i( iv_date+6(2) ).
    DATA(lv_month) = CONV i( iv_date+4(2) ).
    DATA(lv_year)  = CONV i( iv_date(4) ) + 543.

    rv_text = |{ lv_day } { gt_thai_months[ lv_month ] } { lv_year }|.

  ENDMETHOD.


  METHOD format_date_dmy.

    IF iv_date IS INITIAL.
      RETURN.
    ENDIF.

    rv_text = |{ iv_date+6(2) }/{ iv_date+4(2) }/{ iv_date(4) }|.

  ENDMETHOD.


  METHOD format_quantity.

    " แปลงผ่าน decfloat34 แล้วให้ string template ตัด 0 ท้ายให้ (12.000 → 12)
    DATA(lv_quantity) = CONV decfloat34( iv_quantity ).
    rv_text = |{ lv_quantity NUMBER = USER }|.

    " NUMBER = USER อาจใส่ตัวคั่นหลักพันตาม user setting → ตัดออกให้เหลือตัวเลขล้วน
    " (ฟอร์มจัด format เอง ถ้าต้องการตัวคั่นหลักพัน)
    REPLACE ALL OCCURRENCES OF ',' IN rv_text WITH ''.

  ENDMETHOD.


  METHOD amount_in_words.

    DATA(lv_amount) = CONV ty_amount( iv_amount ).

    " แยกส่วนจำนวนเต็มกับเศษ 2 ตำแหน่ง (ปัดตามค่าที่เก็บ ไม่ปัดเพิ่ม)
    DATA(lv_integer)  = CONV int8( trunc( lv_amount ) ).
    DATA(lv_fraction) = CONV int8( ( lv_amount - trunc( lv_amount ) ) * 100 ).

    IF iv_currency = 'THB'.

      rv_text = number_to_words_th( lv_integer ).
      rv_text = COND #( WHEN lv_fraction = 0
                        THEN |{ rv_text }บาทถ้วน|
                        ELSE |{ rv_text }บาท{ number_to_words_th( lv_fraction ) }สตางค์| ).

    ELSE.

      " สกุลอื่น: ภาษาอังกฤษ เช่น "One Hundred Twenty-Three and 45/100 USD"
      rv_text = |{ number_to_words_en( lv_integer ) } and { lv_fraction WIDTH = 2 ALIGN = RIGHT PAD = '0' }/100 { iv_currency }|.

    ENDIF.

  ENDMETHOD.


  METHOD number_to_words_th.

    IF iv_number = 0.
      rv_text = COND #( WHEN iv_has_higher = abap_false THEN gt_thai_digits[ 1 ] ELSE '' ).
      RETURN.
    ENDIF.

    " เกินล้าน → อ่านส่วนล้านก่อน แล้ว recursion ส่วนที่เหลือ (หนึ่งล้านเอ็ด, สองล้านห้าแสน)
    IF iv_number >= 1000000.
      rv_text = |{ number_to_words_th( iv_number div 1000000 ) }ล้าน{
                   number_to_words_th( iv_number = iv_number mod 1000000 iv_has_higher = abap_true ) }|.
      RETURN.
    ENDIF.

    " ต่ำกว่าล้าน: ไล่จากหลักแสน (pos 6) ถึงหลักหน่วย (pos 1)
    DATA(lv_remaining) = iv_number.
    DATA(lv_divisor)   = CONV int8( 100000 ).

    DO 6 TIMES.
      DATA(lv_pos)   = 7 - sy-index.                    " 6 = แสน … 1 = หน่วย
      DATA(lv_digit) = CONV i( lv_remaining div lv_divisor ).
      lv_remaining   = lv_remaining mod lv_divisor.
      lv_divisor     = lv_divisor div 10.

      IF lv_digit = 0.
        CONTINUE.
      ENDIF.

      CASE lv_pos.
        WHEN 2.   " หลักสิบ: สิบ / ยี่สิบ / สามสิบ …
          rv_text = rv_text && SWITCH string( lv_digit
                                  WHEN 1 THEN 'สิบ'
                                  WHEN 2 THEN 'ยี่สิบ'
                                  ELSE gt_thai_digits[ lv_digit + 1 ] && 'สิบ' ).
        WHEN 1.   " หลักหน่วย: เอ็ด เมื่อมีหลักที่สูงกว่านำหน้า (ในกลุ่มนี้หรือกลุ่มล้านก่อนหน้า)
          rv_text = rv_text && COND string(
                      WHEN lv_digit = 1 AND ( iv_number > 9 OR iv_has_higher = abap_true )
                      THEN 'เอ็ด'
                      ELSE gt_thai_digits[ lv_digit + 1 ] ).
        WHEN OTHERS.
          rv_text = rv_text && gt_thai_digits[ lv_digit + 1 ] && gt_thai_units[ lv_pos ].
      ENDCASE.
    ENDDO.

  ENDMETHOD.


  METHOD number_to_words_en.

    IF iv_number = 0.
      rv_text = gt_en_ones[ 1 ].
      RETURN.
    ENDIF.

    DATA(lv_remaining) = iv_number.

    " กลุ่มละพัน: Billion / Million / Thousand / (none)
    DATA(lt_scale) = VALUE string_table( ( `Billion` ) ( `Million` ) ( `Thousand` ) ( `` ) ).
    DATA(lv_divisor) = CONV int8( 1000000000 ).

    LOOP AT lt_scale INTO DATA(lv_scale).
      DATA(lv_group) = CONV i( lv_remaining div lv_divisor ).
      lv_remaining   = lv_remaining mod lv_divisor.
      lv_divisor     = lv_divisor div 1000.

      IF lv_group = 0.
        CONTINUE.
      ENDIF.

      DATA(lv_group_text) = ``.
      DATA(lv_hundreds)   = lv_group div 100.
      DATA(lv_tens_part)  = lv_group mod 100.

      IF lv_hundreds > 0.
        lv_group_text = |{ gt_en_ones[ lv_hundreds + 1 ] } Hundred|.
      ENDIF.

      IF lv_tens_part > 0.
        DATA(lv_tens_text) = COND string(
          WHEN lv_tens_part < 20
            THEN gt_en_ones[ lv_tens_part + 1 ]
          WHEN lv_tens_part mod 10 = 0
            THEN gt_en_tens[ lv_tens_part div 10 + 1 ]
          ELSE |{ gt_en_tens[ lv_tens_part div 10 + 1 ] }-{ gt_en_ones[ lv_tens_part mod 10 + 1 ] }| ).
        lv_group_text = COND #( WHEN lv_group_text IS INITIAL THEN lv_tens_text
                                ELSE |{ lv_group_text } { lv_tens_text }| ).
      ENDIF.

      IF lv_scale IS NOT INITIAL.
        lv_group_text = |{ lv_group_text } { lv_scale }|.
      ENDIF.

      rv_text = COND #( WHEN rv_text IS INITIAL THEN lv_group_text
                        ELSE |{ rv_text } { lv_group_text }| ).
    ENDLOOP.

  ENDMETHOD.
ENDCLASS.
