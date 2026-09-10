# Data Interface — RAP UI ↔ Adobe Form

เอกสารนี้คือ **สัญญาระหว่าง ABAP กับ Adobe LiveCycle Designer**
ผู้ทำฟอร์ม (`ZPURF001`) bind field ตามชื่อ node ในนี้ ผู้เขียน ABAP เติมค่าตามนี้

> อ้างอิง layout เป้าหมาย: [docs/spec/po-form-target-layout.png](spec/po-form-target-layout.png)
> และ mockup หน้าจอ: [docs/spec/ui-mockup-columns.png](spec/ui-mockup-columns.png)

สถานะ field ในเอกสารนี้

| สัญลักษณ์ | ความหมาย |
|---|---|
| ✅ | มีใน PO มาตรฐาน — map ได้เลย |
| 🔧 | ต้อง derive / format ใน ABAP |
| ⏸ | **รอ functional สรุปที่มา** → ทำเป็น placeholder ไว้ก่อน (ดู [05-open-questions.md](05-open-questions.md)) |
| ❓ | ชื่อ CDS/field ยังต้องยืนยันบน tenant จริงก่อน |

---

## 1. โครงสร้าง node ทั้งหมด

```
ZI_PURE001_FDP                        (root, key: PurchaseOrder)
│   ├─ company block   — โลโก้ / ที่อยู่ / เลขผู้เสียภาษี Thappline
│   ├─ PO block        — เลขที่ วันที่ อ้างอิง เงื่อนไขชำระเงิน
│   ├─ supplier block  — ผู้ขาย + ผู้ติดต่อ
│   ├─ ship-to block   — สถานที่จัดส่ง + ผู้รับสินค้า
│   ├─ totals block    — ยอดรวม ภาษี สุทธิ ตัวอักษร
│   └─ signature block — ผู้จัดทำ / ผู้อนุมัติ + ลายเซ็น
│
└─ _Item : composition of exact one to many
   ZI_PURE001_FDP_ITEM                (key: PurchaseOrder, PurchaseOrderItem)
   │   ลำดับ / รายการ / จำนวน / หน่วย / ราคาต่อหน่วย / จำนวนเงินรวม
   │   PR No. · Acc.Code · Order No. · WBS · Delivery Time
   │
   └─ _ItemText : composition of exact one to many
      ZI_PURE001_FDP_ITXT             (key: PurchaseOrder, PurchaseOrderItem, TextSeq)
          บรรทัดข้อความใต้ชื่อรายการ (Material PO Text / Item Text / หมายเหตุ)
```

**เหตุผลที่แยก `ZI_PURE001_FDP_ITXT` ออกมาเป็น node** — ในฟอร์มตัวอย่าง ช่อง
"รายการ/Description" ของแต่ละ item มีข้อความหลายบรรทัดที่มาจากคนละที่
(Material PO Text 2 บรรทัด, Item Text 2 บรรทัด, หมายเหตุแบบมีเลขข้อ)
ถ้ายัดเป็น string เดียวแล้วคั่นด้วย newline ฝั่ง LiveCycle จะคุมระยะบรรทัด
กับการขึ้นหน้าใหม่ไม่ได้ — แยกเป็น node ให้ designer ใช้ subform แบบ repeat แทน

---

## 2. `ZI_PURE001_FDP` — root (header)

### 2.1 Key

| Node | Type | สถานะ | ที่มา |
|---|---|---|---|
| `PurchaseOrder` | `ebeln` | ✅ | key — ค่าที่ FDP ส่งเข้ามาผ่าน `get_keys( )` ชื่อ `'PURCHASEORDER'` |

### 2.2 Company block (หัวกระดาษ)

