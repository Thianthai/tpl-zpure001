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
 '$.PurchaseOrderNode.CorrespncInternalReference':  H+'InternalReference',
 '$.PurchaseOrderNode.PurchaseOrderItems.PurchaseOrderItemNode[*].FirstDeliveryDate': H+'DeliveryDateText',
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
 '$.PurchaseOrderQuantityUnit':    '$.UnitText',
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
s=edit_field(s,'ShiptoAddress',bind(H+'ShipToAddressLine1'))       # ที่อยู่ของ plant จาก address master
s=edit_field(s,'AmtInWord',    bind(H+'AmountInWords'))
s=edit_field(s,'Create_date',  bind(H+'PreparedDateText'))
s=edit_field(s,'Field_Date_Source', bind(H+'PurchaseOrderDate'))
s=edit_field(s,'TextField7',   bind(H+'PurchaseOrderDateText'))
# ต้นทางเปลี่ยน DeliveryDate เป็น calculate script จึงต้อง bind ตรงนี้เอง
s=edit_field(s,'DeliveryDate',  bind(H+'DeliveryDateText'))

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
UnitText DocumentCurrency NetPriceAmount NetPriceQuantity ItemAmount TaxCode TaxRate TaxAmount DeliveryDate DeliveryDateText PerformancePeriodStartDate
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


# ---------- 10b. drop scripts that still read the standard data model ----------
s=open('ZPURF002.xdp',encoding='utf-8').read()
pattern=re.compile(r'\n[ \t]*<event activity="[^"]*"[^>]*>\s*<script[^>]*>(?:(?!</script>).)*?PurchaseOrderNode(?:(?!</script>).)*?</script>\s*</event>', re.S)
n=len(pattern.findall(s))
s=pattern.sub('', s)
open('ZPURF002.xdp','w',encoding='utf-8').write(s)
print(f"removed {n} event scripts that referenced the standard data model")

# ---------- 11. hide the logo and the company address until the order is approved ----------
s=open('ZPURF002.xdp',encoding='utf-8').read()
LOGO_SCRIPT = """
               <event activity="ready" ref="$layout" name="event__layout_ready">
                  <script contentType="application/x-javascript">// โลโก้และที่อยู่บริษัทพิมพ์เฉพาะใบที่อนุมัติแล้ว
// ABAP ส่ง ApprovalNoteText มาเมื่อสถานะอนุมัติเท่านั้น จึงใช้เป็นตัวชี้วัด
var oNote = xfa.resolveNode("xfa.datasets.data.Form.PurchaseOrderHeader.ApprovalNoteText");
var bApproved = (oNote !== null &amp;&amp; oNote.value !== null &amp;&amp; oNote.value !== "");
var sPresence = bApproved ? "visible" : "hidden";

// ทั้งสองตัวเป็น draw และ subform ที่ผูก script กับตัวเองไม่ได้
// จึงสั่ง presence จาก field ที่อยู่บน master page เดียวกัน
var aNames = ["Image1", "CompAddress"];

for (var i = 0; i &lt; aNames.length; i++) {

    var oTarget = null;
    try { oTarget = this.parent.resolveNode(aNames[i]); } catch (oError) { }
    if (oTarget === null) { try { oTarget = xfa.resolveNode(aNames[i]); } catch (oError) { } }

    if (oTarget !== null) {
        oTarget.presence = sPresence;
    }
}
</script>
               </event>"""
m=re.search(r'<field name="PurchaseOrderNumber"[\s>]', s)
end=s.find('</field>', m.start())
assert end > 0
s=s[:end]+LOGO_SCRIPT+"\n            "+s[end:]
open('ZPURF002.xdp','w',encoding='utf-8').write(s)
print("logo and company address visibility script added")


