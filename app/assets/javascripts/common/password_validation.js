PasswordValidation = function() {
  const DebounceTimeout = 500;
  const Validations = ["too_short", "needs_number", "needs_lower", "needs_upper"];

  this.initialize = () => {
    this.timer = null;
    this.passwordInput = $("#password");
    this.passwordInput.on("input", this.debounce);
  }

  this.debounce = () => {
    const later = () => {
      clearTimeout(this.timer);
      this.validatePassword();
    };

    clearTimeout(this.timer);
    this.timer = setTimeout(later, DebounceTimeout);
  }

  this.validatePassword = () => {
    const token = $("meta[name=csrf-token]").attr("content");
    const url = "http://localhost:3000/email_authentications/validate";
    const password = this.passwordInput.val();

    $.ajax({
      type: "POST",
      url: url,
      headers: {
        "X-CSRF-Token": token
      },
      data: {"password": password}
    }).done((data, status) => {
      let response;
      if (status === "success") {
        response = data["errors"];
      } else {
        // if we don't get a response, mark all validations as failures
        response = Validations;
      }
      this.updateChecklist(response);
      this.updateSubmitStatus(response);
    });
  }

  this.updateChecklist = (response) => {
    Validations.forEach(validationName => {
      response.includes(validationName) ? this.uncheckItem(validationName) : this.checkItem(validationName);
    });
  }

  this.checkItem = (id) => {
    const text = $(`#${id}`);
    text.addClass("completed");
  }

  this.uncheckItem = (id) => {
    const text = $(`#${id}`);
    text.removeClass("completed");
  }

  this.updateSubmitStatus = (response) => {
    const button = $("#password-submit");
    if (response.length === 0) {
      button.removeAttr("disabled");
    } else {
      button.attr("disabled", true);
    }
  }
}