# Data Interface — RAP UI ↔ Adobe Form `ZPURF002`

เอกสารนี้คือ **สัญญาระหว่าง ABAP กับ Adobe LiveCycle Designer**
ผู้ทำฟอร์ม (`ZPURF002`) bind field ตามชื่อ node ในนี้ · ผู้เขียน ABAP เติมค่าตามนี้
· XML จริงที่ FDP คาย (`cl_fp_fdp_services=>read_to_xml_v2`) มีโครงตาม §2–§4 — **ยืนยันแล้ว 2026-09-14** (checkpoint `c5b66b3`, ดู §0)

> layout เป้าหมาย: [docs/spec/po-form-target-layout.png](spec/po-form-target-layout.png)
> spec ฟอร์ม: `TPL_ZPURF002_PO Form.docx` (ระบุเพิ่ม 2 field: Our Reference + Delivery Date ของ item แรก)

สถานะ field

| สัญลักษณ์ | ความหมาย |
|---|---|
| ✅ | มี source บน tenant แล้ว (ยืนยัน 2026-09-13) |
| 🔧 | derive / format ใน ABAP (`ZCL_PURE001_FDP` + `ZCL_PURE001_UTIL`) |
| ⏸ | **placeholder** — ประกาศ node ไว้ในสัญญาแล้ว แต่ยังไม่มี source (config / custom field / graphics) → ค่าว่างจนกว่าจะปิด |

**หลักการ** — ประกาศ node ให้ครบตั้งแต่รอบนี้ แม้ยังเป็น ⏸ เพื่อให้ **layout ฟอร์มไม่ต้องแก้** เมื่อเติม source ทีหลัง

---

## 0. ผลทดสอบจริง (tenant 100 · 2026-09-14 · `ZCL_PURE001_TEST_FDP`)

XML ที่ได้จาก `read_to_xml_v2( )` — **ชื่อ node ระดับบนสุดคือ alias ใน `ZAPI_PURE001_FDP` ไม่ใช่ชื่อ entity**

```xml
<Form version="2">
  <PurchaseOrderHeader>                 ← ZR_PURE001_FDP   (alias PurchaseOrderHeader)
    <PurchaseOrder>99680198</PurchaseOrder> … field ตาม §2 …
    <_Item>
      <PurchaseOrderItem>               ← ZI_PURE001_ITEM_FDP (alias PurchaseOrderItem) · 1 node ต่อ item
        … field ตาม §3 …
        <_ItemText>
          <PurchaseOrderItemText>       ← ZI_PURE001_ITXT_FDP (alias PurchaseOrderItemText) · 1 node ต่อ text type
            … field ตาม §4 …
          </PurchaseOrderItemText>
        </_ItemText>                    ← item ที่ไม่มี text จะเป็น <_ItemText/> ว่าง
      </PurchaseOrderItem>
    </_Item>
  </PurchaseOrderHeader>
</Form>
```

| PO | เส้นทางที่พิสูจน์ | ผล |
|---|---|---|
| `99680198` | material item 6 รายการ · F03 · ผู้อนุมัติจริง · 800,000 + VAT 7% | ✅ `แปดแสนห้าหมื่นหกพันบาทถ้วน` |
| `4500000080` | approved automatically (`IsApprovedAutomatically = X`, ApprovedBy ว่าง) · WBS `C-2026-004` · PR / GL · performance period · text item | ✅ |
| `0099680019` | WBS `C-2025-054` · GL 820000 · item บริการ quantity 0 · ไม่มี tax code | ✅ (ดูข้อสังเกต) |
| `99680044` | **item ลบไม่ออก** → 870,000.25 ตรง standard · VAT ปัดเศษ `60,900.02` · สตางค์ `…ยี่สิบเจ็ดสตางค์` · In Approval · F01+F04 | ✅ |
| `0099680047` | header text F01/F02/F06 → `HeaderText` / `HeaderNote` / `ShipVia` · supplier อังกฤษ district ว่าง | ✅ |
| `0099680042` | F03 → F01 → F04 ครบ 3 node · Order No. · 10.5 ล้าน (recursion หลักล้าน) · `&amp;` escape | ✅ |

**พฤติกรรมของ serializer ที่ผู้ทำฟอร์มต้องรู้**

