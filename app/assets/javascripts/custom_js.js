var setTime;
$(document).ready(function() {
  fadeout_alert();
  showPeriod($('#default_dn').val());
  $("#advance_period").click(function() {
    $("#modal-popup-advance").modal();

    $('.start_date').datepicker({
      format: "dd/mm/yyyy",
      autoclose: true
    }).on('changeDate', function(selected) {
      var startDate = new Date(selected.date.valueOf());
      $('.end_date').datepicker('setStartDate', startDate);
    }).on('clearDate', function(selected) {
      $('.end_date').datepicker('setStartDate', null);
    });

    $('.end_date').datepicker({
      format: "dd/mm/yyyy",
      autoclose: true
    }).on('changeDate', function(selected) {
      var endDate = new Date(selected.date.valueOf());
      $('.start_date').datepicker('setEndDate', endDate);
    }).on('clearDate', function(selected) {
      $('.start_date').datepicker('setEndDate', null);
    });

    $('.start_date_inv').datepicker({
      format: "dd/mm/yyyy",
      autoclose: true
    }).on('changeDate', function(selected) {
      var startDate = new Date(selected.date.valueOf());
      $('.end_date_inv').datepicker('setStartDate', startDate);
    }).on('clearDate', function(selected) {
      $('.end_date_inv').datepicker('setStartDate', null);
    });

    $('.end_date_inv').datepicker({
      format: "dd/mm/yyyy",
      autoclose: true
    }).on('changeDate', function(selected) {
      var endDate = new Date(selected.date.valueOf());
      $('.start_date_inv').datepicker('setEndDate', endDate);
    }).on('clearDate', function(selected) {
      $('.start_date_inv').datepicker('setEndDate', null);
    });

    $('.start_date_due').datepicker({
      format: "dd/mm/yyyy",
      autoclose: true
    }).on('changeDate', function(selected) {
      var startDate = new Date(selected.date.valueOf());
      $('.end_date_due').datepicker('setStartDate', startDate);
    }).on('clearDate', function(selected) {
      $('.end_date_due').datepicker('setStartDate', null);
    });

    $('.end_date_due').datepicker({
      format: "dd/mm/yyyy",
      autoclose: true
    }).on('changeDate', function(selected) {
      var endDate = new Date(selected.date.valueOf());
      $('.start_date_due').datepicker('setEndDate', endDate);
    }).on('clearDate', function(selected) {
      $('.start_date_due').datepicker('setEndDate', null);
    });
  });

});

Array.prototype.unique = function(a) {
  return function() {
    return this.filter(a)
  }
}(function(a, b, c) {
  return c.indexOf(a, b + 1) < 0
});

$.fn.cleditor_plgn = function() {
  $('.content_body').cleditor({
    controls: // controls to add to the toolbar
      "bold italic underline strikethrough subscript superscript | font size " +
      "style | color highlight removeformat | bullets numbering | outdent " +
      "indent | alignleft center alignright justify | undo redo | " +
      "rule image link unlink | cut copy paste pastetext | print source"
  });
}

// fadeout alert after show message
function fadeout_alert() {
  setTime = setInterval(function() {
    $('#flash-message .alert').fadeOut('slow', function() {
      $('#flash-message .alert').remove();
    });
  }, 5000);
}

function load_page(url) {
  $.ajax({
    beforeSend: function(request) {},
    success: function(request) {
      jQuery('#page-content').html(request)
    },
    error: function(request) {},
    complete: function(request) {},
    url: url
  });
}

//remove '...' from paginate gem default.
function remove_page_gap() {
  $(".page.gap").remove();
}

function remove_row(id) {
  $("#row_" + id).remove();
}

//create alert notice, the function only use when remove data
function create_alert_notice_for_js(text) {
  var alert_html = "<div class='alert alert-success'><button data-dismiss='alert' class='close' type='button'><i class='icon-remove'></i></button><i class='icon-ok green'></i> <strong>" + text + "</strong></div>";
  return alert_html
}

//create alert error, the function only use when remove data
function create_alert_error_for_js(text) {
  var alert_html = "<div class='alert alert-error'><button data-dismiss='alert' class='close' type='button'><i class='icon-remove'></i></button><i class='icon-warning-sign red'></i> <strong>" + text + "</strong></div>";
  return alert_html
}

