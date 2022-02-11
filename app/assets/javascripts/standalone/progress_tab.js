// Hides and shows each "Progress tab" sub-page

function openWindow(subPageId, homePageId) {
  const subPage = document.getElementById(subPageId);
  subPage.style.display = "block";

  var homePage = document.getElementById(homePageId);
  homePage.style.display = "none";
  homePage.style.height = "0";

  document.body.scrollTop = 0;
  document.documentElement.scrollTop = 0;
}

function closeWindow(subPageId, homePageId) {
  const subPage = document.getElementById(subPageId);
  subPage.style.display = "none";

  var homePage = document.getElementById(homePageId);
  homePage.style.display = "block";
  homePage.style.height = "auto";
}