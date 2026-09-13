@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Print Purchase Order - PO Follow-On Doc'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZI_PURE001_FOLLOWON
  as select from I_MaterialDocumentItem_2
{
  key PurchaseOrder
}
where
  PurchaseOrder <> ''

union

  select from I_SuplrInvcItemPurOrdRefAPI01
{
  key PurchaseOrder
}
where
  PurchaseOrder <> ''
