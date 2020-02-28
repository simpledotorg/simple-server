// Hides and shows each page of Help

function open_window(id) {
   var element = document.getElementById(id);
   element.style.display = 'block';
}

function close_window(id) {
   var element = document.getElementById(id);
   element.style.display = 'none';
}

// FAQ hides and shows answers
window.onload = function() {
    var acc = document.getElementsByClassName("faq");
    var i;

    for (i = 0; i < acc.length; i++) {
      acc[i].addEventListener("click", function() {
        this.classList.toggle("active");
        var answer = this.nextElementSibling;
        if (answer.style.display === "block") {
          answer.style.display = "none";
        } else {
          answer.style.display = "block";
        }
      });
    } 
}
