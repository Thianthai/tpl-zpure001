@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Print PO - Header'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZI_PURE001_HEADER
  as select from I_PurchaseOrderAPI01 as Header

    left outer to one join ZI_PURE001_TOTAL as Total
      on Total.PurchaseOrder = Header.PurchaseOrder

    left outer to one join ZI_PURE001_FOLLOWON as FollowOn
      on FollowOn.PurchaseOrder = Header.PurchaseOrder

    left outer to one join ZI_PURE001_WORKFLOW as Workflow
      on Workflow.PurchaseOrder = Header.PurchaseOrder

    left outer to one join I_WorkflowStatusOverview as WorkflowStatus
      on WorkflowStatus.WorkflowInternalID = Workflow.WorkflowInternalID

    left outer to one join I_Supplier as Supplier
      on Supplier.Supplier = Header.Supplier

    left outer to one join I_PurchasingGroup as PurchasingGroup
      on PurchasingGroup.PurchasingGroup = Header.PurchasingGroup

    left outer to one join I_PurchasingDocumentTypeText as TypeText
      on  TypeText.PurchasingDocumentCategory = 'F'
      and TypeText.PurchasingDocumentType     = Header.PurchaseOrderType
      and TypeText.Language                   = $session.system_language
{
  key Header.PurchaseOrder,

      Header.PurchaseOrderType,
      TypeText.PurchasingDocumentTypeName  as PurchaseOrderTypeName,

      Header.CompanyCode,

      Header.PurchasingGroup,
      PurchasingGroup.PurchasingGroupName,

      Header.Supplier,
      Supplier.SupplierName,

      Header.PurchaseOrderDate,
      Header.CreationDate,

      Header.CorrespncInternalReference    as InternalReference,
      Header.CorrespncExternalReference    as ExternalReference,

      @Semantics.amount.currencyCode: 'DocumentCurrency'
      Total.NetOrderValue,

      Header.DocumentCurrency,

      //=== Status (filter "Status") — รหัสของ I_PurchasingDocumentStatus =============
      // ลำดับ case สำคัญ ตัวบน Priority สูงกว่าตัวล่าง · text มา join ใน ZCL_PURE001_QUERY
      // ข้อจำกัด: Sent / Not Yet Sent / Output Error รวมเป็น 08 Released
      // (source ของ output status ไม่ released — ดู docs/06-decisions.md)
      case
        when Header.PurchasingDocumentDeletionCode = 'L'
          then '10'                                           // Deleted
        when Header.PurchasingCompletenessStatus = 'X'
          then '01'                                           // Draft (ยังไม่ Order)
        when Header.PurchasingProcessingStatus = '08'
          then '38'                                           // Rejected
        when Header.PurchasingProcessingStatus = '03'
          or Header.PurchasingProcessingStatus = '04'
          or Header.PurchasingProcessingStatus = '26'
          then '02'                                           // In Approval
        when ( Header.PurchasingProcessingStatus = '02'
            or Header.PurchasingProcessingStatus = '05' )
          and FollowOn.PurchaseOrder is not null
          then '05'                                           // Follow-On Documents
        when Header.PurchasingProcessingStatus = '02'
          or Header.PurchasingProcessingStatus = '05'
          then '08'                                           // Released 
        else   '27'                                           // Created (01, 11-14)
      end                                  as PurchaseOrderStatus,

      //=== Approval Status (column "Approval Status") — ผลอนุมัติจาก PROCSTAT + flexible workflow ========
      // A = Approved · B = Approved automatically · I = In Approval · R = Rejected · '' = ไม่มี
      case
        when Header.PurchasingCompletenessStatus = 'X'
          then ''
        when Header.PurchasingProcessingStatus = '08'
          then 'R'
        when Header.PurchasingProcessingStatus = '03'
          or Header.PurchasingProcessingStatus = '04'
          or Header.PurchasingProcessingStatus = '26'
          then 'I'
        when WorkflowStatus.WorkflowExternalStatus = 'COMPLETED'
          and WorkflowStatus.NmbrOfCmpltdWrkflwDialogTasks = 0
          then 'B'
        when WorkflowStatus.WorkflowExternalStatus = 'COMPLETED'
          then 'A'
        else ''
      end                                  as ApprovalStatus,

      case
        when Header.PurchasingCompletenessStatus = 'X'
          then ''
        when Header.PurchasingProcessingStatus = '08'
          then 'Rejected'
        when Header.PurchasingProcessingStatus = '03'
          or Header.PurchasingProcessingStatus = '04'
          or Header.PurchasingProcessingStatus = '26'
          then 'In Approval'
        when WorkflowStatus.WorkflowExternalStatus = 'COMPLETED'
          and WorkflowStatus.NmbrOfCmpltdWrkflwDialogTasks = 0
          then 'Approved automatically'
        when WorkflowStatus.WorkflowExternalStatus = 'COMPLETED'
          then 'Approved'
        else ''
      end                                  as ApprovalStatusText,
      
      //=== Criticality สำหรับ icon/สีบน Fiori: 0 ไม่มี · 1 แดง · 2 เหลือง · 3 เขียว =====
      case
        when Header.PurchasingDocumentDeletionCode = 'L'  then 1   // Deleted
        when Header.PurchasingCompletenessStatus   = 'X'  then 0   // Draft
        when Header.PurchasingProcessingStatus     = '08' then 1   // Rejected
        when Header.PurchasingProcessingStatus     = '03'
          or Header.PurchasingProcessingStatus     = '04'
          or Header.PurchasingProcessingStatus     = '26' then 0   // In Approval
        when Header.PurchasingProcessingStatus     = '02'
          or Header.PurchasingProcessingStatus     = '05' then 3   // Follow-On / Released
        else 0                                                    // Created
      end                                  as PurchaseOrderStatusCriticality,

      case
        when Header.PurchasingCompletenessStatus = 'X'          then 0
        when Header.PurchasingProcessingStatus   = '08'         then 1   // Rejected
        when Header.PurchasingProcessingStatus   = '03'
          or Header.PurchasingProcessingStatus   = '04'
          or Header.PurchasingProcessingStatus   = '26'         then 0   // In Approval
        when WorkflowStatus.WorkflowExternalStatus = 'COMPLETED' then 3  // Approved / automatically
        else 0
      end                                  as ApprovalStatusCriticality
}
