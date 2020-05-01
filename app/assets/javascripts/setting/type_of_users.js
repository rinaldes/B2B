function get_company(){
  if ($("#type_of_user_parent_id option:selected").text() == "Customer"){
    $("#desc_supplier").hide();
    $("#desc_empo").show();
  }else{
    $("#desc_supplier").show();
    $("#desc_empo").hide();
  }
}