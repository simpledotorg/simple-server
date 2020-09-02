window.addEventListener("DOMContentLoaded", function() {
  if($('#analytics-table').length) {
    new Tablesort(document.getElementById('analytics-table'), { descending: true })
  }
});
