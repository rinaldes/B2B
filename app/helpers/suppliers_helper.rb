module SuppliersHelper
  def txt_email_address(level_limit)
    _arr_email = ["email_address_1", "email_address_2", "email_address_3","email_address_4","email_address_5"]
    _text = []
    _arr_grn_and_grtn = ["Store ALC",
             "Store Duty Manager",
             "Store General Manager",
             "Store Regional General Manager",
             "Score Operation Director (Final Decision)"
           ]
    _arr_grpc = ["Head Office Buyer",
                 "Head Office Category Manager",
                 "Head Office Food/Non-Food Commercial Director (Final Decision)"
              ]

    if level_limit.level_type == GRPC
      _arr_email.delete_if{|ll| ll == "email_address_5" || ll == "email_address_4"}
    end

    _arr_email.each_with_index do |ll, i|
      if level_limit.level_type == GRN
        _text << "Level #{i+1}: #{text_field_tag 'grn['+ll+']', level_limit.try(ll), placeholder: 'Email' } (#{_arr_grn_and_grtn[i]})"
      elsif level_limit.level_type == GRPC
        _text << "Level #{i+1}: #{text_field_tag 'grpc['+ll+']', level_limit.try(ll), placeholder: 'Email'} (#{_arr_grpc[i]})"
      else
        _text << "Level #{i+1}: #{text_field_tag 'grtn['+ll+']', level_limit.try(ll), placeholder: 'Email'} (#{_arr_grn_and_grtn[i]})"
      end
    end

    return _text.join("<br/>").html_safe
  end
end