| เรื่อง | ที่เห็น | ผล/ทางแก้ |
|---|---|---|
| field type data element ที่มี conversion exit (`ebeln`) ถูกตัด 0 นำหน้า | `<PurchaseOrder>99680198</PurchaseOrder>` | ตรง standard |
| field `abap.char(n)` ออกดิบ | `<PurchaseRequisition>0003680141</PurchaseRequisition>`, `<GLAccount>0000611401</GLAccount>`, `<OrderID>008200000042</OrderID>` | ⬜ รอเลือก: เปลี่ยน type เป็น `banfn`/`saknr`/`kostl`/`aufnr` หรือใช้ `AccountAssignmentText` (ตัด 0 แล้ว) |
| `abap.unit` ถูกแปลงเป็น **ISO code** | `<Unit>C62</Unit>` (ภายใน `ST`) · `EA`/`DR`/`BX` บังเอิญเท่ากัน | ⬜ ควรเพิ่ม `UnitName` (`I_UnitOfMeasureText` ภาษา PO) หรือ commercial code |
| `abap.int4` / `abap.dec` มี space ท้าย (ตำแหน่งเครื่องหมาย) | `<ItemNumber>1 </ItemNumber>`, `<TaxRate>7.00 </TaxRate>`, `<TextSequence>1 </TextSequence>` | ปกติ ADS parse ได้ — ถ้าเพี้ยนเปลี่ยนเป็น text field |
| `abap.curr` / `abap.quan` / `abap.dats` ออกสะอาด | `856000.00`, `2`, `20260714` | ใช้ได้เลย |
| `Language` ออกเป็น ISO 2 ตัว | `EN` | (ภายใน `E` — lookup text ทำใน ABAP แล้ว ไม่กระทบ) |
| `AccountAssignmentText` เว้นวรรคเกิน | `PR No.: 3680141     Acc.Code: 611401` | 🔧 **ต้องแก้** — `ALPHA = OUT` คืน blank ท้าย ต้อง `condense` |

**field ที่เพิ่ม 2026-09-18 เพื่อให้ฟอร์ม `ZPURF002` ไม่ต้องมี script (D14)** — XML ยืนยันแล้วกับ 0099680042

| Node | Entity | Type | ค่า |
|---|---|---|---|
| `SupplierCodeName` | `ZR_PURE001_FDP` | `abap.char(100)` | `10004 บริษัท นาคา…` (แทน `YY1_SuppCodeNameBranch` — สาขาไม่มี source, 05 ข้อ 22) |
| `ApprovalNoteText` | `ZR_PURE001_FDP` | `abap.char(120)` | `เอกสารสั่งซื้อนี้ได้รับการอนุมัติจากผู้มีอำนาจ ผ่านระบบอิเล็กทรอนิกส์เรียบร้อยแล้ว` เมื่อ ApprovalStatus = A หรือ B · ไม่งั้นว่าง (ฟอร์มไม่พิมพ์) |
| `ItemDescriptionText` | `ZI_PURE001_ITEM_FDP` | `abap.string` | ช่อง "รายการ" ทั้งช่อง คั่น newline: `ItemDescription` → text F03 → F01 → F04 → `DeliveryDateText` → `AccountAssignmentText` → `WBS: …` |
| (กติกา) service item | `ZI_PURE001_ITEM_FDP` | — | `Quantity = 0` → `QuantityText = 1`, `Unit = AU` (`Quantity` ตัวเลขคง 0) — ตามฟอร์มเดิม |
| (แก้) `AccountAssignmentText` | | | `condense` หลัง `ALPHA = OUT` → `PR No.: 2680017  Acc.Code: 542000  Order No.: 8200000042` |

**การ bind บนฟอร์ม `ZPURF002`** — ดู [../form/README.md](../form/README.md) · binding ทั้งหมดอยู่ใน `form/build_xdp.py` (`ref_map`)

**2026-09-23 ฟอร์มต้นทางเพิ่ม 2 ช่องในกรอบขวาบน** — ฝั่ง ABAP **ไม่ต้องแก้อะไร** ทั้งสองค่ามีใน `ZR_PURE001_FDP` ตั้งแต่ Phase 2

| ช่องบนฟอร์ม | bind กับ | ที่มา |
|---|---|---|
| เลขที่อ้างอิงภายใน / Our Reference | `InternalReference` | `I_PurchaseOrderAPI01.CorrespncInternalReference` |
| วันที่ส่งสินค้า / Delivery Date | `DeliveryDateText` | schedule line `0001` ของ item แรกที่ไม่ถูกลบ แปลงเป็นวันที่ไทย |

