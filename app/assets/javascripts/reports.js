$(document).ready(function(){
	$(".print_to").click(function(){
	  var param = $("#form_search_reports").serialize();
		window.location = this.name +"?"+ param;
	})

	$(".print_to_pdf").click(function(){
	  var param = $("#form_search_reports").serialize();
		 window.open(this.name + "?" + param, "_blank")
	})	
})
