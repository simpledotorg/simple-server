PasswordVisibilityToggle = function () {
  const passwordInput = document.getElementById("password");
  const togglePasswordButton = document.getElementById("toggle-password");
  togglePasswordButton.addEventListener("click", togglePassword);

  function togglePassword() {
    if (passwordInput.type === "password") {
      passwordInput.type = "text";
      togglePasswordButton.setAttribute("aria-label", "Hide password.");
      togglePasswordButton.value = "Hide"
    } else {
      passwordInput.type = "password";
      togglePasswordButton.setAttribute(
        "aria-label",
        "Show password as plain text. Warning: this will display your password on the screen."
      );
      togglePasswordButton.value = "Show"
    }
  }
}