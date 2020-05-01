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
  $("#dialog-confirmation #message").html("Are you sure you want to accept this Debit Note?");

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

$(".period").height(131);
function add_debit_note_from_api(link){
  var id = link.id;
  $("#"+id).bind('ajax:beforeSend', function(){
  $("#progress-bar").addClass("progress-info active");
    progress.showPleaseWait();
  }).bind('ajax:success', function(data,status,xhr,request){
    console.log(request.status);
    success_synch_res(request.status,"Debit Note")
    return false
  }).bind('ajax:error', function(data,status,xhr,request){
    error_synch_res(status.status)
    return false;
  });
}

function create_debit_note_type_cr_from_api(link){
  var id = link.id;
  $("#"+id).bind('ajax:beforeSend', function(){
  $("#progress-bar").addClass("progress-info active");
    progress.showPleaseWait();
  }).bind('ajax:success', function(data,status,xhr,request){
    console.log(request.status);
    success_synch_res(request.status,"Debit Note")
    return false
  }).bind('ajax:error', function(data,status,xhr,request){
    error_synch_res(status.status)
    return false;
  });
}

function getTakeAction(obj){
  var path = $(obj).attr("location");
  var dest = $(obj).attr("text");
  $("#dialog-confirmation").modal();

  var txt = "";
  switch ($(obj).attr("text")) {
  case "accept":
    txt = "Are you sure you want to accept this debit note?";
    break;
  case "reject":
    txt = "Are you sure you want to reject this debit note?";
    break;
  case "dispute":
    txt = "Are you sure you want to dispute this debit note?";
    break;
  }

  $("#dialog-confirmation #message").html(txt);

  var btn = '<button type="button" class="btn btn-default" data-dismiss="modal">Cancel</button> \
             <button type="button" class="btn btn-primary">OK</button>'

  $("#dialog-confirmation .modal-footer").html(btn);
  $("#dialog-confirmation .modal-footer button").click(function() {
    $("#dialog-confirmation").modal();
  });
  $("#dialog-confirmation .modal-footer .btn-primary").click(function() {
    $("form").attr("action", path+dest).submit();
  });


  return false;
}

function get_print_debit_notes(path){
  window.open(path + "?" + $("#form_search").serialize(), "_blank")
}
