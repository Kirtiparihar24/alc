# To change this template, choose Tools | Templates
# and open the template in the editor.

class FinancialTransactionSweeper < ActionController::Caching::Sweeper
  observe FinancialTransaction

  # If our sweeper detects that a FinancialTransaction was created call this
  def after_create(financial_transaction)
    expire_cache_for(financial_transaction)
  end

  # If our sweeper detects that a FinancialTransaction was updated call this
  def after_update(financial_transaction)
    expire_cache_for(financial_transaction)
  end

  # If our sweeper detects that a FinancialTransaction was deleted call this
  def after_destroy(financial_transaction)
    expire_cache_for(financial_transaction)
  end

  private
  def expire_cache_for(financial_transaction)
    # Expire the index page now that we added a new financial_transaction
#    expire_page(:controller => 'financial_transactions', :action => 'index')

    # Expire a fragment
    expire_fragment("financial_transactions_#{financial_transaction.company_id}")
    expire_fragment("client_view_fragment_cache_#{financial_transaction.company_id}")

  end
  
end
