function populateDropdown(body) {
  $(".typeahead .typeahead-dropdown").html(body);
}

function searchUser(e) {
  let searchQuery = e.value;
  if (searchQuery.length > 2) {
    showSpinner();
    $.ajax({
      url: "/admin/users.js",
      data: {"search_query": searchQuery}
    });
  }
}

function debounce(func, wait = 500) {
  let timeout;
  return function (...args) {
    const later = () => {
      clearTimeout(timeout);
      func(...args);
    };

    clearTimeout(timeout);
    timeout = setTimeout(later, wait);
  };
}

function showSpinner() {
  let spinner = $(".typeahead-spinner").first().clone();
  spinner.css({display: "block"});

  populateDropdown(spinner);
}

function toggleTeleconsultationFields(checkbox) {
  if (checkbox.checked) {
    $("#teleconsultation-fields").show();
  } else {
    $("#teleconsultation-fields").hide();
  }
}

