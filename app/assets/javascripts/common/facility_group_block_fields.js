FacilityGroupBlockFields = function() {
  this.newBlockRow = (name) => {
    let template = $("template#block-row").html()
    let $template = $(template);
    $template.find(".block-name").text(name);
    $template.attr("data-block-identifier", name);
    $template.find(".remove-block").attr("data-block-identifier", name);
    $template.find(".remove-block").attr(
        "onclick",
        "new FacilityGroupBlockFields().removeBlock(this.getAttribute('data-block-identifier'))"
    );

    return $template;
  }

  this.sanitizeInput = (input) => {
    return $("<div/>").text(input).html();
  }

  this.submitAddBlock = () => {
    let $blockInput = $("#new-block-name")
    let $blockName = this.sanitizeInput($blockInput.val());
    this.addBlock($blockName);
    $blockInput.val("");
    this.scrollBlockListToBottom();
  }

  this.addedBlocks = () => {
    return $(".block-name").map((i, el) => $(el).text()).get()
  }

  this.isBlockAdded = (name) => {
    return this.addedBlocks().map(block => block.toLowerCase().trim()).includes(name.toLowerCase().trim())
  }

  this.addBlock = (name) => {
    if(name !== "" && !this.isBlockAdded(name)) {
      $('<input>').attr({
        "name": "facility_group[new_block_names][]",
        "value": name,
        "data-block-identifier": name,
        "type": "hidden"
      }).appendTo("#facility-group-form");
      this.newBlockRow(name).appendTo("#block-list");
    }
  }

  this.removeBlock = (identifier) =>{
    if(existingBlocks.includes(identifier)) {
      $('<input>').attr({
        "name": "facility_group[remove_block_ids][]",
        "value": identifier,
        "data-block-identifier": identifier,
        "type": "hidden"
      }).appendTo("#facility-group-form");
    }

    $(`.list-group-item[data-block-identifier='${identifier}']`).remove();
  }

  this.scrollBlockListToBottom = () => {
    $("#block-list").scrollTop($("#block-list")[0].scrollHeight)
  }

  this.listen = () => {
    let facilityGroupBlockFields = this;

    $(".remove-block").on("click", function () {
      facilityGroupBlockFields.removeBlock($(this)[0].getAttribute('data-block-identifier'));
    })

    $(".add-block").on("click", function () {
      facilityGroupBlockFields.submitAddBlock();
    })

    $("#new-block-name").on("keydown", function (e) {
      if (e.key === "Enter") {
        e.preventDefault();
        facilityGroupBlockFields.submitAddBlock();
      }
    })
  }
}
