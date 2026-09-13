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
      @Consumption.valueHelpDefinition : [{ entity: { name: 'ZI_PURE001_HEADER', element: 'PurchaseOrder' } }]
  key PurchaseOrder                    : ebeln;

      //=== Document type =====================================================
      @EndUserText.label               : 'Purchasing Doc. Type'
      @UI.selectionField               : [{ position: 120 }]
      @UI.lineItem                     : [{ position: 10, importance: #HIGH }]
      @UI.textArrangement              : #TEXT_FIRST
      @ObjectModel.text.element        : ['PurchaseOrderTypeName']
      @Consumption.valueHelpDefinition : [{ entity: { name: 'ZI_PURE001_POTYPE_VH', element: 'PurchasingDocumentType' } }]
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
      @Search.defaultSearchElement     : true
      ExternalReference                : abap.char(12);

      //=== Supplier ==========================================================
      @EndUserText.label               : 'Supplier'
      @UI.selectionField               : [{ position: 20 }]
      @UI.lineItem                     : [{ position: 40, importance: #HIGH }]
      @UI.textArrangement              : #TEXT_FIRST
      @ObjectModel.text.element        : ['SupplierName']
      @Consumption.valueHelpDefinition : [{ entity: { name: 'I_Supplier', element: 'Supplier' } }]
      Supplier                         : lifnr;

      @UI.hidden                       : true
      @Semantics.text                  : true
      @Search.defaultSearchElement     : true
      SupplierName                     : abap.char(80);

      //=== Organization ======================================================
      @EndUserText.label               : 'Company Code'
      @UI.selectionField               : [{ position: 50 }]
      @Consumption.filter.mandatory    : true
      @Consumption.filter.defaultValue : 'TL01'
      @Consumption.valueHelpDefinition : [{ entity: { name: 'I_CompanyCodeVH', element: 'CompanyCode' } }]
      CompanyCode                      : bukrs;

      @EndUserText.label               : 'Purchasing Group'
      @UI.selectionField               : [{ position: 40 }]
      @UI.lineItem                     : [{ position: 80 }]
      @UI.textArrangement              : #TEXT_FIRST
      @ObjectModel.text.element        : ['PurchasingGroupName']
      @Consumption.valueHelpDefinition : [{ entity: { name: 'I_PurchasingGroup', element: 'PurchasingGroup' } }]
      PurchasingGroup                  : ekgrp;

      @UI.hidden                       : true
      @Semantics.text                  : true
      PurchasingGroupName              : abap.char(18);

      //=== Item-level filter (filter อย่างเดียว) ==============================
      // query class: EXISTS "PO มี item ที่ material ตรง หรือ item text มีคำนี้ (ไม่สนตัวพิมพ์)"
      @EndUserText.label               : 'Material'
      @UI.selectionField               : [{ position: 70 }]
      @Consumption.valueHelpDefinition : [{ entity: { name: 'I_Product', element: 'Product' } }]
      Material                         : matnr;

      @EndUserText.label               : 'Plant'
      @UI.selectionField               : [{ position: 80 }]
      @Consumption.valueHelpDefinition : [{ entity: { name: 'I_Plant', element: 'Plant' } }]
      Plant                            : werks_d;

      //=== Item-level display (ประกอบใน ABAP) =================================
      @EndUserText.label               : 'Material'
      @UI.lineItem                     : [{ position: 100, importance: #LOW }]
      @Consumption.filter.hidden       : true
      MaterialList                     : abap.char(1000);

      @EndUserText.label               : 'Plant'
      @UI.lineItem                     : [{ position: 110, importance: #LOW }]
      @Consumption.filter.hidden       : true
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

      //=== Status (filter + column) ==========================================
      @EndUserText.label               : 'Status'
      @UI.selectionField               : [{ position: 60 }]
      @UI.lineItem                     : [{ position: 70, criticality: 'PurchaseOrderStatusCriticality' }]
      @UI.textArrangement              : #TEXT_ONLY
      @ObjectModel.text.element        : ['PurchaseOrderStatusName']
      @Consumption.valueHelpDefinition : [{ entity: { name: 'ZI_PURE001_STATUS_VH', element: 'PurchasingDocumentStatus' } }]
      PurchaseOrderStatus              : abap.char(2);

      @UI.hidden                       : true
      @Semantics.text                  : true
      PurchaseOrderStatusName          : abap.char(60);

      @UI.hidden                       : true
      @Consumption.filter.hidden       : true
      PurchaseOrderStatusCriticality   : abap.int1;

      //=== Approval Status (column) ==========================================
      @EndUserText.label               : 'Approval Status'
      @UI.lineItem                     : [{ position: 75, criticality: 'ApprovalStatusCriticality' }]
      @UI.textArrangement              : #TEXT_ONLY
      @ObjectModel.text.element        : ['ApprovalStatusText']
      ApprovalStatus                   : abap.char(1);

      @UI.hidden                       : true
      @Semantics.text                  : true
      ApprovalStatusText               : abap.char(60);

      @UI.hidden                       : true
      @Consumption.filter.hidden       : true
      ApprovalStatusCriticality        : abap.int1;
}
