import re, uuid, datetime
SRC='/Users/thianthai/Downloads/YY1_MM_PUR_PURCHASE_ORDER_EN/YY1_MM_PUR_PURCHASE_ORDER_E.xdp'
s=open(SRC,encoding='utf-8').read()
log=[]

# ---------- helpers ----------
def remove_subform(s, name):
    m=re.search(r'\n[ \t]*<subform[^>]*\bname="%s"[^>]*>'%re.escape(name), s)
    assert m, name
    start=m.start()
    i=m.end(); depth=1
    while depth:
        n=re.compile(r'<subform\b|</subform>').search(s,i)
        depth += 1 if n.group(0)=='<subform' else -1
        i=n.end()
    log.append(f"removed subform {name} ({i-start} chars)")
    return s[:start]+s[i:]

def field_blocks(s, name):
    return [(m.start(), s.find('</field>', m.start())+len('</field>')) for m in re.finditer(r'<field name="%s"[\s>]'%re.escape(name), s)]

def edit_field(s, name, fn):
    out=[]; last=0
    for a,b in field_blocks(s,name):
        out.append(s[last:a]); out.append(fn(s[a:b])); last=b
    out.append(s[last:])
    return ''.join(out)

# ---------- 1. drop subforms we do not use ----------
s=remove_subform(s,'frmHiddenGlobalFields')
s=remove_subform(s,'ItemLimit')

# ---------- 2. drop every <calculate> script (all replaced by ABAP values) ----------
n=len(re.findall(r'<calculate>', s))
s=re.sub(r'\n[ \t]*<calculate\b(?:\s[^>]*[^/>])?>.*?</calculate>', '', s, flags=re.S)
log.append(f"removed {n} calculate blocks")

# ---------- 3. global binding map (old standard FDP path -> ZAPI_PURE001_FDP) ----------
H='$.PurchaseOrderHeader.'
ref_map={
 '$.PurchaseOrderNode.PurchaseOrder':               H+'PurchaseOrder',
 '$.PurchaseOrderNode.PurchaseOrderDate':           H+'PurchaseOrderDate',
 '$.PurchaseOrderNode.YY1_IssuedDateTH_PDH':        H+'PurchaseOrderDateText',
 '$.PurchaseOrderNode.YY1_FrameworkStartDate_PDH':  H+'ValidityStartDateText',
 '$.PurchaseOrderNode.YY1_FrameworkEndDate_PDH':    H+'ValidityEndDateText',
 '$.PurchaseOrderNode.YY1_ValidFromTH_PDH':         H+'ValidityStartDateText',
 '$.PurchaseOrderNode.YY1_ValidToTH_PDH':           H+'ValidityEndDateText',
 '$.PurchaseOrderNode.YY1_SuppCodeNameBranch_PDH':  H+'SupplierCodeName',
 '$.PurchaseOrderNode.YY1_SupplierAddress_PDH':     H+'SupplierAddress',
 '$.PurchaseOrderNode.CorrespncExternalReference':  H+'ExternalReference',
 '$.PurchaseOrderNode.SupplierRespSalesPersonName': H+'SupplierContactName',
 '$.PurchaseOrderNode.YY1_Email_PO_PDH':            H+'SupplierEmail',
 '$.PurchaseOrderNode.SupplierPhoneNumber':         H+'SupplierPhone',
 '$.PurchaseOrderNode.ShipToParty.AddressLine2':    H+'ShipToName',
 '$.PurchaseOrderNode.YY1_RecipientContact_PDH':    H+'GoodsRecipientName',
 '$.PurchaseOrderNode.YY1_RecipientTelephone_PDH':  H+'GoodsRecipientPhone',
 '$.PurchaseOrderNode.PaymentTermsName':            H+'PaymentTermsText',
 '$.PurchaseOrderNode.YY1_PerformanceBond_PO_PDH':  H+'PerfGuaranteeFlag',
 '$.PurchaseOrderNode.YY1_BankGuarantee_PO_P_PDH':  H+'PerfGuaranteeBG',
 '$.PurchaseOrderNode.YY1_Retention_PO_Per_PDH':    H+'PerfGuaranteeCash',
 '$.PurchaseOrderNode.YY1_Insurance_PO_PDH':        H+'InsurancePolicyFlag',
 '$.PurchaseOrderNode.YY1_WarrantyBond_PO_PDH':     H+'WarrantyGuaranteeFlag',
 '$.PurchaseOrderNode.YY1_Retention_PO_W_PDH':      H+'WarrantyGuaranteeCash',
 '$.PurchaseOrderNode.YY1_BankGuarantee_PO_W_PDH':  H+'WarrantyGuaranteeBG',
 '$.PurchaseOrderNode.YY1_CreateNameTH_PDH':        H+'PreparedByName',
 '$.PurchaseOrderNode.YY1_Last_Change_PO_PDH':      H+'PreparedDateText',
 '$.PurchaseOrderNode.YY1_Approval_PDH':            H+'ApprovedByName',
 '$.PurchaseOrderNode.YY1_Approval_Position_PDH':   H+'ApprovedByPosition',
 '$.PurchaseOrderNode.YY1_Approval_date_PDH':       H+'ApprovedDateText',
 '$.PurchaseOrderNode.YY1_SumNetAmt_PDH':           H+'TotalAmount',
 '$.PurchaseOrderNode.YY1_SumOtherExpense_PDH':     H+'DiscountAmount',
 '$.PurchaseOrderNode.YY1_SumAmount_PDH':           H+'AmountBeforeTax',
 '$.PurchaseOrderNode.YY1_SumTax_PDH':              H+'TaxAmount',
 '$.PurchaseOrderNode.YY1_SumTotalNetAmt_PDH':      H+'NetAmount',
 '$.PurchaseOrderNode.PurchaseOrderItems.PurchaseOrderItemNode[*]': H+'_Item.PurchaseOrderItem[*]',
 # cells (relative to item node)
 '$.PurchaseOrderItem':            '$.ItemNumber',
 '$.PurchaseOrderQty':             '$.QuantityText',
 '$.PurchaseOrderQuantityUnit':    '$.Unit',
 '$.PurchaseOrderNetPriceAmount':  '$.NetPriceAmount',
 '$.PurchaseOrderItemNetAmount':   '$.ItemAmount',
}
for old,new in ref_map.items():
    c=s.count(f'ref="{old}"')
    s=s.replace(f'ref="{old}"', f'ref="{new}"')
    log.append(f"ref {old} -> {new} ({c})")

