PasswordValidation = function() {
  const DebounceTimeout = 500;

  this.initialize = function() {
    this.timer = null;
    this.response = null;
    this.passwordInput = $("#password");
    this.passwordInput.on("input", this.handlePasswordInput);
  }

  this.handlePasswordInput = () => {
    console.log("CHANGE", this.passwordInput.val());
    this.setTimer();
  }

  this.setTimer = function() {
    console.log("STARTING TIMER")
    this.cancelTimer();
    this.timer = setTimeout(this.validatePassword, DebounceTimeout);
  }

  this.cancelTimer = function() {
    console.log("CANCELING TIMER")
    if (!this.timer) return;
    clearTimeout(this.timer);
    this.timer = null;
  }

  this.validatePassword = () => {
    console.log("MAKING REQUEST")
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
    }).done(function(data, status){
      console.log(status)
      console.log(data)
      this.timer = null;
      if (status === "success") {
        this.response = data["errors"];
      } else {
        this.response = null;
      }
    });
  }
}