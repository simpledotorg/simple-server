UserTeleconsultSearch = function () {
  this.userJSONToRow = (user) => {
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

  this.noUsersFound = (searchQuery) => {
    let html = $("template#user-search-no-results-found").html();
    let $html = $(html);
    $html.find(".search-query").text(searchQuery);

    return $html;
  }

  this.filterExistingUsers = (users) => {
    let existingUsers = new FacilityTeleconsultFields().existingUsers();
    return users.filter(user => !existingUsers.includes(user["id"]));
  }

  this.emptyTypeahead = () => {
    $(".typeahead-dropdown").empty();
    $(".typeahead-input").val("");
  }

  this.usersJSONToHTML = (users) => {
    return users.map((user) => {
      return this.userJSONToRow(user)
    })
  }

  this.searchResultsToHTML = (searchQuery, results) => {
    return results.length ? this.usersJSONToHTML(results) : this.noUsersFound(searchQuery);
  }

  this.populateDropdown = (body) => {
    $(".typeahead .typeahead-dropdown").html(body)
  }

  this.populateSearchResults = (searchQuery, response) => {
    let filteredResults = this.filterExistingUsers(response);
    let results = this.searchResultsToHTML(searchQuery, filteredResults);

    this.populateDropdown(results);
  }

  this.showSpinner = () => {
    let spinner = $(".typeahead-spinner").first().clone();
    spinner.css({display: "block"});

    this.populateDropdown(spinner);
  }

  this.searchURL = "/admin/users/teleconsult_search.json";

  this.search = (e) => {
    let searchQuery = e.value;
    let facilityGroupId = $("#search_query").data("facilityGroupId");

    if (searchQuery.length) {
      this.showSpinner();
      $.ajax({
        url: this.searchURL,
        data: {
          "search_query": searchQuery,
          "facility_group_id": facilityGroupId
        },
        success: (res) => {
          this.populateSearchResults(searchQuery, res)
        }
      })
    }
  }

  this.debounce = (func, wait = 400) => {
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

  this.debouncedSearch = this.debounce(this.search);
}