# ---------- 4. field-specific bindings ----------
def bind(new_ref):
    def fn(b):
        b2=re.sub(r'<bind match="none"( ref="")?/>', f'<bind match="dataRef" ref="{new_ref}"/>', b)
        b2=re.sub(r'<bind match="dataRef" ref="[^"]*"/>', f'<bind match="dataRef" ref="{new_ref}"/>', b2)
        return b2
    return fn
s=edit_field(s,'Cell2',        bind('$.ItemDescriptionText'))
s=edit_field(s,'TextField6',   bind(H+'ShipVia'))
s=edit_field(s,'ShiptoAddress',bind(H+'ShipToPlantName'))          # ⏸ until ShipToAddressLine1/2 have a source
s=edit_field(s,'AmtInWord',    bind(H+'AmountInWords'))
s=edit_field(s,'Create_date',  bind(H+'PreparedDateText'))
s=edit_field(s,'Field_Date_Source', bind(H+'PurchaseOrderDate'))
s=edit_field(s,'TextField7',   bind(H+'PurchaseOrderDateText'))

# TextField8: approval note = value from ABAP (empty = nothing printed) -> drop caption + presence script, multiline
def fix_note(b):
    b=re.sub(r'\n[ \t]*<caption reserve="[^"]*">.*?</caption>', '', b, flags=re.S)
    b=re.sub(r'\n[ \t]*<event activity="ready".*?</event>', '', b, flags=re.S)
    b=b.replace('<textEdit/>','<textEdit multiLine="1"/>')
    return bind(H+'ApprovalNoteText')(b)
s=edit_field(s,'TextField8',fix_note)

# ---------- 5. checkboxes: on value 'X' / off '' (ABAP flag) ----------
n=0
def cb(m):
    global n; n+=1
    return m.group(1)+'X'+m.group(2)+''+m.group(3)
s=re.sub(r'(<items>\s*<text xliff:rid="[^"]*">)true(</text>\s*<text xliff:rid="[^"]*">)0(</text>\s*</items>)', cb, s)
log.append(f"checkbox items true/0 -> X/'' ({n})")

