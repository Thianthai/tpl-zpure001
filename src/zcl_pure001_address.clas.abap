"! <p class="shorttext synchronized">Print Purchase Order - ที่อยู่ขององค์กร</p>
"! อ่านที่อยู่ของ plant หรือของบริษัทจาก address master
"! ต้องอ่านแบบข้ามการตรวจสิทธิ์เพราะ DCL ของ I_OrganizationAddress ปิดข้อมูลไว้ทั้งหมด
"! ขอบเขตการใช้งานคือที่อยู่ขององค์กรเองที่ปรากฏบนเอกสารอยู่แล้ว ไม่ใช่ข้อมูลส่วนบุคคล
CLASS zcl_pure001_address DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    "! ที่อยู่ที่ประกอบเป็นบรรทัดพร้อมพิมพ์แล้ว
    "! Name1 เป็นชื่อภาษาอังกฤษ Name2 เป็นชื่อภาษาไทย
    "! AddressText รวมถนน อำเภอจังหวัด และรหัสไปรษณีย์ไว้บรรทัดเดียว
    TYPES:
      BEGIN OF ty_address,
        AddressID   TYPE i_organizationaddress-AddressID,
        Name1       TYPE i_organizationaddress-AddresseeName1,
        Name2       TYPE i_organizationaddress-AddresseeName2,
        StreetName  TYPE i_organizationaddress-StreetName,
        CityName    TYPE i_organizationaddress-CityName,
        PostalCode  TYPE i_organizationaddress-PostalCode,
        Country     TYPE i_organizationaddress-Country,
        AddressText TYPE string,
      END OF ty_address.

    "! อ่านที่อยู่ของ plant
    "! @parameter iv_plant | plant ที่ต้องการ
    "! @parameter rs_address | ว่างเมื่อ plant ไม่มีที่อยู่ผูกไว้
    CLASS-METHODS get_by_plant
      IMPORTING iv_plant          TYPE i_plant-Plant
      RETURNING VALUE(rs_address) TYPE ty_address.

    "! อ่านที่อยู่จากเลขที่อยู่โดยตรง ใช้ได้ทั้งของ plant และของบริษัท
    "! @parameter iv_address_id | เลขที่อยู่จาก master เช่น I_Plant หรือ I_CompanyCode
    "! @parameter rs_address | ว่างเมื่อไม่พบที่อยู่
    CLASS-METHODS get_by_address_id
      IMPORTING iv_address_id     TYPE i_organizationaddress-AddressID
      RETURNING VALUE(rs_address) TYPE ty_address.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.


CLASS zcl_pure001_address IMPLEMENTATION.


  METHOD get_by_plant.

    SELECT SINGLE FROM I_Plant
      FIELDS AddressID
      WHERE Plant = @iv_plant
      INTO @DATA(lv_address_id).

    IF sy-subrc <> 0 OR lv_address_id IS INITIAL.
      RETURN.
    ENDIF.

    rs_address = get_by_address_id( lv_address_id ).

  ENDMETHOD.


  METHOD get_by_address_id.

    " DCL ของ view นี้ปิดข้อมูลไว้ทั้งหมด จึงต้องอ่านแบบข้ามการตรวจสิทธิ์
    " ที่อยู่ที่อ่านเป็นขององค์กรเองและปรากฏบนเอกสารที่ผู้ใช้เปิดได้อยู่แล้ว
    SELECT SINGLE FROM I_OrganizationAddress WITH PRIVILEGED ACCESS
      FIELDS AddressID,
             AddresseeName1 AS Name1,
             AddresseeName2 AS Name2,
             StreetName,
             CityName,
             PostalCode,
             Country
      WHERE AddressID                 = @iv_address_id
      AND   AddressPersonID           = @space
      AND   AddressRepresentationCode = @space
      INTO CORRESPONDING FIELDS OF @rs_address.

    IF sy-subrc <> 0.
      CLEAR rs_address.
      RETURN.
    ENDIF.

    " ที่อยู่บนฟอร์มพิมพ์เป็นบรรทัดเดียว เว้นวรรคระหว่างส่วนที่มีค่า
    DATA lt_part TYPE string_table.

    IF rs_address-StreetName IS NOT INITIAL.
      APPEND |{ rs_address-StreetName }| TO lt_part.
    ENDIF.
    IF rs_address-CityName IS NOT INITIAL.
      APPEND |{ rs_address-CityName }| TO lt_part.
    ENDIF.
    IF rs_address-PostalCode IS NOT INITIAL.
      APPEND |{ rs_address-PostalCode }| TO lt_part.
    ENDIF.

    rs_address-AddressText = concat_lines_of( table = lt_part sep = ` ` ).

  ENDMETHOD.

ENDCLASS.
