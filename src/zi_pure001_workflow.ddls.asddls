@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Print Purchase Order - PO Workflow'
define view entity ZI_PURE001_WORKFLOW
  as select from I_WorkflowStatusOverview
{
      // PO 1 ใบมี workflow ได้หลาย instance (แก้ PO แล้ว restart) → เอา ID สูงสุด = ล่าสุด
  key SAPBusinessObjectNodeKey1   as PurchaseOrder,
      max( WorkflowInternalID )   as WorkflowInternalID
}
where
  SAPObjectNodeRepresentation = 'PurchaseOrder'
group by
  SAPBusinessObjectNodeKey1