# ---------- 6. data connection + data description ----------
s=re.sub(r'<uri>[^<]*</uri>', r'<uri>.\\ZPURF002.xsd</uri>', s)
s=re.sub(r'\s*<\?templateDesigner fileDigest[^?]*\?>', '', s)

header_fields=[l.strip() for l in """
PurchaseOrder CompanyCode CompanyName CompanyTaxNumber CompanyAddressLine1 CompanyAddressLine2 CompanyPhone CompanyWebsite
CompanyLogoMimeType CompanyLogoFileName CompanyLogo PurchaseOrderType PurchaseOrderTypeName Language PurchaseOrderDate PurchaseOrderDateText
ExternalReference InternalReference PaymentTerms PaymentTermsText DeliveryDate DeliveryDateText ValidityStartDate ValidityStartDateText
ValidityEndDate ValidityEndDateText ShipVia HeaderText HeaderNote PerfGuaranteeFlag PerfGuaranteeCash PerfGuaranteeBG InsurancePolicyFlag
WarrantyGuaranteeFlag WarrantyGuaranteeCash WarrantyGuaranteeBG Supplier SupplierName SupplierCodeName SupplierTaxNumber SupplierAddress
SupplierStreet SupplierDistrict SupplierCity SupplierPostalCode SupplierContactName SupplierPhone SupplierEmail ShipToPlant ShipToName
ShipToPlantName ShipToAddressLine1 ShipToAddressLine2 GoodsRecipientName UnloadingPointName GoodsRecipientPhone DocumentCurrency TotalAmount
DiscountAmount AmountBeforeTax TaxAmount NetAmount AmountInWords PreparedByUser PreparedByName PreparedDate PreparedDateText ApprovedByUser
ApprovedByName ApprovedDate ApprovedDateText ApprovedByPosition ApprovedBySignMimeType ApprovedBySignFileName ApprovedBySignature
IsApprovedAutomatically ApprovalNoteText""".split()]
item_fields="""PurchaseOrder PurchaseOrderItem ItemNumber Material MaterialDescription ItemDescription ItemDescriptionText Quantity QuantityText Unit
DocumentCurrency NetPriceAmount NetPriceQuantity ItemAmount TaxCode TaxRate TaxAmount DeliveryDate DeliveryDateText PerformancePeriodStartDate
PerformancePeriodEndDate PurchaseRequisition GLAccount CostCenter OrderID WBSElement AccountAssignmentText Plant""".split()
text_fields="PurchaseOrder PurchaseOrderItem TextSequence TextObjectType TextTypeName Text".split()
decimals={'TotalAmount','DiscountAmount','AmountBeforeTax','TaxAmount','NetAmount','Quantity','NetPriceAmount','NetPriceQuantity','ItemAmount','TaxRate','ItemNumber','TextSequence'}

def dd_block():
    L=['   <dd:dataDescription xmlns:dd="http://ns.adobe.com/data-description/" dd:name="Form">','      <Form>','         <PurchaseOrderHeader>']
    L+=[f'            <{f}/>' for f in header_fields]
    L+=['            <_Item>','               <PurchaseOrderItem dd:maxOccur="-1">']
    L+=[f'                  <{f}/>' for f in item_fields]
    L+=['                  <_ItemText>','                     <PurchaseOrderItemText dd:maxOccur="-1">']
    L+=[f'                        <{f}/>' for f in text_fields]
    L+=['                     </PurchaseOrderItemText>','                  </_ItemText>','               </PurchaseOrderItem>','            </_Item>','         </PurchaseOrderHeader>','      </Form>','   </dd:dataDescription>']
    return '\n'.join(L)
s=re.sub(r'   <dd:dataDescription .*?</dd:dataDescription>', dd_block(), s, flags=re.S)

# ---------- 7. identity ----------
new_uuid=str(uuid.uuid4()); ts=datetime.datetime.utcnow().strftime('%Y-%m-%dT%H:%M:%SZ')
s=re.sub(r'timeStamp="[^"]*" uuid="[^"]*"', f'timeStamp="{ts}" uuid="{new_uuid}"', s, count=1)
s=re.sub(r'<xmpMM:DocumentID>uuid:[^<]*</xmpMM:DocumentID>', f'<xmpMM:DocumentID>uuid:{new_uuid}</xmpMM:DocumentID>', s)
s=re.sub(r'<xmp:MetadataDate>[^<]*</xmp:MetadataDate>', f'<xmp:MetadataDate>{ts}</xmp:MetadataDate>', s)

