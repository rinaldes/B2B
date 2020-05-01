/*$().ready(function(){
	$("#form-create-asn").validate({
      rules: {
      commited_qty: "required",
      ordered_qty: "required"
      },
      submitHandler: function (form) {
        return false;
      }
	});
	$("#form-service-level").validate({
      rules: {
      sl_code: "required",
      sl_time: {
               required: true,
                number: true
            },
      sl_qty: {
               required: true,
                number: true
            },
      sl_line: {
               required: true,
               number: true
            }
      },
      submitHandler: function (form) {
      }
	});
});*/

function remove_line(el, id) {
  $("#dialog-confirmation").modal();
  $("#dialog-confirmation #message").html("Are you sure you want to cancel this line?");

  var btn = '<button type="button" class="btn btn-default" data-dismiss="modal">Cancel</button> \
             <button type="button" class="btn btn-primary">OK</button>'

  $("#dialog-confirmation .modal-footer").html(btn);
  $("#dialog-confirmation .modal-footer button").click(function() {
    $("#dialog-confirmation").modal("hide");
  });
  $("#dialog-confirmation .modal-footer .btn-primary").click(function() {
    $(el).parent().parent().parent().hide();
    $("#pod_" + id).val(1);
  });
  return false;
}

function confirm_cancel(po_id){
  $("#dialog-confirmation").modal();
  $("#dialog-confirmation #message").html("Are you sure you want to cancel this ASN ?");

  var btn = '<button type="button" class="btn btn-default" data-dismiss="modal">Cancel</button> \
             <button type="button" class="btn btn-primary">OK</button>'

  $("#dialog-confirmation .modal-footer").html(btn);
  $("#dialog-confirmation .modal-footer button").click(function() {
    $("#dialog-confirmation").modal("hide");
  });
  $("#dialog-confirmation .modal-footer .btn-primary").click(function() {
    window.location = '/order_to_payments/destroy/'+po_id
  });
  return false;
}

function confirm_accept_asn(act){
  $("#dialog-confirmation").modal();
  $("#dialog-confirmation #message").html("Are you sure you want to "+act+" this ASN?");

  var btn = '<button type="button" class="btn btn-default" data-dismiss="modal">Cancel</button> \
             <button type="button" class="btn btn-primary">OK</button>'

  $("#dialog-confirmation .modal-footer").html(btn);
  $("#dialog-confirmation .modal-footer button").click(function() {
    $("#dialog-confirmation").modal("hide");
  });
  $("#dialog-confirmation .modal-footer .btn-primary").click(function() {
    $('form').submit()
  });
  return false;
}

function update_value(el, id) {
  $("#pod_t" + id).val($(el).val());
  all_same = true
  for (i=0; i<$('td input[type=text]').length; i++){
    if (($('td input[type=text]')[i].value) != ($('.unit_qty')[i].innerHTML)){
      all_same = false
      break
    }
  }
  if(all_same){
    init_asn_buttons()
  }
  else{
    $('.btn-info').removeAttr('disabled')
    $('.btn-success').attr('disabled', 'disabled')
    $('.save_asn').click(function(){
      if ($('.save_asn').attr('disabled') != 'disabled'){
        $('#commit').val('save_asn');
        confirm_accept_asn('save')
      }
    })
  }
}

function init_asn_buttons(){
  $('.btn-success').removeAttr('disabled')
  $('.btn-info').attr('disabled', 'disabled')
  $('.accept_asn').click(function(){
    if ($('.accept_asn').attr('disabled') != 'disabled'){
      $('#commit').val('accept_asn');
      confirm_accept_asn('accept')
    }
  })
}

function zero_commited(asn_id) {
  $.ajax({
    dataType: "script",
    beforeSend: function(request) {},
    error: function(request) {},
    complete: function(request) {},
    url: '/order_to_payments/advance_shipment_notifications/'+asn_id+'?flag=0'
  });
}

function diff_commited(asn_id) {
  $.ajax({
    dataType: "script",
    beforeSend: function(request) {},
    error: function(request) {},
    complete: function(request) {},
    url: '/order_to_payments/advance_shipment_notifications/'+asn_id+'?flag=diff'
  });
}

function all_commited(asn_id) {
  $.ajax({
    dataType: "script",
    beforeSend: function(request) {},
    error: function(request) {},
    complete: function(request) {},
    url: '/order_to_payments/advance_shipment_notifications/'+asn_id
  });
}

$(document).ready(function () {
	// Setup - add a text input to each footer cell
	$('#results tfoot th').each(function () {
		var title = $(this).text();
		$(this).html('<input type="text" placeholder="Search ' + title + '" />');
	});

	// DataTable
	var table = $('#results').DataTable({
		"aoColumnDefs": [
			{
				"bSortable": false,
				"aTargets": [7]
			}
		],
		"aaSorting": []
	});
	$('#results tfoot th').each(function (i) {
		var title = $('#results thead th').eq($(this).index()).text();
		// or just var title = $('#sample_3 thead th').text();
		var serach = '<input type="text" placeholder="Search ' + title + '" />';
		$(this).html('');
		$(serach).appendTo(this).keyup(function () {
			table.fnFilter($(this).val(), i)
		})
	});

	// Apply the search

});
