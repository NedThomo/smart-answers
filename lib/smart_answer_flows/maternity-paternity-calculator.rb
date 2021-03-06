module SmartAnswer
  class MaternityPaternityCalculatorFlow < Flow
    def define
      content_id "05d5412d-455b-485e-a570-020c9176a46e"
      name 'maternity-paternity-calculator'
      status :published
      satisfies_need "100990"

      ## Q1
      multiple_choice :what_type_of_leave? do
        save_input_as :leave_type
        option maternity: :baby_due_date_maternity?
        option paternity: :leave_or_pay_for_adoption?
        option adoption: :taking_paternity_leave_for_adoption?
      end

      use_shared_logic ("adoption-calculator")
      use_shared_logic ("paternity-calculator")
      use_shared_logic ("maternity-calculator")
    end
  end
end
