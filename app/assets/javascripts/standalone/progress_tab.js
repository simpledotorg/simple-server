// Hides and shows each "Progress tab" sub-page

function openWindow(id, homePageId) {
  const element = document.getElementById(id);
  element.style.display = "block";

  var homePage = document.getElementById(homePageId);
  homePage.style.display = "none";
  homePage.style.height = "0";

  document.body.scrollTop = 0;
  document.documentElement.scrollTop = 0;
}

function closeWindow(id, homePageId) {
  const element = document.getElementById(id);
  element.style.display = "none";

  var homePage = document.getElementById(homePageId);
  homePage.style.display = "block";
  homePage.style.height = "auto";
}