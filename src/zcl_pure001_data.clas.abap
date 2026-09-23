CLASS zcl_pure001_data DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    TYPES ty_text_pattern TYPE c LENGTH 80.

    " เงื่อนไขค้นหา PO — range ทุกตัว optional (ว่าง = ไม่กรอง)
    TYPES:
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

    "! PO header + status / approval / ยอดรวม — field ชุดแรกชื่อเดียวกับ ZR_PURE001 (CORRESPONDING ได้ตรง ๆ)
    "! + field เพิ่มที่ฟอร์มต้องใช้
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

            "--- เพิ่มสำหรับฟอร์ม (Phase 2) ---
            CompanyTaxNumber               TYPE i_companycode-VATRegistration,
            CompanyCountry                 TYPE i_companycode-Country,
            SupplierTaxNumber              TYPE i_supplier-TaxNumber3,
            SupplierName1                  TYPE i_supplier-BusinessPartnerName1,
            SupplierName2                  TYPE i_supplier-BusinessPartnerName2,
            SupplierStreet                 TYPE i_supplier-StreetName,
            SupplierDistrict               TYPE i_supplier-DistrictName,
            SupplierCity                   TYPE i_supplier-CityName,
            SupplierPostalCode             TYPE i_supplier-PostalCode,
            SupplierMasterPhone            TYPE i_supplier-PhoneNumber1,
            PaymentTermsText               TYPE i_paymenttermstext-PaymentTermsDescription,
          END OF ty_header,
          tt_header TYPE STANDARD TABLE OF ty_header WITH EMPTY KEY.

    " PO item (รวม item ที่ลบ — ผู้เรียกกรองเอง) · Phase 2 จะเพิ่ม schedule / account assignment / tax rate
    TYPES:
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
      BEGIN OF ty_po_key,
        PurchaseOrder TYPE zr_pure001-PurchaseOrder,
      END OF ty_po_key,
      tt_po_key TYPE STANDARD TABLE OF ty_po_key WITH EMPTY KEY.

    " schedule line แรก (0001) ของ item — วันส่ง / PR / performance period
    TYPES:
      BEGIN OF ty_schedule_line,
        PurchaseOrder              TYPE i_purordschedulelineapi01-PurchaseOrder,
        PurchaseOrderItem          TYPE i_purordschedulelineapi01-PurchaseOrderItem,
        ScheduleLineDeliveryDate   TYPE i_purordschedulelineapi01-ScheduleLineDeliveryDate,
        PerformancePeriodStartDate TYPE i_purordschedulelineapi01-PerformancePeriodStartDate,
        PerformancePeriodEndDate   TYPE i_purordschedulelineapi01-PerformancePeriodEndDate,
        PurchaseRequisition        TYPE i_purordschedulelineapi01-PurchaseRequisition,
        PurchaseRequisitionItem    TYPE i_purordschedulelineapi01-PurchaseRequisitionItem,
      END OF ty_schedule_line,
      tt_schedule_line TYPE STANDARD TABLE OF ty_schedule_line WITH EMPTY KEY.

    " account assignment แรก (01) ของ item + WBS external ID
    TYPES:
      BEGIN OF ty_account_assignment,
        PurchaseOrder         TYPE i_purordaccountassignmentapi01-PurchaseOrder,
        PurchaseOrderItem     TYPE i_purordaccountassignmentapi01-PurchaseOrderItem,
        GLAccount             TYPE i_purordaccountassignmentapi01-GLAccount,
        CostCenter            TYPE i_purordaccountassignmentapi01-CostCenter,
        OrderID               TYPE i_purordaccountassignmentapi01-OrderID,
        WBSElementInternalID  TYPE i_purordaccountassignmentapi01-WBSElementInternalID_2,
        WBSElement            TYPE i_enterpriseprojectelement-ProjectElement,
        GoodsRecipientName    TYPE i_purordaccountassignmentapi01-GoodsRecipientName,
        UnloadingPointName    TYPE i_purordaccountassignmentapi01-UnloadingPointName,
      END OF ty_account_assignment,
      tt_account_assignment TYPE STANDARD TABLE OF ty_account_assignment WITH EMPTY KEY.

    " อัตราภาษี input tax (MWVS) ต่อ tax code ที่มีผลวันนี้
    TYPES:
      BEGIN OF ty_tax_rate,
        TaxCode TYPE i_taxcoderate-TaxCode,
        TaxRate TYPE i_taxcoderate-ConditionRateRatio,
      END OF ty_tax_rate,
      tt_tax_rate TYPE STANDARD TABLE OF ty_tax_rate WITH EMPTY KEY.

    " text ของ PO header (item ว่าง) / item — จาก projection view (อ่านได้เฉพาะ ABAP SQL)
    TYPES:
      BEGIN OF ty_text,
        PurchaseOrder     TYPE i_purchaseorderitemnotetp_2-PurchaseOrder,
        PurchaseOrderItem TYPE i_purchaseorderitemnotetp_2-PurchaseOrderItem,
        TextObjectType    TYPE i_purchaseorderitemnotetp_2-TextObjectType,
        Language          TYPE i_purchaseorderitemnotetp_2-Language,
        PlainLongText     TYPE i_purchaseorderitemnotetp_2-PlainLongText,
      END OF ty_text,
      tt_text TYPE STANDARD TABLE OF ty_text WITH EMPTY KEY.

    " ผู้อนุมัติ = คนกด RELEASED ล่าสุดใน workflow ล่าสุด (ไม่มีแถว = approved automatically / ยังไม่อนุมัติ)
    TYPES:
      BEGIN OF ty_approver,
        PurchaseOrder    TYPE zr_pure001-PurchaseOrder,
        ApprovedByUser   TYPE i_workflowstatusdetails-WorkflowTaskProcessor,
        ApprovedByName   TYPE i_businessuserbasic-PersonFullName,
        ApprovedDateTime TYPE i_workflowstatusdetails-WrkflwTskCompletionUTCDateTime,
      END OF ty_approver,
      tt_approver TYPE STANDARD TABLE OF ty_approver WITH EMPTY KEY.

    TYPES:
      BEGIN OF ty_user_name,
        UserID         TYPE i_businessuserbasic-UserID,
        PersonFullName TYPE i_businessuserbasic-PersonFullName,
      END OF ty_user_name,
      tt_user_name TYPE STANDARD TABLE OF ty_user_name WITH EMPTY KEY.

    METHODS read_schedule_lines
      IMPORTING it_purchase_order        TYPE tt_po_key
      RETURNING VALUE(rt_schedule_line)  TYPE tt_schedule_line.

    METHODS read_account_assignments
      IMPORTING it_purchase_order             TYPE tt_po_key
      RETURNING VALUE(rt_account_assignment)  TYPE tt_account_assignment.

    METHODS read_tax_rates
      IMPORTING iv_country         TYPE i_companycode-Country
      RETURNING VALUE(rt_tax_rate) TYPE tt_tax_rate.

    METHODS read_header_texts
      IMPORTING it_purchase_order TYPE tt_po_key
      RETURNING VALUE(rt_text)    TYPE tt_text.

    METHODS read_item_texts
      IMPORTING it_purchase_order TYPE tt_po_key
      RETURNING VALUE(rt_text)    TYPE tt_text.

    METHODS read_approvers
      IMPORTING it_header          TYPE tt_header
      RETURNING VALUE(rt_approver) TYPE tt_approver.

    METHODS read_user_names
      IMPORTING it_user             TYPE tt_user_name
      RETURNING VALUE(rt_user_name) TYPE tt_user_name.

    " รหัส Status = I_PurchasingDocumentStatus (ตรง standard app)
    CONSTANTS:
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
        active            TYPE c LENGTH 2 VALUE '02',
        in_release        TYPE c LENGTH 2 VALUE '03',
        partially_released TYPE c LENGTH 2 VALUE '04',
        release_completed TYPE c LENGTH 2 VALUE '05',
        rejected          TYPE c LENGTH 2 VALUE '08',
        external_approval TYPE c LENGTH 2 VALUE '26',
      END OF gc_procstat.

    "! อ่าน PO header ตามเงื่อนไข พร้อม derive status / approval / ยอดรวม / follow-on
    METHODS read_headers
      IMPORTING is_selection     TYPE ty_selection
      RETURNING VALUE(rt_header) TYPE tt_header.

    "! อ่าน item ของ PO ที่ระบุ (รวม item ที่ลบ) เรียงตาม PO / item
    METHODS read_items
      IMPORTING it_purchase_order TYPE tt_po_key
      RETURNING VALUE(rt_item)    TYPE tt_item.

  PROTECTED SECTION.
  PRIVATE SECTION.

    METHODS enrich_master_texts CHANGING ct_header TYPE tt_header.
    METHODS enrich_totals       CHANGING ct_header TYPE tt_header.
    METHODS enrich_follow_on    CHANGING ct_header TYPE tt_header.
    METHODS enrich_workflow     CHANGING ct_header TYPE tt_header.
    METHODS derive_status       CHANGING ct_header TYPE tt_header.

