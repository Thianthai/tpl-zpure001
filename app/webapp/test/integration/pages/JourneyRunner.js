sap.ui.define([
    "sap/fe/test/JourneyRunner",
	"zpure001/test/integration/pages/PrintPurchaseOrderList.gen",
	"zpure001/test/integration/pages/PrintPurchaseOrderObjectPage.gen"
], function (JourneyRunner, PrintPurchaseOrderListGenerated, PrintPurchaseOrderObjectPageGenerated) {
    'use strict';

    const runner = new JourneyRunner({
        launchUrl: sap.ui.require.toUrl('zpure001') + '/test/flp.html#app-preview',
        pages: {
			onThePrintPurchaseOrderListGenerated: PrintPurchaseOrderListGenerated,
			onThePrintPurchaseOrderObjectPageGenerated: PrintPurchaseOrderObjectPageGenerated
        },
        async: true
    });

    return runner;
});

