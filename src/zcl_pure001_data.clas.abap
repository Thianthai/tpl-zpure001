CLASS zcl_pure001_data DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    "! pattern ค้นใน item text แบบไม่สนตัวพิมพ์
    TYPES ty_text_pattern TYPE c LENGTH 80.

    TYPES:
    "! เงื่อนไขค้นหาใบสั่งซื้อ
    "! range ทุกตัวไม่บังคับ ว่างหมายถึงไม่กรอง
      BEGIN OF ty_selection,
        purchase_order   TYPE RANGE OF zr_pure001-PurchaseOrder,
        po_type          TYPE RANGE OF zr_pure001-PurchaseOrderType,
        supplier         TYPE RANGE OF zr_pure001-Supplier,
        company_code     TYPE RANGE OF zr_pure001-CompanyCode,
        purchasing_group TYPE RANGE OF zr_pure001-PurchasingGroup,
        material         TYPE RANGE OF zr_pure001-Material,
        item_text        TYPE RANGE OF ty_text_pattern,
        plant            TYPE RANGE OF zr_pure001-Plant,
        po_date          TYPE RANGE OF zr_pure001-PurchaseOrderDate,
        creation_date    TYPE RANGE OF zr_pure001-CreationDate,
        internal_ref     TYPE RANGE OF zr_pure001-InternalReference,
        external_ref     TYPE RANGE OF zr_pure001-ExternalReference,
      END OF ty_selection.

    "! header ของใบสั่งซื้อพร้อม status, approval และยอดรวม
    "! field ชุดแรกชื่อตรงกับ ZR_PURE001 จึง CORRESPONDING ได้ตรง ๆ
    "! field ชุดหลังเป็นค่าที่ฟอร์มต้องใช้เพิ่ม
    TYPES BEGIN OF ty_header.
            INCLUDE TYPE zr_pure001.
    TYPES:
            CompanyCodeName                TYPE i_companycode-CompanyCodeName,
            PurchasingOrganization         TYPE i_purchaseorderapi01-PurchasingOrganization,
            Language                       TYPE i_purchaseorderapi01-Language,
            PaymentTerms                   TYPE i_purchaseorderapi01-PaymentTerms,
            CreatedByUser                  TYPE i_purchaseorderapi01-CreatedByUser,
            ValidityStartDate              TYPE i_purchaseorderapi01-ValidityStartDate,
            ValidityEndDate                TYPE i_purchaseorderapi01-ValidityEndDate,
            SupplierRespSalesPersonName    TYPE i_purchaseorderapi01-SupplierRespSalesPersonName,
            SupplierPhoneNumber            TYPE i_purchaseorderapi01-SupplierPhoneNumber,
            PurchasingProcessingStatus     TYPE i_purchaseorderapi01-PurchasingProcessingStatus,
            PurchasingCompletenessStatus   TYPE i_purchaseorderapi01-PurchasingCompletenessStatus,
            PurchasingDocumentDeletionCode TYPE i_purchaseorderapi01-PurchasingDocumentDeletionCode,
            HasFollowOnDocument            TYPE abap_bool,
            WorkflowInternalID             TYPE i_workflowstatusoverview-WorkflowInternalID,
            WorkflowExternalStatus         TYPE i_workflowstatusoverview-WorkflowExternalStatus,
            NmbrOfCmpltdWrkflwDialogTasks  TYPE i_workflowstatusoverview-NmbrOfCmpltdWrkflwDialogTasks,

            "--- ค่าที่ฟอร์มใช้ ---
            CompanyTaxNumber               TYPE i_companycode-VATRegistration,
            SupplierTaxNumber              TYPE i_supplier-TaxNumber3,
            SupplierStreet                 TYPE i_supplier-StreetName,
            SupplierDistrict               TYPE i_supplier-DistrictName,
            SupplierCity                   TYPE i_supplier-CityName,
            SupplierPostalCode             TYPE i_supplier-PostalCode,
            SupplierMasterPhone            TYPE i_supplier-PhoneNumber1,
            PaymentTermsText               TYPE i_paymenttermstext-PaymentTermsDescription,

            "--- custom field ที่ผู้ใช้กรอกบนใบสั่งซื้อ ---
            ManualSupplierAddressID        TYPE i_purchaseorderapi01-ManualSupplierAddressID,
            LastChangeDateTime             TYPE i_purchaseorderapi01-LastChangeDateTime,
            PerformanceBondFlag            TYPE i_purchaseorderapi01-YY1_PerformanceBond_PO_PDH,
            PerformanceBondCash            TYPE i_purchaseorderapi01-YY1_Retention_PO_Per_PDH,
            PerformanceBondBG              TYPE i_purchaseorderapi01-YY1_BankGuarantee_PO_P_PDH,
            InsuranceFlag                  TYPE i_purchaseorderapi01-YY1_Insurance_PO_PDH,
            WarrantyBondFlag               TYPE i_purchaseorderapi01-YY1_WarrantyBond_PO_PDH,
            WarrantyBondCash               TYPE i_purchaseorderapi01-YY1_Retention_PO_W_PDH,
            WarrantyBondBG                 TYPE i_purchaseorderapi01-YY1_BankGuarantee_PO_W_PDH,
            SupplierEmail                  TYPE i_purchaseorderapi01-YY1_Email_PO_PDH,
            FrameworkStartDate             TYPE i_purchaseorderapi01-YY1_FrameworkStartDate_PDH,
            FrameworkEndDate               TYPE i_purchaseorderapi01-YY1_FrameworkEndDate_PDH,
          END OF ty_header,
          tt_header TYPE STANDARD TABLE OF ty_header WITH EMPTY KEY.

    TYPES:
    "! item ของใบสั่งซื้อ รวม item ที่ถูกลบ
    "! ผู้เรียกต้องกรอง item ที่ลบออกเอง
      BEGIN OF ty_item,
        PurchaseOrder                  TYPE i_purchaseorderitemapi01-PurchaseOrder,
        PurchaseOrderItem              TYPE i_purchaseorderitemapi01-PurchaseOrderItem,
        PurchasingDocumentDeletionCode TYPE i_purchaseorderitemapi01-PurchasingDocumentDeletionCode,
        Material                       TYPE i_purchaseorderitemapi01-Material,
        MaterialDescription            TYPE i_purchaseorderitemapi01-PurchaseOrderItemText,
        Quantity                       TYPE i_purchaseorderitemapi01-OrderQuantity,
        Unit                           TYPE i_purchaseorderitemapi01-PurchaseOrderQuantityUnit,
        NetPriceAmount                 TYPE i_purchaseorderitemapi01-NetPriceAmount,
        NetPriceQuantity               TYPE i_purchaseorderitemapi01-NetPriceQuantity,
        NetAmount                      TYPE i_purchaseorderitemapi01-NetAmount,
        DocumentCurrency               TYPE i_purchaseorderitemapi01-DocumentCurrency,
        TaxCode                        TYPE i_purchaseorderitemapi01-TaxCode,
        Plant                          TYPE i_purchaseorderitemapi01-Plant,
        PlantName                      TYPE i_plant-PlantName,
        PurchaseRequisition            TYPE i_purchaseorderitemapi01-PurchaseRequisition,
      END OF ty_item,
      tt_item TYPE STANDARD TABLE OF ty_item WITH EMPTY KEY.

    TYPES:
    "! key ของใบสั่งซื้อที่ส่งให้ method อ่านข้อมูล
      BEGIN OF ty_po_key,
        PurchaseOrder TYPE zr_pure001-PurchaseOrder,
      END OF ty_po_key,
      tt_po_key TYPE STANDARD TABLE OF ty_po_key WITH EMPTY KEY.

    TYPES:
    "! schedule line แรกของ item
    "! ใช้หาวันส่งของ เลขที่ใบขอซื้อ และช่วง performance period
      BEGIN OF ty_schedule_line,
        PurchaseOrder              TYPE i_purordschedulelineapi01-PurchaseOrder,
        PurchaseOrderItem          TYPE i_purordschedulelineapi01-PurchaseOrderItem,
        ScheduleLineDeliveryDate   TYPE i_purordschedulelineapi01-ScheduleLineDeliveryDate,
        PerformancePeriodStartDate TYPE i_purordschedulelineapi01-PerformancePeriodStartDate,
        PerformancePeriodEndDate   TYPE i_purordschedulelineapi01-PerformancePeriodEndDate,
        PurchaseRequisition        TYPE i_purordschedulelineapi01-PurchaseRequisition,
      END OF ty_schedule_line,
      tt_schedule_line TYPE STANDARD TABLE OF ty_schedule_line WITH EMPTY KEY.

    TYPES:
    "! account assignment แรกของ item พร้อมรหัส WBS แบบภายนอก
      BEGIN OF ty_account_assignment,
        PurchaseOrder        TYPE i_purordaccountassignmentapi01-PurchaseOrder,
        PurchaseOrderItem    TYPE i_purordaccountassignmentapi01-PurchaseOrderItem,
        GLAccount            TYPE i_purordaccountassignmentapi01-GLAccount,
        CostCenter           TYPE i_purordaccountassignmentapi01-CostCenter,
        OrderID              TYPE i_purordaccountassignmentapi01-OrderID,
        WBSElementInternalID TYPE i_purordaccountassignmentapi01-WBSElementInternalID_2,
        WBSElement           TYPE i_enterpriseprojectelement-ProjectElement,
        UnloadingPointName   TYPE i_purordaccountassignmentapi01-UnloadingPointName,
      END OF ty_account_assignment,
      tt_account_assignment TYPE STANDARD TABLE OF ty_account_assignment WITH EMPTY KEY.

    TYPES:
    "! long text ของ header หรือ item
    "! text ของ header มี PurchaseOrderItem ว่าง
    "! อ่านจาก projection view ซึ่งอ่านได้ผ่าน ABAP SQL เท่านั้น
      BEGIN OF ty_text,
        PurchaseOrder     TYPE i_purchaseorderitemnotetp_2-PurchaseOrder,
        PurchaseOrderItem TYPE i_purchaseorderitemnotetp_2-PurchaseOrderItem,
        TextObjectType    TYPE i_purchaseorderitemnotetp_2-TextObjectType,
        Language          TYPE i_purchaseorderitemnotetp_2-Language,
        PlainLongText     TYPE i_purchaseorderitemnotetp_2-PlainLongText,
      END OF ty_text,
      tt_text TYPE STANDARD TABLE OF ty_text WITH EMPTY KEY.

    TYPES:
    "! ค่าที่ฟอร์มต้องใช้แต่ต้องให้ custom class ของลูกค้าคำนวณ
    "! เป็นชุดเดียวกับที่ BAdI MM_PUR_S4_PO_MODIFY_HEADER เติมให้ฟอร์มมาตรฐาน
      BEGIN OF ty_form_detail,
        PurchaseOrder      TYPE zr_pure001-PurchaseOrder,
        ApproverName       TYPE zcl_get_approval_name=>gty_data,
        ApproverPosition   TYPE zcl_get_approval_name=>gty_data,
        ApprovalDateRaw    TYPE zcl_get_approval_name=>gty_po_rel_date,
        ApprovalDateText   TYPE i_purchaseorderapi01-YY1_Approval_date_PDH,
        RecipientContact   TYPE i_purchaseorderapi01-YY1_RecipientContact_PDH,
        RecipientTelephone TYPE i_purchaseorderapi01-YY1_RecipientTelephone_PDH,
        SumAmount          TYPE i_purchaseorderapi01-YY1_SumAmount_PDH,
        SumNetAmount       TYPE i_purchaseorderapi01-YY1_SumNetAmt_PDH,
        SumOtherExpense    TYPE i_purchaseorderapi01-YY1_SumOtherExpense_PDH,
        SumTax             TYPE i_purchaseorderapi01-YY1_SumTax_PDH,
        SumTotalNetAmount  TYPE i_purchaseorderapi01-YY1_SumTotalNetAmt_PDH,
        SupplierCodeName   TYPE i_purchaseorderapi01-YY1_SuppCodeNameBranch_PDH,
        SupplierAddress    TYPE i_purchaseorderapi01-YY1_SupplierAddress_PDH,
        PreparedByName     TYPE zcl_get_fullname_th=>gty_data,
        IssuedDateText     TYPE i_purchaseorderapi01-YY1_IssuedDateTH_PDH,
      END OF ty_form_detail,
      tt_form_detail TYPE STANDARD TABLE OF ty_form_detail WITH EMPTY KEY.

    "! อ่านค่าที่ฟอร์มต้องใช้จาก custom class ของลูกค้า
    "! เรียกทีละใบสั่งซื้อจึงใช้เฉพาะตอนพิมพ์ฟอร์ม ห้ามเรียกจาก list report
    "! @parameter it_header | header ที่อ่านมาแล้วจาก read_headers
    "! @parameter rt_detail | หนึ่งบรรทัดต่อหนึ่งใบสั่งซื้อ
    METHODS read_form_details
      IMPORTING it_header        TYPE tt_header
      RETURNING VALUE(rt_detail) TYPE tt_form_detail.

    "! อ่าน schedule line แรกของทุก item
    "! @parameter it_purchase_order | ใบสั่งซื้อที่ต้องการ
    "! @parameter rt_schedule_line | หนึ่งบรรทัดต่อหนึ่ง item
    METHODS read_schedule_lines
      IMPORTING it_purchase_order       TYPE tt_po_key
      RETURNING VALUE(rt_schedule_line) TYPE tt_schedule_line.

    "! อ่าน account assignment แรกของทุก item พร้อมแปลง WBS เป็นรหัสภายนอก
    "! @parameter it_purchase_order | ใบสั่งซื้อที่ต้องการ
    "! @parameter rt_account_assignment | หนึ่งบรรทัดต่อหนึ่ง item
    METHODS read_account_assignments
      IMPORTING it_purchase_order            TYPE tt_po_key
      RETURNING VALUE(rt_account_assignment) TYPE tt_account_assignment.

    "! อ่าน long text ของ header ทุกภาษาและทุกประเภท
    "! @parameter it_purchase_order | ใบสั่งซื้อที่ต้องการ
    "! @parameter rt_text | ผู้เรียกเลือกภาษาและประเภทเอง
    METHODS read_header_texts
      IMPORTING it_purchase_order TYPE tt_po_key
      RETURNING VALUE(rt_text)    TYPE tt_text.

    "! อ่าน long text ของ item ทุกภาษาและทุกประเภท
    "! @parameter it_purchase_order | ใบสั่งซื้อที่ต้องการ
    "! @parameter rt_text | เรียงตามใบสั่งซื้อ item และประเภท text
    METHODS read_item_texts
      IMPORTING it_purchase_order TYPE tt_po_key
      RETURNING VALUE(rt_text)    TYPE tt_text.

    CONSTANTS:
    "! รหัส status ชุดเดียวกับ I_PurchasingDocumentStatus ตรงกับแอปมาตรฐาน
    "! รหัส approval status และ criticality ที่ list report ใช้
      BEGIN OF gc_status,
        draft       TYPE zr_pure001-PurchaseOrderStatus VALUE '01',
        in_approval TYPE zr_pure001-PurchaseOrderStatus VALUE '02',
        follow_on   TYPE zr_pure001-PurchaseOrderStatus VALUE '05',
        released    TYPE zr_pure001-PurchaseOrderStatus VALUE '08',
        deleted     TYPE zr_pure001-PurchaseOrderStatus VALUE '10',
        created     TYPE zr_pure001-PurchaseOrderStatus VALUE '27',
        rejected    TYPE zr_pure001-PurchaseOrderStatus VALUE '38',
      END OF gc_status,

      BEGIN OF gc_approval,
        approved    TYPE zr_pure001-ApprovalStatus VALUE 'A',
        automatic   TYPE zr_pure001-ApprovalStatus VALUE 'B',
        in_approval TYPE zr_pure001-ApprovalStatus VALUE 'I',
        rejected    TYPE zr_pure001-ApprovalStatus VALUE 'R',
      END OF gc_approval,

      BEGIN OF gc_criticality,
        neutral  TYPE zr_pure001-PurchaseOrderStatusCriticality VALUE 0,
        negative TYPE zr_pure001-PurchaseOrderStatusCriticality VALUE 1,
        positive TYPE zr_pure001-PurchaseOrderStatusCriticality VALUE 3,
      END OF gc_criticality,

      "! PROCSTAT (I_PurgProcessingStatusText)
      BEGIN OF gc_procstat,
        active             TYPE c LENGTH 2 VALUE '02',
        in_release         TYPE c LENGTH 2 VALUE '03',
        partially_released TYPE c LENGTH 2 VALUE '04',
        release_completed  TYPE c LENGTH 2 VALUE '05',
        rejected           TYPE c LENGTH 2 VALUE '08',
        external_approval  TYPE c LENGTH 2 VALUE '26',
      END OF gc_procstat.

    "! อ่าน header ของใบสั่งซื้อตามเงื่อนไข
    "! พร้อม derive status, approval status, ยอดรวม และเอกสารต่อเนื่อง
    METHODS read_headers
      IMPORTING is_selection     TYPE ty_selection
      RETURNING VALUE(rt_header) TYPE tt_header.

    "! อ่าน item ของใบสั่งซื้อที่ระบุ รวม item ที่ถูกลบ
    "! ผลลัพธ์เรียงตามใบสั่งซื้อแล้วตาม item
    METHODS read_items
      IMPORTING it_purchase_order TYPE tt_po_key
      RETURNING VALUE(rt_item)    TYPE tt_item.

  PROTECTED SECTION.
  PRIVATE SECTION.

    "! เติมชื่อประเภทเอกสารตามภาษาที่ login
    "! ข้อมูล master อื่นอ่านมาพร้อม header ใน read_headers แล้ว
    METHODS enrich_master_texts CHANGING ct_header TYPE tt_header.

    "! เติมมูลค่าสุทธิทั้งใบ ไม่นับ item ที่ถูกลบ
    METHODS enrich_totals       CHANGING ct_header TYPE tt_header.

    "! ตั้ง flag เมื่อมีใบรับของหรือใบแจ้งหนี้อ้างถึงใบสั่งซื้อ
    METHODS enrich_follow_on    CHANGING ct_header TYPE tt_header.

    "! เติมสถานะของ workflow instance ล่าสุด
    METHODS enrich_workflow     CHANGING ct_header TYPE tt_header.

    "! derive status และ approval status จากข้อมูลที่เติมไว้แล้ว
    METHODS derive_status       CHANGING ct_header TYPE tt_header.

    "! ประกอบชื่อผู้ขายพร้อมสาขาและที่อยู่ ตามกติกาเดียวกับ BAdI ของฟอร์มมาตรฐาน
    "! ใบที่ระบุที่อยู่เองจะอ่านที่อยู่จากใบสั่งซื้อแทนข้อมูลผู้ขาย
    METHODS compose_supplier_info
      IMPORTING is_header TYPE ty_header
      CHANGING  cs_detail TYPE ty_form_detail.