| Node | Type | สถานะ | ที่มา / หมายเหตุ |
|---|---|---|---|
| `CompanyLogo` | `abap.rawstring(0)` | 🔧 | `ZPURE001_GRPH` name = `THAPPLINE_LOGO` · `@Semantics.largeObject` |
| `CompMimeType` / `CompFileName` | char | 🔧 | คู่กับ `CompanyLogo` |
| `CompanyName` | `abap.char(120)` | ❓ | `I_CompanyCode` → `CompanyCodeName` |
| `CompanyAddress` | `abap.char(255)` | ❓ | ประกอบจาก address ของ company code |
| `CompanyPhone` | `abap.char(60)` | ⏸ | ฟอร์มโชว์ `Tel: 02-034-9199,02-533-2190` — น่าจะมาจาก setting |
| `CompanyWebsite` | `abap.char(60)` | ⏸ | `www.thappline.co.th` |
| `CompanyTaxNumber` | `abap.char(30)` | ❓ | เลขประจำตัวผู้เสียภาษี `0105534002696` |

### 2.3 PO block (กรอบขวาบน)

| Node | Type | สถานะ | ที่มา |
|---|---|---|---|
| `PurchaseOrderTypeName` | `abap.char(60)` | ✅ | `I_PurchaseOrderTypeText` |
| `IssuedDate` | `datum` | ✅ | `PurchaseOrderDate` |
| `IssuedDateText` | `abap.char(30)` | 🔧 | **วันที่ไทย พ.ศ.** `21 พฤศจิกายน 2568` ← `ZCL_PURE001_UTIL=>to_thai_date( )` |
| `ExternalReference` | `abap.char(20)` | ✅ | `CorrespncExternalReference` (เลขที่อ้างอิง / Your Reference) ❓ |
| `InternalReference` | `abap.char(20)` | ✅ | `CorrespncInternalReference` (เลขที่อ้างอิงภายใน / Our Reference) ❓ |
| `PaymentTerms` | `dzterm` | ✅ | `PaymentTerms` |
| `PaymentTermsText` | `abap.char(120)` | ❓ | `I_PaymentTermsText` — ฟอร์มโชว์ `Due 30 days after Billing Date` |
| `DeliveryDate` | `datum` | 🔧 | วันที่ส่งสินค้า — เอาวันแรกสุดจาก schedule line ของ item |
| `DeliveryDateText` | `abap.char(30)` | 🔧 | วันที่ไทย |
| `ContractValidFrom` / `ContractValidTo` | `datum` | ⏸ | วันที่เริ่ม/สิ้นสุดสัญญา |
| `ContractValidFromText` / `ContractValidToText` | char | ⏸ | วันที่ไทย |
| `PerfGuaranteeFlag` | `abap_boolean` | ⏸ | ☐ หลักประกันการดำเนินงาน |
| `PerfGuaranteeCash` / `PerfGuaranteeBG` | `abap_boolean` | ⏸ | ☐ เงินค้ำประกัน / ☐ BG |
| `InsurancePolicyFlag` | `abap_boolean` | ⏸ | ☐ กรมธรรม์ประกันภัย |
| `WarrantyGuaranteeFlag` | `abap_boolean` | ⏸ | ☐ หลักประกันผลงาน |
| `WarrantyGuaranteeCash` / `WarrantyGuaranteeBG` | `abap_boolean` | ⏸ | ☐ เงินค้ำประกัน / ☐ BG |

### 2.4 Supplier block (กรอบซ้ายบน)

| Node | Type | สถานะ | ที่มา |
|---|---|---|---|
| `Supplier` | `lifnr` | ✅ | `Supplier` |
| `SupplierName` | `abap.char(255)` | ✅ | `I_Supplier` → `SupplierName` / `SupplierFullName` ❓ |
| `SupplierBranch` | `abap.char(60)` | ❓ | `(สำนักงานใหญ่)` — Thai branch code ของ business partner |
| `SupplierAddress` | `abap.char(510)` | 🔧 | ประกอบหลายบรรทัดจาก `I_BusinessPartnerAddress` ❓ |
| `SupplierContactName` | `abap.char(120)` | ❓ | นามตัวแทนขาย — จาก PO Partner (role VN/แทน) หรือ BP contact |
| `SupplierEmail` | `abap.char(241)` | ❓ | |
| `SupplierPhone` | `abap.char(60)` | ❓ | |

### 2.5 Ship-to block

