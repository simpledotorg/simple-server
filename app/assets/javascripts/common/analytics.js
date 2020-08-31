window.addEventListener("DOMContentLoaded", initializeTables);

function initializeTables() {
  if($('#analytics-table').length) {
    new Tablesort(document.getElementById('analytics-table'), { descending: true })
  }
}