ENDCLASS.



CLASS ZCL_PURE001_DATA IMPLEMENTATION.

  METHOD read_headers.

    " Material, Plant และ item text อยู่ระดับ item จึงกรองด้วย EXISTS เพื่อไม่ให้แถวของ header ซ้ำ
    " นับ item ที่ถูกลบด้วยตามแอปมาตรฐาน
    " master ของผู้ขาย บริษัท กลุ่มจัดซื้อ และเงื่อนไขการชำระเงิน อ่านด้วย LEFT OUTER JOIN
    " ใบสั่งซื้อที่ไม่มี master บางตัวจึงยังอยู่ในผลลัพธ์
    SELECT FROM I_PurchaseOrderAPI01 AS po
           LEFT OUTER JOIN I_Supplier AS sup
             ON sup~Supplier = po~Supplier
           LEFT OUTER JOIN I_PurchasingGroup AS pgr
             ON pgr~PurchasingGroup = po~PurchasingGroup
           LEFT OUTER JOIN I_CompanyCode AS cmp
             ON cmp~CompanyCode = po~CompanyCode
           LEFT OUTER JOIN I_PaymentTermsText AS pmt
             ON  pmt~PaymentTerms = po~PaymentTerms
             AND pmt~Language     = po~Language
      FIELDS po~PurchaseOrder,
             po~PurchaseOrderType,
             po~CompanyCode,
             po~PurchasingGroup,
             po~PurchasingOrganization,
             po~Supplier,
             po~PurchaseOrderDate,
             po~CreationDate,
             po~CreatedByUser,
             po~Language,
             po~CorrespncInternalReference   AS InternalReference,
             po~CorrespncExternalReference   AS ExternalReference,
             po~DocumentCurrency,
             po~PaymentTerms,
             po~ValidityStartDate,
             po~ValidityEndDate,
             po~SupplierRespSalesPersonName,
             po~SupplierPhoneNumber,
             po~PurchasingProcessingStatus,
             po~PurchasingCompletenessStatus,
             po~PurchasingDocumentDeletionCode,
             po~ManualSupplierAddressID,
             po~LastChangeDateTime,
             po~YY1_PerformanceBond_PO_PDH  AS PerformanceBondFlag,
             po~YY1_Retention_PO_Per_PDH    AS PerformanceBondCash,
             po~YY1_BankGuarantee_PO_P_PDH  AS PerformanceBondBG,
             po~YY1_Insurance_PO_PDH        AS InsuranceFlag,
             po~YY1_WarrantyBond_PO_PDH     AS WarrantyBondFlag,
             po~YY1_Retention_PO_W_PDH      AS WarrantyBondCash,
             po~YY1_BankGuarantee_PO_W_PDH  AS WarrantyBondBG,
             po~YY1_Email_PO_PDH            AS SupplierEmail,
             po~YY1_FrameworkStartDate_PDH  AS FrameworkStartDate,
             po~YY1_FrameworkEndDate_PDH    AS FrameworkEndDate,
             sup~SupplierName,
             sup~TaxNumber3                 AS SupplierTaxNumber,
             sup~StreetName                 AS SupplierStreet,
             sup~DistrictName               AS SupplierDistrict,
             sup~CityName                   AS SupplierCity,
             sup~PostalCode                 AS SupplierPostalCode,
             sup~PhoneNumber1               AS SupplierMasterPhone,
             pgr~PurchasingGroupName,
             cmp~CompanyCodeName,
             cmp~VATRegistration            AS CompanyTaxNumber,
             " ใช้ Description ก่อน ถ้าว่างจึงใช้ Name
             CASE WHEN pmt~PaymentTermsDescription = @space
                  THEN pmt~PaymentTermsName
                  ELSE pmt~PaymentTermsDescription
             END                            AS PaymentTermsText
      WHERE po~PurchaseOrder              IN @is_selection-purchase_order
      AND   po~PurchaseOrderType          IN @is_selection-po_type
      AND   po~Supplier                   IN @is_selection-supplier
      AND   po~CompanyCode                IN @is_selection-company_code
      AND   po~PurchasingGroup            IN @is_selection-purchasing_group
      AND   po~PurchaseOrderDate          IN @is_selection-po_date
      AND   po~CreationDate               IN @is_selection-creation_date
      AND   po~CorrespncInternalReference IN @is_selection-internal_ref
      AND   po~CorrespncExternalReference IN @is_selection-external_ref
      AND   EXISTS ( SELECT itm~PurchaseOrder
                       FROM I_PurchaseOrderItemAPI01 AS itm
                       WHERE itm~PurchaseOrder = po~PurchaseOrder
                       AND   (    itm~Material                       IN @is_selection-material
                               OR upper( itm~PurchaseOrderItemText ) IN @is_selection-item_text )
                       AND   itm~Plant                               IN @is_selection-plant )
      INTO CORRESPONDING FIELDS OF TABLE @rt_header.

    IF rt_header IS INITIAL.
      RETURN.
    ENDIF.

    " กันแถวซ้ำกรณี view ที่ join มามีมากกว่าหนึ่งแถวต่อ key
    SORT rt_header BY PurchaseOrder.
    DELETE ADJACENT DUPLICATES FROM rt_header COMPARING PurchaseOrder.

    enrich_master_texts( CHANGING ct_header = rt_header ).
    enrich_totals(       CHANGING ct_header = rt_header ).
    enrich_follow_on(    CHANGING ct_header = rt_header ).
    enrich_workflow(     CHANGING ct_header = rt_header ).
    derive_status(       CHANGING ct_header = rt_header ).

  ENDMETHOD.


  METHOD enrich_master_texts.

    " ชื่อประเภทเอกสารอ่านทั้งชุดครั้งเดียว เพราะมีไม่กี่แถวและไม่ขึ้นกับใบสั่งซื้อ
    SELECT FROM I_PurchasingDocumentTypeText
      FIELDS PurchasingDocumentType,
             PurchasingDocumentTypeName
      WHERE PurchasingDocumentCategory = 'F'
      AND   Language                   = @sy-langu
      INTO TABLE @DATA(lt_potype).

    LOOP AT ct_header ASSIGNING FIELD-SYMBOL(<lfs_header>).
      <lfs_header>-PurchaseOrderTypeName = VALUE #( lt_potype[ PurchasingDocumentType = <lfs_header>-PurchaseOrderType ]-PurchasingDocumentTypeName OPTIONAL ).
    ENDLOOP.

  ENDMETHOD.


  METHOD enrich_totals.

    TYPES:
      BEGIN OF ty_total,
        PurchaseOrder TYPE zr_pure001-PurchaseOrder,
        NetAmount     TYPE zr_pure001-NetOrderValue,
      END OF ty_total.

    DATA lt_total TYPE STANDARD TABLE OF ty_total WITH NON-UNIQUE KEY PurchaseOrder.

    IF ct_header IS INITIAL.
      RETURN.
    ENDIF.

    " ยอดรวมทั้งใบไม่นับ item ที่ถูกลบ ตรงกับ Net Order Value ของแอปมาตรฐาน
    " FOR ALL ENTRIES ใช้กับ GROUP BY ไม่ได้ จึงรวมยอดใน ABAP
    SELECT FROM I_PurchaseOrderItemAPI01
      FIELDS PurchaseOrder,
             NetAmount
      FOR ALL ENTRIES IN @ct_header
      WHERE PurchaseOrder                  = @ct_header-PurchaseOrder
      AND   PurchasingDocumentDeletionCode <> 'L'
      INTO TABLE @DATA(lt_item_amount).

    LOOP AT lt_item_amount ASSIGNING FIELD-SYMBOL(<lfs_amount>).
      COLLECT VALUE ty_total( PurchaseOrder = <lfs_amount>-PurchaseOrder
                              NetAmount     = <lfs_amount>-NetAmount ) INTO lt_total.
    ENDLOOP.

    LOOP AT ct_header ASSIGNING FIELD-SYMBOL(<lfs_header>).
      <lfs_header>-NetOrderValue = VALUE #( lt_total[ PurchaseOrder = <lfs_header>-PurchaseOrder ]-NetAmount OPTIONAL ).
    ENDLOOP.

  ENDMETHOD.


  METHOD enrich_follow_on.

    IF ct_header IS INITIAL.
      RETURN.
    ENDIF.

    " มีใบรับของหรือใบแจ้งหนี้อ้างถึงใบสั่งซื้อ ถือว่ามีเอกสารต่อเนื่อง
    " นับทุกเอกสารรวมที่ถูก reverse ตามแอปมาตรฐาน
    SELECT DISTINCT PurchaseOrder
      FROM I_MaterialDocumentItem_2
      FOR ALL ENTRIES IN @ct_header
      WHERE PurchaseOrder = @ct_header-PurchaseOrder
      INTO TABLE @DATA(lt_follow_on).

    SELECT DISTINCT PurchaseOrder
      FROM I_SuplrInvcItemPurOrdRefAPI01
      FOR ALL ENTRIES IN @ct_header
      WHERE PurchaseOrder = @ct_header-PurchaseOrder
      APPENDING TABLE @lt_follow_on.

    SORT lt_follow_on BY PurchaseOrder.
    DELETE ADJACENT DUPLICATES FROM lt_follow_on COMPARING PurchaseOrder.

    LOOP AT ct_header ASSIGNING FIELD-SYMBOL(<lfs_header>).
      <lfs_header>-HasFollowOnDocument = xsdbool( line_exists( lt_follow_on[ PurchaseOrder = <lfs_header>-PurchaseOrder ] ) ).
    ENDLOOP.

  ENDMETHOD.


  METHOD enrich_workflow.

    " FOR ALL ENTRIES ต้องใช้ field type เดียวกัน
    " จึงแปลงเลขที่ใบสั่งซื้อเป็น type ของ SAPBusinessObjectNodeKey1 ก่อน
    TYPES:
      BEGIN OF ty_wf_key,
        SAPBusinessObjectNodeKey1 TYPE i_workflowstatusoverview-SAPBusinessObjectNodeKey1,
      END OF ty_wf_key,
      tt_wf_key TYPE STANDARD TABLE OF ty_wf_key WITH EMPTY KEY.

    IF ct_header IS INITIAL.
      RETURN.
    ENDIF.

    DATA(lt_wf_key) = VALUE tt_wf_key( FOR ls_header IN ct_header
                                       ( SAPBusinessObjectNodeKey1 = ls_header-PurchaseOrder ) ).

    " ใบสั่งซื้อที่ถูกแก้แล้วเริ่ม workflow ใหม่ได้หลายรอบ
    " จึงอ่านทุก instance แล้วเก็บเฉพาะตัวล่าสุดซึ่งมี ID สูงสุด
    SELECT FROM I_WorkflowStatusOverview
      FIELDS SAPBusinessObjectNodeKey1 AS PurchaseOrder,
             WorkflowInternalID,
             WorkflowExternalStatus,
             NmbrOfCmpltdWrkflwDialogTasks
      FOR ALL ENTRIES IN @lt_wf_key
      WHERE SAPObjectNodeRepresentation = 'PurchaseOrder'
      AND   SAPBusinessObjectNodeKey1   = @lt_wf_key-SAPBusinessObjectNodeKey1
      INTO TABLE @DATA(lt_workflow).

    SORT lt_workflow BY PurchaseOrder ASCENDING WorkflowInternalID DESCENDING.
    DELETE ADJACENT DUPLICATES FROM lt_workflow COMPARING PurchaseOrder.

    LOOP AT ct_header ASSIGNING FIELD-SYMBOL(<lfs_header>).
      ASSIGN lt_workflow[ PurchaseOrder = <lfs_header>-PurchaseOrder ] TO FIELD-SYMBOL(<lfs_workflow>).
      IF sy-subrc = 0.
        <lfs_header>-WorkflowInternalID            = <lfs_workflow>-WorkflowInternalID.
        <lfs_header>-WorkflowExternalStatus        = <lfs_workflow>-WorkflowExternalStatus.
        <lfs_header>-NmbrOfCmpltdWrkflwDialogTasks = <lfs_workflow>-NmbrOfCmpltdWrkflwDialogTasks.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.


  METHOD derive_status.

    " ชื่อ status ตามภาษาที่ login จากตาราง text มาตรฐาน
    SELECT FROM I_PurchasingDocumentStatusText
      FIELDS PurchasingDocumentStatus,
             PurchasingDocumentStatusName
      WHERE Language = @sy-langu
      INTO TABLE @DATA(lt_status_text).

    LOOP AT ct_header ASSIGNING FIELD-SYMBOL(<lfs_header>).

      DATA(lv_procstat) = <lfs_header>-PurchasingProcessingStatus.

      DATA(lv_in_approval) = xsdbool( lv_procstat = gc_procstat-in_release
                                   OR lv_procstat = gc_procstat-partially_released
                                   OR lv_procstat = gc_procstat-external_approval ).

      DATA(lv_ordered)     = xsdbool( lv_procstat = gc_procstat-active
                                   OR lv_procstat = gc_procstat-release_completed ).

      "--- Status ใช้เป็น filter ---------------------------------------------------
      " ลำดับของเงื่อนไขมีผล เงื่อนไขบนชนะเงื่อนไขล่าง
      <lfs_header>-PurchaseOrderStatus = COND #(
        WHEN <lfs_header>-PurchasingDocumentDeletionCode = 'L'        THEN gc_status-deleted
        WHEN <lfs_header>-PurchasingCompletenessStatus   = 'X'        THEN gc_status-draft
        WHEN lv_procstat = gc_procstat-rejected                       THEN gc_status-rejected
        WHEN lv_in_approval = abap_true                               THEN gc_status-in_approval
        WHEN lv_ordered = abap_true AND <lfs_header>-HasFollowOnDocument = abap_true
                                                                      THEN gc_status-follow_on
        WHEN lv_ordered = abap_true                                   THEN gc_status-released
        ELSE                                                               gc_status-created ).

      <lfs_header>-PurchaseOrderStatusName = VALUE #(
        lt_status_text[ PurchasingDocumentStatus = <lfs_header>-PurchaseOrderStatus ]-PurchasingDocumentStatusName OPTIONAL ).

      <lfs_header>-PurchaseOrderStatusCriticality = SWITCH #( <lfs_header>-PurchaseOrderStatus
        WHEN gc_status-deleted OR gc_status-rejected     THEN gc_criticality-negative
        WHEN gc_status-follow_on OR gc_status-released   THEN gc_criticality-positive
        ELSE                                                  gc_criticality-neutral ).

      "--- Approval Status ใช้เป็นคอลัมน์ -------------------------------------------
      " ดู processing status ก่อน แล้วจึงดูสถานะของ workflow
      <lfs_header>-ApprovalStatus = COND #(
        WHEN <lfs_header>-PurchasingCompletenessStatus = 'X'          THEN ''
        WHEN lv_procstat = gc_procstat-rejected                       THEN gc_approval-rejected
        WHEN lv_in_approval = abap_true                               THEN gc_approval-in_approval
        WHEN <lfs_header>-WorkflowExternalStatus = 'COMPLETED'
         AND <lfs_header>-NmbrOfCmpltdWrkflwDialogTasks = 0           THEN gc_approval-automatic
        WHEN <lfs_header>-WorkflowExternalStatus = 'COMPLETED'        THEN gc_approval-approved
        ELSE                                                               '' ).

      <lfs_header>-ApprovalStatusText = SWITCH #( <lfs_header>-ApprovalStatus
        WHEN gc_approval-approved    THEN 'Approved'
        WHEN gc_approval-automatic   THEN 'Approved automatically'
        WHEN gc_approval-in_approval THEN 'In Approval'
        WHEN gc_approval-rejected    THEN 'Rejected'
        ELSE                              '' ).

      <lfs_header>-ApprovalStatusCriticality = SWITCH #( <lfs_header>-ApprovalStatus
        WHEN gc_approval-rejected                          THEN gc_criticality-negative
        WHEN gc_approval-approved OR gc_approval-automatic THEN gc_criticality-positive
        ELSE                                                    gc_criticality-neutral ).

    ENDLOOP.

  ENDMETHOD.


  METHOD read_items.

    IF it_purchase_order IS INITIAL.
      RETURN.
    ENDIF.

    SELECT FROM I_PurchaseOrderItemAPI01 AS itm
           LEFT OUTER JOIN I_Plant AS plt
             ON plt~Plant = itm~Plant
      FIELDS itm~PurchaseOrder,
             itm~PurchaseOrderItem,
             itm~PurchasingDocumentDeletionCode,
             itm~Material,
             itm~PurchaseOrderItemText     AS MaterialDescription,
             itm~OrderQuantity             AS Quantity,
             itm~PurchaseOrderQuantityUnit AS Unit,
             itm~NetPriceAmount,
             itm~NetPriceQuantity,
             itm~NetAmount,
             itm~DocumentCurrency,
             itm~TaxCode,
             itm~Plant,
             plt~PlantName,
             itm~PurchaseRequisition
      FOR ALL ENTRIES IN @it_purchase_order
      WHERE itm~PurchaseOrder = @it_purchase_order-PurchaseOrder
      INTO CORRESPONDING FIELDS OF TABLE @rt_item.

    SORT rt_item BY PurchaseOrder PurchaseOrderItem.

  ENDMETHOD.


  METHOD read_schedule_lines.

    IF it_purchase_order IS INITIAL.
      RETURN.
    ENDIF.

    SELECT FROM I_PurOrdScheduleLineAPI01
      FIELDS PurchaseOrder,
             PurchaseOrderItem,
             ScheduleLineDeliveryDate,
             PerformancePeriodStartDate,
             PerformancePeriodEndDate,
             PurchaseRequisition
      FOR ALL ENTRIES IN @it_purchase_order
      WHERE PurchaseOrder             = @it_purchase_order-PurchaseOrder
      AND   PurchaseOrderScheduleLine = '0001'
      INTO CORRESPONDING FIELDS OF TABLE @rt_schedule_line.

  ENDMETHOD.


  METHOD read_account_assignments.

    IF it_purchase_order IS INITIAL.
      RETURN.
    ENDIF.

    SELECT FROM I_PurOrdAccountAssignmentAPI01
      FIELDS PurchaseOrder,
             PurchaseOrderItem,
             GLAccount,
             CostCenter,
             OrderID,
             WBSElementInternalID_2 AS WBSElementInternalID,
             UnloadingPointName
      FOR ALL ENTRIES IN @it_purchase_order
      WHERE PurchaseOrder           = @it_purchase_order-PurchaseOrder
      AND   AccountAssignmentNumber = '01'
      INTO CORRESPONDING FIELDS OF TABLE @rt_account_assignment.

    " แปลงรหัส WBS ภายในเป็นรหัสภายนอกผ่าน Enterprise Project
    DATA(lt_wbs_key) = VALUE tt_account_assignment( FOR ls_aa IN rt_account_assignment
                                                    WHERE ( WBSElementInternalID IS NOT INITIAL )
                                                    ( WBSElementInternalID = ls_aa-WBSElementInternalID ) ).
    IF lt_wbs_key IS INITIAL.
      RETURN.
    ENDIF.

    SELECT FROM I_EnterpriseProjectElement
      FIELDS WBSElementInternalID,
             ProjectElement
      FOR ALL ENTRIES IN @lt_wbs_key
      WHERE WBSElementInternalID = @lt_wbs_key-WBSElementInternalID
      INTO TABLE @DATA(lt_wbs).

    LOOP AT rt_account_assignment ASSIGNING FIELD-SYMBOL(<lfs_aa>) WHERE WBSElementInternalID IS NOT INITIAL.
      <lfs_aa>-WBSElement = VALUE #( lt_wbs[ WBSElementInternalID = <lfs_aa>-WBSElementInternalID ]-ProjectElement OPTIONAL ).
    ENDLOOP.

  ENDMETHOD.


  METHOD read_header_texts.

    IF it_purchase_order IS INITIAL.
      RETURN.
    ENDIF.

    " column แบบ STRING ใช้กับ FOR ALL ENTRIES ไม่ได้เพราะมี DISTINCT แฝงอยู่
    " จึงใช้ range แทน ซึ่งพอเพราะพิมพ์ครั้งละไม่กี่ใบ
    DATA(lr_purchase_order) = VALUE ty_selection-purchase_order(
      FOR ls_key IN it_purchase_order ( sign = 'I' option = 'EQ' low = ls_key-PurchaseOrder ) ).

    " ประเภทที่ฟอร์มใช้คือ F01 Header Text
    " F02 Header Note
    " F06 Shipping Instructions สำหรับช่องจัดส่งโดย
    SELECT FROM I_PurchaseOrderNoteTP_2
      FIELDS PurchaseOrder,
             TextObjectType,
             Language,
             PlainLongText
      WHERE PurchaseOrder IN @lr_purchase_order
      INTO CORRESPONDING FIELDS OF TABLE @rt_text.

  ENDMETHOD.


  METHOD read_item_texts.

    IF it_purchase_order IS INITIAL.
      RETURN.
    ENDIF.

    DATA(lr_purchase_order) = VALUE ty_selection-purchase_order(
      FOR ls_key IN it_purchase_order ( sign = 'I' option = 'EQ' low = ls_key-PurchaseOrder ) ).

    " ประเภทที่ฟอร์มใช้คือ F03 Material PO Text และ F01 Item Text
    SELECT FROM I_PurchaseOrderItemNoteTP_2
      FIELDS PurchaseOrder,
             PurchaseOrderItem,
             TextObjectType,
             Language,
             PlainLongText
      WHERE PurchaseOrder IN @lr_purchase_order
      INTO CORRESPONDING FIELDS OF TABLE @rt_text.

    SORT rt_text BY PurchaseOrder PurchaseOrderItem TextObjectType.

  ENDMETHOD.


  METHOD read_form_details.

    DATA lv_last_change TYPE i_purchaseorderapi01-YY1_IssuedDateTH_PDH.

    LOOP AT it_header INTO DATA(ls_header).

      APPEND INITIAL LINE TO rt_detail ASSIGNING FIELD-SYMBOL(<lfs_detail>).
      <lfs_detail>-PurchaseOrder = ls_header-PurchaseOrder.

      " ชื่อ ตำแหน่ง และวันที่ของผู้อนุมัติ
      zcl_get_approval_name=>get_data(
        EXPORTING iv_po_no         = ls_header-PurchaseOrder
        IMPORTING es_data_name     = <lfs_detail>-ApproverName
                  es_data_position = <lfs_detail>-ApproverPosition
                  es_data_date     = <lfs_detail>-ApprovalDateRaw ).

      " class คืนวันที่มาแบบดิบ ต้องแปลงเป็นวันที่ไทยด้วย class เดียวกับฟอร์มมาตรฐาน
      " iv_blank_date = X คือให้คืนเส้นประเมื่อยังไม่มีวันที่อนุมัติ
      zcl_conv_date_to_th=>get_data( EXPORTING iv_approval_date = <lfs_detail>-ApprovalDateRaw
                                               iv_blank_date    = 'X'
                                     IMPORTING es_approval_date = <lfs_detail>-ApprovalDateText ).

      " นามผู้รับสินค้าพร้อมเบอร์โทร และยอดรวมท้ายฟอร์มทั้งห้าช่อง
      zcl_get_other_detail=>get_data(
        EXPORTING iv_po_no            = ls_header-PurchaseOrder
        IMPORTING es_recipientcontact = <lfs_detail>-RecipientContact
                  es_recipienttel     = <lfs_detail>-RecipientTelephone
                  es_sumamount        = <lfs_detail>-SumAmount
                  es_sumnetamt        = <lfs_detail>-SumNetAmount
                  es_sumotherexpense  = <lfs_detail>-SumOtherExpense
                  es_sumtax           = <lfs_detail>-SumTax
                  es_sumtotalnetamt   = <lfs_detail>-SumTotalNetAmount ).

      compose_supplier_info( EXPORTING is_header = ls_header
                             CHANGING  cs_detail = <lfs_detail> ).

      " ชื่อภาษาไทยของผู้จัดทำ
      IF ls_header-CreatedByUser IS NOT INITIAL.
        zcl_get_fullname_th=>get_data( EXPORTING iv_createdby = ls_header-CreatedByUser
                                       IMPORTING es_nameth    = <lfs_detail>-PreparedByName ).
      ENDIF.

      " วันที่ออกเอกสารใช้วันที่แก้ไขล่าสุด ไม่ใช่วันที่ของใบสั่งซื้อ
      " เป็นกติกาเดียวกับฟอร์มมาตรฐาน
      IF ls_header-LastChangeDateTime IS NOT INITIAL.
        zcl_get_lastchange_po=>get_data( EXPORTING iv_lastchangedatetime = ls_header-LastChangeDateTime
                                         IMPORTING es_approval_date      = lv_last_change ).

        zcl_conv_date_to_th=>get_data( EXPORTING iv_approval_date = lv_last_change
                                                 iv_blank_date    = ''
                                       IMPORTING es_approval_date = <lfs_detail>-IssuedDateText ).
      ENDIF.

    ENDLOOP.

  ENDMETHOD.


  METHOD compose_supplier_info.

    DATA lv_room    TYPE string.
    DATA lv_floor   TYPE string.
    DATA ls_address TYPE zcl_get_address_form_bp=>gty_data_t.

    " ชื่อผู้ขายมาจากสี่บรรทัดของ business partner ต่อท้ายรหัสที่ตัดศูนย์นำหน้าแล้ว
    zcl_get_name_form_bp=>get_data( EXPORTING iv_businesspartner = is_header-Supplier
                                    IMPORTING es_data            = DATA(ls_name) ).

    IF ls_name IS NOT INITIAL.
      CONDENSE: ls_name-BusinessPartner,
                ls_name-OrganizationBPName1,
                ls_name-OrganizationBPName2,
                ls_name-OrganizationBPName3,
                ls_name-OrganizationBPName4.

      SHIFT ls_name-BusinessPartner LEFT DELETING LEADING '0'.

      CONCATENATE ls_name-BusinessPartner
                  ls_name-OrganizationBPName1
                  ls_name-OrganizationBPName2
                  ls_name-OrganizationBPName3
                  ls_name-OrganizationBPName4
             INTO cs_detail-SupplierCodeName SEPARATED BY space.
    ENDIF.

    IF is_header-ManualSupplierAddressID IS INITIAL.

      zcl_get_address_form_bp=>get_data( EXPORTING iv_businesspartner = is_header-Supplier
                                         IMPORTING es_data           = ls_address ).

    ELSE.

      " ใบที่พิมพ์ที่อยู่เอง ชื่อผู้ขายจะเป็นรหัสตามด้วยที่อยู่เต็มแทนชื่อจาก master
      zcl_get_address_form_onetime=>get_data(
        EXPORTING iv_supplieraddressid = is_header-ManualSupplierAddressID
                  iv_purchaseorder     = is_header-PurchaseOrder
        IMPORTING es_data              = ls_address ).

      CLEAR cs_detail-SupplierCodeName.
      CONCATENATE ls_name-BusinessPartner
                  ls_address-CompleteAddress
             INTO cs_detail-SupplierCodeName SEPARATED BY space.

    ENDIF.

    IF ls_address IS INITIAL.
      RETURN.
    ENDIF.

    " คำนำหน้าห้องและชั้นเปลี่ยนตามประเทศของที่อยู่
    IF ls_address-RoomNumber IS NOT INITIAL.
      lv_room  = COND #( WHEN ls_address-Country = 'TH' THEN `ห้อง` ELSE `Room` ).
      lv_room  = |{ lv_room } { ls_address-RoomNumber }|.
    ENDIF.

    IF ls_address-Floor IS NOT INITIAL.
      lv_floor = COND #( WHEN ls_address-Country = 'TH' THEN `ชั้น` ELSE `Floor` ).
      lv_floor = |{ lv_floor } { ls_address-Floor }|.
    ENDIF.

    CONDENSE: ls_address-HouseNumber,
              ls_address-StreetPrefixName,
              ls_address-StreetSuffixName,
              ls_address-Building,
              ls_address-AdditionalStreetPrefixName,
              ls_address-StreetName,
              ls_address-HomeCityName,
              ls_address-District,
              ls_address-CityName,
              ls_address-Region,
              ls_address-PostalCode,
              ls_address-AdditionalStreetSuffixName,
              lv_room,
              lv_floor.

    CONCATENATE ls_address-HouseNumber
                ls_address-StreetPrefixName
                ls_address-StreetSuffixName
                ls_address-Building
                lv_floor
                lv_room
                ls_address-AdditionalStreetPrefixName
                ls_address-StreetName
                ls_address-HomeCityName
                ls_address-District
                ls_address-CityName
                ls_address-Region
                ls_address-PostalCode
           INTO cs_detail-SupplierAddress SEPARATED BY space.

    CONDENSE cs_detail-SupplierAddress.

    " สาขาของผู้ขายต่อท้ายชื่อ
    IF ls_address-AdditionalStreetSuffixName IS NOT INITIAL.
      CONCATENATE cs_detail-SupplierCodeName
                  ls_address-AdditionalStreetSuffixName
             INTO cs_detail-SupplierCodeName SEPARATED BY space.
    ENDIF.

  ENDMETHOD.

ENDCLASS.