| Node | Type | สถานะ | ที่มา |
|---|---|---|---|
| `ShipToName` | `abap.char(255)` | ❓ | สถานที่จัดส่ง — จาก plant / address ของ item แรก |
| `ShipToAddress` | `abap.char(510)` | 🔧 | |
| `ShipVia` | `abap.char(60)` | ⏸ | จัดส่งโดย — ฟอร์มโชว์ `Truck` |
| `GoodsRecipientName` | `abap.char(120)` | ⏸ | นามผู้รับสินค้า |
| `GoodsRecipientPhone` | `abap.char(60)` | ⏸ | |

### 2.6 Totals block (ท้ายฟอร์ม)

| Node | Type | สถานะ | ที่มา |
|---|---|---|---|
| `Currency` | `waers` | ✅ | `DocumentCurrency` |
| `TotalAmount` | `abap.dec(23,2)` | 🔧 | รวมเงิน/Total = Σ item amount |
| `DiscountAmount` | `abap.dec(23,2)` | ⏸ | ส่วนลด — ฟอร์มตัวอย่างเป็น `-` |
| `AmountBeforeTax` | `abap.dec(23,2)` | 🔧 | รวมเงิน/Amount |
| `TaxAmount` | `abap.dec(23,2)` | ✅ | ภาษี/Tax ❓ (field tax ระดับ header) |
| `NetAmount` | `abap.dec(23,2)` | 🔧 | สุทธิ/Net Amount |
| `AmountInWords` | `abap.char(255)` | 🔧 | `(สี่แสนสี่หมื่นเก้าพันสี่ร้อยบาทถ้วน)` ← `ZCL_PURE001_UTIL=>amount_in_words_th( )` |

### 2.7 Signature block

| Node | Type | สถานะ | ที่มา |
|---|---|---|---|
| `PreparedByName` | `abap.char(120)` | ❓ | ผู้จัดทำ — `CreatedByUser` → ชื่อจริง |
| `PreparedByDateText` | `abap.char(30)` | 🔧 | วันที่ไทย จาก `CreationDate` |
| `ApprovedByName` | `abap.char(120)` | ⏸ | ผู้อนุมัติ — จาก approval workflow หรือ setting |
| `ApprovedByPosition` | `abap.char(120)` | ⏸ | `ผู้จัดการฝ่ายสนับสนุนองค์กร` |
| `ApprovedByDateText` | `abap.char(30)` | ⏸ | |
| `ApprovedBySignature` | `abap.rawstring(0)` | ⏸ | รูปลายเซ็น จาก `ZPURE001_GRPH` |
| `SignMimeType` / `SignFileName` | char | ⏸ | คู่กับ `ApprovedBySignature` |

> ข้อความยาว ๆ ท้ายฟอร์ม (`โปรดระบุใบสั่งซื้อนี้ลงในใบส่งของ...` /
> `We hereby accept description above...`) เป็นข้อความคงที่ → **ฝังใน layout ฟอร์มเลย**
> ไม่ต้องผ่าน data interface

---

## 3. `ZI_PURE001_FDP_ITEM` — item line

| Node | Type | สถานะ | ที่มา |
|---|---|---|---|
| `PurchaseOrder` | `ebeln` | ✅ | key |
| `PurchaseOrderItem` | `ebelp` | ✅ | key |
| `ItemNumber` | `abap.int4` | 🔧 | ลำดับ/Item — นับ 1..n ใหม่ ไม่ใช้เลข item ดิบ |
| `Material` | `matnr` | ✅ | `Material` — ฟอร์มโชว์ `1000001` |
| `MaterialDescription` | `abap.char(255)` | ✅ | `PurchaseOrderItemText` |
| `Quantity` | `abap.dec(13,3)` | ✅ | `OrderQuantity` |
| `QuantityText` | `abap.char(20)` | 🔧 | จำนวนที่ format แล้ว (ตัดทศนิยมท้าย) |
| `Unit` | `meins` | ✅ | `PurchaseOrderQuantityUnit` |
| `NetPriceAmount` | `abap.dec(23,2)` | ✅ | `NetPriceAmount` |
| `NetPriceQuantity` | `abap.dec(13,3)` | ✅ | `NetPriceQuantity` (ราคาต่อกี่หน่วย) |
| `ItemAmount` | `abap.dec(23,2)` | 🔧 | จำนวนเงินรวม = qty × price / priceUnit |
| `DeliveryDate` | `datum` | ✅ | จาก schedule line |
| `DeliveryDateText` | `abap.char(30)` | 🔧 | `Delivery Time : 26/06/2025` |
| `PurchaseRequisition` | `banfn` | ✅ | `PurchaseRequisition` — `PR No.` |
| `GLAccount` | `saknr` | ✅ | `I_PurchaseOrderAccountAssignment` ❓ — `Acc.Code` |
| `InternalOrder` | `aufnr` | ✅ | `OrderID` ❓ — `Order No.` |
| `WBSElement` | `abap.char(24)` | ✅ | `WBSElementExternalID` ❓ |

