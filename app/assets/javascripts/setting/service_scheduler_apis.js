$( "#service_scheduler_api_type_time" ).change(function() {
  time = $("#time").val();
  type_time = this.value;
  if (type_time == "M" || type_time == "H"){
    $.ajax({
      url: '/setting/service_scheduler_apis/get_type_time?'+ "type_time=" + type_time + "&time="+ time
    });    
  }
});

$( document ).ready(function() {
  time = $("#time").val();
  if(time > 0){
    type_time = $("#service_scheduler_api_type_time").val();
    $.ajax({
      url: '/setting/service_scheduler_apis/get_type_time?'+ "type_time=" + type_time + "&time="+ time
    }); 
  }
});