> ฟอร์มเดิมที่พิมพ์ผ่าน standard ต้องใช้ JavaScript แปลงวันที่เอง (`FirstDeliveryDate` ของ `PurchaseOrderItemNode[0]` → พ.ศ. + เดือนไทย)
> เพราะ XFA display pattern ทำปฏิทินพุทธไม่ได้ · ต้องระบุ index `[0]` ไม่ใช่ `[*]` ซึ่งใช้ได้เฉพาะ subform ที่ repeat
> — ผู้ใช้ upload ฟอร์มเดิมเข้า *Maintain Form Templates* แล้วทดสอบกับ PO จริง **ผ่านแล้ว 2026-09-23**

**ข้อสังเกตที่ต้องให้ functional ตัดสิน** — ดู [05-open-questions.md](05-open-questions.md) ข้อ 14–22

---

## 1. โครงสร้าง node

```
ZR_PURE001_FDP  → XML <PurchaseOrderHeader>          root · key: PurchaseOrder
│  §2.1 company · §2.2 PO · §2.3 supplier · §2.4 ship-to · §2.5 totals · §2.6 signature
│
└─ _Item : composition [0..*]
   ZI_PURE001_ITEM_FDP  → XML <_Item><PurchaseOrderItem>       key: PurchaseOrder, PurchaseOrderItem
   │  §3 รายการ · จำนวน · หน่วย · ราคา · ภาษี · PR / Acc / Order / WBS · วันส่ง
   │
   └─ _ItemText : composition [0..*]
      ZI_PURE001_ITXT_FDP  → XML <_ItemText><PurchaseOrderItemText>   key: PurchaseOrder, PurchaseOrderItem, TextSequence
         §4 ข้อความใต้รายการ 1 node ต่อ text type (Material PO Text → Item Text → Delivery Text)

(ชื่อ node = alias ใน ZAPI_PURE001_FDP · composition ใน custom entity ไม่มี on-condition เอง — derive จาก
 association to parent ของลูก จึงต้อง activate ลูกก่อน/พร้อมกัน ไม่งั้น CATALOG_INCONSISTENCY ตอน runtime)
```

**การไหลของข้อมูล (D12 — logic ทั้งหมดใน ABAP)**

```
ZAPI_PURE001_FDP (service def)
  └─ ZR_PURE001_FDP / ZI_PURE001_ITEM_FDP / ZI_PURE001_ITXT_FDP   (custom entity — ประกาศ field)
       └─ ZCL_PURE001_FDP (query provider)     ← ประกอบ 3 node · ภาษีรวม · วันที่ไทย · amount in words
            ├─ ZCL_PURE001_DATA                ← ตัวเดียวกับ list: header + status + ยอดรวม + items
            │    + read_schedule_lines · read_account_assignments (+WBS ผ่าน I_EnterpriseProjectElement)
            │    + read_tax_rates · read_texts (I_PurchaseOrder(Item)NoteTP_2) · read_approvers
            └─ ZCL_PURE001_UTIL                ← to_thai_date · format_date_dmy · amount_in_words · format_quantity
```

> ที่อยู่ผู้ขาย: จาก field ใน `I_Supplier` (street / district / city / postal) — `I_BusinessPartnerAddressTP_3.CompleteAddress` เป็น projection ใช้ใน CDS ไม่ได้ จึงประกอบใน ABAP

---

## 2. `ZR_PURE001_FDP` — root (header)

### 2.1 Company block (หัวกระดาษ)

