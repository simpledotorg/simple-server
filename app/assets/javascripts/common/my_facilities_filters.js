window.addEventListener("DOMContentLoaded", function() {
  const $filtersForm = document.getElementById("query-filters");
  const $filterByZoneButtons = document.getElementsByClassName("filter-by-zone");
  const $selectedZone = document.getElementById("selected-zone");

  Array.from($filterByZoneButtons).forEach($button => {
    const zone = $button.getAttribute("data-value");
    $button.addEventListener("click", function() {
      const $selectedZone = document.getElementById("selected-zone");
      $selectedZone.setAttribute("value", zone);
      $filtersForm.submit();
    });
  });

  function filterBySize(size) {
    const $selectedSize = document.getElementById("selected-size");
    $selectedSize.setAttribute("value", size == undefined ? "" : size);
    $filtersForm.submit();
  }
});
