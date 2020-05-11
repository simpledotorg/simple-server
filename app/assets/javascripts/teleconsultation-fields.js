$(document).ready(function () {
    $("#facility_enable_teleconsultation").click(function () {
        var isEnabled = $(this).prop("checked");
        var teleconsultationFields = $("#teleconsultation_fields");
        if (isEnabled) {
            teleconsultationFields.show();
        } else {
            teleconsultationFields.hide();
        }
    });
});
