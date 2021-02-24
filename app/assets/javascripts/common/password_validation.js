PasswordValidation = function() {
  const DebounceTimeout = 500;

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
    const token = $("meta[name=csrf-token]").attr("content")
    const url = "http://localhost:3000/email_authentications/validate"
    const password = this.passwordInput.val();

    $.ajax({
      type: "POST",
      url: url,
      headers: {
        "X-CSRF-Token": token
      },
      data: {"password": password}
    }).done((data, status) => {
      let response = []
      if (status === "success") {
        response = data["errors"]
      }
      this.updateChecklist(response);
      this.updateSubmitStatus(response);
    });
  }

  this.updateChecklist = (response) => {
    response.includes("too_short") ? this.uncheckItem("length") : this.checkItem("length");
    response.includes("needs_lower") ? this.uncheckItem("lower") : this.checkItem("lower");
    response.includes("needs_upper") ? this.uncheckItem("upper") : this.checkItem("upper");
    response.includes("needs_number") ? this.uncheckItem("number") : this.checkItem("number");
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