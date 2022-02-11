function goToPage(startPageId, endPageId) {
  const startPage = document.getElementById(startPageId);
  startPage.style.display = "none";
  startPage.style.height = "0";

  const endPage = document.getElementById(endPageId);
  endPage.style.display = "block";
  endPage.style.height = "auto";

  document.body.scrollTop = 0;
  document.documentElement.scrollTop = 0;
}