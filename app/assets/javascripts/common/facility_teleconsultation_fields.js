function toggleTeleconsultationFields() {
  $("#teleconsultation-fields").toggle();
}

// Populate search results into typeahead search
function userJSONToRow(user) {
  let html = $("template#user-search-result-row").html();
  let $html = $(html);

  $html.attr({
    "data-user-id": user["id"],
    "data-user-full-name": user["full_name"],
    "data-user-registration-facility": user["registration_facility"],
    "data-user-teleconsultation-phone-number": user["teleconsultation_phone_number"]
  })
  $html.find(".user-full-name").text(user["full_name"])
  $html.find(".user-registration-facility").text(user["registration_facility"])

  return $html;
}

function noUsersFound(searchQuery) {
  let html = $("template#user-search-no-results-found").html();
  let $html = $(html);
  $html.find(".search-query").html(searchQuery);

  return $html;
}

function filterExistingUsers(users) {
  return users.filter(user => !existingUsers().includes(user["id"]));
}

// Adding/removing MO from search results
function medicalOfficerCard(user) {
  let card = $("template#medical-officer-card").html();
  let $card = $(card);
  let userID = user["userId"];

  $card.find(".medical-officer-id").val(userID);
  $card.find(".medical-officer-name").html(user["userFullName"]);
  $card.find(".medical-officer-registration-facility").html(user["userRegistrationFacility"]);
  $card.find(".medical-officer-phone-number").html(user["userTeleconsultationPhoneNumber"]);
  $card.find("[data-user-id]").attr("data-user-id", userID);
  $card.attr("data-user-id", userID);
  $card.find("a").attr("href", `/admin/users/${userID}/edit`); //TODO: rewrite

  return $card;
}

function existingUsers() {
  return $(".medical-officer-card").map((_, el) => $(el).attr("data-user-id")).get();
}

function isAdded(user) {
  let addedMedicalOfficerIDs = existingUsers();
  return addedMedicalOfficerIDs.includes(user["userId"])
}

function medicalOfficersCount() {
  return $(".medical-officer-card").length
}

function hideNoMedicalOfficers() {
  $(".no-medical-officers").hide()
}

function showNoMedicalOfficers() {
  $(".no-medical-officers").show()
}

function addMedicalOfficer(user) {
  if (isAdded(user)) return false;

  $(".medical-officers").append(medicalOfficerCard(user));
  hideNoMedicalOfficers();
}

function removeMedicalOfficer(userID) {
  $(`[data-user-id="${userID}"]`).remove();

  if (!medicalOfficersCount()) showNoMedicalOfficers();
}

$(document).ready(function () {
  $("body").on("click", ".mo-search .typeahead-dropdown-row", function () {
    let user = $(this).data();
    addMedicalOfficer(user);
    emptyTypeahead();
  });

  $("body").on("click", ".remove-medical-officer", function () {
    let userID = $(this).attr('data-user-id');
    removeMedicalOfficer(userID);
  });
})