| Node | Type | สถานะ | Source |
|---|---|---|---|
| `CompanyCode` | `bukrs` | ✅ | `I_PurchaseOrderAPI01.CompanyCode` |
| `CompanyName` | `abap.char(80)` | ✅ | `I_CompanyCode.CompanyCodeName` — *"Thai Petroleum Pipeline"* (ฟอร์มโชว์ "…Company Limited" → ถ้าต้องการชื่อเต็มเป็น ⏸ config) |
| `CompanyTaxNumber` | `abap.char(20)` | ✅ | `I_CompanyCode.VATRegistration` — *0105534002696* ตรงฟอร์ม |
| `CompanyAddressLine1` | `abap.char(120)` | ⏸ | config — `2/8 Moo 11 Lumlukka Rd., Ladsawai, Lumlukka Pathumthani 12150` (address view ทั้งหมดว่างเพราะ DCL) |
| `CompanyAddressLine2` | `abap.char(120)` | ⏸ | config |
| `CompanyPhone` | `abap.char(60)` | ⏸ | config — `02-034-9199,02-533-2190` |
| `CompanyWebsite` | `abap.char(80)` | ⏸ | config — `www.thappline.co.th` |
| `CompanyLogo` | `abap.rawstring(0)` `@Semantics.largeObject` | ⏸ | graphics table (รอเช็ค table กลางบน tenant) |
| `CompanyLogoMimeType` / `CompanyLogoFileName` | char | ⏸ | คู่กับ `CompanyLogo` |

### 2.2 PO block (กรอบขวาบน)

| Node | Type | สถานะ | Source |
|---|---|---|---|
| `PurchaseOrder` | `ebeln` | ✅ | **key** — FDP ส่งเข้ามาผ่าน `get_keys( )` ชื่อ `'PURCHASEORDER'` |
| `PurchaseOrderType` | `ze_bsart` | ✅ | `PurchaseOrderType` |
| `PurchaseOrderTypeName` | `abap.char(20)` | ✅ | `I_PurchasingDocumentTypeText` (category `F`) |
| `Language` | `spras` | ✅ | `I_PurchaseOrderAPI01.Language` — ใช้เลือกภาษาของ text ทุกตัวในฟอร์ม |
| `PurchaseOrderDate` | `abap.dats` | ✅ | `PurchaseOrderDate` (วันที่ออกใบสั่งซื้อ) |
| `PurchaseOrderDateText` | `abap.char(40)` | 🔧 | `21 พฤศจิกายน 2568` ← `to_thai_date( )` |
| `ExternalReference` | `abap.char(12)` | ✅ | `CorrespncExternalReference` — **เลขที่อ้างอิง/Reference** (Your Reference) |
| `InternalReference` | `abap.char(12)` | ✅ | `CorrespncInternalReference` — **เลขที่อ้างอิงภายใน/Our Reference** (spec ZPURF002 ข้อ 1) |
| `PaymentTerms` | `abap.char(4)` | ✅ | `PaymentTerms` |
| `PaymentTermsText` | `abap.char(50)` | ✅ | `I_PaymentTermsText` — `PaymentTermsDescription` ถ้าว่างใช้ `PaymentTermsName` (ภาษาของ PO) — `NT30` → *"Due 30 days after Billing Date"* |
| `DeliveryDate` | `abap.dats` | ✅ | schedule line ของ **item แรก** (spec ZPURF002 ข้อ 2) — `I_PurOrdScheduleLineAPI01.ScheduleLineDeliveryDate` |
| `DeliveryDateText` | `abap.char(40)` | 🔧 | วันที่ไทย |
| `ValidityStartDate` / `ValidityEndDate` | `abap.dats` | ✅ | `I_PurchaseOrderAPI01.ValidityStartDate` / `ValidityEndDate` (วันที่เริ่ม/สิ้นสุดสัญญา — มาตรฐานของ PO แบบ framework) ⚠️ ถ้า functional ใช้ custom field `YY1_FrameworkStartDate` แทน สลับ source ได้ |
| `ValidityStartDateText` / `ValidityEndDateText` | `abap.char(40)` | 🔧 | วันที่ไทย |
| `ShipVia` | `abap.char(80)` | ✅ | `I_PurchaseOrderNoteTP_2` text `F06` (Shipping Instructions) — ค่าจริง *Truck / Messenger* |
| `HeaderText` | `abap.string` | ✅ | `I_PurchaseOrderNoteTP_2` text `F01` |
| `HeaderNote` | `abap.string` | ✅ | `I_PurchaseOrderNoteTP_2` text `F02` |
| `PerfGuaranteeFlag` | `abap.char(1)` | ⏸ | custom field `YY1_PerformanceBond_PDH` *(mock — ชื่อจริงรอ tenant)* → ☐ หลักประกันการดำเนินงาน |
| `PerfGuaranteeCash` / `PerfGuaranteeBG` | `abap.char(1)` | ⏸ | custom field |
| `InsurancePolicyFlag` | `abap.char(1)` | ⏸ | custom field → ☐ กรมธรรม์ประกันภัย |
| `WarrantyGuaranteeFlag` | `abap.char(1)` | ⏸ | custom field `YY1_Retention_PDH` → ☐ หลักประกันผลงาน |
| `WarrantyGuaranteeCash` / `WarrantyGuaranteeBG` | `abap.char(1)` | ⏸ | custom field `YY1_BankGuarantee_PDH` |

