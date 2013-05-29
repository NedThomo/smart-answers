module SmartAnswer::Calculators
  class PIPDatesV2

    GROUP_65_CUTOFF = Date.parse('1948-04-08')
    MIDDLE_GROUP_CUTOFF = Date.parse('1997-04-08')
    TURNING_16_UPPER_CUTOFF = Date.parse('1997-10-07')

    attr_accessor :dob

    def in_group_65?
      self.dob <= GROUP_65_CUTOFF
    end

    def in_middle_group?
      self.dob > GROUP_65_CUTOFF and self.dob < MIDDLE_GROUP_CUTOFF
    end

    def turning_16_before_oct_2013?
      self.dob >= MIDDLE_GROUP_CUTOFF and self.dob < TURNING_16_UPPER_CUTOFF
    end
  end
end
