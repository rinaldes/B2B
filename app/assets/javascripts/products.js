function add_products_from_api(link)
{
  var id = link.id;
  $("#"+id).bind('ajax:beforeSend', function(){
  $("#progress-bar").addClass("progress-info active");
    progress.showPleaseWait();
  }).bind('ajax:success', function(data,status,xhr,request){
    console.log(request.status);
    success_synch_res(request.status,"Products")
    return false
  }).bind('ajax:error', function(data,status,xhr,request){
    error_synch_res(status.status)
    return false;
  });
}
function update_product_from_api(el)
{
  var id = el.id;
  $("#"+id).bind('ajax:beforeSend', function(){
    $("#progress-bar").addClass("progress-info active");
    progress.showPleaseWait();
  }).bind('ajax:success', function(data,status,xhr,request){
    console.log(request.status);
    success_synch_res(request.status,"Product")
    return false
  }).bind('ajax:error', function(data,status,xhr,request){
    error_synch_res(status.status)
    return false;
  });
}