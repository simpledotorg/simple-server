$(document).on('ajax:before', '.organization-facility-groups', function (event) {
    $('.facility-group-statistics-spinner').removeClass('invisible');
})

$(document).on('ajax:complete', '.organization-facility-groups', function (event) {
    $('.facility-group-statistics-spinner').addClass('invisible');
})