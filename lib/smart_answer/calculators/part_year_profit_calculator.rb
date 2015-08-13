module SmartAnswer
  module Calculators
    class PartYearProfitCalculator
      include ActiveModel::Model

      attr_accessor :tax_credits_award_ends_on, :started_trading_on, :stopped_trading_on, :accounts_start_on

      def stopped_trading?
        stopped_trading_on.present?
      end

      YEARS_TO_DISPLAY = 4

      def reference_year
        reference_year = tax_credits_award_ends_on.year
      end

      def calendar_years
        ((reference_year - YEARS_TO_DISPLAY + 1)..reference_year).map do |year|
          YearRange.new(begins_on: Date.new(year, 1, 1))
        end
      end

      def tax_years
        ((reference_year - YEARS_TO_DISPLAY + 1)..reference_year).map do |year|
          TaxYear.new(begins_in: year)
        end
      end

      def accounting_years
        ((reference_year - YEARS_TO_DISPLAY + 1)..reference_year).map do |year|
          YearRange.new(begins_on: Date.new(year, accounts_start_on.month, accounts_start_on.day))
        end
      end

      def timeline_window
        years = calendar_years + tax_years + accounting_years
        begins_on = years.map(&:begins_on).min
        ends_on = years.map(&:ends_on).max
        DateRange.new(begins_on: begins_on, ends_on: ends_on)
      end

      def trading_period
        DateRange.new(begins_on: started_trading_on, ends_on: stopped_trading_on) & timeline_window
      end

      def trading_period_before_award_ends
        trading_period & DateRange.new(ends_on: tax_credits_award_ends_on)
      end

      def accounting_periods
        accounting_years.map { |ac| ac & trading_period }.reject(&:empty?)
      end

      def tax_credits_part_year
        DateRange.new(begins_on: TaxYear.on(tax_credits_award_ends_on).begins_on, ends_on: tax_credits_award_ends_on)
      end

      def universal_credit_part_year
        DateRange.new(begins_on: tax_credits_award_ends_on + 1, ends_on: TaxYear.on(tax_credits_award_ends_on).ends_on)
      end

      def tax_credits_part_year_trading
        tax_credits_part_year & trading_period
      end
    end
  end
end
