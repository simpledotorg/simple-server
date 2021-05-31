FacilityDrugStockParentField = function () {
    this.setVisibility = (value) => {
        if (value === 'community')
        { $('#drug_stock_parent_div').show(); }
        else
        {
            $('#drug_stock_parent_div').hide();
            $('#drug_stock_parent_div select').val(null).change();
        }
    }
}
