window.addEventListener("DOMContentLoaded", function() {
  const $filtersForm = document.getElementById("query-filters");
  const $filterByZoneButtons = document.getElementsByClassName("filter-by-zone");
  const $filterBySizeButtons = document.getElementsByClassName("filter-by-size");

  Array.from($filterByZoneButtons).forEach($button => {
    const zone = $button.getAttribute("data-value");

    $button.addEventListener("click", function() {
      const $selectedZone = document.getElementById("selected-zone");

      $selectedZone.setAttribute("value", zone);
      $filtersForm.submit();
    });
  });

  Array.from($filterBySizeButtons).forEach($button => {
    const size = $button.getAttribute("data-value");

    $button.addEventListener("click", function() {
      const $selectedSize = document.getElementById("selected-size");

      $selectedSize.setAttribute("value", size);
      $filtersForm.submit();
    });
  });
});
