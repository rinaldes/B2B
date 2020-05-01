function update_supplier_group_from_api(link)
{
  var id = link.id;
  $("#"+id).bind('ajax:beforeSend', function(){
  $("#progress-bar").addClass("progress-info active");
    progress.showPleaseWait();
  }).bind('ajax:success', function(data,status,xhr,request){
    console.log(request.status);
    success_synch_res(request.status,"Group")
    return false
  }).bind('ajax:error', function(data,status,xhr,request){
    error_synch_res(status.status)
    return false;
  });
}
