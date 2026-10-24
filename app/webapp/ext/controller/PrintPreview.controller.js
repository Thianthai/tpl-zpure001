sap.ui.define([
    "sap/ui/core/mvc/ControllerExtension",
    "sap/m/BusyDialog",
    "sap/m/MessageToast",
    "sap/m/MessageBox",
    "sap/m/library",
    "zpure001/ext/util/PrintUtils"
], function (ControllerExtension, BusyDialog, MessageToast, MessageBox, mobileLibrary, PrintUtils) {
    "use strict";

    var URLHelper = mobileLibrary.URLHelper;

    // ชื่อ action ใน behavior definition ของ ZR_PURE001
    var PRINT_ACTION = "PrintPOForm";

    return ControllerExtension.extend("zpure001.ext.controller.PrintPreview", {

        override: {

            /**
             * Fiori Elements ไม่ทำอะไรกับไฟล์ที่ action ส่งกลับมา
             * จึงต้องดัก invokeAction เองเพื่อเปิด PDF ให้ผู้ใช้
             */
            onInit: function () {
                var oExtensionAPI = this.base.getExtensionAPI();
                var oEditFlow = oExtensionAPI && oExtensionAPI.getEditFlow();

                if (!oEditFlow) {
                    return;
                }

                var fnOriginalInvoke = oEditFlow.invokeAction.bind(oEditFlow);

                oEditFlow.invokeAction = function (sActionName, mParameters) {

                    // action อื่นปล่อยให้ framework จัดการตามปกติ
                    if (!sActionName || sActionName.indexOf(PRINT_ACTION) === -1) {
                        return fnOriginalInvoke(sActionName, mParameters);
                    }

                    var oBusyDialog = new BusyDialog({ text: "กำลังสร้างไฟล์ PDF..." });
                    oBusyDialog.open();

                    return Promise.resolve(fnOriginalInvoke(sActionName, mParameters))
                        .then(function (oResult) {
                            oBusyDialog.close();

                            var oFile = PrintUtils.unwrap(oResult);
                            var sContent = oFile && oFile.FileContent;

                            // ABAP ส่งข้อความ error กลับมาทาง message แทนไฟล์
                            if (!sContent) {
                                MessageToast.show("ไม่ได้รับไฟล์ PDF จากระบบ");
                                return oResult;
                            }

                            try {
                                var sUrl = PrintUtils.toBlobUrl(sContent, oFile.MimeType);

                                // เปิดดูในแท็บใหม่
                                // ถ้าต้องการให้ดาวน์โหลดพร้อมชื่อไฟล์จาก ABAP ให้ใช้บรรทัดล่างแทน
                                // PrintUtils.download(sUrl, oFile.FileName);
                                URLHelper.redirect(sUrl, true);

                                // คืนหน่วยความจำของ blob หลังผู้ใช้เปิดไฟล์แล้ว
                                setTimeout(function () {
                                    URL.revokeObjectURL(sUrl);
                                }, 60000);

                            } catch (oError) {
                                MessageBox.error("เปิดไฟล์ PDF ไม่สำเร็จ: " + oError.message);
                            }

                            return oResult;
                        })
                        .catch(function (oError) {
                            oBusyDialog.close();
                            throw oError;
                        });
                };
            }
        }
    });
});