open('ZPURF002.xdp','w',encoding='utf-8').write(s)

# ---------- 8. XSD for Designer data connection ----------
def el(name, ind):
    t='decimal' if name in decimals else 'string'
    return f'{" "*ind}<element name="{name}" type="{t}"/>'
X=['<?xml version="1.0" encoding="utf-8"?>','<schema xmlns="http://www.w3.org/2001/XMLSchema">',
   ' <element name="Form">','  <complexType>','   <sequence>','    <element name="PurchaseOrderHeader" type="PurchaseOrderHeader"/>','   </sequence>','  </complexType>',' </element>',
   ' <complexType name="PurchaseOrderHeader">','  <sequence>']
X+=[el(f,3) for f in header_fields]
X+=['   <element name="_Item">','    <complexType>','     <sequence>','      <element name="PurchaseOrderItem" type="PurchaseOrderItem" minOccurs="0" maxOccurs="unbounded"/>','     </sequence>','    </complexType>','   </element>',
    '  </sequence>',' </complexType>',' <complexType name="PurchaseOrderItem">','  <sequence>']
X+=[el(f,3) for f in item_fields]
X+=['   <element name="_ItemText">','    <complexType>','     <sequence>','      <element name="PurchaseOrderItemText" type="PurchaseOrderItemText" minOccurs="0" maxOccurs="unbounded"/>','     </sequence>','    </complexType>','   </element>',
    '  </sequence>',' </complexType>',' <complexType name="PurchaseOrderItemText">','  <sequence>']
X+=[el(f,3) for f in text_fields]
X+=['  </sequence>',' </complexType>','</schema>','']
open('ZPURF002.xsd','w',encoding='utf-8').write('\n'.join(X))

print('\n'.join(log))
print("xdp bytes", len(s.encode('utf-8')))

# ---------- 9. cleanup: stale validate (from old short type) + comment-only event scripts ----------
s=open('ZPURF002.xdp',encoding='utf-8').read()
s=re.sub(r'\n[ \t]*<validate>\s*<script contentType="application/x-javascript">this\.isNull \|\|[^<]*</script>\s*</validate>', '', s)
s=re.sub(r'\n[ \t]*<event activity="ready" ref="\$layout" name="[^"]*">\s*<script contentType="application/x-javascript">(//[^<]*)?</script>\s*</event>', '', s)
open('ZPURF002.xdp','w',encoding='utf-8').write(s)
print("cleanup done; scripts left:", len(re.findall(r'<script contentType="application/x-javascript">[^<]{5,}</script>', s)))

# ---------- 10. fixes from Designer preview round 1 ----------
s=open('ZPURF002.xdp',encoding='utf-8').read()
# (a) date fields: our values are ready-made Thai text -> no data picture, no null validation
n1=len(re.findall(r'<bind match="dataRef" ref="([^"]*)">\s*<picture>[^<]*</picture>\s*</bind>', s))
s=re.sub(r'<bind match="dataRef" ref="([^"]*)">\s*<picture>[^<]*</picture>\s*</bind>', r'<bind match="dataRef" ref="\1"/>', s)
n2=s.count('<validate nullTest="error"/>')
s=s.replace('\n               <validate nullTest="error"/>','')
s=s.replace('<validate nullTest="error"/>','')
# (b) amount in words: use the same last-page presence script as the totals (editValue trick blanks the bound value)
old_js='var curPage = xfa.layout.page(this); \nvar totalPage = xfa.layout.pageCount(); \nthis.editValue = (curPage === totalPage) ? this.rawValue : "";'
new_js='var cur = xfa.layout.page(this);\nvar total = xfa.layout.pageCount();\nthis.presence = (cur === total) ? "visible" : "invisible"'
n3=s.count(old_js); s=s.replace(old_js,new_js)
open('ZPURF002.xdp','w',encoding='utf-8').write(s)
print(f"round1 fixes: bind pictures removed={n1}, nullTest removed={n2}, AmtInWord script replaced={n3}")
