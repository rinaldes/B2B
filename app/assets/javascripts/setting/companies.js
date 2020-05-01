function readURL(input){
  console.log(input.files && input.files[0])
  if (input.files && input.files[0]) {
    var reader = new FileReader();
    reader.onload = function (e) {
        $("#image-logo").attr("src", e.target.result).load(function(){
          if ($(this).width() > 100){
            $(this).width(100);
          }  
        })
    }
    reader.readAsDataURL(input.files[0]);
  }
}

$('#company_asset_name').change(function(){
  readURL(this);
});