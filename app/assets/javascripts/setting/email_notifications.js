function loadEmailForm(email_type, var2){
	if($( "#collapse"+var2).hasClass( "in" )){
	}else{
		$.ajax({
			url: 'email_notifications/load_email_form/' + email_type + '?id_form=' + var2
		}); 
	}
}