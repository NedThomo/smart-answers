module SmartAnswer
  module Calculators
    class PartYearProfitCalculator
      include ActiveModel::Model

      attr_accessor :tax_credits_award_ends_on, :accounts_start_on, :profit_for_current_period

      def basis_period
        YearRange.new(begins_on: accounts_start_on)
      end

      def award_period
        DateRange.new(begins_on: TaxYear.current.begins_on, ends_on: tax_credits_award_ends_on)
      end

      def profit_per_day
        (profit_for_current_period / basis_period.number_of_days).floor(2)
      end

      def part_year_profit
        (profit_per_day * award_period.number_of_days).floor
      end
    end
  end
end