### 2.3 Supplier block (กรอบซ้ายบน)

| Node | Type | สถานะ | Source |
|---|---|---|---|
| `Supplier` | `lifnr` | ✅ | `Supplier` — แสดง `10035` |
| `SupplierName` | `abap.char(80)` | ✅ | `I_Supplier.SupplierName` — มี `(สำนักงานใหญ่)` ฝังอยู่แล้วในชื่อ |
| `SupplierTaxNumber` | `abap.char(20)` | ✅ | `I_Supplier.TaxNumber3` (เลข 13 หลัก) |
| `SupplierAddress` | `abap.char(255)` | 🔧 | ประกอบจาก `I_Supplier` street / district / city / postal (ข้ามส่วนที่ว่าง) |
| `SupplierStreet` / `SupplierDistrict` / `SupplierCity` / `SupplierPostalCode` | char | ✅ | `I_Supplier.StreetName` / `DistrictName` / `CityName` / `PostalCode` |
| `SupplierContactName` | `abap.char(35)` | ✅ | `I_PurchaseOrderAPI01.SupplierRespSalesPersonName` (นามตัวแทนขาย — Communication tab) |
| `SupplierPhone` | `abap.char(16)` | ✅ | `I_PurchaseOrderAPI01.SupplierPhoneNumber` |
| `SupplierEmail` | `abap.char(241)` | ⏸ | custom field `YY1_Email_PDH` *(mock)* — `I_AddressEmailAddress_2` ว่าง |

### 2.4 Ship-to block (สถานที่จัดส่ง)

| Node | Type | สถานะ | Source |
|---|---|---|---|
| `ShipToPlant` | `werks_d` | ✅ | plant ของ item แรก |
| `ShipToName` | `abap.char(80)` | ✅ | **ชื่อบริษัท** (`I_CompanyCode.CompanyCodeName` — ตามฟอร์ม · ชื่อเต็มเป็น ⏸ config) — ผู้ใช้ตัดสินใจ 2026-09-13 |
| `ShipToPlantName` | `abap.char(30)` | ✅ | `I_Plant.PlantName` — *Lumlukka Terminal* เผื่อใช้ |
| `ShipToAddressLine1` / `ShipToAddressLine2` | `abap.char(120)` | ⏸ | config ต่อ plant (`I_Plant.AddressID` มี แต่ address view ว่าง) |
| `GoodsRecipientName` | `abap.char(35)` | ✅ | `I_PurOrdAccountAssignmentTP_2.GoodsRecipientName` ของ item แรก (นามผู้รับสินค้า) — ว่างได้ |
| `UnloadingPointName` | `abap.char(25)` | ✅ | `I_PurOrdAccountAssignmentTP_2.UnloadingPointName` |
| `GoodsRecipientPhone` | `abap.char(30)` | ⏸ | ไม่มี source |

### 2.5 Totals block (ท้ายฟอร์ม)

| Node | Type | สถานะ | Source |
|---|---|---|---|
| `DocumentCurrency` | `waers` | ✅ | `DocumentCurrency` |
| `TotalAmount` | `abap.curr(16,2)` | 🔧 | Σ `ItemAmount` ของ item ที่ไม่ลบ (= `ZI_PURE001_TOTAL.NetOrderValue`) — รวมเงิน/Total |
| `DiscountAmount` | `abap.curr(16,2)` | ⏸ | ไม่มี source ระดับ header → `0` (ฟอร์มโชว์ `-`) |
| `AmountBeforeTax` | `abap.curr(16,2)` | 🔧 | `TotalAmount − DiscountAmount` — รวมเงิน/Amount |
| `TaxAmount` | `abap.curr(16,2)` | 🔧 | Σ (`ItemAmount` × `TaxRate` / 100) ต่อ item — ภาษี/Tax |
| `NetAmount` | `abap.curr(16,2)` | 🔧 | `AmountBeforeTax + TaxAmount` — สุทธิ/Net Amount |
| `AmountInWords` | `abap.char(255)` | 🔧 | `(สี่แสนสี่หมื่นเก้าพันสี่ร้อยบาทถ้วน)` ← `amount_in_words_th( NetAmount )` · สกุลอื่นที่ไม่ใช่ THB → ภาษาอังกฤษ (open question 7) |

