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
    const url = "/email_authentications/validate";
    const password = this.passwordInput.val();

    $.ajax({
      type: "POST",
      url: url,
      headers: {
        "X-CSRF-Token": token
      },
      data: {"password": password},
      error: () => {
        this.updateChecklist(Validations);
        this.updateSubmitStatus(Validations);
        this.displayValidationError();
      },
      success: (response) => {
        this.hideValidationError();
        const errors = response["errors"];
        this.updateChecklist(errors);
        this.updateSubmitStatus(errors);
      }
    });
  }

  this.hideValidationError = () => {
    $("#password").removeClass("is-invalid");
    $("#validation-error-message").addClass("hidden");
  }

  this.displayValidationError = () => {
    $("#password").addClass("is-invalid");
    $("#validation-error-message").removeClass("hidden");
  }

  this.updateChecklist = (errors) => {
    Validations.forEach(validation => {
      if(errors.includes(validation)) {
        $(`#${validation}`).removeClass("completed")
      } else {
        $(`#${validation}`).addClass("completed")
      }
    });
  }

  this.updateSubmitStatus = (errors) => {
    const button = $("#password-submit");
    if (errors.length === 0) {
      button.removeAttr("disabled");
    } else {
      button.attr("disabled", true);
    }
  }
}