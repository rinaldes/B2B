function auto_selected_priority(){
  var priority_1 = parseInt($("#supplier_priority_0").val());
  // selectbox two
  $("#supplier_priority_1 option[value="+priority_1+"]").hide();

  //selectbox three
  var priority_2 = parseInt($("#supplier_priority_1").val());
  $("#supplier_priority_2 option[value="+priority_1+"]").hide();
  $("#supplier_priority_2 option[value="+priority_2+"]").hide();
}

function getCheckNumber(value, priority){
  $(".selectbox select").each(function(i){
    if (i == priority){
      i += 1;
      if (i == 3){
        return false;
      }else{
        $("#supplier_priority_"+i+" option[value=1]").show();
        $("#supplier_priority_"+i+" option[value=2]").show();
        $("#supplier_priority_"+i+" option[value=3]").show();
        if (i == 2){
          $('#supplier_priority_'+(i)+' option[value=' +  $("#supplier_priority_0").val() + ']').hide();

          $('#supplier_priority_'+(i)+' option[value=' +  $("#supplier_priority_1").val() + ']').hide();
           $('#supplier_priority_'+i).prop("selectedIndex", 0);
        }else{
          $('#supplier_priority_'+(i)+' option[value=' + value + ']').hide();
          $('#supplier_priority_'+i).prop("selectedIndex", 0);
        }
      } 
    }
    
  })
}

$(".radioB").prop("checked", false);
function getSelectedArea(val){
  $("#tmp_selected_area").val(val);
}

function updateWh(){
  var area_id = $("#tmp_selected_area").val();
  var warehouse_id = $("#tmp_warehouse_id").val();
  if (area_id == "" || area_id == undefined){
    $("#message_error").addClass("alert alert-error").html("Please choose an area");
    return false;
  }else{
    $.ajax({
      url: "/warehouses/update_area/"+warehouse_id+"/"+area_id,
      type: "GET",
      success: function(request){
        $("#flash-message").html(create_alert_notice_for_js("Area has been updated"))
        $("#modal-set-area").modal("hide");
      },
      error: function(request){
        ("#message_error").addClass("alert alert-error").html(request);
      } 
    })
  }
}

function add_warehouses_from_api(el)
{
  var id = el.id;
  $("#"+id).bind('ajax:beforeSend', function(){
    $("#progress-bar").addClass("progress-info active");
    progress.showPleaseWait();
  }).bind('ajax:success', function(data,status,xhr,request){
    console.log(request.status);
    success_synch_res(request.status,"Warehouse")
    return false
  }).bind('ajax:error', function(data,status,xhr,request){
    error_synch_res(status.status)
    return false;
  });
}

function update_warehouse_from_api(el)
{
  var id = el.id;
  $("#"+id).bind('ajax:beforeSend', function(){
    $("#progress-bar").addClass("progress-info active");
    progress.showPleaseWait();
  }).bind('ajax:success', function(data,status,xhr,request){
    console.log(request.status);
    success_synch_res(request.status,"Warehouse")
    return false
  }).bind('ajax:error', function(data,status,xhr,request){
    error_synch_res(status.status)
    return false;
  });
}