module SmartAnswer
  class EnergyGrantsCalculatorFlow < Flow
    def define
      content_id "20c0a04d-1db4-4828-bd40-bc99954ca5f9"
      name 'energy-grants-calculator'
      status :published
      satisfies_need "100259"

      # Q1
      multiple_choice :what_are_you_looking_for? do
        option :help_with_fuel_bill
        option :help_energy_efficiency
        option :help_boiler_measure
        option :all_help
        save_input_as :which_help

        calculate :bills_help do |response|
          %w(help_with_fuel_bill).include?(response) ? :bills_help : nil
        end
        calculate :measure_help do |response|
          %w(help_energy_efficiency help_boiler_measure).include?(response) ? :measure_help : nil
        end
        calculate :both_help do |response|
          %w(all_help).include?(response) ? :both_help : nil
        end

        calculate :warm_home_discount_amount do
          ''
        end

        next_node_if(:what_are_your_circumstances?, responded_with("help_with_fuel_bill")) # Q2
        next_node :what_are_your_circumstances_without_bills_help? # Q2A
      end

      # Q2
      checkbox_question :what_are_your_circumstances? do
        option :benefits
        option :property
        option :permission
        option :social_housing

        calculate :circumstances do |response|
          response.split(",")
        end

        calculate :benefits_claimed do
          []
        end

        validate(:error_perm_prop_house) { |r| ! r.include?('permission,property,social_housing') }
        validate(:error_prop_house) { |r| ! r.include?('property,social_housing') }
        validate(:error_perm_prop) { |r| ! r.include?('permission,property') }
        validate(:error_perm_house) { |r| ! r.include?('permission,social_housing')}

        next_node(:date_of_birth?) # Q3
      end

      # Q2A
      checkbox_question :what_are_your_circumstances_without_bills_help? do
        option :benefits
        option :property
        option :permission

        calculate :circumstances do |response|
          response.split(",")
        end

        calculate :benefits_claimed do
          []
        end

        validate(:error_perm_prop) { |r| ! r.include?('permission,property') }

        define_predicate(:measure?) {
          %w(help_energy_efficiency help_boiler_measure).include?(which_help)
        }

        next_node_if(:date_of_birth?) { both_help }
        on_condition(measure?) do
          next_node_if(:which_benefits?, responded_with("benefits"))
          next_node :when_property_built?
        end
      end

      # Q3
      date_question :date_of_birth? do
        date_of_birth_defaults

        calculate :age_variant do |response|
          dob = response
          if dob < Date.new(1951, 7, 5)
            :winter_fuel_payment
          elsif dob < 60.years.ago(Date.today + 1)
            :over_60
          end
        end

        next_node_if(:which_benefits?) { circumstances.include?('benefits') }
        next_node_if(:outcome_help_with_bills) { bills_help } # outcome 1
        next_node(:when_property_built?) # Q6
      end

      # Q4
      checkbox_question :which_benefits? do
        option :pension_credit
        option :income_support
        option :jsa
        option :esa
        option :child_tax_credit
        option :working_tax_credit
        option :universal_credit

        calculate :benefits_claimed do |response|
          response.split(",")
        end
        calculate :incomesupp_jobseekers_2 do |response|
          if %w(working_tax_credit).include?(response)
            if age_variant == :over_60
              :incomesupp_jobseekers_2
            end
          end
        end

        define_predicate(:disabled_or_have_children_question?) do |response|
          response == 'income_support' ||
            response == 'jsa' ||
            response == 'esa' ||
            response == 'working_tax_credit' ||
            response.include?('universal_credit') ||
            %w{child_tax_credit esa income_support jsa pension_credit}.all? {|key| response.include? key} ||
            %w{child_tax_credit esa income_support pension_credit}.all? {|key| response.include? key} ||
            %w{child_tax_credit esa jsa pension_credit}.all? {|key| response.include? key}
        end

        on_condition(responded_with('pension_credit') || responded_with('child_tax_credit')) do
          next_node_if(:outcome_help_with_bills) { bills_help } # outcome 1
          next_node(:when_property_built?) # Q6
        end
        next_node_if(:disabled_or_have_children?, disabled_or_have_children_question?) # Q5
        next_node_if(:outcome_help_with_bills) { bills_help } # outcome 1
        next_node(:when_property_built?) # Q6
      end

      # Q5
      checkbox_question :disabled_or_have_children? do
        option :disabled
        option :disabled_child
        option :child_under_5
        option :child_under_16
        option :pensioner_premium
        option :work_support_esa

        calculate :incomesupp_jobseekers_1 do |response|
          case response
          when 'disabled', 'disabled_child', 'child_under_5', 'pensioner_premium'
            :incomesupp_jobseekers_1
          end
        end
        calculate :incomesupp_jobseekers_2 do |response|
          case response
          when 'child_under_16', 'work_support_esa'
            if circumstances.include?('social_housing') || (benefits_claimed.include?('working_tax_credit') && age_variant != :over_60)
              nil
            else
              :incomesupp_jobseekers_2
            end
          end
        end

        calculate :may_qualify_for_affordable_warmth_obligation do |response|
          response != 'none' && benefits_claimed.include?('universal_credit')
        end

        next_node_if(:outcome_help_with_bills) { bills_help } # outcome 1
        next_node(:when_property_built?) # Q6
      end

      # Q6
      multiple_choice :when_property_built? do
        option :"on-or-after-1995"
        option :"1940s-1984"
        option :"before-1940"
        save_input_as :property_age

        calculate :modern do |response|
          %w(on-or-after-1995).include?(response)
        end
        calculate :older do |response|
          %w(1940s-1984).include?(response)
        end
        calculate :historic do |response|
          %w(before-1940).include?(response)
        end

        next_node :type_of_property?
      end

      # Q7a
      multiple_choice :type_of_property? do
        option :house
        option :flat
        save_input_as :property_type

        on_condition(responded_with('house')) do
          next_node_if(:home_features_modern?) { modern }
          next_node_if(:home_features_older?) { older }
          next_node(:home_features_historic?)
        end
        next_node(:type_of_flat?)
      end

      # Q7b
      multiple_choice :type_of_flat? do
        option :top_floor
        option :ground_floor
        save_input_as :flat_type

        next_node_if(:home_features_modern?) { modern }
        next_node_if(:home_features_older?) { older }
        next_node(:home_features_historic?)
      end

      # Q8a modern
      checkbox_question :home_features_modern? do
        option :mains_gas
        option :electric_heating
        option :loft_attic_conversion
        option :draught_proofing

        calculate :features do |response|
          response.split(",")
        end

        define_predicate(:modern_and_gas_and_electric_heating?) do |response|
          modern && response.include?('mains_gas') && response.include?('electric_heating')
        end

        define_predicate(:measure_help_and_property_permission_circumstance?) do
          measure_help && (circumstances & %w(property permission)).any?
        end

        define_predicate(:no_benefits?) { circumstances.exclude?('benefits') }

        define_predicate(:property_permission_circumstance_and_benefits?) do
          (circumstances & %w(property permission)).any? and ((benefits_claimed & %w(child_tax_credit esa pension_credit)).any? or incomesupp_jobseekers_1 or incomesupp_jobseekers_2)
        end

        next_node_if(:outcome_no_green_deal_no_energy_measures, modern_and_gas_and_electric_heating?)
        on_condition(measure_help_and_property_permission_circumstance?) do
          next_node(:outcome_measures_help_green_deal)
        end
        next_node_if(:outcome_bills_and_measures_no_benefits, no_benefits?)
        next_node_if(:outcome_bills_and_measures_on_benefits_eco_eligible, property_permission_circumstance_and_benefits?)
        next_node(:outcome_bills_and_measures_on_benefits_not_eco_eligible)
      end

      # Q8b
      checkbox_question :home_features_historic? do
        option :mains_gas
        option :electric_heating
        option :modern_double_glazing
        option :loft_attic_conversion
        option :loft_insulation
        option :solid_wall_insulation
        option :modern_boiler
        option :draught_proofing

        calculate :features do |response|
          response.split(",")
        end

        define_predicate(:measure_help_and_property_permission_circumstance?) do
          measure_help && (circumstances & %w(property permission)).any?
        end

        define_predicate(:no_benefits?) { circumstances.exclude?('benefits') }

        define_predicate(:property_permission_circumstance_and_benefits?) do
          (circumstances & %w(property permission)).any? and ((benefits_claimed & %w(child_tax_credit esa pension_credit)).any? or incomesupp_jobseekers_1 or incomesupp_jobseekers_2)
        end

        on_condition(measure_help_and_property_permission_circumstance?) do
          next_node(:outcome_measures_help_green_deal)
        end
        next_node_if(:outcome_bills_and_measures_no_benefits, no_benefits?)
        next_node_if(:outcome_bills_and_measures_on_benefits_eco_eligible, property_permission_circumstance_and_benefits?)
        next_node(:outcome_bills_and_measures_on_benefits_not_eco_eligible)
      end

      # Q8c
      checkbox_question :home_features_older? do
        option :mains_gas
        option :electric_heating
        option :modern_double_glazing
        option :loft_attic_conversion
        option :loft_insulation
        option :solid_wall_insulation
        option :cavity_wall_insulation
        option :modern_boiler
        option :draught_proofing

        calculate :features do |response|
          response.split(",")
        end

        define_predicate(:measure_help_and_property_permission_circumstance?) do
          measure_help && (circumstances & %w(property permission)).any?
        end

        define_predicate(:no_benefits?) { circumstances.exclude?('benefits') }

        define_predicate(:property_permission_circumstance_and_benefits?) do
          (circumstances & %w(property permission)).any? and ((benefits_claimed & %w(child_tax_credit esa pension_credit)).any? or incomesupp_jobseekers_1 or incomesupp_jobseekers_2)
        end

        on_condition(measure_help_and_property_permission_circumstance?) do
          next_node(:outcome_measures_help_green_deal)
        end
        next_node_if(:outcome_bills_and_measures_no_benefits, no_benefits?)
        next_node_if(:outcome_bills_and_measures_on_benefits_eco_eligible, property_permission_circumstance_and_benefits?)
        next_node(:outcome_bills_and_measures_on_benefits_not_eco_eligible)
      end

      outcome :outcome_help_with_bills do
        precalculate :may_qualify_for_affordable_warmth_obligation do
          may_qualify_for_affordable_warmth_obligation
        end
        precalculate :incomesupp_jobseekers_1 do
          incomesupp_jobseekers_1
        end
      end

      outcome :outcome_measures_help_green_deal do
        precalculate :flat_type do
          flat_type
        end
      end

      outcome :outcome_bills_and_measures_no_benefits do
        precalculate :flat_type do
          flat_type
        end
      end

      outcome :outcome_bills_and_measures_on_benefits_eco_eligible do
        precalculate :may_qualify_for_affordable_warmth_obligation do
          may_qualify_for_affordable_warmth_obligation
        end
        precalculate :incomesupp_jobseekers_1 do
          incomesupp_jobseekers_1
        end
        precalculate :flat_type do
          flat_type
        end
      end

      outcome :outcome_bills_and_measures_on_benefits_not_eco_eligible do
        precalculate :may_qualify_for_affordable_warmth_obligation do
          may_qualify_for_affordable_warmth_obligation
        end
        precalculate :incomesupp_jobseekers_1 do
          incomesupp_jobseekers_1
        end
        precalculate :flat_type do
          flat_type
        end
      end

      outcome :outcome_no_green_deal_no_energy_measures
    end
  end
end