### 2.6 Signature block

| Node | Type | สถานะ | Source |
|---|---|---|---|
| `PreparedByUser` | `abap.char(12)` | ✅ | `CreatedByUser` |
| `PreparedByName` | `abap.char(80)` | ✅ | `I_BusinessUserBasic.PersonFullName` (`UserID` = `CreatedByUser`) |
| `PreparedDate` / `PreparedDateText` | dats / char(40) | ✅🔧 | `CreationDate` + วันที่ไทย |
| `ApprovedByUser` | `abap.char(12)` | ✅ | `ZI_PURE001_FORM_APPROVER` — task `RELEASED` ล่าสุดของ workflow ล่าสุด → `WorkflowTaskProcessor` · ว่างถ้า approved automatically |
| `ApprovedByName` | `abap.char(80)` | ✅ | `I_BusinessUserBasic.PersonFullName` |
| `ApprovedDate` / `ApprovedDateText` | dats / char(40) | ✅🔧 | `WrkflwTskCompletionUTCDateTime` → วันที่ (แปลง UTC → เวลาไทย) + วันที่ไทย |
| `ApprovedByPosition` | `abap.char(80)` | ⏸ | config / HR — *ผู้จัดการฝ่ายสนับสนุนองค์กร* |
| `ApprovedBySignature` | `abap.rawstring(0)` `@Semantics.largeObject` | ⏸ | graphics table |
| `ApprovedBySignMimeType` / `ApprovedBySignFileName` | char | ⏸ | คู่กับรูป |
| `IsApprovedAutomatically` | `abap.char(1)` | ✅ | `ZI_PURE001_HEADER.ApprovalStatus = 'B'` — ให้ฟอร์มเลือกข้อความ *"เอกสารสั่งซื้อนี้ได้รับการอนุมัติจากผู้มีอำนาจผ่านระบบอิเล็กทรอนิกส์เรียบร้อยแล้ว"* |

> ข้อความคงที่ท้ายฟอร์ม (*โปรดระบุใบสั่งซื้อนี้ลงในใบส่งของ…* / *We hereby accept…*) → **ฝังใน layout** ไม่ผ่าน data

---

## 3. `ZI_PURE001_ITEM_FDP` — item line

เฉพาะ item ที่ **ไม่ถูกลบ** (`PurchasingDocumentDeletionCode <> 'L'`) เรียงตาม `PurchaseOrderItem`

