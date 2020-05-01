var delay = (function(){
  var timer = 0;
  return function(callback, ms){
    clearTimeout (timer);
    timer = setTimeout(callback, ms);
  };
})();
function get_supplier_auto_complete(el)
{
 	var value = $("#"+el.id ).val();
 	//if (((value.length ) > 3) && ((value.length % 2) == 0 )){
   	$.ajax({
    beforeSend: function(request){},
    success: function(request){
      var nana=[];
      request.map(function(val){
	    nana.push(val.label);
        if ($('#supplier_name_autocomplete').val() != '')
	      $('#retur, #debit').removeClass('disabled')
	  });
      suppliers_auto(nana);
    },
    error: function(request){
    	console.log("Error");
    },
    complete: function(request){},
    url: '/get_autocomplete_details/suppliers/'+value,
    type: "GET",
    dataType: "json"
    });
  //}
}

function suppliers_auto(dataSources)
{
  $('#supplier_name_autocomplete').focus();
	$('#supplier_name_autocomplete').typeahead({
	  minLength: 0,
	  updater: function(item){
	    return item;
	  },
	  sorter: function(items) {
	    if (items.length == 0) {
	      var noResult = new Object();
	      items.push(noResult);
	    }
	      return items;
	  },
	  highlighter: function(item) {
	    if (dataSources.indexOf(item) == -1) {
	      return "<span>No Match Found.</span>";
	    }else {
	      return "<span>"+item+"</span>";
	    }
	  },
	  source: function (typeahead, query){
	    return dataSources
	  }
	})
    // ====================== end autocomplete take order ===============
}

function get_invoice_auto_complete(el)
{
 	var value = $("#"+el.id ).val();
 	$.ajax({
    beforeSend: function(request){},
    success: function(request){
      var nana=[];
      request.map(function(val){
        nana.push(val.label);
      });
      invoices_auto(nana);
    },
    error: function(request){
    	console.log("Error");
    },
    complete: function(request){},
    url: '/get_autocomplete_details/invoices/'+value,
    type: "GET",
    dataType: "json"
  });
}

function invoices_auto(dataSources)
{
  $('#invoice_id_autocomplete').focus();
  var $input2 = $('.typeahead');// EDIT FORM
	$input2.typeahead({
	  minLength: 0,
	  updater: function(item){
	    return item;
	  },
	  sorter: function(items) {
	    if (items.length == 0) {
	      var noResult = new Object();
	      items.push(noResult);
	    }
	    return items;
	  },
	  highlighter: function(item) {
	    if (dataSources.indexOf(item) == -1) {
	      return "<span>No Match Found.</span>";
	    }else {
	      return "<span>"+item+"</span>";
	    }
	  },
	  source: function (typeahead, query){
	    return dataSources
	  }
	}).change(function(){
    $('#invoice_number').val($('#invoice_id_autocomplete').val())
  })
    // ====================== end autocomplete take order ===============
}

function get_autocomplete_vouchers(el){

}

function to_select_toggle(el){
  // check select all or unselect all
  if ($("#"+el.id).is(":checked") == true){
    if (el.id == "select_all_dn"){
      $("#check_dn").find(":checkbox").prop("checked", true)
    }else if (el.id == "select_all_pv"){
      $("#check_pv").find(":checkbox").prop("checked", true)
    }else{
      $("#check_retur").find(":checkbox").prop("checked", true)
    }
  }else{
    if (el.id == "select_all_dn"){
      $("#check_dn").find(":checkbox").prop("checked", false)
    }else if (el.id == "select_all_pv"){
      $("#check_pv").find(":checkbox").prop("checked", false)
    }else{
      $("#check_retur").find(":checkbox").prop("checked", false)
    }
  }
}

function change_format_currency(n){
  return accounting.formatMoney(n, "", 2, ".", ",")
}

