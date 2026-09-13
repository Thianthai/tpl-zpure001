@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Print Purchase Order - Purchasing Type'
@ObjectModel.resultSet.sizeCategory: #XS
@Search.searchable: true
define view entity ZI_PURE001_POTYPE_VH
  as select from I_PurchasingDocumentTypeText
{
      @ObjectModel.text.element: ['PurchasingDocumentTypeName']
      @UI.textArrangement: #TEXT_FIRST
  key PurchasingDocumentType,

      @Search.defaultSearchElement: true
      PurchasingDocumentTypeName
}
where
      PurchasingDocumentCategory = 'F'   // เฉพาะ PO — NB มีทั้ง F (PO) และ B (PR)
  and Language                   = $session.system_language
