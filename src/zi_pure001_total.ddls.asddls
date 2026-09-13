@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Print PO - PO Net Order Value'
define view entity ZI_PURE001_TOTAL
  as select from I_PurchaseOrderItemAPI01
{
  key PurchaseOrder,

      @Semantics.amount.currencyCode: 'DocumentCurrency'
      sum( NetAmount )   as NetOrderValue,        // TODO verify: ชื่อ field ยอดสุทธิระดับ item

      DocumentCurrency                            // TODO verify: มี field นี้บน item view ไหม
}
where
  PurchasingDocumentDeletionCode <> 'L'   // ไม่นับ item ที่ลบ — ตรง Net Order Value ของ standard
group by
  PurchaseOrder,
  DocumentCurrency
