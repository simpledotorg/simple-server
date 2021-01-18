// Allow users to enter only some of the protocol drugs in the list, while validating whatever is entered.
// i.e, if stock value is not blank, then in_stock is a required field.
function markRequiredFields(facility_id) {
    let protocol_drugs = document.querySelectorAll('#drug_report_form_'+ facility_id + ' .protocol-drug-stock-inputs');
    protocol_drugs.forEach(function(protocol_drug) {
        let received = protocol_drug.querySelector('.received');
        let in_stock = protocol_drug.querySelector('.in_stock');
        if(received.value.trim() != '') {
            in_stock.required = true;
        } else {
            in_stock.required = false;
        }
    });
};

function validateAndCloseDrugStockForm(facility_id) {
    markRequiredFields(facility_id);
    if ($('#drug_report_form_' + facility_id)[0].checkValidity()) {
        $('#drug_report_modal_' + facility_id).modal('toggle');
    }
};
