function confirm_dispute(obj) {
  $("#dialog-confirmation").modal();
  $("#dialog-confirmation #message").html("Are you sure you want to dispute this GRN?");

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

function confirm_reject(obj) {
  $("#dialog-confirmation").modal();
  $("#dialog-confirmation #message").html("Are you sure you want to reject this GRN?");

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
  $("#dialog-confirmation #message").html("Are you sure you want to accept this GRN?");

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
  setup_datatable();
});

function setup_table(id, sort) {
  $('#' + id + ' tfoot th').each(function() {
    var title = $(this).text();
    $(this).html('<input type="text" placeholder="Search ' + title + '" />');
  });

  var table = null;
  if (sort) {
    table = $('#' + id).DataTable({
      "aoColumnDefs": [{
        "bSortable": false,
        "aTargets": [sort]
      }],
      "aaSorting": []
    });
  } else {
    table = $('#' + id).DataTable({
      "aaSorting": []
    });
  }

  $('#' + id + ' tfoot th').each(function(i) {
    var title = $('#' + id + ' thead th').eq($(this).index()).text();
    var search = '<input type="text" placeholder="Search ' + title + '" />';
    $(this).html('');
    $(search).appendTo(this).keyup(function() {
      table.fnFilter($(this).val(), i)
    })
  });
}

function setup_datatable() {
  setup_table("details", -1);
  setup_table("remarks", -1);
  setup_table("serials");
}