var last_id = 0;
function add_checked_pv_to_total_results(el,table_name){
  var pv_ids = []
  var str = "";
  var id_tempat='';
  var total_pv = 0;
  var total_dn = 0;
  var total_retur = 0;
  var total_dr = 0;
  var total_all = 0;
  var first_total = 0;
  if ($("#pv").parent().hasClass("active")) {
    $("#table-pv-results > tbody  > tr").each(function() {
 	    if ($("#"+this.id+" input[type=checkbox]").is(":checked") ==  true) {
        var id = this.id.split("_")[1];
        var tot = parseFloat(""+$("#"+this.id+" :nth-child(4)").text().split(" ")[1].split(".").join(""));
   	    var string = "<tr><td style='width:50%;'>"+$("#"+this.id+" :nth-child(1)").text()+"</td><td class='text-right'><input class='pv-edit-total' data-link='detcost_"+last_id+"' value='"+tot+"'/></td></tr>";
   	    total_pv = tot + total_pv;
        str = str.concat(string);
   	    var type ="PaymentVoucher";
        if (!$('#for-pv').length ) {
          id_tempat = "for-pv";
          $("<div id='for-pv'></div>").insertAfter('#inputs-for-details');
        }
        $("<input type='hidden' name='payment[payment_details_attributes]["+last_id+"][temp_detail_candidate]' value='"+id+"'\> \
           <input type='hidden' name='payment[payment_details_attributes]["+last_id+"][temp_type]' value='"+type+"' \>\
           <input id='detcost_"+last_id+"' type='hidden' name='payment[payment_details_attributes]["+last_id+"][temp_total]' value='"+tot+"' \>").appendTo("#inputs-for-details");
   	    ++last_id;
 	    }
 	  });

 	  if (str.length > 0) {
 	    $("#pv-rek-di-bayar > table > tbody").html(str);
      $("#total-pv").html("Rp. "+change_format_currency(total_pv));
 	  }
  }

  if ($("#debit").parent().hasClass("active")) {
    str ='';
    $("#table-dn-results > tbody  > tr").each(function(){
 	    if ($("#"+this.id+" input[type=checkbox]").is(":checked") ==  true) {
        var id = this.id.split("_")[1];
        var tot = parseFloat(""+$("#"+this.id+" :nth-child(3)").text().split(" ")[1].split(".").join(""));
   	    var string = "<tr><td style='width:50%;'>"+$("#"+this.id+" :nth-child(1)").text()+"</td><td class='text-right'><input class='dn-edit-total' data-link='detcost_"+last_id+"' value='"+tot+"'/></td></tr>";
	      total_dn = total_dn + tot;
	      str = str.concat(string);
	      var type ="DebitNote"
	      if (!$('#for-dn').length ){
      	  id_tempat = "for-dn";
      	  $("<div id='for-dn'></div>").insertAfter('#inputs-for-details');
    	  }
        $("<input type='hidden' name='payment[payment_details_attributes]["+last_id+"][temp_detail_candidate]' value='"+id+"'\> \
           <input type='hidden' name='payment[payment_details_attributes]["+last_id+"][temp_type]' value='"+type+"' \>\
           <input id='detcost_"+last_id+"' type='hidden' name='payment[payment_details_attributes]["+last_id+"][temp_total]' value='"+tot+"' \>").appendTo("#inputs-for-details");
 	      ++last_id;
 	    }
 	  });
 	 //  var check = $("#total-pv").text().split(" ");
 	 //  if (str.length > 0 && (check.length > 1)) {
 	 //    var check_again = parseFloat(check[1].split(".").join(""));
    //   if (check_again != NaN){
        $("#dn-nu-rek-di-pake > table > tbody").html(str);
 	      $("#total-dn").html("Rp. "+change_format_currency(total_dn));
    //   }
 	 //  }
  }

  if ($("#retur").parent().hasClass("active")) {
    str ='';
    $("#table-retur-results > tbody  > tr").each(function() {
      if ($("#"+this.id+" input[type=checkbox]").is(":checked") ==  true) {
        var id = this.id.split("_")[1];
        var tot = parseFloat(""+$("#"+this.id+" :nth-child(4)").text().split(" ")[1].split(".").join(""));
        var string = "<tr><td style='width:50%;'>"+$("#"+this.id+" :nth-child(1)").text()+"</td><td class='text-right'><input class='retur-edit-total' data-link='detcost_"+last_id+"' value='"+tot+"'/></td></tr>";
        total_retur = total_retur + tot;
        str = str.concat(string);
        var type ="ReturnedProcess"
        if (!$('#for-retur').length ){
          id_tempat = "for-retur";
          $("<div id='for-retur'></div>").insertAfter('#inputs-for-details');
        }
        $("<input type='hidden' name='payment[payment_details_attributes]["+last_id+"][temp_detail_candidate]' value='"+id+"'\> \
           <input type='hidden' name='payment[payment_details_attributes]["+last_id+"][temp_type]' value='"+type+"' \>\
           <input id='detcost_"+last_id+"' type='hidden' name='payment[payment_details_attributes]["+last_id+"][temp_total]' value='"+tot+"' \>").appendTo("#inputs-for-details");
        ++last_id;
      }
    });
    //
    // var check = $("#total-pv").text().split(" ");
    // if (str.length > 0 && (check.length > 1)) {
    //   var check_again = parseFloat(check[1].split(".").join(""));
    //   if (check_again != NaN){
        $("#retur-nu-rek-di-pake > table > tbody").html(str);
        $("#total-retur").html("Rp. "+change_format_currency(total_retur));
    //   }
    // }
  }

  var total_pv = 0;
  var l_total_pv = $("#total-pv").text().split(" ");
  if (l_total_pv.length > 1){
    total_pv = parseFloat(l_total_pv[1].split(".").join(""));
  }

  var total_dn = 0;
  var l_total_dn = $("#total-dn").text().split(" ");
  if (l_total_dn.length > 1){
    total_dn = parseFloat(l_total_dn[1].split(".").join(""));
  }

  var total_retur = 0
  var l_total_retur = $("#total-retur").text().split(" ");
  if (l_total_retur.length > 1){
    total_retur = parseFloat(l_total_retur[1].split(".").join(""))
  }

  first_total = total_pv - total_dn;
  total_all = total_pv - (total_dn + total_retur);
  $("#create-payment").removeAttr("disabled");
  $("#total-all").html("Rp. "+change_format_currency(total_all));

  $(".pv-edit-total, .dn-edit-total, .retur-edit-total").autoNumeric("init",{
      aSep: '.',
      aDec: ',',
      aSign: 'Rp '
  });

  $(".pv-edit-total, .dn-edit-total, .retur-edit-total").on('keyup', function() {
    var total_pv = 0;
    var total_dn = 0;
    var total_retur = 0;
    $(".pv-edit-total").each(function() {
      if ($(this).val() == "")
        return;

      var val = parseFloat($(this).val().split(" ")[1].split(".").join(""));
      if (!isNaN(val))
        total_pv += val;
    });

    $(".dn-edit-total").each(function() {
      if ($(this).val() == "")
        return;

      var val = parseFloat($(this).val().split(" ")[1].split(".").join(""));
      if (!isNaN(val))
        total_dn += val;
    });

    $(".retur-edit-total").each(function() {
      if ($(this).val() == "")
        return;

      var val = parseFloat($(this).val().split(" ")[1].split(".").join(""));
      if (!isNaN(val))
        total_retur += val;
    });

    var total_all = total_pv - (total_dn + total_retur);
    if ($("#total-pv").html() != "") $("#total-pv").html("Rp. "+change_format_currency(total_pv));
    if ($("#total-dn").html() != "") $("#total-dn").html("Rp. "+change_format_currency(total_dn));
    if ($("#total-retur").html() != "") $("#total-retur").html("Rp. "+change_format_currency(total_retur));
    $("#total-all").html("Rp. "+change_format_currency(total_all));

    $('#' + $(this).attr('data-link')).val(parseFloat($(this).val().split(" ")[1].split(".").join("")));
  });
}

