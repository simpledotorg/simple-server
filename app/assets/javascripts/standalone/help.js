// Hides and shows each page of Help

function open_window(id) {
   const element = document.getElementById(id);
   element.style.display = 'block';
}

function close_window(id) {
   const element = document.getElementById(id);
   element.style.display = 'none';
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
