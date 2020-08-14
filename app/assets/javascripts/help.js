// Hides and shows each page of Help

function openWindow(id, parentId) {
   var element = document.getElementById(id);
   element.style.display = 'block';

   if (parentId) {
     var parent = document.getElementById(parentId);
     parent.style.display = 'none';
     parent.style.height = '0';
   }

   document.body.scrollTop = 0; // For Safari
   document.documentElement.scrollTop = 0; // For Chrome, Firefox, IE and Opera
}

function closeWindow(id, parentId) {
   var element = document.getElementById(id);
   element.style.display = 'none';

   if (parentId) {
     var parent = document.getElementById(parentId);
     parent.style.display = 'block';
     parent.style.height = 'auto';
   }
}

// FAQ hides and shows answers
window.onload = function() {
    var acc = document.getElementsByClassName("faq");
    var i;

    for (i = 0; i < acc.length; i++) {
      acc[i].addEventListener("click", function() {
        this.classList.toggle("active");
        var panel = this.nextElementSibling;
        if (panel.style.maxHeight) {
          panel.style.maxHeight = null;
        } else {
          panel.style.maxHeight = panel.scrollHeight + "px";
        }
      });
    } 
}
