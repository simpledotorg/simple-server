FacilityTeleconsultFields = function () {
  this.userSearch = new UserTeleconsultSearch();

  this.toggleTeleconsultationFields = () => {
    $("#teleconsultation-fields").toggle();
  }

// Adding/removing MO from search results
  this.medicalOfficerCard = (user) => {
    let card = $("template#medical-officer-card").html();
    let $card = $(card);
    let userID = user["userId"];

    $card.find(".medical-officer-id").val(userID);
    $card.find(".medical-officer-name").text(user["userFullName"]);
    $card.find(".medical-officer-registration-facility").text(user["userRegistrationFacility"]);
    $card.find(".medical-officer-phone-number").text(user["userTeleconsultationPhoneNumber"]);
    $card.find("[data-user-id]").attr("data-user-id", userID);
    $card.attr("data-user-id", userID);
    $card.find("a").attr("href", `/admin/users/${userID}/edit`);

    return $card;
  }

  this.existingUsers = () => {
    return $(".medical-officer-card").map((_, el) => $(el).attr("data-user-id")).get();
  }

  this.isAdded = (user) => {
    let addedMedicalOfficerIDs = this.existingUsers();
    return addedMedicalOfficerIDs.includes(user["userId"])
  }

  this.medicalOfficersCount = () => {
    return $(".medical-officer-card").length
  }

  this.hideNoMedicalOfficers = () => {
    $(".no-medical-officers").hide()
  }

  this.showNoMedicalOfficers = () => {
    $(".no-medical-officers").show()
  }

  this.addMedicalOfficer = (user) => {
    if (this.isAdded(user)) return false;

    $(".medical-officers").prepend(this.medicalOfficerCard(user));
    this.hideNoMedicalOfficers();
  }

  this.removeMedicalOfficer = (userID) => {
    $(`[data-user-id="${userID}"]`).remove();

    if (!this.medicalOfficersCount()) this.showNoMedicalOfficers();
  }

  this.listen = () => {
    let teleconsultationFields = this;

    // Populate MOs from search results
    $("body").on("click", ".mo-search .typeahead-dropdown-row", function () {
      let user = $(this).data();
      teleconsultationFields.addMedicalOfficer(user);
      teleconsultationFields.userSearch.emptyTypeahead();
    });

    $("body").on("click", ".remove-medical-officer", function () {
      let userID = $(this).attr('data-user-id');
      teleconsultationFields.removeMedicalOfficer(userID);
    });
  }
}