//remove data with ajax, this function can use for all page is needed
function _remove_data(path, id) {
  message_confirm = confirm("Are you sure?")
  var token = $("meta[name='csrf-token']").attr("content");
  if (message_confirm == true) {
    $.ajax({
      url: path + "?&authenticity_token=" + token,
      type: "DELETE",
      beforeSend: function(request) {
        window.clearInterval(setTime);
      },
      success: function(request) {
        remove_row(id);
        $("#flash_notice").html(create_alert_notice_for_js(request))
      },
      complete: function(request) {
        fadeout_alert();
      },
      error: function(request) {
        $("#flash_notice").html(create_alert_error_for_js(request.responseText))
      }
    })
  } else {
    return false;
  }
}

function checkingSupplier(val) {
  if (val == "Supplier") {
    $(".div-supplier").fadeIn(20);
  } else {
    $(".div-supplier").fadeOut(20);
  }
}
//function to get autocomplete
function get_autocomplete_state(parent, cont) {
  var val = $("#" + parent + " #search_field option:selected").val();
  if (cont == "user_logs") {
    if (val == "Transaction Number / Voucher") {
      $("#user_logs_filter_act_type").show();
      $("#search_field_2").prop("disabled", false)
    } else {
      $("#user_logs_filter_act_type").hide();
      $("#search_field_2").prop("disabled", true)
    }
  } else {
    if (val == "Status") {
      $.ajax({
        beforeSend: function(request) {},
        success: function(request) {
          // features_auto_complete(request);
          features_checkbox_status(request);
        },
        error: function(request) {},
        complete: function(request) {},
        url: '/get_autocomplete_state/' + cont,
        type: "GET",
        dataType: "json"
      });
    } else {
      $(".table-header").animate({
        height: "38px"
      }, 'fast');

      // display text field
      $("#search_detail").val("");
      $("#search_detail").show();
      $("#checkbox_status").remove();
    }
  }
}

// show autocomplete features
function features_auto_complete(accesses) {
  $('.auto-complete').typeahead({
    source: function(query, process) {
      return accesses
    },
    updater: function(item) {
      return item
    }
  });

  $('#ls-code').typeahead({
    source: function(query, process) {
      return accesses
    },
    updater: function(item) {
      return item
    }
  });
}

// show checkbox status
function features_checkbox_status(arr) {
  var text = "<div class='control-group pull-left' id='checkbox_status' style='color: white; margin-top: 20px;'>";
  for (var i = 0; i < arr.length; ++i) {
    text += "<div class='checkbox' style='display:inline-block;'><label>" + "<input name='" + arr[i].split(" ").join("_") + "' type='checkbox' class='ace' onchange='checkbox_change(this);'>" + "<span class='lbl'> " + arr[i] + "</span>" + "</label></div>";
  }

  text += "</div>";

  // remove search text field
  $("#search_detail").parent().parent().append(text);
  $("#search_detail").val("");
  $("#search_detail").hide();

  // increase filter bar height
  $(".table-header").animate({
    height: "90px"
  }, 'fast');
}

function checkbox_change(el) {
  if ($(el).is(":checked")) {
    // add string to text field
    $("#search_detail").val($("#search_detail").val() + $(el).attr("name") + " ");
  } else {
    // remove string from text field
    $("#search_detail").val($("#search_detail").val().replace($(el).attr("name") + " ", ""));
  }
}

//function for check all checkboxes on respective features on show role page
function check_all(feature) {
  temp = feature.split(" ");
  if (temp.length > 1) {
    feature = temp.join("");
  }
  if ($("#check-box_" + feature + " .check-all").is(":checked")) {
    $("#check-box_" + feature + " input[type=checkbox]").each(function() {
      $(this).prop("checked", true);
    });
  } else {
    $("#check-box_" + feature + "  input[type=checkbox]").each(function() {
      $(this).prop("checked", false);
    });
  }
}

//function for listening search form on submit
// variable request sementara di coment dulu, soalnya dulu di buat begini karena ajax ngerequest 2x broo
//var request = true;
$(function() {
  //$("#form_search").bind("click", function(){
  // var height = $("#results").height();
  //$("#form_search").submit();
  //if (request == true){
  //$.get(this.action, $('#form_search').serialize(), null, 'script');
  //request = false;
  //}else{
  //  request = true;
  //}
  //})

  $("#reset_finding").bind("click", function() {
    $("#search_period_1").val("");
    $("#search_period_2").val("");
    $("#popup_period_1").val("");
    $("#popup_period_2").val("");

    $("#search_period_1_inv_date").val("");
    $("#search_period_2_inv_date").val("");
    $("#popup_period_1_inv_date").val("");
    $("#popup_period_2_inv_date").val("");

    $("#search_period_1_due_date").val("");
    $("#search_period_2_due_date").val("");
    $("#popup_period_1_due_date").val("");
    $("#popup_period_2_due_date").val("");

    showPeriod();
    $("#search_detail").val("");
    $(".checkbox input:checkbox").prop("checked", false);

    get_autocomplete_state("form_search", "user_logs")
    $.get(this.action, {}, null, 'script');
  })
});

