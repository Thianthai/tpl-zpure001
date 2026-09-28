@EndUserText.label: 'Print Purchase Order - FDP'
@ObjectModel.query.implementedBy: 'ABAP:ZCL_PURE001_FDP'
@ObjectModel.supportedCapabilities: [ #OUTPUT_FORM_DATA_PROVIDER ]
define root custom entity ZR_PURE001_FDP
{
      //=== Key ===============================================================
  key PurchaseOrder            : ebeln;

      //=== Company ===========================================================
      CompanyCode              : bukrs;
      CompanyName              : abap.char(80);
      CompanyTaxNumber         : abap.char(20);
      // ที่อยู่ โทรศัพท์ เว็บไซต์ และโลโก้ของบริษัทพิมพ์เป็นค่าคงที่ในฟอร์ม
      // field กลุ่มนี้จึงไม่มีค่า
      CompanyAddressLine1      : abap.char(120);
      CompanyAddressLine2      : abap.char(120);
      CompanyPhone             : abap.char(60);
      CompanyWebsite           : abap.char(80);
      @Semantics.mimeType      : true
      CompanyLogoMimeType      : abap.char(128);
      CompanyLogoFileName      : abap.char(255);
      @Semantics.largeObject   : { mimeType: 'CompanyLogoMimeType', fileName: 'CompanyLogoFileName',
                                   acceptableMimeTypes: ['image/png', 'image/jpeg'], contentDispositionPreference: #INLINE }
      CompanyLogo              : abap.rawstring(0);

      //=== PO ================================================================
      PurchaseOrderType        : ze_bsart;
      PurchaseOrderTypeName    : abap.char(20);
      Language                 : abap.lang;
      PurchaseOrderDate        : abap.dats;
      PurchaseOrderDateText    : abap.char(40);
      ExternalReference        : abap.char(12);
      InternalReference        : abap.char(12);
      PaymentTerms             : abap.char(4);
      PaymentTermsText         : abap.char(50);
      DeliveryDate             : abap.dats;
      DeliveryDateText         : abap.char(40);
      ValidityStartDate        : abap.dats;
      ValidityStartDateText    : abap.char(40);
      ValidityEndDate          : abap.dats;
      ValidityEndDateText      : abap.char(40);
      ShipVia                  : abap.char(80);
      HeaderText               : abap.string;
      HeaderNote               : abap.string;
      // ช่องหลักประกันมาจาก custom field บนใบสั่งซื้อ
      PerfGuaranteeFlag        : abap.char(1);
      PerfGuaranteeCash        : abap.char(1);
      PerfGuaranteeBG          : abap.char(1);
      InsurancePolicyFlag      : abap.char(1);
      WarrantyGuaranteeFlag    : abap.char(1);
      WarrantyGuaranteeCash    : abap.char(1);
      WarrantyGuaranteeBG      : abap.char(1);

      //=== Supplier ==========================================================
      Supplier                 : lifnr;
      SupplierName             : abap.char(80);
      // รหัสผู้ขายตามด้วยชื่อและสาขา ค่าเดียวกับ YY1_SuppCodeNameBranch ของฟอร์มมาตรฐาน
      SupplierCodeName         : abap.char(100);
      SupplierTaxNumber        : abap.char(20);
      SupplierAddress          : abap.char(255);
      SupplierStreet           : abap.char(60);
      SupplierDistrict         : abap.char(40);
      SupplierCity             : abap.char(40);
      SupplierPostalCode       : abap.char(10);
      SupplierContactName      : abap.char(35);
      SupplierPhone            : abap.char(30);
      SupplierEmail            : abap.char(241);

      //=== Ship-to ===========================================================
      ShipToPlant              : werks_d;
      ShipToName               : abap.char(80);
      ShipToPlantName          : abap.char(30);
      // ที่อยู่ของ plant รวมอยู่บรรทัดเดียว บรรทัดที่สองจึงไม่มีค่า
      ShipToAddressLine1       : abap.char(120);
      ShipToAddressLine2       : abap.char(120);
      GoodsRecipientName       : abap.char(35);
      UnloadingPointName       : abap.char(25);
      GoodsRecipientPhone      : abap.char(30);

      //=== Totals ============================================================
      @Semantics.currencyCode  : true
      DocumentCurrency         : waers;
      @Semantics.amount.currencyCode : 'DocumentCurrency'
      TotalAmount              : abap.curr(16,2);
      @Semantics.amount.currencyCode : 'DocumentCurrency'
      DiscountAmount           : abap.curr(16,2);
      @Semantics.amount.currencyCode : 'DocumentCurrency'
      AmountBeforeTax          : abap.curr(16,2);
      @Semantics.amount.currencyCode : 'DocumentCurrency'
      TaxAmount                : abap.curr(16,2);
      @Semantics.amount.currencyCode : 'DocumentCurrency'
      NetAmount                : abap.curr(16,2);
      AmountInWords            : abap.char(255);

      //=== Signature =========================================================
      PreparedByUser           : abap.char(12);
      PreparedByName           : abap.char(80);
      PreparedDate             : abap.dats;
      PreparedDateText         : abap.char(40);
      ApprovedByUser           : abap.char(12);
      ApprovedByName           : abap.char(80);
      ApprovedDate             : abap.dats;
      ApprovedDateText         : abap.char(40);
      ApprovedByPosition       : abap.char(80);
      @Semantics.mimeType      : true
      ApprovedBySignMimeType   : abap.char(128);
      ApprovedBySignFileName   : abap.char(255);
      @Semantics.largeObject   : { mimeType: 'ApprovedBySignMimeType', fileName: 'ApprovedBySignFileName',
                                   acceptableMimeTypes: ['image/png', 'image/jpeg'], contentDispositionPreference: #INLINE }
      // ฟอร์มมาตรฐานไม่มีรูปลายเซ็น field นี้จึงไม่มีค่า
      ApprovedBySignature      : abap.rawstring(0);
      IsApprovedAutomatically  : abap.char(1);
      // ข้อความอนุมัติผ่านระบบอิเล็กทรอนิกส์ ว่างเมื่อยังไม่อนุมัติ
      ApprovalNoteText         : abap.char(120);
      
      _Item                    : composition of exact one to many ZI_PURE001_ITEM_FDP;
}
