$(document).ready(function(){
  switch_field_detail($("#search_field"))
  $("#search_field").change(function(){
    switch_field_detail($("#search_field"))
  })

  $('.date').datepicker({
      format : "dd-mm-yyyy",
      autoclose : true
  });
})


function switch_field_detail(el){
  if (el.val() == "Payment Invoice Due Date"){
    $(".due_date").show()
    $(".another_detail").hide()
  }else{
    $(".due_date").hide()
    $(".another_detail").show()
  }
}

function get_ajax_list_supplier(el){
  var value = $("#"+el.id ).val();
  if (((value.length ) > 1) && ((value.length % 2) == 0 ))
  {
    $.ajax({
    beforeSend: function(request){},
    success: function(request){
      var _arr=[];
      request.map(function(val){
          _arr.push(val.label);
    });
      get_autocomplete_supplier(_arr);
    },
    error: function(request){
      console.log("Error");
    },
    complete: function(request){},
    url: '/get_autocomplete_details/suppliers/'+value,
    type: "GET",
    dataType: "json"
    });
  }
}

function confirm_generate(obj){
  $("#dialog-confirmation").modal();
  $("#dialog-confirmation #message").html("Are you sure you want to generate this voucher?");

  var btn = '<button type="button" class="btn btn-default" data-dismiss="modal">Cancel</button> \
             <button type="button" class="btn btn-primary">OK</button>'

  $("#dialog-confirmation .modal-footer").html(btn);
  $("#dialog-confirmation .modal-footer button").click(function() {
    $("#dialog-confirmation").modal("hide");
  });
  $("#dialog-confirmation .modal-footer .btn-primary").click(function() {
    $("form").submit();
  });

  return false;
}

function get_autocomplete_supplier(dataSources){
  $('#supplier_name_autocomplete').typeahead({
    minLenght: 0,
    updater: function(item){
      console.log(item)
      return item;
    },
    sorter: function(items) {
      if (items.length == 0) {
        var noResult = new Object();
        items.push(noResult);
      }
        return items;
    },
    highlighter: function(item) {
      if (dataSources.indexOf(item) == -1) {
        return "<span>No Match Found.</span>";
      }else {
        return "<span>"+item+"</span>";
      }
    },
    source: function (typeahead, query){
      return dataSources
    }
  })
}

$(document).ready(function(){
  // check select all or unselect all
  $("#select_all").change(function(){
    if ($(this).is(":checked") == true){
      $(":checkbox").prop("checked", true)
    }else{
      $(":checkbox").prop("checked", false)
    }
  });

  var track_load = 2; //total loaded record group(s)
  var loading  = false; //to prevents multipal ajax loads
  var total_groups = parseInt($("#total_count").val()); //total record group(s)

  $(window).scroll(function() { //detect page scroll
    if($(window).scrollTop() + $(window).height() == $(document).height())  //user scrolled to bottom of the page?
    {
      if(track_load <= total_groups && loading==false) //there's more data to load
      {
        loading = true; //prevent further ajax loading
        $('.animation_image').show(); //show loading image

        //load data from the server using a HTTP POST request
        $.get("get_invoice_based_on_supplier/"+$("#supplier_id").val(), {'page': track_load}, function(data){

          $(".get_invoice").append(data); //append received data into the element

          //hide loading image
          $('.animation_image').hide(); //hide loading image once data is received

          track_load++; //loaded group increment
          loading = false;

        }).fail(function(xhr, ajaxOptions, thrownError) { //any errors?

          alert(thrownError); //alert with HTTP error
          $('.animation_image').hide(); //hide loading image
          loading = false;

        });

      }
    }
  });
});

function get_invoice_based_on_supplier(value){
  $.ajax({
    success: function(request){
      $(".get_invoice").html(request);
    }, url: "/payment_vouchers/get_invoice_based_on_supplier/"+value
  })
}

$(function(){
  $('#search_detail').bind('keypress', function(e) {
    var category = $("#search_field option:selected").text().split(" ").join("_");
    var detail = $("#search_detail").val();
    if(e.keyCode==13){
      $.get("/payment_vouchers/get_invoice_based_on_supplier/"+$("#supplier_name_autocomplete").val()+"?"+category+"="+detail, function(request){
      $(".get_invoice").html(request);
    });
    }
  });
})

function get_data_invoice(){
  var category = $("#search_field option:selected").text().split(" ").join("_");
  if ($("#search_detail").is(":visible")){
    var detail = $("#search_detail").val();
  }else{
    var detail = $("#search_detail_due_date").val();
  }

  $.get("/payment_vouchers/get_invoice_based_on_supplier/"+$("#supplier_name_autocomplete").val()+"?"+category+"="+detail, function(request){
    $(".get_invoice").html(request);
  })
}
