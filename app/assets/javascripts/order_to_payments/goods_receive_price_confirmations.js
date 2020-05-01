function confirm_dispute(obj){
  $("#dialog-confirmation").modal();
  $("#dialog-confirmation #message").html("Are you sure you want to dispute this GRPC?");

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

function confirm_reject(obj){
  $("#dialog-confirmation").modal();
  $("#dialog-confirmation #message").html("Are you sure you want to reject this GRPC?");

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

function confirm_accept(obj){
  $("#dialog-confirmation").modal();
  $("#dialog-confirmation #message").html("Are you sure you want to accept this GRPC?");

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

$(document).ready(function() {
  // Setup - add a text input to each footer cell
  $('#tdetails tfoot th').each( function () {
    var title = $(this).text();
    $(this).html( '<input type="text" placeholder="Search '+title+'" />' );
  });

  // DataTable
  var table = $('#tdetails').DataTable({
    "aoColumnDefs": [
      { "bSortable": false, "aTargets": [ 11 ] }
    ],
    "aaSorting": [] });
  $('#tdetails tfoot th').each(function (i)
  {
    var title = $('#tdetails thead th').eq($(this).index()).text();
    // or just var title = $('#sample_3 thead th').text();
    var serach = '<input type="text" placeholder="Search ' + title + '" />';
    $(this).html('');
    $(serach).appendTo(this).keyup(function(){table.fnFilter($(this).val(),i)})
  });
});
