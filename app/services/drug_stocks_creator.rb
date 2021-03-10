class DrugStocksCreator
  def self.call(*args)
    new(*args).call
  end

  def initialize(user, facility, month, drug_stock_params)
    @user = user
    @facility = facility
    @month = month
    @for_end_of_month = @month.end_of_month
    @drug_stock_params = drug_stock_params || []
  end

  def call
    DrugStock.transaction do
      @drug_stock_params.map do |drug_stock|
        DrugStock.create!(facility: @facility,
                          user: @user,
                          protocol_drug_id: drug_stock[:protocol_drug_id],
                          received: drug_stock[:received].presence,
                          in_stock: drug_stock[:in_stock].presence,
                          for_end_of_month: @for_end_of_month)
      end
    end
  end
end