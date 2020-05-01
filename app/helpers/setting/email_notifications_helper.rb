module Setting::EmailNotificationsHelper
	def email_process(var)
		arr = ['Good Receive note disputed mail to supplier', 'Good Receive note revised mail to Customer / supplier', 'Good Receive note accepted mail to Customer', 'Good Receive Price disputed mail to supplier', 'Good Receive Price revised mail to Customer / supplier', 'Good Receive Price accepted mail to Customer', 'Good Return note disputed mail to supplier', 'Good Return note revised mail to Customer / supplier', 'Good Return note accepted mail to Customer', 'Invoice created mail to Customer','Early payment request pend','Early payment request sent','Early payment request accepted','Early payment request rejected', 'Payment voucher created mail to supplier', 'Payment voucher pend mail to Customer', 'Payment voucher approved mail to Customer', 'Early payment process created mail to Customer','Early payment accepted mail to Customer', 'Early payment process rejected mail to Customer','Debitnote disputed', 'Debitnote Revised', 'Debitnote Accepted', 'Debitnote rejected' ]
		return arr[var]
	end
end
