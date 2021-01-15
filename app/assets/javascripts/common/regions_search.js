// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.

RegionsSearch = function () {

  this.showSpinner = () => {
    let spinner = $(".typeahead-spinner").first().clone();
    spinner.css({display: "block"});

    // this.populateDropdown(spinner);
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
          // this.populateSearchResults(searchQuery, res)
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