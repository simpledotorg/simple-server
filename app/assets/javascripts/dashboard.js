$(document).ready(function () {
    $('.organization-facility-groups').on('ajax:before', function () {
        $('.facility-group-statistics-spinner').removeClass('invisible');
    })

    $('.organization-facility-groups').on('ajax:complete', function () {
        $('.facility-group-statistics-spinner').addClass('invisible');
    })
});