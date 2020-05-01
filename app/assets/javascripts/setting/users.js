function generate_code_and_name_supplier(id){
  if ($("#supplier_code_"+id).text() != ""){
    var arr = [$("#supplier_code_"+id).text(), $("#supplier_name_"+id).text()]
  }else{
    var arr = [$("#group_code_"+id).text(), $("#group_name_"+id).text()]
  }
  return arr.join(" | ");
}
function generate_code_and_name_warehouse(id){
  console.log($("#warehouse_code_"+id).text() != "")
  if ($("#warehouse_code_"+id).text() != ""){
    var arr = [$("#warehouse_code_"+id).text(), $("#warehouse_name_"+id).text()]
  }else{
    var arr = [$("#group_code_"+id).text(), $("#group_name_"+id).text()]
  }
  return arr.join(" | ");
}
show_list_supplier($("#group_user").val());

$("#submit_btn").on("click", function(){
  if ($("#supplier-table").length > 0){
    $("#supplier_supplier_id").val($('input[type=radio][name=supplier_id]:checked').val());
    console.log($("#supplier_supplier_id").val())
    var result = generate_code_and_name_supplier($("#supplier_supplier_id").val())
    $("#warehouse_or_supplier").val(result);
  }else if ($("#warehouse-table").length > 0) {
    $("#warehouse_warehouse_id").val($('input[type=radio][name=warehouse_id]:checked').val());
    var result = generate_code_and_name_warehouse($("#warehouse_warehouse_id").val())
    $("#warehouse_or_supplier").val(result);
  }
  $("#modal-select-warehouse-or-warehouse").modal("hide")
  return false;
});

$("#submit_change_warehouse_btn").on("click", function(){
  if ($("#warehouse-table").length > 0){
    $("#warehouse_warehouse_id").val($('input[type=radio][name=warehouse_id]:checked').val());
    var warehouse_selected = $('input[type=radio][name=warehouse_id]:checked').val();
    send_to_update_mutation("warehouse",warehouse_selected);
  }
});

$("#submit_change_supplier_btn").on("click", function(){
  if ($("#supplier-table").length > 0){
    $("#supplier_supplier_id").val($('input[type=radio][name=supplier_id]:checked').val());
    var supplier_selected = $('input[type=radio][name=supplier_id]:checked').val();
    send_to_update_mutation("supplier",supplier_selected);
  }
});

function send_to_update_mutation(type,id){
  var user_id = $("#selected_user_id").val();
  $.ajax({
    url: "/setting/users/update_mutation/"+user_id+"?mutation_type="+type+"&supp_wh_id="+id,
    error: function(request){
      document.getElementById('alert-wh-supp').scrollIntoView(true)
      $(".alert-selected").html(create_alert_error_for_js("Failed, please choose a "+type))
    },
    success: function(request){
      $(".modal").modal("hide");
      create_alert_notice_for_js("Success");
    }
  })
}

function remove_default_role(){
  $("#role_name option[value='customer_admin_group']").remove();
  $("#role_name option[value='supplier_admin_group']").remove();
}

function show_list_supplier(id){
  $.get("/setting/users/check_is_supplier?group_id="+id, function(request){
    if (request == "Supplier"){
      $('#supplier_group').show();
      $('#empo_group').hide();
      $("#warehouse_or_supplier").prop("placeholder","Supplier");
      remove_default_role();
      $("#role_name").append("<option value='supplier_admin_group'>SupplierAdminGroup</option>");
    }else{
      $('#empo_group').show();
      $('#supplier_group').hide();
      $("#warehouse_or_supplier").prop("placeholder","Warehouse");
      remove_default_role();
      $("#role_name").append("<option value='customer_admin_group'>CustomerAdminGroup</option>");
    }
  });
}

$(function() {
	$('#group_user').change(function(){
  });
});

var request = true;
$(function () {
  $("#find-supplier").bind("click", function(e){
    e.preventDefault();
    if (request == true){
      if ($(this).attr("from") == "select_supplier_or_warehouse"){
        $.get("/setting/select_supplier_or_warehouse/supplier", $('#form_search_supplier').serialize(), null, 'script');
      }else{
        $.get("/setting/users/mutation/"+this.name, $('#form_search_supplier').serialize(), null, 'script');
      }
      request = false;
    }else{
      request = true;
    }
  })
});

$(function () {
  $("#find-warehouse").bind("click", function(){
    if (request == true){
      if ($(this).attr("from") == "select_supplier_or_warehouse"){
        $.get("/setting/select_supplier_or_warehouse/warehouse", $('#form_search_warehouses').serialize(), null, 'script');
      }else{
        $.get("/setting/users/mutation/"+this.name, $('#form_search_warehouses').serialize(), null, 'script');
      }
      request = false;
    }else{
      request = true;
    }
  })
});