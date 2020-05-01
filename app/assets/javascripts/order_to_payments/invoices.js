function confirmPaymentRequest(path){
  var conf = confirm("Are you sure create Early Payment Request?");
  if (conf){
    $.ajax({
      url: path,
      beforeSend: function(request){},
      success: function(request){
        window.location = path_destination
      },
      error: function(request){}
    })
  }
}

function confirmUpdateInvoiceToAPI(path,destination){
  var conf = confirm("Are you sure update Invoice to API?");
  if (conf){
    $.ajax({
      url: destination,
      beforeSend: function(request){
        $("#progress-bar").addClass("progress-info active");
        progress.showPleaseWait();
      },
      success: function(data,status,xhr,request){
        success_synch_res(xhr.status,"Invoice")
        return false;
      },
      error: function (xhr, options, error){
               error_synch_res(xhr.status)
               return false;
             }
    })
  }
}

function receiving_invoice(){
  $("#dialog-confirmation").modal();
  $("#dialog-confirmation #message").html("Are you sure you want to receive this invoice?");

  var btn = '<button type="button" class="btn btn-default" data-dismiss="modal">Cancel</button> \
             <button type="button" class="btn btn-primary">OK</button>'

  $("#dialog-confirmation .modal-footer").html(btn);
  $("#dialog-confirmation .modal-footer button").click(function() {
    $('#commit').val('')
    $("#dialog-confirmation").modal("hide");
  });
  $("#dialog-confirmation .modal-footer .btn-primary").click(function() {
    $('#commit').val('receive')
    $('form').submit()
  });
  return false;
}

$(document).ready(function(){
  $('.date').datepicker({
      format : "dd-mm-yyyy",
      autoclose : true
  });
})

function confirm_print(obj) {
  if ($("#dialog-confirmation").hasClass("in"))
    return true;

  $("#dialog-confirmation").modal();
  $("#dialog-confirmation #message").html("Are you sure you want to print this invoice?");

  var btn = '<button type="button" class="btn btn-default" data-dismiss="modal">Cancel</button> \
             <button type="button" class="btn btn-primary">OK</button>'

  $("#dialog-confirmation .modal-footer").html(btn);
  $("#dialog-confirmation .modal-footer .btn-primary").click(function() {
    $(obj)[0].click();
  });

  return false;
}
