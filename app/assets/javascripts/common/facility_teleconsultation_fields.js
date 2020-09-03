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

function toggleTeleconsultationFields() {
  $("#teleconsultation-fields").toggle();
}

function addMedicalOfficer(user){
  if(isAdded(user)) return false;

  $(".medical-officers").append(medicalOfficerCard(user));
  hideNoMedicalOfficers();
}

function medicalOfficersCount() {
  return $(".medical-officer-card").length
}

function removeMedicalOfficer(userID) {
  $(`[data-user-id="${userID}"]`).remove();

  if(!medicalOfficersCount()) showNoMedicalOfficers();
}

function hideNoMedicalOfficers() {
  $(".no-medical-officers").hide()
}

function showNoMedicalOfficers() {
  $(".no-medical-officers").show()
}

function isAdded(user) {
  let addedMedicalOfficerIDs = $(".medical-officer-input").map((_,el) => el.value).get();
  return addedMedicalOfficerIDs.includes(user["userId"])
}

function medicalOfficerCard(user) {
  let card = $("template#teleconsultation-medical-officer").html();
  let $card = $(card)
  let userID = user["userId"]

  $card.find(".medical-officer-input").val(userID);
  $card.find(".medical-officer-name").html(user["userFullName"]);
  $card.find(".medical-officer-registration-facility").html(user["userRegistrationFacility"]);
  $card.find(".medical-officer-phone-number").html(user["userTeleconsultPhoneNumber"]);
  $card.find("[data-user-id]").attr("data-user-id", userID);
  $card.attr("data-user-id", userID);

  return $card;
}

$(document).ready(function() {
  $("body").on("click", ".typeahead-dropdown-row", function () {
    let user = $(this).data();
    addMedicalOfficer(user);
  });

  $("body").on("click", ".remove-medical-officer", function () {
    let userID = $(this).attr('data-user-id');
    removeMedicalOfficer(userID);
  });

})