function premeptivestrike() {
  $("#feature-access").change(function() {
    var text = $(this).val();
    if (text.match(/:/)) {
      text = text.split(":");
      var a = text[2].split("/");
    } else {
      var a = text.split("/")
    }
    $("#model-name").val(a[0]);
  });
}

function change_notif_state(id) {
  $.ajax({
    url: "/change_notif_state/" + id,
    type: "GET",
    success: function(request) {}
  })
}

// FUNCTION IS NUMERICABLE
jQuery.fn.ForceNumericOnly =
  function() {
    return this.each(function() {
      $(this).keydown(function(e) {
        var key = e.charCode || e.keyCode || 0;
        return (
          key == 8 ||
          key == 9 ||
          key == 13 ||
          key == 46 ||
          key == 110 ||
          key == 190 ||
          (key >= 35 && key <= 40) ||
          (key >= 48 && key <= 57) ||
          (key >= 96 && key <= 105));
      });
    });
  };

$(document).ready(function() {
  $(".input_only_numeric").ForceNumericOnly();
  $("#datepicker").datepicker({
    format: "yyyy-mm",
    startView: "months",
    minViewMode: "months"
  });

  $("#datepicker").on("change", function() {
    get_po_stats_by(document.getElementById("select-order-type"));
  });
});

var progress;
progress = progress || (function() {
  var pleaseWaitDiv = $('<div class="modal hide" id="pleaseWaitDialog" data-backdrop="static" data-keyboard="false"><div class="modal-header"><h3>Please wait...</h3></div><div class="modal-body"><div id = "progress-bar"class="progress progress-striped active progress-info"><div class="bar" style="width: 100%;"></div></div><span id="msg"></span></div><div id="foot"></div></div>');
  return {
    showPleaseWait: function() {
      pleaseWaitDiv.modal();
    },
    hidePleaseWait: function() {
      pleaseWaitDiv.modal('hide');
    },

  };
})();

function ajax_loading_graph(id) {
  $("<div id='insert-before-ajax-loading' class='insert-before-ajax-loading'><div id='ajax-loading_gif' class='ajax-loader-gif span4 offset4'><h4>Loading</h4></div></div>").insertBefore("#" + id);
}

function ajax_loading_table(id, height, width_dn) {
  $("<div id='insert-before-ajax-loading' class='insert-before-ajax-loading-table' style='height:" + height + "px;width:" + width_dn + "px;'><div id='ajax-loading_gif' class='ajax-loader-gif-table span4 offset4'></div></div>").insertBefore("#" + id);
}

function close_ajax_loading() {
  $("#foot").html("");
  $("#msg").html("");
  progress.hidePleaseWait();
}

function success_synch_res(status, controller) {
  var msg = '';
  var message = ''
  if (status == 200) {
    msg = "" + controller + " is now Success Synchorizing";
    message = create_alert_notice_for_js(msg);
    $("#flash-message").html(message);
    progress.hidePleaseWait();
    close_ajax_loading();
    $("#progress-bar").removeClass("active");
  } else if (status == 204) {
    message = "There is No New Data";
    $("#msg").addClass("red").html(message);
    $("#foot").addClass("modal-footer").html("<button class='btn' id='close-ajax-loading' data-dismiss='modal' aria-hidden='true' onClick = 'close_ajax_loading()'>Close</button>");
    $("#progress-bar").removeClass("active progress-info").addClass("progress-danger");
    return false;
  } else if (status == 206) {
    message = "Found, One item is invalid, please try again";
    $("#msg").addClass("red").html(message);
    $("#foot").addClass("modal-footer").html("<button class='btn' id='close-ajax-loading' data-dismiss='modal' aria-hidden='true' onClick = 'close_ajax_loading()'>Close</button>");
    $("#progress-bar").removeClass("active progress-info").addClass("progress-danger");
    return false;
  } else {
    message = "We donn't know how to handle error like this";
    $("#msg").addClass("red").html(message);
    $("#foot").addClass("modal-footer").html("<button class='btn' id='close-ajax-loading' data-dismiss='modal' aria-hidden='true' onClick = 'close_ajax_loading()'>Close</button>");
    $("#progress-bar").removeClass("active progress-info").addClass("progress-danger");
  }
}

