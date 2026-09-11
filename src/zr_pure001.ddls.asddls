@EndUserText.label: 'Print Purchase Order'
@ObjectModel.query.implementedBy: 'ABAP:ZCL_PURE001_QUERY'
@Search.searchable: true
@UI.headerInfo: { typeName      : 'Purchase Order',
                  typeNamePlural: 'Purchase Orders',
                  title         : { type: #STANDARD, value: 'PurchaseOrder' } }
define root custom entity ZR_PURE001
{
      //=== Key ===============================================================
      @EndUserText.label               : 'Purchase Order'
      @UI.selectionField               : [{ position: 30 }]
      @UI.lineItem                     : [{ position: 30, importance: #HIGH }]
      @Search.defaultSearchElement     : true
  key PurchaseOrder                    : ebeln;

      //=== Document type =====================================================
      @EndUserText.label               : 'Purchasing Doc. Type'
      @UI.selectionField               : [{ position: 120 }]
      @UI.lineItem                     : [{ position: 10, importance: #HIGH }]
      @UI.textArrangement              : #TEXT_FIRST
      @ObjectModel.text.element        : ['PurchaseOrderTypeName']
      PurchaseOrderType                : ze_bsart;

      @UI.hidden                       : true
      @Semantics.text                  : true
      PurchaseOrderTypeName            : abap.char(20);

      //=== References ========================================================
      @EndUserText.label               : 'Our Reference'
      @UI.selectionField               : [{ position: 100 }]
      @UI.lineItem                     : [{ position: 20 }]
      @Search.defaultSearchElement     : true
      InternalReference                : abap.char(12);

      @EndUserText.label               : 'Your Reference'
      @UI.selectionField               : [{ position: 110 }]
      @UI.hidden                       : true
      @Search.defaultSearchElement     : true
      ExternalReference                : abap.char(12);

      //=== Supplier ==========================================================
      @EndUserText.label               : 'Supplier'
      @UI.selectionField               : [{ position: 20 }]
      @UI.lineItem                     : [{ position: 40, importance: #HIGH }]
      @UI.textArrangement              : #TEXT_FIRST
      @ObjectModel.text.element        : ['SupplierName']
      Supplier                         : lifnr;

      @UI.hidden                       : true
      @Semantics.text                  : true
      @Search.defaultSearchElement     : true
      SupplierName                     : abap.char(80);

      //=== Organization ======================================================
      @EndUserText.label               : 'Company Code'
      @UI.selectionField               : [{ position: 50 }]
      @Consumption.filter.mandatory    : true
      @Consumption.valueHelpDefinition : [{ entity: { name: 'I_CompanyCodeVH', element: 'CompanyCode' } }]
      @UI.hidden                       : true
      CompanyCode                      : bukrs;

      @EndUserText.label               : 'Purchasing Group'
      @UI.selectionField               : [{ position: 40 }]
      @UI.lineItem                     : [{ position: 80 }]
      @UI.textArrangement              : #TEXT_FIRST
      @ObjectModel.text.element        : ['PurchasingGroupName']
      PurchasingGroup                  : ekgrp;

      @UI.hidden                       : true
      @Semantics.text                  : true
      PurchasingGroupName              : abap.char(18);

      //=== Item-level filter (filter อย่างเดียว ไม่แสดงในตาราง) ================
      // query class ใช้ EXISTS: "PO ใบนี้มี item ที่ตรงเงื่อนไขอย่างน้อย 1 รายการ"
      @EndUserText.label               : 'Material'
      @UI.selectionField               : [{ position: 70 }]
      @UI.hidden                       : true
      Material                         : matnr;

      @EndUserText.label               : 'Plant'
      @UI.selectionField               : [{ position: 80 }]
      @UI.hidden                       : true
      Plant                            : werks_d;

      //=== Item-level display (ประกอบใน ABAP จากทุก item ของใบ) ===============
      @EndUserText.label               : 'Material'
      @UI.lineItem                     : [{ position: 100, importance: #LOW }]
      MaterialList                     : abap.char(1000);

      @EndUserText.label               : 'Plant'
      @UI.lineItem                     : [{ position: 110, importance: #LOW }]
      PlantList                        : abap.char(255);

      //=== Dates =============================================================
      @EndUserText.label               : 'Purchase Order Date'
      @UI.selectionField               : [{ position: 90 }]
      @UI.lineItem                     : [{ position: 50 }]
      @Consumption.filter.selectionType: #INTERVAL
      PurchaseOrderDate                : abap.dats;

      @EndUserText.label               : 'Created On'
      @UI.selectionField               : [{ position: 130 }]
      @UI.lineItem                     : [{ position: 90 }]
      @Consumption.filter.selectionType: #INTERVAL
      CreationDate                     : abap.dats;

      //=== Amount ============================================================
      @EndUserText.label               : 'Net Order Value'
      @UI.lineItem                     : [{ position: 60, importance: #HIGH }]
      @Semantics.amount.currencyCode   : 'DocumentCurrency'
      NetOrderValue                    : abap.curr(16,2);

      @UI.hidden                       : true
      @Semantics.currencyCode          : true
      DocumentCurrency                 : waers;

      //=== Approval ==========================================================
      @EndUserText.label               : 'Approval Status'
      @UI.selectionField               : [{ position: 60 }]
      @UI.lineItem                     : [{ position: 70 }]
      @UI.textArrangement              : #TEXT_ONLY
      @ObjectModel.text.element        : ['ApprovalStatusText']
      ApprovalStatus                   : abap.char(1);

      @UI.hidden                       : true
      @Semantics.text                  : true
      ApprovalStatusText               : abap.char(60);
}
