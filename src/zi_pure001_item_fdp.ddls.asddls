@EndUserText.label: 'Print Purchase Order - FDP Item'
@ObjectModel.query.implementedBy: 'ABAP:ZCL_PURE001_FDP'
@ObjectModel.supportedCapabilities: [ #OUTPUT_FORM_DATA_PROVIDER ]
define custom entity ZI_PURE001_ITEM_FDP
{
  key PurchaseOrder              : ebeln;
  key PurchaseOrderItem          : abap.char(5);


      ItemNumber                 : abap.int4;
      Material                   : matnr;
      MaterialDescription        : abap.char(40);
      ItemDescription            : abap.char(80);
      ItemDescriptionText        : abap.string;     // ช่อง "รายการ" ทั้งช่อง หลายบรรทัด (ประกอบใน ABAP)
      @Semantics.quantity.unitOfMeasure : 'Unit'
      Quantity                   : abap.quan(13,3);
      QuantityText               : abap.char(20);
      @Semantics.unitOfMeasure   : true
      Unit                       : abap.unit(3);
      UnitText                   : abap.char(3);
      @Semantics.currencyCode    : true
      DocumentCurrency           : waers;
      @Semantics.amount.currencyCode : 'DocumentCurrency'
      NetPriceAmount             : abap.curr(11,2);
      NetPriceQuantity           : abap.dec(5,0);
      @Semantics.amount.currencyCode : 'DocumentCurrency'
      ItemAmount                 : abap.curr(16,2);
      TaxCode                    : abap.char(2);
      TaxRate                    : abap.dec(5,2);
      @Semantics.amount.currencyCode : 'DocumentCurrency'
      TaxAmount                  : abap.curr(16,2);
      DeliveryDate               : abap.dats;
      DeliveryDateText           : abap.char(40);
      PerformancePeriodStartDate : abap.dats;
      PerformancePeriodEndDate   : abap.dats;
      PurchaseRequisition        : abap.char(10);
      GLAccount                  : abap.char(10);
      CostCenter                 : abap.char(10);
      OrderID                    : abap.char(12);
      WBSElement                 : abap.char(24);
      AccountAssignmentText      : abap.char(120);
      Plant                      : werks_d;

      _ItemText                  : composition of exact one to many ZI_PURE001_ITXT_FDP;
      _PurchaseOrder             : association to parent ZR_PURE001_FDP
                                     on _PurchaseOrder.PurchaseOrder = $projection.PurchaseOrder;
}
