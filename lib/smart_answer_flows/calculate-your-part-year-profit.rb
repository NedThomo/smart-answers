module SmartAnswer
  class CalculateYourPartYearProfitFlow < Flow
    def initialize(calculator = Calculators::PartYearProfitCalculator.new)
      @calculator = calculator
      super()
    end

    def define
      name 'calculate-your-part-year-profit'

      status :published
      satisfies_need "103438"

      calculator = @calculator

      date_question :when_did_your_tax_credits_award_end? do
        next_node do |response|
          calculator.tax_credits_award_ends_on = response
          :when_did_you_start_trading?
        end
      end

      date_question :when_did_you_start_trading? do
        next_node do |response|
          calculator.started_trading_on = response
          :have_you_stopped_trading?
        end
      end

      multiple_choice :have_you_stopped_trading? do
        option :yes
        option :no

        next_node do |response|
          if response == 'yes'
            :when_did_you_stop_trading?
          else
            :when_do_your_business_accounts_start?
          end
        end
      end

      date_question :when_did_you_stop_trading? do
        next_node do |response|
          calculator.stopped_trading_on = response
          :when_do_your_business_accounts_start?
        end
      end

      date_question :when_do_your_business_accounts_start? do
        default_year 0

        next_node do |response|
          calculator.accounts_start_on = response
          # :what_is_your_taxable_profit?
          :outcome
        end
      end

      # money_question :what_is_your_taxable_profit? do
      #   precalculate(:from_date) { calculator.basis_period.begins_on }
      #   precalculate(:to_date) { calculator.basis_period.ends_on }
      #
      #   next_node do |response|
      #     calculator.profit_for_current_period = response
      #     :outcome
      #   end
      # end

      use_outcome_templates

      outcome :outcome do
        precalculate(:calculator) { calculator }
      end
    end
  end
end
