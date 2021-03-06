class DrugStocksCreator
  def self.call(*args)
    new(*args).call
  end

  def initialize(user:, facility:, for_end_of_month:, drug_stocks_params:, region: nil)
    @user = user
    @facility = facility
    @for_end_of_month = for_end_of_month
    @drug_stocks_params = drug_stocks_params || []
    @region = region || facility.region
  end

  def call
    DrugStock.transaction do
      @drug_stocks_params.map do |drug_stock|
        DrugStock.create!(facility: @facility,
                          user: @user,
                          protocol_drug_id: drug_stock[:protocol_drug_id],
                          received: drug_stock[:received].presence,
                          in_stock: drug_stock[:in_stock].presence,
                          for_end_of_month: @for_end_of_month,
                          region: @region)
      end
    end
  end
end