# ---------- 12. amount in words on two lines (2026-11-25) ----------
# The footer cannot grow downwards: EndOfPage ends at 282.8mm and CompAddress starts at 283.5mm.
# So the footer grows upwards by DELTA: the item table and the content area become DELTA shorter,
# the footer and the totals column move up by DELTA, and the amount in words and net amount rows
# become DELTA taller. Everything from EndOfPage down stays where it was.
s=open('ZPURF002.xdp',encoding='utf-8').read()
DELTA=3.3
pa_start=s.index('<pageArea name="mstDummy"'); pa_end=s.index('</pageArea>',pa_start)
pa=s[pa_start:pa_end]
assert 'name="Footer" y="221.5mm"' in pa or 'name="Footer" y="218.2mm"' in pa

if 'name="Footer" y="218.2mm"' in pa:
    print("step 12 already applied")
else:
    def mm(v): return float(v[:-2])
    def fmt(v): return ('%.3f' % v).rstrip('0').rstrip('.') + 'mm'

    def shift(block, tag, name, attr, delta, indent=None):
        # change one numeric attribute of the element <tag name="name" ...> (exactly one match)
        tags = list(re.finditer(r'<%s\b[^>]*\bname="%s"[^>]*>' % (tag, re.escape(name)), block))
        assert len(tags) == 1, (name, len(tags))
        t = tags[0]
        new_tag, n = re.subn(r'(\b%s=")([0-9.]+mm)(")' % attr,
                             lambda m: m.group(1) + fmt(mm(m.group(2)) + delta) + m.group(3), t.group(0))
        assert n == 1, (name, attr, n)
        return block[:t.start()] + new_tag + block[t.end():]

    # page level: item grid, content area, totals column, footer
    pa = re.sub(r'(<contentArea\b[^>]*\bh=")([0-9.]+mm)(")', lambda m: m.group(1)+fmt(mm(m.group(2))-DELTA)+m.group(3), pa, count=1)
    for i in range(1, 7):
        pa = shift(pa, 'draw', 'Rectangle%d' % i, 'h', -DELTA)
    for name in ['Total', 'Discount', 'SumAmt', 'TaxAmt', 'NetAmt']:
        pa = shift(pa, 'field', name, 'y', -DELTA)
    pa = shift(pa, 'field', 'NetAmt', 'h', DELTA)
    pa = shift(pa, 'subform', 'Footer', 'y', -DELTA)
    pa = shift(pa, 'subform', 'Footer', 'h', DELTA)

    # inside the footer: the amount in words row and the net amount label row grow by DELTA
    f_start = re.search(r'<subform\b[^>]*\bname="Footer"', pa).start()
    f_end = pa.index('</subform>', f_start)
    ft = pa[f_start:f_end]
    ft = shift(ft, 'field', 'AmtInWord', 'h', DELTA)
    ft = shift(ft, 'draw', 'Text8', 'h', DELTA)

    a = ft.index('<field name="AmtInWord"'); b = ft.index('</field>', a)
    fld = ft[a:b]
    # wrap long text onto the second line
    assert fld.count('<textEdit/>') == 1
    fld = fld.replace('<textEdit/>', '<textEdit multiLine="1"/>')
    # value uses the same font as the caption "Amount in words"
    assert fld.count('<font typeface="Tahoma" size="7.5pt"/>') == 1
    fld = fld.replace('<font typeface="Tahoma" size="7.5pt"/>', '<font typeface="Tahoma" size="7.5pt" fontHorizontalScale="98%"/>')
    # caption and value centred vertically so one or two lines both look aligned
    assert fld.count('<para vAlign="bottom" hAlign="justify"') == 1
    fld = fld.replace('<para vAlign="bottom" hAlign="justify"', '<para vAlign="middle" hAlign="justify"')
    assert fld.count('<para spaceAbove="0pt" vAlign="bottom"/>') == 1
    fld = fld.replace('<para spaceAbove="0pt" vAlign="bottom"/>', '<para spaceAbove="0pt" vAlign="middle"/>')
    ft = ft[:a] + fld + ft[b:]

    pa = pa[:f_start] + ft + pa[f_end:]
    s = s[:pa_start] + pa + s[pa_end:]
    open('ZPURF002.xdp','w',encoding='utf-8').write(s)
    print("step 12 applied: footer grows upwards by %.1fmm, amount in words on two lines" % DELTA)


