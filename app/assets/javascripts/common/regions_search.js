// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.

RegionsSearch = function () {
  this.resultToRow = (result) => {
    let html = $("template#user-search-result-row").html();
    let $html = $(html);

    $html.attr({
      "data-id": result["id"],
      "data-name": result["name"],
      "data-link": "regions/" + result["slug"]
    })
    $html.find(".name").text(result["name"])
    return $html
  }

  this.noResultsFound = (searchQuery) => {
    let html = $("template#no-results-found").html();
    let $html = $(html);
    $html.find(".search-query").html(searchQuery);

    return $html;
  }

  this.showSpinner = () => {
    let spinner = $(".typeahead-spinner").first().clone();
    spinner.css({display: "block"});

    this.populateDropdown(spinner);
  }

  this.resultsToHTML = (results) => {
    return results.map((result) => {
      return this.resultToRow(result)
    })
  }

  this.searchResultsToHTML = (searchQuery, results) => {
    return this.resultsToHTML(results)
  }

  this.populateDropdown = (body) => {
    console.log("populateDropdown called")
    console.log(body)
    $(".typeahead .typeahead-dropdown").html(body)
  }

  this.populateSearchResults = (searchQuery, response) => {
    if (response.length) {
      console.log("got " + response.length + " results")
      let results = this.searchResultsToHTML(searchQuery, response)
      this.populateDropdown(results);
    } else {
      console.log("no results")
    }
  }

  this.searchURL = "/regions_search.json";

  this.searchRequest = (e) => {
    let searchQuery = e.value;

    if (searchQuery.length) {
      this.showSpinner();
      $.ajax({
        url: this.searchURL,
        data: {
          "query": searchQuery,
        },
        success: (res) => {
          console.log(res)
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

  this.search = this.debounce(this.searchRequest);
}