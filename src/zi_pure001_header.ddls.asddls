@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Print PO - Header'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZI_PURE001_HEADER
  as select from I_PurchaseOrderAPI01 as Header

    left outer to one join ZI_PURE001_TOTAL as Total
      on Total.PurchaseOrder = Header.PurchaseOrder

    // TODO verify: ชื่อ text view ทั้ง 3 ตัวข้างล่าง — ถ้าตัวไหน activate ไม่ผ่าน
    // ให้ comment join นั้นกับ field ที่ใช้ออกก่อน คอลัมน์จะแสดงแค่รหัส ไม่กระทบอย่างอื่น
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

      // TODO verify: ที่มาของสถานะอนุมัติ — ตอนนี้ derive จาก ReleaseIsNotCompleted
      // ถ้าเจอ field/view ที่ถูกต้อง แก้แค่ 2 case นี้ ที่อื่นไม่ต้องแตะ
      case Header.ReleaseIsNotCompleted
        when 'X' then 'I'
        else          'A'
      end                                  as ApprovalStatus,

      case Header.ReleaseIsNotCompleted
        when 'X' then 'In Approval'
        else          'Approved'
      end                                  as ApprovalStatusText
}
