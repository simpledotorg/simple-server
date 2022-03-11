// Hides and shows each page of Help

function goToPage(startPageId, endPageId) {
  const startPage = document.getElementById(startPageId);
  startPage.style.display = "none";
  startPage.style.height = "0";

  const endPage = document.getElementById(endPageId);
  endPage.style.display = "block";
  endPage.style.height = "0";

  document.body.scrollTop = 0;
  document.documentElement.scrollTop = 0;
}

// FAQ hides and shows answers
window.onload = function() {
    const acc = document.getElementsByClassName("faq");

    for (let i = 0; i < acc.length; i++) {
      acc[i].addEventListener("click", function() {
        this.classList.toggle("active");
        let panel = this.nextElementSibling;
        if (panel.style.maxHeight) {
          panel.style.maxHeight = null;
        } else {
          panel.style.maxHeight = panel.scrollHeight + "px";
        }
      });
    }
}