# ---------- 13. general conditions page at the end of every order (2026-11-26, D23) ----------
# Text master = ZPURF002_general_conditions.docx (checked by the user, spelling kept as production).
# Layout copies the production page of PO 99690990: no logo, header or footer, DokChampa 7pt,
# every line in DokChampa regular, the heading too (the production page only looks bold
# because the whole page is drawn with a 0.2pt text stroke), number at 15mm, text at 20mm, line pitch 9.4pt, justified.
# The page is not counted: every pageCount() becomes pageCount() - 1.
import zipfile, html
s=open('ZPURF002.xdp',encoding='utf-8').read()
if 'name="mstTerms"' in s:
    print("step 13 already applied")
else:
    dx = zipfile.ZipFile('ZPURF002_general_conditions.docx').read('word/document.xml').decode('utf-8')
    paras = []
    for p in re.findall(r'<w:p[ >].*?</w:p>', dx, re.S):
        t = html.unescape(''.join(re.findall(r'<w:t[^>]*>([^<]*)</w:t>', p)))
        if t.strip():
            paras.append(t)
    assert len(paras) == 36, len(paras)
    title, subtitle, body = paras[0], paras[1], paras[2:]

    LINE = 'lineHeight="9.4pt"'
    W_ALL, W_NO = 179.95, 5.0
    W_TXT = W_ALL - W_NO
    def esc(t): return t.replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;')
    def draw(name, text, w, typeface, bold=False, align='justify', below='0pt'):
        weight = ' weight="bold"' if bold else ''
        return ('<draw name="%s" w="%.2fmm" minH="3.3mm"><ui><textEdit/></ui>'
                '<value><text>%s</text></value>'
                '<font typeface="%s" size="7pt"%s/>'
                '<margin topInset="0mm" bottomInset="0mm" leftInset="0mm" rightInset="0mm"/>'
                '<para hAlign="%s" %s spaceAbove="0pt" spaceBelow="%s"/></draw>'
                % (name, w, esc(text), typeface, weight, align, LINE, below))

    parts = ['<subform name="Terms" layout="tb" w="%.2fmm">' % W_ALL,
             '<bind match="none"/>',
             '<breakBefore targetType="pageArea" target="mstTerms" startNew="1"/>',
             draw('Title', title, W_ALL, 'DokChampa', align='left'),
             draw('Subtitle', subtitle, W_ALL, 'DokChampa', align='left', below='9.4pt')]
    for i in range(0, len(body), 2):
        en, th = body[i], body[i + 1]
        m = re.match(r'^(\d+)\.\s+(.*)$', en)
        assert m, en[:30]
        parts += ['<subform name="Clause" layout="lr-tb" w="%.2fmm"><bind match="none"/>' % W_ALL,
                  draw('No', m.group(1) + '.', W_NO, 'DokChampa', align='left'),
                  '<subform name="Body" layout="tb" w="%.2fmm"><bind match="none"/>' % W_TXT,
                  draw('En', m.group(2), W_TXT, 'DokChampa'),
                  draw('Th', th, W_TXT, 'DokChampa'),
                  '</subform></subform>']
    parts.append('</subform>')
    terms = '\n      '.join(parts) + '\n      '

    # new page area without any master-page content; the order pages repeat on mstDummy
    medium = '<medium stock="a4" short="210mm" long="297mm"/>'
    pa_start = s.index('<pageArea name="mstDummy"'); pa_end = s.index('</pageArea>', pa_start)
    pa = s[pa_start:pa_end]
    assert pa.count(medium) == 1
    pa = pa.replace(medium, medium + '\n            <occur max="-1"/>')
    s = s[:pa_start] + pa + s[pa_end:]
    close_pa = s.index('</pageArea>', pa_start) + len('</pageArea>')
    s = s[:close_pa] + ('\n         <pageArea name="mstTerms" id="mstTerms_ID">'
                        '\n            <contentArea x="15.03mm" y="12.63mm" w="179.95mm" h="274mm" name="cntTerms" id="cntTerms_ID"/>'
                        '\n            ' + medium +
                        '\n            <occur min="0" max="-1"/>'
                        '\n         </pageArea>') + s[close_pa:]

    # terms subform after Main, before the hidden static texts
    anchor = '<subform w="100mm" h="30mm" name="frmHiddenStaticTexts"'
    assert s.count(anchor) == 1
    s = s.replace(anchor, terms + anchor)

    # page numbers and last-page checks ignore the terms page
    n = s.count('xfa.layout.pageCount()')
    s = s.replace('xfa.layout.pageCount()', '(xfa.layout.pageCount() - 1)')
    open('ZPURF002.xdp','w',encoding='utf-8').write(s)
    print("step 13 applied: general conditions page, %d clauses, %d pageCount() calls adjusted" % (len(body)//2, n))


# ---------- 13b. Thai lines of the general conditions: spaces in Arial (2026-11-26) ----------
# Preview showed the spaces between Thai words much wider than production (DokChampa's space
# in a Thai run). Each Thai line becomes rich text where only the spaces use Arial.
s=open('ZPURF002.xdp',encoding='utf-8').read()
th_draws = list(re.finditer(r'<draw name="Th" [^>]*>.*?</draw>', s, re.S))
assert len(th_draws) == 17, len(th_draws)
if 'exData' in th_draws[0].group(0):
    print("step 13b already applied")
else:
    def to_rich(m):
        d = m.group(0)
        t = re.search(r'<value><text>(.*?)</text></value>', d, re.S)
        body = re.sub(r' +', lambda sp: '<span style="font-family:Arial">%s</span>' % sp.group(0), t.group(1))
        rich = ('<value><exData contentType="text/html"><body xmlns="http://www.w3.org/1999/xhtml" '
                'xmlns:xfa="http://www.xfa.org/schema/xfa-data/1.0/">'
                '<p style="font-family:DokChampa;font-size:7pt;text-align:justify;line-height:9.4pt;'
                'margin-top:0pt;margin-bottom:0pt">%s</p></body></exData></value>' % body)
        return d[:t.start()] + rich + d[t.end():]
    s = re.sub(r'<draw name="Th" [^>]*>.*?</draw>', to_rich, s, flags=re.S)
    open('ZPURF002.xdp','w',encoding='utf-8').write(s)
    print("step 13b applied: 17 Thai lines with Arial spaces")


# ---------- 13c. preview round 2 fixes (2026-11-26) ----------
# (a) clause 17: "SUPPLIER/" must start the last line like production. A word joiner (U+2060)
#     after the slash keeps SUPPLIER/CONTRACTOR together, so the whole word moves down.
# (b) Thai lines: font size is tuned step by step against production (TH_SIZE, re-runnable).
TH_SIZE = '6.5pt'
s=open('ZPURF002.xdp',encoding='utf-8').read()
old17 = 'invoices, SUPPLIER/CONTRACTOR shall make'
new17 = 'invoices, SUPPLIER/⁠CONTRACTOR shall make'
if new17 not in s:
    assert s.count(old17) == 1
    s = s.replace(old17, new17)
def th_size(m):
    d = m.group(0)
    d = re.sub(r'(<font typeface="DokChampa" size=")[0-9.]+pt(")', r'\g<1>%s\2' % TH_SIZE, d)
    return re.sub(r'(font-size:)[0-9.]+pt', r'\g<1>%s' % TH_SIZE, d)
s = re.sub(r'<draw name="Th" [^>]*>.*?</draw>', th_size, s, flags=re.S)
open('ZPURF002.xdp','w',encoding='utf-8').write(s)
print("step 13c applied: clause 17 word joiner, Thai lines %s" % TH_SIZE)
