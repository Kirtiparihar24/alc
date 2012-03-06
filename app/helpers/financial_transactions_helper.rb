module FinancialTransactionsHelper
  def financial_transaction_title
    params[:height] ? "Edit Receipt" : t(:text_financial_account_edit_receipt)
  end

  def financial_account_record_receipt_form
    if params[:height]
      remote_form_for :financial_transaction,@financial_transaction,:url=>financial_account_financial_transaction_path(@financial_account,@financial_transaction),:html=>{:method=>:put} do |f|
        render :partial => "form", :locals => { :f => f }
      end   
    else
      form_for :financial_transaction,@financial_transaction,:url=>financial_account_financial_transaction_path(@financial_account,@financial_transaction),:html=>{:method=>:put} do |f|
        render :partial => "form", :locals => { :f => f }
      end   
    end
  end
end
