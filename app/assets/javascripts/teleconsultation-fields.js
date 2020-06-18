function $teleconsultationFields() {
    return document.getElementById('teleconsultation_fields');
}

function $MORowsContainer() {
    return document.getElementById('mo_rows');
}

function toggleTeleconsultationFields(checkbox) {
    let teleconsultationFields = $teleconsultationFields();
    
    if (checkbox.checked) {
        teleconsultationFields.style.display = '';
    } else {
        teleconsultationFields.style.display = 'none';
    }
}

function addPhoneNumberFields() {
    // Clones the first phone number fieldset, and resets it to an empty form state.
    // Uses Date.now() to index new phone numbers

    let elem = document.querySelector('#mo_row_0')
    let clone = elem.cloneNode(true)
    let id = Date.now()
    let isd_field = clone.querySelector('input[name="facility[teleconsultation_phone_numbers_attributes][0][isd_code]"]')
    let phone_number_field = clone.querySelector('input[name="facility[teleconsultation_phone_numbers_attributes][0][phone_number]"]')
    let delete_field = clone.querySelector('input[name="facility[teleconsultation_phone_numbers_attributes][0][_destroy]"]')
    let button = clone.querySelector('button[name="delete_button"]')

    clone.id = "mo_row_" + id

    isd_field.id = "facility[teleconsultation_phone_numbers_attributes][" + id + "][isd_code]"
    isd_field.name = "facility[teleconsultation_phone_numbers_attributes][" + id + "][isd_code]"
    isd_field.removeAttribute('disabled')

    phone_number_field.id = "facility[teleconsultation_phone_numbers_attributes]["+ id + "][phone_number]"
    phone_number_field.name = "facility[teleconsultation_phone_numbers_attributes][" + id + "][phone_number]"
    phone_number_field.removeAttribute('disabled')
    phone_number_field.value = ''

    delete_field.id = "facility[teleconsultation_phone_numbers_attributes][" + id + "][_destroy]"
    delete_field.name = "facility[teleconsultation_phone_numbers_attributes][" + id + "][_destroy]"
    delete_field.setAttribute('value', "false")

    button.removeAttribute('disabled')

    $MORowsContainer().appendChild(clone)
}

function deletePhoneNumber(button) {
    // Sets the _destroy field's value to true
    // Disables form inputs for the deleted row
    let array_index = button.parentElement.parentElement.id.replace('mo_row_', '')
    let delete_field = document.querySelector('input[name="facility[teleconsultation_phone_numbers_attributes][' + array_index + '][_destroy]"]')
    let phone_number_field = document.querySelector('input[name="facility[teleconsultation_phone_numbers_attributes][' + array_index + '][phone_number]"]')
    let isd_field = document.querySelector('input[name="facility[teleconsultation_phone_numbers_attributes][' + array_index + '][isd_code]"]')

    delete_field.setAttribute('value', "true")
    button.setAttribute('disabled', "disabled")
    phone_number_field.setAttribute('disabled', "disabled")
    isd_field.setAttribute('disabled', "disabled")
}
