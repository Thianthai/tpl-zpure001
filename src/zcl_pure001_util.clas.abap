CLASS zcl_pure001_util DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    "! สกุลเงินบาท อ่านเป็นภาษาไทยในวงเล็บ
    CONSTANTS gc_thai_currency TYPE waers VALUE 'THB'.

    "! แยกชุดคำจากค่าคงที่เป็น table ครั้งเดียวต่อ session
    CLASS-METHODS class_constructor.

    "! วันที่ไทยแบบ พ.ศ. พร้อมชื่อเดือนภาษาไทย เช่น 21 พฤศจิกายน 2568
    "! วันที่ว่างคืนค่าว่าง
    CLASS-METHODS to_thai_date
      IMPORTING iv_date        TYPE d
      RETURNING VALUE(rv_text) TYPE string.

    "! วันที่แบบ dd/mm/yyyy ปี ค.ศ. เช่น 26/06/2025
    "! วันที่ว่างคืนค่าว่าง
    CLASS-METHODS format_date_dmy
      IMPORTING iv_date        TYPE d
      RETURNING VALUE(rv_text) TYPE string.

    "! จำนวนเงินเป็นตัวอักษร
    "! THB เป็นภาษาไทยในวงเล็บ ลงท้ายด้วยบาทถ้วน หรือบาทตามด้วยสตางค์
    "! สกุลอื่นเป็นภาษาอังกฤษขึ้นต้นด้วยตัวใหญ่ตัวเดียว ไม่มีวงเล็บ
    "! สกุลอื่นที่ไม่มีเศษลงท้ายด้วย Only มีเศษตามด้วย and ตามด้วยหน่วยย่อย
    CLASS-METHODS amount_in_words
      IMPORTING iv_amount      TYPE numeric
                iv_currency    TYPE waers
      RETURNING VALUE(rv_text) TYPE string.

    "! จำนวนที่ตัดศูนย์ท้ายทศนิยมออก
    "! เช่น 12.000 -> 12
    "! เช่น 1.500 -> 1.5
    CLASS-METHODS format_quantity
      IMPORTING iv_quantity    TYPE numeric
      RETURNING VALUE(rv_text) TYPE string.

  PROTECTED SECTION.
  PRIVATE SECTION.

    "! จำนวนเงินทศนิยมสองตำแหน่งที่ใช้แยกส่วนบาทกับสตางค์
    TYPES ty_amount TYPE p LENGTH 12 DECIMALS 2.

    TYPES:
      "! ชื่อสกุลเงินภาษาอังกฤษ ทั้งหน่วยหลักและหน่วยย่อย รูปเอกพจน์และพหูพจน์
      BEGIN OF ty_currency_name,
        major_singular TYPE string,
        major_plural   TYPE string,
        minor_singular TYPE string,
        minor_plural   TYPE string,
      END OF ty_currency_name.

    CONSTANTS:
    "! ชุดคำภาษาไทยและภาษาอังกฤษ คั่นด้วยจุลภาค
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

    "! ชื่อสกุลเงินสำหรับอ่านจำนวนเงินเป็นภาษาอังกฤษ
    "! สกุลที่ไม่อยู่ในรายการใช้รหัสสกุลเงินแทนชื่อ และใช้ cent เป็นหน่วยย่อย
    "! @parameter iv_currency | รหัสสกุลเงิน
    "! @parameter rs_name | ชื่อหน่วยหลักและหน่วยย่อย
    CLASS-METHODS get_currency_name
      IMPORTING iv_currency    TYPE waers
      RETURNING VALUE(rs_name) TYPE ty_currency_name.

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

    " แปลงผ่าน decfloat34 แล้วให้ string template ตัดศูนย์ท้ายให้
    DATA(lv_quantity) = CONV decfloat34( iv_quantity ).
    rv_text = |{ lv_quantity NUMBER = USER }|.

    " NUMBER = USER อาจใส่ตัวคั่นหลักพันตาม user setting จึงตัดออกให้เหลือตัวเลขล้วน
    " ถ้าต้องการตัวคั่นหลักพันให้ฟอร์มจัด format เอง
    REPLACE ALL OCCURRENCES OF ',' IN rv_text WITH ''.

  ENDMETHOD.


  METHOD amount_in_words.

    DATA(lv_amount) = CONV ty_amount( iv_amount ).

    " แยกส่วนจำนวนเต็มกับเศษสองตำแหน่ง ใช้ค่าตามที่เก็บ ไม่ปัดเพิ่ม
    DATA(lv_integer)  = CONV int8( trunc( lv_amount ) ).
    DATA(lv_fraction) = CONV int8( ( lv_amount - trunc( lv_amount ) ) * 100 ).

    IF iv_currency = gc_thai_currency.

      DATA(lv_words) = number_to_words_th( lv_integer ).
      lv_words = COND #( WHEN lv_fraction = 0
                         THEN |{ lv_words }บาทถ้วน|
                         ELSE |{ lv_words }บาท{ number_to_words_th( lv_fraction ) }สตางค์| ).

      " เงินบาทครอบวงเล็บตามฟอร์มมาตรฐาน
      rv_text = |( { lv_words } )|.
      RETURN.

    ENDIF.

    " สกุลอื่นเป็นภาษาอังกฤษ ขึ้นต้นด้วยตัวใหญ่ตัวเดียว ตามด้วยชื่อสกุลเงินเต็ม
    DATA(ls_name)   = get_currency_name( iv_currency ).
    DATA(lv_number) = to_lower( number_to_words_en( lv_integer ) ).
    lv_number = |{ to_upper( substring( val = lv_number len = 1 ) ) }{ substring( val = lv_number off = 1 ) }|.

    DATA(lv_major) = COND string( WHEN lv_integer = 1 THEN ls_name-major_singular ELSE ls_name-major_plural ).

    " ไม่มีเศษลงท้ายด้วย Only
    IF lv_fraction = 0.
      rv_text = |{ lv_number } { lv_major } Only|.
      RETURN.
    ENDIF.

    " มีเศษให้อ่านเป็นคำแล้วตามด้วยหน่วยย่อย เช่น and forty-six cents
    DATA(lv_minor) = COND string( WHEN lv_fraction = 1 THEN ls_name-minor_singular ELSE ls_name-minor_plural ).
    rv_text = |{ lv_number } { lv_major } and { to_lower( number_to_words_en( lv_fraction ) ) } { lv_minor }|.

  ENDMETHOD.


  METHOD number_to_words_th.

    IF iv_number = 0.
      rv_text = COND #( WHEN iv_has_higher = abap_false THEN gt_thai_digits[ 1 ] ELSE '' ).
      RETURN.
    ENDIF.

    " ตั้งแต่หนึ่งล้านขึ้นไป อ่านส่วนที่เป็นล้านก่อน แล้วเรียกซ้ำกับส่วนที่เหลือ
    " เช่น หนึ่งล้านเอ็ด และสองล้านห้าแสน
    IF iv_number >= 1000000.
      rv_text = |{ number_to_words_th( iv_number div 1000000 ) }ล้าน{
                   number_to_words_th( iv_number = iv_number mod 1000000 iv_has_higher = abap_true ) }|.
      RETURN.
    ENDIF.

    " ต่ำกว่าล้าน ไล่จากหลักแสนซึ่งเป็นตำแหน่ง 6 ลงไปถึงหลักหน่วยซึ่งเป็นตำแหน่ง 1
    DATA(lv_remaining) = iv_number.
    DATA(lv_divisor)   = CONV int8( 100000 ).

    DO 6 TIMES.
      DATA(lv_pos)   = 7 - sy-index.
      DATA(lv_digit) = CONV i( lv_remaining div lv_divisor ).
      lv_remaining   = lv_remaining mod lv_divisor.
      lv_divisor     = lv_divisor div 10.

      IF lv_digit = 0.
        CONTINUE.
      ENDIF.

      CASE lv_pos.
        WHEN 2.
          " หลักสิบอ่านเป็น สิบ ยี่สิบ สามสิบ และต่อไปตามปกติ
          rv_text = rv_text && SWITCH string( lv_digit
                                  WHEN 1 THEN 'สิบ'
                                  WHEN 2 THEN 'ยี่สิบ'
                                  ELSE gt_thai_digits[ lv_digit + 1 ] && 'สิบ' ).

        WHEN 1.
          " หลักหน่วยอ่านเป็นเอ็ด เมื่อมีหลักที่สูงกว่านำหน้าในกลุ่มนี้หรือกลุ่มล้านก่อนหน้า
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

    " อ่านทีละกลุ่มสามหลัก ได้แก่ Billion, Million, Thousand และกลุ่มสุดท้ายที่ไม่มีหน่วย
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


  METHOD get_currency_name.

    " เพิ่มสกุลใหม่ตามรายการที่ functional ส่งมาได้ที่นี่
    CASE iv_currency.

      WHEN 'USD'.
        rs_name = VALUE #( major_singular = `US dollar`
                           major_plural   = `US dollars`
                           minor_singular = `cent`
                           minor_plural   = `cents` ).

      WHEN 'SGD'.
        rs_name = VALUE #( major_singular = `Singapore dollar`
                           major_plural   = `Singapore dollars`
                           minor_singular = `cent`
                           minor_plural   = `cents` ).

      WHEN OTHERS.
        " ยังไม่มีชื่อสกุลเงิน จึงใช้รหัสสกุลเงินแทน
        rs_name = VALUE #( major_singular = iv_currency
                           major_plural   = iv_currency
                           minor_singular = `cent`
                           minor_plural   = `cents` ).

    ENDCASE.

  ENDMETHOD.
ENDCLASS.
