function $teleconsultationFields() {
    return document.getElementById('teleconsultation_fields');
}

function toggleTeleconsultationFields(checkbox) {
    let teleconsultationFields = $teleconsultationFields();
    if (checkbox.checked) {
        teleconsultationFields.style.display = '';
    } else {
        teleconsultationFields.style.display = 'none';
    }
}