function get_search_dn(el)
{
  var lala =$("#" + el.id).attr("data-toggle").toString();
 	var path = "/payments/search_dn/";
  var panel = "panel-debit";
  var table = 'table-dn-results'
  var supplier_code = $("#supplier_name_autocomplete").val();
  supplier_code = supplier_code.replace(" ", "%20");

  $.ajax({
    beforeSend: function(request){
      var height = $("#"+table).height();
      var width = 1092;
      ajax_loading_table(table,height, width);
    },
    success: function(request){
      $("#insert-before-ajax-loading").remove();
    },
    error: function(request){
      console.log("Please check again");
    },
    complete: function(request){},
      url: path+''+supplier_code,
      type: "GET"
  });
}

function get_search_retur(el){
  lala = $("#"+el.id).attr("data-toggle").toString();
  var path = "/payments/search_retur/";
  var panel = "panel-retur";
  var table = 'table-retur-results'
  var supplier_code = $("#supplier_name_autocomplete").val();
  $.ajax({
    beforeSend: function(request){
      var height = $("#"+table).height();
      var width = 1092;
      ajax_loading_table(table,height, width);
    },
    success: function(request){
      $("#insert-before-ajax-loading").remove();
    },
    error: function(request){
      console.log("Please check again");
    },
    complete: function(request){},
    url: path+''+supplier_code,
    type: "GET"
  });
}