| Node | Type | สถานะ | Source |
|---|---|---|---|
| `PurchaseOrder` | `ebeln` | ✅ | key |
| `PurchaseOrderItem` | `ebelp` | ✅ | key |
| `ItemNumber` | `abap.int4` | 🔧 | ลำดับ/Item — นับ 1..n ใหม่ |
| `Material` | `matnr` | ✅ | `Material` — ว่างถ้าเป็น text item |
| `MaterialDescription` | `abap.char(40)` | ✅ | `PurchaseOrderItemText` |
| `ItemDescription` | `abap.char(80)` | 🔧 | บรรทัดแรกของช่องรายการ: `1000001 MA Core Switch Year 2024` = `Material` + ` ` + `MaterialDescription` (ถ้าไม่มี material = description อย่างเดียว) |
| `Quantity` | `abap.quan(13,3)` | ✅ | `OrderQuantity` |
| `QuantityText` | `abap.char(20)` | 🔧 | `12` / `1.5` — ตัดทศนิยมท้ายที่เป็น 0 ← `format_quantity( )` |
| `Unit` | `meins` | ✅ | `PurchaseOrderQuantityUnit` |
| `NetPriceAmount` | `abap.curr(11,2)` | ✅ | `NetPriceAmount` — ราคาต่อหน่วย |
| `NetPriceQuantity` | `abap.quan(5,0)` | ✅ | `NetPriceQuantity` (ราคาต่อกี่หน่วย ปกติ 1) |
| `ItemAmount` | `abap.curr(16,2)` | ✅ | `NetAmount` — จำนวนเงินรวม |
| `TaxCode` | `abap.char(2)` | ✅ | `TaxCode` |
| `TaxRate` | `abap.dec(5,2)` | ✅ | `I_TaxCodeRate.ConditionRateRatio` where `TaxType='V'` and `VATConditionType='MWVS'` — `V1` → 7.00 |
| `TaxAmount` | `abap.curr(16,2)` | 🔧 | `ItemAmount × TaxRate / 100` |
| `DeliveryDate` | `abap.dats` | ✅ | `I_PurOrdScheduleLineAPI01.ScheduleLineDeliveryDate` (schedule line `0001`) |
| `DeliveryDateText` | `abap.char(40)` | 🔧 | `Delivery Time : 26/06/2025` — ฟอร์มใช้ dd/mm/yyyy ค.ศ. (ต่างจาก header ที่เป็นไทย) |
| `PerformancePeriodStartDate` / `EndDate` | `abap.dats` | ✅ | schedule line — สำหรับ service item (`16 January 2025 - 16 January 2026`) |
| `PurchaseRequisition` | `banfn` | ✅ | `I_PurchaseOrderItemAPI01.PurchaseRequisition` — `PR No.` |
| `GLAccount` | `saknr` | ✅ | `I_PurOrdAccountAssignmentTP_2.GLAccount` (account assignment `01`) — `Acc.Code` |
| `CostCenter` | `kostl` | ✅ | `CostCenter` |
| `OrderID` | `aufnr` | ✅ | `OrderID` — `Order No.` |
| `WBSElement` | `abap.char(24)` | ✅ | `WBSElementExternalID` — `WBS: C-19-OPD13-00CO-ME` |
| `AccountAssignmentText` | `abap.char(120)` | 🔧 | `PR No.: 168999  Acc.Code: 820000  Order No.: 1600000001` — ประกอบให้ (ข้ามส่วนที่ว่าง) เผื่อ designer ไม่อยากต่อเอง |
| `Plant` | `werks_d` | ✅ | `Plant` |

---

## 4. `ZI_PURE001_ITXT_FDP` — ข้อความใต้รายการ

**แบบ B (ผู้ใช้ตัดสินใจ 2026-09-13)** — แยก node ต่อ text type ให้ฟอร์มจัด layout เอง (ตามแนวทาง SAP standard)
· 1 node ต่อ **text type** — text เป็น `string` หลายบรรทัดได้ (ตาม `\n` ที่ user พิมพ์ใน PO) designer ใช้ text field
*Allow Multiple Lines* + *Expand to fit* · ลำดับตามฟอร์ม: Material PO Text → Item Text → Delivery Text · ภาษา = `Language` ของ PO

ช่อง "รายการ/Description" ของ item 1 ในฟอร์มตัวอย่าง ประกอบจาก field ของ §3 + node ของ §4 ดังนี้

```
1000001 MA Core Switch Year 2024                          ← §3 ItemDescription
Material PO Text XXXXXXXXXXXXXXXXXX 1                     ┐ §4 node TextObjectType = F03
Material PO Text XXXXXXXXXXXXXXXXXX 2                     ┘
Item Text XXXXXXXXXXXXXXXXXXXX 1                          ┐ §4 node TextObjectType = F01
Item Text XXXXXXXXXXXXXXXXXXXX 2                          ┘
Delivery Time : 26/06/2025                                ← §3 DeliveryDateText (มี label มาให้แล้ว)
PR No.: 168999  Acc.Code: 820000  Order No.: 1600000001   ← §3 AccountAssignmentText (หรือแยก field + label ในฟอร์ม)
WBS: C-19-OPD13-00CO-ME                                   ← §3 WBSElement (ฟอร์มใส่ label "WBS:")
```

| Node | Type | สถานะ | Source |
|---|---|---|---|
| `PurchaseOrder` | `ebeln` | ✅ | key |
| `PurchaseOrderItem` | `ebelp` | ✅ | key |
| `TextSequence` | `abap.int4` | 🔧 | key — 1 = `F03`, 2 = `F01`, 3 = `F04` (เฉพาะที่มีข้อความ) |
| `TextObjectType` | `abap.char(4)` | ✅ | `I_PurchaseOrderItemNoteTP_2.TextObjectType` — `F03` Material PO Text · `F01` Item Text · `F04` Delivery Text |
| `TextTypeName` | `abap.char(40)` | 🔧 | `Material PO Text` / `Item Text` / `Delivery Text` |
| `Text` | `abap.string` | ✅ | `PlainLongText` |