function error_synch_res(status) {
  var message = "";
  if (status == 503) {
    message = "Service is unavailable right now, please try again later";
    $("#msg").addClass("red").html(message);
  } else if (status == 404) {
    message = "Service not found on server, please contact administrator";
    $("#msg").addClass("red").html(message);
  } else if (status == 401) {
    message = "System can't access the server, please contact administrator";
    $("#msg").addClass("red").html(message);
  } else if (status == 408) {
    message = "Request time out, please try again later";
    $("#msg").addClass("red").html(message);
  } else if (status == 422) {
    message = "Data can not be processed by server, please contact administrator";
    $("#msg").addClass("red").html(message);
  } else if (status == 509) {
    message = "Data can not be processed because API could not extract ResultSet, please contact administrator";
    $("#msg").addClass("red").html(message);
  } else {
    message = "Data can not be processed, please contact administrator";
    $("#msg").addClass("red").html(message);
  }
  $("#foot").addClass("modal-footer").html("<button class='btn' id='close-ajax-loading' data-dismiss='modal' aria-hidden='true' onClick = 'close_ajax_loading()'>Close</button>");
  $("#progress-bar").removeClass("active progress-info").addClass("progress-danger");
}

function create_flot(id, data, str, title) {
  var allowed = null;
  switch (title) {
    case 'Purchase Order':
      allowed = ["new", "on_time", "on_time_but_less_than_100", "late", "late_but_less_than_100", "expired", "cancelled"]
      break;
    case 'Goods Receive Notes':
      allowed = ["new", "disputed", "revised", "accepted", "pending"]
      break;
    case 'Goods Receive Price Confirmations':
      allowed = ["unread", "disputed", "revised", "accepted", "pending"]
      break;
    case 'Invoice':
    case 'Goods Return Note':
    case 'Debit Notes':
      break;
  }
  var max = 0;
  var values = [];
  for (var key in data) {
    if (data.hasOwnProperty(key)) {
      if (allowed && allowed.indexOf(key) == -1)
        continue;

      values.push({
        name: key.charAt(0).toUpperCase() + key.slice(1).replace(/_/g, " "),
        y: data[key]
      });

      max = Math.max(data[key], max);
    }
  }

  $('#' + id).highcharts({
    series: [{
      name: title,
      colorByPoint: true,
      data: values
    }],
    chart: {
      type: 'column',
      height: 400,
    },
    title: {
      text: title,
    },
    xAxis: {
      type: 'category'
    },
    legend: {
      enabled: false
    },
    exporting: {
      enabled: false
    },
    yAxis: {
      allowDecimals: false,
      minPadding: 0,
      maxPadding: 0,
      max: max + 1,
      min: 0,
      minRange: 0.1,
      title: {
        text: ""
      }
    },
    plotOptions: {
      line: {
        lineWidth: 1,
        softThreshold: false
      },
      series: {
        borderWidth: 0,
        dataLabels: {
          enabled: false
        }
      }
    }
  });
}

function status_color(state) {
  var color;
  var status = state;
  switch (status) {
    case "pending":
      break;
    case "unread":
      break;
    case "read":
      break;
    case "new":
      break;
    case "open":
      break;
    case "on time":
      break;
    case "on time but less than 100":
      break;
    case "late":
      break;
    case "late but less than 100":
      break;
    case "dispute":
      break;
    case "rev":
      break;
    case "accepted":
      break;
    case "printed":
      break;
    case "incomplete":
      break;
    case "completed":
      break;
    case "rejected":
      break;
    case "received":
      break;
    default:
      break;
  }
}

function isEmpty(str) {
  return (!str || 0 === str.length);
}

function getDateSelectedPeriod(from) {
  $("#search_period_1").val($("#popup_period_1").val());
  $("#search_period_2").val($("#popup_period_2").val());
  if (from == "dn") {
    $("#search_period_1_inv_date").val($("#popup_period_1_inv_date").val());
    $("#search_period_2_inv_date").val($("#popup_period_2_inv_date").val());

    $("#search_period_1_due_date").val($("#popup_period_1_due_date").val());
    $("#search_period_2_due_date").val($("#popup_period_2_due_date").val());
  }
  showPeriod(from);
  $("#modal-popup-advance").modal('hide')
}

