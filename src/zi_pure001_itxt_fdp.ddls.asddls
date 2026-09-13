@EndUserText.label: 'Print Purchase Order - FDP Item Text'
@ObjectModel.query.implementedBy: 'ABAP:ZCL_PURE001_FDP'
@ObjectModel.supportedCapabilities: [ #OUTPUT_FORM_DATA_PROVIDER ]
define custom entity ZI_PURE001_ITXT_FDP
{
  key PurchaseOrder     : ebeln;
  key PurchaseOrderItem : abap.char(5);
  key TextSequence      : abap.int4;


      TextObjectType    : abap.char(4);
      TextTypeName      : abap.char(40);
      Text              : abap.string;

      _Item             : association to parent ZI_PURE001_ITEM_FDP
                            on  _Item.PurchaseOrder     = $projection.PurchaseOrder
                            and _Item.PurchaseOrderItem = $projection.PurchaseOrderItem;
}
