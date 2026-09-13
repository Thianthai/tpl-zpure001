@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Print Purchase Order - Purchasing Status'
@ObjectModel.resultSet.sizeCategory: #XS
@Search.searchable: true
define view entity ZI_PURE001_STATUS_VH
  as select from I_PurchasingDocumentStatusText
{
      @ObjectModel.text.element: ['PurchasingDocumentStatusName']
      @UI.textArrangement: #TEXT_ONLY
  key PurchasingDocumentStatus,

      @Search.defaultSearchElement: true
      PurchasingDocumentStatusName
}
where
      Language = $session.system_language
  and (
       PurchasingDocumentStatus = '01'   // Draft
    or PurchasingDocumentStatus = '02'   // In Approval
    or PurchasingDocumentStatus = '05'   // Follow-On Documents
    or PurchasingDocumentStatus = '08'   // Released
    or PurchasingDocumentStatus = '10'   // Deleted
    or PurchasingDocumentStatus = '27'   // Created
    or PurchasingDocumentStatus = '38'   // Rejected
  )
