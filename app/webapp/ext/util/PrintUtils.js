sap.ui.define([], function () {
    "use strict";

    return {

        /**
         * ดึงข้อมูลจริงออกจากผลลัพธ์ของ invokeAction
         * รูปร่างของผลลัพธ์ต่างกันตามจำนวนแถวที่เลือกและเวอร์ชัน UI5
         * @param {object} oResult ผลลัพธ์จาก invokeAction
         * @returns {object|null} โครงสร้างของ ZA_PURE001_FILE
         */
        unwrap: function (oResult) {
            if (!oResult) {
                return null;
            }

            if (oResult.context && oResult.context.getObject) {
                try {
                    return oResult.context.getObject();
                } catch (oError) {
                    // ไม่ใช่รูปแบบนี้ ลองรูปแบบถัดไป
                }
            }

            if (oResult.getObject) {
                try {
                    return oResult.getObject();
                } catch (oError) {
                    // ไม่ใช่รูปแบบนี้ ลองรูปแบบถัดไป
                }
            }

            // เลือกหลายแถวจะได้ array กลับมา ทุกรายการชี้ไฟล์เดียวกันเพราะ ABAP รวมให้แล้ว
            if (Array.isArray(oResult)) {
                var vFirst = (oResult[0] && oResult[0].value) || oResult[0];
                if (vFirst && vFirst.getObject) {
                    try {
                        return vFirst.getObject();
                    } catch (oError) {
                        return vFirst;
                    }
                }
                return vFirst;
            }

            if (typeof oResult === "object" && "value" in oResult) {
                return oResult.value;
            }

            return oResult;
        },

        /**
         * แปลง base64 ที่ ABAP ส่งมาเป็น Blob URL
         * @param {string} sBase64 เนื้อไฟล์แบบ base64
         * @param {string} sMimeType ชนิดไฟล์ ว่างได้ จะใช้ application/pdf
         * @returns {string} Blob URL ที่ต้อง revoke ทิ้งเมื่อใช้เสร็จ
         */
        toBlobUrl: function (sBase64, sMimeType) {
            if (typeof sBase64 !== "string" || sBase64 === "") {
                throw new Error("Invalid base64 payload");
            }

            // เผื่อกรณีที่ส่งมาเป็น data URL เต็มรูปแบบ
            var sClean = sBase64.indexOf("base64,") > -1 ? sBase64.split("base64,").pop() : sBase64;

            var sBinary = atob(sClean);
            var aBytes = new Uint8Array(sBinary.length);
            for (var i = 0; i < sBinary.length; i++) {
                aBytes[i] = sBinary.charCodeAt(i);
            }

            return URL.createObjectURL(new Blob([aBytes], { type: sMimeType || "application/pdf" }));
        },

        /**
         * บันทึกไฟล์ลงเครื่องโดยคงชื่อไฟล์ที่ ABAP ตั้งมา
         * ใช้แทน openInNewTab เมื่อต้องการดาวน์โหลดแทนการเปิดดู
         * @param {string} sUrl Blob URL
         * @param {string} sFileName ชื่อไฟล์พร้อมนามสกุล
         */
        download: function (sUrl, sFileName) {
            var oLink = document.createElement("a");
            oLink.href = sUrl;
            oLink.download = sFileName || "download.pdf";
            document.body.appendChild(oLink);
            oLink.click();
            document.body.removeChild(oLink);
        }
    };
});