window.addEventListener("DOMContentLoaded", function() {
  if($('#analytics-table').length) {
    new Tablesort(document.getElementById('analytics-table'), { descending: true })
  }

  if($('#ranked-facilities-table').length) {
    new Tablesort(document.getElementById('ranked-facilities-table'), { descending: true })
  }
});