ENDCLASS.



CLASS ZCL_PURE001_DATA IMPLEMENTATION.


  METHOD read_headers.

    " Material / Plant / item text อยู่ระดับ item → EXISTS (semi-join) ไม่ให้แถวบาน · รวม item ที่ลบ (ตาม standard)
    SELECT FROM I_PurchaseOrderAPI01 AS po
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
             po~PurchasingDocumentDeletionCode
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

    enrich_master_texts( CHANGING ct_header = rt_header ).
    enrich_totals(       CHANGING ct_header = rt_header ).
    enrich_follow_on(    CHANGING ct_header = rt_header ).
    enrich_workflow(     CHANGING ct_header = rt_header ).
    derive_status(       CHANGING ct_header = rt_header ).

  ENDMETHOD.


  METHOD enrich_master_texts.

    SELECT FROM I_Supplier
      FIELDS Supplier, SupplierName, TaxNumber3,
             BusinessPartnerName1, BusinessPartnerName2,
             StreetName, DistrictName, CityName, PostalCode, PhoneNumber1
      FOR ALL ENTRIES IN @ct_header
      WHERE Supplier = @ct_header-Supplier
      INTO TABLE @DATA(lt_supplier).

    SELECT FROM I_PurchasingGroup
      FIELDS PurchasingGroup, PurchasingGroupName
      FOR ALL ENTRIES IN @ct_header
      WHERE PurchasingGroup = @ct_header-PurchasingGroup
      INTO TABLE @DATA(lt_pgroup).

    SELECT FROM I_CompanyCode
      FIELDS CompanyCode, CompanyCodeName, VATRegistration, Country
      FOR ALL ENTRIES IN @ct_header
      WHERE CompanyCode = @ct_header-CompanyCode
      INTO TABLE @DATA(lt_company).

    SELECT FROM I_PurchasingDocumentTypeText
      FIELDS PurchasingDocumentType, PurchasingDocumentTypeName
      WHERE PurchasingDocumentCategory = 'F'
      AND   Language                   = @sy-langu
      INTO TABLE @DATA(lt_potype).

    " payment terms text ภาษาของ PO — Description ก่อน ถ้าว่างใช้ Name
    SELECT FROM I_PaymentTermsText
      FIELDS PaymentTerms, Language, PaymentTermsName, PaymentTermsDescription
      FOR ALL ENTRIES IN @ct_header
      WHERE PaymentTerms = @ct_header-PaymentTerms
      AND   Language     = @ct_header-Language
      INTO TABLE @DATA(lt_payment_terms).

    LOOP AT ct_header ASSIGNING FIELD-SYMBOL(<lfs_header>).

      ASSIGN lt_supplier[ Supplier = <lfs_header>-Supplier ] TO FIELD-SYMBOL(<lfs_supplier>).
      IF sy-subrc = 0.
        <lfs_header>-SupplierName        = <lfs_supplier>-SupplierName.
        <lfs_header>-SupplierTaxNumber   = <lfs_supplier>-TaxNumber3.
        <lfs_header>-SupplierName1       = <lfs_supplier>-BusinessPartnerName1.
        <lfs_header>-SupplierName2       = <lfs_supplier>-BusinessPartnerName2.
        <lfs_header>-SupplierStreet      = <lfs_supplier>-StreetName.
        <lfs_header>-SupplierDistrict    = <lfs_supplier>-DistrictName.
        <lfs_header>-SupplierCity        = <lfs_supplier>-CityName.
        <lfs_header>-SupplierPostalCode  = <lfs_supplier>-PostalCode.
        <lfs_header>-SupplierMasterPhone = <lfs_supplier>-PhoneNumber1.
      ENDIF.

      ASSIGN lt_company[ CompanyCode = <lfs_header>-CompanyCode ] TO FIELD-SYMBOL(<lfs_company>).
      IF sy-subrc = 0.
        <lfs_header>-CompanyCodeName  = <lfs_company>-CompanyCodeName.
        <lfs_header>-CompanyTaxNumber = <lfs_company>-VATRegistration.
        <lfs_header>-CompanyCountry   = <lfs_company>-Country.
      ENDIF.

      ASSIGN lt_payment_terms[ PaymentTerms = <lfs_header>-PaymentTerms
                               Language     = <lfs_header>-Language ] TO FIELD-SYMBOL(<lfs_terms>).
      IF sy-subrc = 0.
        <lfs_header>-PaymentTermsText = COND #( WHEN <lfs_terms>-PaymentTermsDescription IS NOT INITIAL
                                                THEN <lfs_terms>-PaymentTermsDescription
                                                ELSE <lfs_terms>-PaymentTermsName ).
      ENDIF.

      <lfs_header>-PurchasingGroupName   = VALUE #( lt_pgroup[ PurchasingGroup = <lfs_header>-PurchasingGroup ]-PurchasingGroupName OPTIONAL ).
      <lfs_header>-PurchaseOrderTypeName = VALUE #( lt_potype[ PurchasingDocumentType = <lfs_header>-PurchaseOrderType ]-PurchasingDocumentTypeName OPTIONAL ).
    ENDLOOP.

  ENDMETHOD.


  METHOD enrich_totals.

    " ยอดรวมทั้งใบ ไม่นับ item ที่ลบ (ตรง Net Order Value ของ standard) — FAE ใช้กับ GROUP BY ไม่ได้ จึงรวมใน ABAP
    SELECT FROM I_PurchaseOrderItemAPI01
      FIELDS PurchaseOrder, NetAmount
      FOR ALL ENTRIES IN @ct_header
      WHERE PurchaseOrder                  = @ct_header-PurchaseOrder
      AND   PurchasingDocumentDeletionCode <> 'L'
      INTO TABLE @DATA(lt_item_amount).

    TYPES: BEGIN OF ty_total,
             PurchaseOrder TYPE zr_pure001-PurchaseOrder,
             NetAmount     TYPE zr_pure001-NetOrderValue,
           END OF ty_total.

    DATA lt_total TYPE STANDARD TABLE OF ty_total WITH NON-UNIQUE KEY PurchaseOrder.

    LOOP AT lt_item_amount ASSIGNING FIELD-SYMBOL(<lfs_amount>).
      COLLECT VALUE ty_total( PurchaseOrder = <lfs_amount>-PurchaseOrder
                              NetAmount     = <lfs_amount>-NetAmount ) INTO lt_total.
    ENDLOOP.

    LOOP AT ct_header ASSIGNING FIELD-SYMBOL(<lfs_header>).
      <lfs_header>-NetOrderValue = VALUE #( lt_total[ PurchaseOrder = <lfs_header>-PurchaseOrder ]-NetAmount OPTIONAL ).
    ENDLOOP.

  ENDMETHOD.


  METHOD enrich_follow_on.

    " มี GR หรือ IR อ้างถึง PO = Follow-On Documents (นับทุก doc ไม่กรอง reverse ตาม standard)
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

    " FAE ต้องใช้ field type เดียวกัน → แปลง PO (char 10) เป็น type ของ SAPBusinessObjectNodeKey1 ก่อน
    TYPES: BEGIN OF ty_wf_key,
             SAPBusinessObjectNodeKey1 TYPE i_workflowstatusoverview-SAPBusinessObjectNodeKey1,
           END OF ty_wf_key,
           tt_wf_key TYPE STANDARD TABLE OF ty_wf_key WITH EMPTY KEY.

    DATA(lt_wf_key) = VALUE tt_wf_key( FOR ls_header IN ct_header
                                       ( SAPBusinessObjectNodeKey1 = ls_header-PurchaseOrder ) ).

    " workflow instance ทั้งหมดของ PO → เอาตัวล่าสุด (ID สูงสุด) — PO ถูกแก้แล้ว restart ได้หลายรอบ
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

    " ชื่อ status ภาษาปัจจุบันจาก standard (33 code, ใช้ 7)
    SELECT FROM I_PurchasingDocumentStatusText
      FIELDS PurchasingDocumentStatus, PurchasingDocumentStatusName
      WHERE Language = @sy-langu
      INTO TABLE @DATA(lt_status_text).

    LOOP AT ct_header ASSIGNING FIELD-SYMBOL(<lfs_header>).

      DATA(lv_procstat) = <lfs_header>-PurchasingProcessingStatus.
      DATA(lv_in_approval) = xsdbool( lv_procstat = gc_procstat-in_release
                                   OR lv_procstat = gc_procstat-partially_released
                                   OR lv_procstat = gc_procstat-external_approval ).
      DATA(lv_ordered)     = xsdbool( lv_procstat = gc_procstat-active
                                   OR lv_procstat = gc_procstat-release_completed ).

      "--- Status (filter) — ลำดับสำคัญ ตัวบนชนะตัวล่าง (D5) -------------------------
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

      "--- Approval Status (คอลัมน์) — PROCSTAT ก่อน แล้วค่อยดู workflow (D6) ----------
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
      FIELDS PurchaseOrder, PurchaseOrderItem, ScheduleLineDeliveryDate,
             PerformancePeriodStartDate, PerformancePeriodEndDate,
             PurchaseRequisition, PurchaseRequisitionItem
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
      FIELDS PurchaseOrder, PurchaseOrderItem, GLAccount, CostCenter, OrderID,
             WBSElementInternalID_2 AS WBSElementInternalID,
             GoodsRecipientName, UnloadingPointName
      FOR ALL ENTRIES IN @it_purchase_order
      WHERE PurchaseOrder           = @it_purchase_order-PurchaseOrder
      AND   AccountAssignmentNumber = '01'
      INTO CORRESPONDING FIELDS OF TABLE @rt_account_assignment.

    " WBS internal → external (C-2025-054) ผ่าน Enterprise Project
    DATA(lt_wbs_key) = VALUE tt_account_assignment( FOR ls_aa IN rt_account_assignment
                                                    WHERE ( WBSElementInternalID IS NOT INITIAL )
                                                    ( WBSElementInternalID = ls_aa-WBSElementInternalID ) ).
    IF lt_wbs_key IS INITIAL.
      RETURN.
    ENDIF.

    SELECT FROM I_EnterpriseProjectElement
      FIELDS WBSElementInternalID, ProjectElement                       " TODO verify: ชื่อ field
      FOR ALL ENTRIES IN @lt_wbs_key
      WHERE WBSElementInternalID = @lt_wbs_key-WBSElementInternalID
      INTO TABLE @DATA(lt_wbs).

    LOOP AT rt_account_assignment ASSIGNING FIELD-SYMBOL(<lfs_aa>) WHERE WBSElementInternalID IS NOT INITIAL.
      <lfs_aa>-WBSElement = VALUE #( lt_wbs[ WBSElementInternalID = <lfs_aa>-WBSElementInternalID ]-ProjectElement OPTIONAL ).
    ENDLOOP.

  ENDMETHOD.


  METHOD read_tax_rates.

    DATA(lv_today) = cl_abap_context_info=>get_system_date( ).

    " input tax (V) condition MWVS ประเทศของ company code ช่วงที่มีผลวันนี้ → 1 แถวต่อ tax code
    SELECT FROM I_TaxCodeRate
      FIELDS TaxCode, ConditionRateRatio AS TaxRate
      WHERE Country                    = @iv_country
      AND   TaxType                    = 'V'
      AND   VATConditionType           = 'MWVS'
      AND   CndnRecordValidityStartDate <= @lv_today
      AND   CndnRecordValidityEndDate   >= @lv_today
      INTO CORRESPONDING FIELDS OF TABLE @rt_tax_rate.

  ENDMETHOD.


  METHOD read_header_texts.

    IF it_purchase_order IS INITIAL.
      RETURN.
    ENDIF.

    " STRING column ใช้กับ FAE ไม่ได้ (implicit DISTINCT) → ใช้ range แทน (พิมพ์ทีละไม่กี่ใบ)
    DATA(lr_purchase_order) = VALUE ty_selection-purchase_order(
      FOR ls_key IN it_purchase_order ( sign = 'I' option = 'EQ' low = ls_key-PurchaseOrder ) ).

    " F01 Header Text · F02 Header Note · F06 Shipping Instructions (จัดส่งโดย)
    SELECT FROM I_PurchaseOrderNoteTP_2
      FIELDS PurchaseOrder, TextObjectType, Language, PlainLongText
      WHERE PurchaseOrder IN @lr_purchase_order
      INTO CORRESPONDING FIELDS OF TABLE @rt_text.

  ENDMETHOD.


  METHOD read_item_texts.

    IF it_purchase_order IS INITIAL.
      RETURN.
    ENDIF.

    DATA(lr_purchase_order) = VALUE ty_selection-purchase_order(
      FOR ls_key IN it_purchase_order ( sign = 'I' option = 'EQ' low = ls_key-PurchaseOrder ) ).

    " F03 Material PO Text · F01 Item Text · F04 Delivery Text
    SELECT FROM I_PurchaseOrderItemNoteTP_2
      FIELDS PurchaseOrder, PurchaseOrderItem, TextObjectType, Language, PlainLongText
      WHERE PurchaseOrder IN @lr_purchase_order
      INTO CORRESPONDING FIELDS OF TABLE @rt_text.

    SORT rt_text BY PurchaseOrder PurchaseOrderItem TextObjectType.

  ENDMETHOD.


  METHOD read_approvers.

    " เฉพาะ PO ที่มี workflow instance
    DATA(lt_workflow) = VALUE tt_header( FOR ls_h IN it_header WHERE ( WorkflowInternalID IS NOT INITIAL ) ( ls_h ) ).
    IF lt_workflow IS INITIAL.
      RETURN.
    ENDIF.

    SELECT FROM I_WorkflowStatusDetails
      FIELDS WorkflowInternalID, WorkflowTaskInternalID, WorkflowTaskProcessor, WrkflwTskCompletionUTCDateTime
      FOR ALL ENTRIES IN @lt_workflow
      WHERE WorkflowInternalID         = @lt_workflow-WorkflowInternalID
      AND   WorkflowTaskResult         = 'RELEASED'
      AND   WorkflowTaskExternalStatus = 'COMPLETED'
      INTO TABLE @DATA(lt_task).

    " task RELEASED ล่าสุดต่อ workflow
    SORT lt_task BY WorkflowInternalID ASCENDING WorkflowTaskInternalID DESCENDING.
    DELETE ADJACENT DUPLICATES FROM lt_task COMPARING WorkflowInternalID.

    LOOP AT lt_workflow ASSIGNING FIELD-SYMBOL(<lfs_header>).
      ASSIGN lt_task[ WorkflowInternalID = <lfs_header>-WorkflowInternalID ] TO FIELD-SYMBOL(<lfs_task>).
      IF sy-subrc = 0.
        APPEND VALUE #( PurchaseOrder    = <lfs_header>-PurchaseOrder
                        ApprovedByUser   = <lfs_task>-WorkflowTaskProcessor
                        ApprovedDateTime = <lfs_task>-WrkflwTskCompletionUTCDateTime ) TO rt_approver.
      ENDIF.
    ENDLOOP.

    IF rt_approver IS INITIAL.
      RETURN.
    ENDIF.

    DATA(lt_user) = read_user_names( VALUE #( FOR ls_a IN rt_approver ( UserID = ls_a-ApprovedByUser ) ) ).

    LOOP AT rt_approver ASSIGNING FIELD-SYMBOL(<lfs_approver>).
      <lfs_approver>-ApprovedByName = VALUE #( lt_user[ UserID = <lfs_approver>-ApprovedByUser ]-PersonFullName OPTIONAL ).
    ENDLOOP.

  ENDMETHOD.


  METHOD read_user_names.

    IF it_user IS INITIAL.
      RETURN.
    ENDIF.

    SELECT FROM I_BusinessUserBasic
      FIELDS UserID, PersonFullName
      FOR ALL ENTRIES IN @it_user
      WHERE UserID = @it_user-UserID
      INTO TABLE @rt_user_name.

  ENDMETHOD.
ENDCLASS.
