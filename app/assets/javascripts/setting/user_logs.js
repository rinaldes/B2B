get_history($("#history_log_selected").val())

function get_history(val){
  if (val == 0){
    login_history(val)
  }else{
    transaction_history(val)
  }
}

function login_history(val){
  $('#table').load("user_logs/login_history");
  $("#search_field option[value='Transaction Number / Voucher']").remove()
}

function transaction_history(){
  $('#table').load("user_logs/transaction_history");
  $("#search_field").append("<option value='Transaction Number / Voucher'>Transaction Number / Voucher</option>")
}