function calculate_return_qty(val, index, rec_qty){
  if (parseFloat(rec_qty) != 0){
    var return_value = $("#returned_process_return_qty_"+index).val();
    var remain_qty = rec_qty - return_value;
    $("#tot_retur_qty_"+index).text(parseInt(remain_qty))
  }
}

function add_api_from_return(link){
  var id = link.id;
  $("#"+id).bind('ajax:beforeSend', function(){
    $("#progress-bar").addClass("progress-info active");
    progress.showPleaseWait();
  }).bind('ajax:success', function(data,status,xhr,request){
    console.log(request.status);
    success_synch_res(request.status,"Returned Process")
    return false
  }).bind('ajax:error', function(data,status,xhr,request){
    error_synch_res(status.status)
    return false;
  });
}

function confirm_dispute(obj) {
  $("#dialog-confirmation").modal();
  $("#dialog-confirmation #message").html("Are you sure you want to dispute this Debit Note?");

  var btn = '<button type="button" class="btn btn-default" data-dismiss="modal">Cancel</button> \
             <button type="button" class="btn btn-primary">OK</button>'

  $("#dialog-confirmation .modal-footer").html(btn);
  $("#dialog-confirmation .modal-footer button").click(function() {
    $("#dialog-confirmation").modal("hide");
  });
  $("#dialog-confirmation .modal-footer .btn-primary").click(function() {
    $("form").submit();
  });

  return false;
}

function confirm_accept(obj) {
  $("#dialog-confirmation").modal();
  $("#dialog-confirmation #message").html("Are you sure you want to accept this Return Process?");

  var btn = '<button type="button" class="btn btn-default" data-dismiss="modal">Cancel</button> \
             <button type="button" class="btn btn-primary">OK</button>'

  $("#dialog-confirmation .modal-footer").html(btn);
  $("#dialog-confirmation .modal-footer button").click(function() {
    $("#dialog-confirmation").modal("hide");
  });
  $("#dialog-confirmation .modal-footer .btn-primary").click(function() {
    $("form").submit();
  });

  return false;
}