function confirmPaymentRequest(path, state_name){
  if (state_name == 'no-state'){
    $.ajax({
      url: path,
      success: function(request){
        $("#modal-popup-bank").modal();
      },
      beforeSend: function(request){},
      error: function(request){}
    });
    return false;
  }

  if (state_name == "Accept"){
    var conf = confirm("Are you sure "+state_name+" Early Payment Request?");
    if (conf){
      $.ajax({
        url: path+"?state_name="+state_name,
        success: function(request){
          $("#modal-popup-bank").modal();
        },
        beforeSend: function(request){},
        error: function(request){}
      });
    }else{

    }
  }else{
    var conf2 = confirm("Are you sure "+state_name+" Early Payment Request?");
    if (conf2){
      getApproved(path, state_name);
    }
  }
}

function getApproved(path, state_name){
  $.ajax({
    url: path+"?state_name="+state_name,
    beforeSend: function(request){},
    error: function(request){}
  })
}