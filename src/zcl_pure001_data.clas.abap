CLASS zcl_pure001_data DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    TYPES ty_text_pattern TYPE c LENGTH 80.

    "! เงื่อนไขค้นหา PO — range ทุกตัว optional (ว่าง = ไม่กรอง)
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
          END OF ty_header,
          tt_header TYPE STANDARD TABLE OF ty_header WITH EMPTY KEY.

    "! PO item (รวม item ที่ลบ — ผู้เรียกกรองเอง) · Phase 2 จะเพิ่ม schedule / account assignment / tax rate
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

    "! รหัส Status = I_PurchasingDocumentStatus (ตรง standard app)
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


CLASS zcl_pure001_data IMPLEMENTATION.


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
      FIELDS Supplier, SupplierName
      FOR ALL ENTRIES IN @ct_header
      WHERE Supplier = @ct_header-Supplier
      INTO TABLE @DATA(lt_supplier).

    SELECT FROM I_PurchasingGroup
      FIELDS PurchasingGroup, PurchasingGroupName
      FOR ALL ENTRIES IN @ct_header
      WHERE PurchasingGroup = @ct_header-PurchasingGroup
      INTO TABLE @DATA(lt_pgroup).

    SELECT FROM I_CompanyCode
      FIELDS CompanyCode, CompanyCodeName
      FOR ALL ENTRIES IN @ct_header
      WHERE CompanyCode = @ct_header-CompanyCode
      INTO TABLE @DATA(lt_company).

    " doc type ทั้งชุด (15 ค่า) ไม่ต้อง FAE
    SELECT FROM I_PurchasingDocumentTypeText
      FIELDS PurchasingDocumentType, PurchasingDocumentTypeName
      WHERE PurchasingDocumentCategory = 'F'
      AND   Language                   = @sy-langu
      INTO TABLE @DATA(lt_potype).

    LOOP AT ct_header ASSIGNING FIELD-SYMBOL(<lfs_header>).
      <lfs_header>-SupplierName          = VALUE #( lt_supplier[ Supplier = <lfs_header>-Supplier ]-SupplierName OPTIONAL ).
      <lfs_header>-PurchasingGroupName   = VALUE #( lt_pgroup[ PurchasingGroup = <lfs_header>-PurchasingGroup ]-PurchasingGroupName OPTIONAL ).
      <lfs_header>-CompanyCodeName       = VALUE #( lt_company[ CompanyCode = <lfs_header>-CompanyCode ]-CompanyCodeName OPTIONAL ).
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

    SORT lt_follow_on.
    DELETE ADJACENT DUPLICATES FROM lt_follow_on.

    LOOP AT ct_header ASSIGNING FIELD-SYMBOL(<lfs_header>).
      <lfs_header>-HasFollowOnDocument = xsdbool( line_exists( lt_follow_on[ table_line = <lfs_header>-PurchaseOrder ] ) ).
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

ENDCLASS.
