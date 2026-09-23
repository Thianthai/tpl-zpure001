@EndUserText.label: 'Print Purchase Order - PDF Result'
define abstract entity ZA_PURE001_FILE
{
      @EndUserText.label: 'File ID'
  key FileId        : sysuuid_x16;

      @EndUserText.label: 'File Name'
      FileName      : abap.char(255);

      @EndUserText.label: 'File Extension'
      FileExtension : abap.char(10);

      @EndUserText.label: 'MIME Type'
      MimeType      : abap.char(128);

      @EndUserText.label: 'File Content'
      FileContent   : abap.string;
}