---

## 5. Query provider `ZCL_PURE001_FDP` — พฤติกรรม

| เรื่อง | กติกา |
|---|---|
| key | รับ `PurchaseOrder` จาก filter (`get_as_ranges` → `PURCHASEORDER`) · framework อ่านทั้ง 3 ชั้นด้วย `$expand=_Item($expand=_ItemText)` แล้วเรียก `select` แยกต่อ entity · **ItemText มาเป็น `(PO = x AND Item = y) OR (…)` ซึ่งแปลง range ไม่ได้ → เดิน `get_as_tree( )` เก็บค่า PO** (D13) — ส่ง text ของ item ที่ไม่ลบทั้งหมดกลับ ซึ่งตรงกับชุด key ที่ขอ |
| item ที่ลบ | ไม่ส่งออก |
| ภาษา text | `Language` ของ PO · ถ้าไม่มี text ในภาษานั้น ไม่ fallback (ว่าง) — ⬜ ทบทวน: ข้อมูลจริง text ทุกใบเป็น `E` (05 ข้อ 18) |
| วันที่ไทย | `to_thai_date( iv_date )` → `21 พฤศจิกายน 2568` · วันที่ว่าง → `''` |
| amount in words | `zcl_pure001_util=>amount_in_words( iv_amount iv_currency )` → THB `(…บาทถ้วน)` / `(…บาท…สตางค์)` · สกุลอื่น → ภาษาอังกฤษ |
| ยอดรวม/ภาษี | คำนวณจาก item ที่ส่งออก (ไม่ใช่จาก header) เพื่อให้ตัวเลขในฟอร์มตรงกับรายการที่พิมพ์ |
| approver | `ZCL_PURE001_DATA->read_approvers( )` — task `RELEASED`+`COMPLETED` ล่าสุดของ workflow ล่าสุด → `I_BusinessUserBasic` · timestamp `TZNTSTMPL` แปลงเป็นวันที่ด้วย `CONVERT TIME STAMP … TIME ZONE 'UTC+7'` · approved automatically → ชื่อว่าง + `IsApprovedAutomatically = 'X'` · ยังไม่อนุมัติ → ว่างทั้งคู่ |
| error | โยน `ZCX_PURE001_QUERY` |

---

## 6. ⏸ Placeholder ที่รอปิด (สรุปให้ functional)

| กลุ่ม | Node | ต้องการ |
|---|---|---|
| Setting View (config) | `CompanyAddressLine1/2`, `CompanyPhone`, `CompanyWebsite`, `ShipToAddressLine1/2`, `ApprovedByPosition` (+ `CompanyName` ถ้าต้องการชื่อเต็ม) | ตาราง config + วิธี maintain |
| Custom field บน PO | `PerfGuarantee*`, `InsurancePolicyFlag`, `WarrantyGuarantee*`, `SupplierEmail` | ชื่อ technical `YY1_*` + expose ใน `I_PurchaseOrderAPI01` |
| Graphics | `CompanyLogo`, `ApprovedBySignature` | table กลางบน tenant หรือ `ZPURE001_GRPH` |
| ไม่มี source | `DiscountAmount`, `GoodsRecipientPhone` | ตัดจากฟอร์ม หรือ config |

---

## 7. `ZR_PURE001` — entity ของ RAP UI (list report) — Phase 1 ✅

**คนละตัวกับ FDP entity** แต่ใช้ `ZCL_PURE001_DATA` ตัวเดียวกัน → Status / Approval / ยอดรวมตรงกันแน่นอน
ดูรายละเอียดที่ [02-object-list.md](02-object-list.md) และ [06-decisions.md D12](06-decisions.md)

| ชั้น | Object | ทำอะไร |
|---|---|---|
| UI | `ZR_PURE001` (custom entity) | 13 filter (VH ครบ) · 11 column · `@Search.searchable` |
| Query | `ZCL_PURE001_QUERY` | filter Status/Approval/$search · count · sort · paging ใน memory · ต่อ string `MaterialList` / `PlantList` |
| Data | `ZCL_PURE001_DATA` | อ่าน view มาตรฐาน + derive `PurchaseOrderStatus` / `ApprovalStatus` + criticality |