## 4. `ZI_PURE001_FDP_ITXT` — บรรทัดข้อความใต้รายการ

| Node | Type | สถานะ | ที่มา |
|---|---|---|---|
| `PurchaseOrder` | `ebeln` | ✅ | key |
| `PurchaseOrderItem` | `ebelp` | ✅ | key |
| `TextSequence` | `abap.int4` | 🔧 | key — ลำดับบรรทัด |
| `TextType` | `abap.char(20)` | 🔧 | `MAT_PO_TEXT` / `ITEM_TEXT` / `NOTE` |
| `TextLine` | `abap.char(255)` | ✅ | เนื้อความ 1 บรรทัด |

---

## 5. `ZI_PURE001` — entity ของ RAP UI (list report)

**คนละตัวกับ FDP entity** — ตัวนี้เบา ไม่มีรูป ไม่มี text ใช้แสดงผลบนหน้าจออย่างเดียว

### 5.1 Selection field (14 ช่อง ตาม spec §2.4 Header)

| # | Label | Node | หมายเหตุ |
|---|---|---|---|
| 1 | Search | `SearchTerm` | ❓ custom entity ไม่รองรับ free-text search ของ Fiori → ทำเป็น filter ธรรมดาที่ค้นเลข PO / ชื่อผู้ขาย |
| 2 | Editing Status | `EditingStatus` | ❓ |
| 3 | Supplier | `Supplier` | value help `I_SupplierVH` |
| 4 | Purchase Order | `PurchaseOrder` | |
| 5 | Purchasing Group | `PurchasingGroup` | |
| 6 | Company Code | `CompanyCode` | mandatory + default `Thai Petroleum` ตาม mockup |
| 7 | Status | `ApprovalStatus` | ❓ overall release status |
| 8 | Material | `Material` | filter ระดับ item |
| 9 | Plant | `Plant` | filter ระดับ item |
| 10 | Purchase Order Date | `PurchaseOrderDate` | `#INTERVAL` |
| 11 | Our Reference | `InternalReference` | |
| 12 | Your Reference | `ExternalReference` | |
| 13 | Purchasing Doc. Type | `PurchaseOrderType` | |
| 14 | Created On | `CreationDate` | `#INTERVAL` |

### 5.2 Column (9 คอลัมน์ + ปุ่ม ตาม spec §2.4 Line)

| # | Label | Node |
|---|---|---|
| 1 | Purchasing Doc. Type | `PurchaseOrderType` + `PurchaseOrderTypeName` |
| 2 | Our Reference | `InternalReference` |
| 3 | Purchase Order | `PurchaseOrder` |
| 4 | Supplier | `SupplierName` |
| 5 | Purchase Order Date | `PurchaseOrderDate` |
| 6 | Net Order Value | `NetAmount` + `Currency` |
| 7 | Approve Status | `ApprovalStatusText` |
| 8 | Purchasing Group | `PurchasingGroup` + `PurchasingGroupName` |
| 9 | Created On | `CreationDate` |
| 10 | **ปุ่ม Print PO Form** | action `PrintPOForm` (toolbar) |
| + | Preview / Download | `PrintUrl` / `DownloadUrl` (`type: #WITH_URL`) |
