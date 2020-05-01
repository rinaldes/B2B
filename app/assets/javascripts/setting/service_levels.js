var request = true;
$(function () { 
  $("#find_service_level").bind("click", function(){
    if (request == true){
      $.get("/suppliers/edit_service_level", $('#form_search').serialize(), null, 'script');
      request = false;
    }else{
      request = true;
    }
  })
});