function showPeriod(from) {
  var date_period = [];
  var inv_date_period = []
  var due_date_period = []
  if (!isEmpty($("#search_period_1").val())) {
    date_period.push($("#search_period_1").val());
  }

  if (!isEmpty($("#search_period_2").val())) {
    date_period.push($("#search_period_2").val());
  }

  if (from == "dn") {
    if (!isEmpty($("#search_period_1_inv_date").val())) {
      inv_date_period.push($("#search_period_1_inv_date").val());
    }

    if (!isEmpty($("#search_period_2_inv_date").val())) {
      inv_date_period.push($("#search_period_2_inv_date").val());
    }

    if (!isEmpty($("#search_period_1_due_date").val())) {
      due_date_period.push($("#search_period_1_due_date").val());
    }

    if (!isEmpty($("#search_period_2_due_date").val())) {
      due_date_period.push($("#search_period_2_due_date").val());
    }
  }

  if (!isEmpty(date_period)) {
    $("#show_period").fadeIn().find("div:first").find("label:first").html("Period : " + date_period.join(" - "));
  } else {
    $("#show_period").fadeOut()
  }

  if (from == "dn") {
    if (!isEmpty(inv_date_period)) {
      $("#show_period").fadeIn().find("div:first").find("label:first").append(", Invoice Date : " + inv_date_period.join(" - "));
    }

    if (!isEmpty(due_date_period)) {
      $("#show_period").fadeIn().find("div:first").find("label:first").append(", Due Date : " + due_date_period.join(" - "));
    }
  }
}

function get_change_logo(method) {
  var fd = new FormData(document.getElementById("change_logo_form"));
  $.ajax({
    url: $("#change_logo_form").attr("action"),
    type: method,
    data: fd,
    enctype: 'multipart/form-data',
    processData: false, // tell jQuery not to process the data
    contentType: false,
    error: function(request) {} // tell jQuery not to set contentType
  }).done(function(data) {
    $(".modal").modal("hide");
  });
  return false;
}

function get_change_attachment(method) {
  var fd = new FormData(document.getElementById("change_attachment_form"));
  $.ajax({
    url: $("#change_attachment_form").attr("action"),
    type: method,
    data: fd,
    enctype: 'multipart/form-data',
    processData: false, // tell jQuery not to process the data
    contentType: false,
    error: function(request) {} // tell jQuery not to set contentType
  }).done(function(data) {
    $(".modal").modal("hide");
  });
  return false;
}

$(document).keyup(function(e) {
  if (e.keyCode == 27) {
    if ($(".modal").is(":visible")) {
      $(".modal").modal("hide");
    }
  }
});

function get_change_brand(method) {
  var fd = new FormData(document.getElementById("change_brand_form"));
  $.ajax({
    url: $("#change_brand_form").attr("action"),
    type: method,
    data: fd,
    enctype: 'multipart/form-data',
    processData: false,
    contentType: false,
    error: function(request) {}
  }).done(function(data) {
    $(".modal").modal("hide");
    location.reload();
  });
  return false;
}

function service_level(id) {
  var i = $("#commited_qty_" + id).val()
  if (i != '') {
    var sum_of_commit = parseInt($("#commited_for_" + id).val());
    var sum_of_ordered = parseInt($("#ordered_qty_" + id).text());
    var sl = (sum_of_commit / sum_of_ordered) * 100;
    sl = Number((sl).toFixed(2));
    if (sum_of_commit < sum_of_ordered) {
      $("#span_" + id).removeClass().addClass("red").html(sl + "%");
    } else if (sum_of_commit >= sum_of_ordered) {
      $("#span_" + id).removeClass().addClass("green").html(sl + "%");
    }
  } else {
    $("#span_" + id).removeClass().addClass("red").html("0%");
  }
}

function add_api_from_po(link) {
  var id = link.id;
  $("#" + id).bind('ajax:beforeSend', function() {
    $("#progress-bar").addClass("progress-info active");
    progress.showPleaseWait();
  }).bind('ajax:success', function(data, status, xhr, request) {
    console.log(request.status);
    success_synch_res(request.status, "Purchase Orders")
    return false
  }).bind('ajax:error', function(data, status, xhr, request) {
    error_synch_res(status.status)
    return false;
  });
}
