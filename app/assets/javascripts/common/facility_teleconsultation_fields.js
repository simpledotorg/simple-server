// Show/hide teleconsultation fields on toggling checkbox
function toggleTeleconsultationFields() {
  $("#teleconsultation-fields").toggle();
}

// AJAX search for users and populate search results
function searchResultsToHTML(searchQuery, users) {
  return users.length ? usersJSONToHTML(users) : noResultsHTML(searchQuery);
}

function usersJSONToHTML(users) {
  return users.map(function (user) {
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
  })
}

function noResultsHTML(searchQuery) {
  let html = $("template#user-search-no-results-found").html();
  let $html = $(html);
  $html.find(".search-query").html(searchQuery);

  return $html;
}

function filterExistingUsers(users) {
  // existingUsers();
  return users;
}

function populateDropdown(body) {
  $(".typeahead .typeahead-dropdown").html(body);
}

function populateSearchResults(searchQuery, users) {
  let filteredUsers = filterExistingUsers(users);
  let results = searchResultsToHTML(searchQuery, filteredUsers);
  populateDropdown(results);
}

function showSpinner() {
  let spinner = $(".typeahead-spinner").first().clone();
  spinner.css({display: "block"});

  populateDropdown(spinner);
}

function searchUser(e) {
  let searchQuery = e.value;
  showSpinner();
  $.ajax({
    url: "/admin/users.json",
    data: {"search_query": searchQuery},
    success: (res) => {
      populateSearchResults(searchQuery, res)
    }
  });
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

let debouncedSearchUser = debounce(searchUser);

// Adding/removing MO from search results
function medicalOfficerCard(user) {
  let card = $("template#medical-officer-card").html();
  let $card = $(card)
  let userID = user["userId"]

  $card.find(".medical-officer-id").val(userID);
  $card.find(".medical-officer-name").html(user["userFullName"]);
  $card.find(".medical-officer-registration-facility").html(user["userRegistrationFacility"]);
  $card.find(".medical-officer-phone-number").html(user["userTeleconsultationPhoneNumber"]);
  $card.find("[data-user-id]").attr("data-user-id", userID);
  $card.attr("data-user-id", userID);
  $card.find("a").attr("href", `/admin/users/${userID}/edit`) //TODO: fix

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

function addMedicalOfficer(user) {
  if (isAdded(user)) return false;

  $(".medical-officers").append(medicalOfficerCard(user));
  hideNoMedicalOfficers();
}

function removeMedicalOfficer(userID) {
  $(`[data-user-id="${userID}"]`).remove();

  if (!medicalOfficersCount()) showNoMedicalOfficers();
}

function hideNoMedicalOfficers() {
  $(".no-medical-officers").hide()
}

function showNoMedicalOfficers() {
  $(".no-medical-officers").show()
}

function emptyTypeahead() {
  $(".typeahead-dropdown").empty();
  $(".typeahead-input").val("");
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
