module SmartAnswer
  module OutcomeHelper
    def format_money(amount)
      number_to_currency(amount, precision: ((amount.to_f == amount.to_f.round) ? 0 : 2))
    end

    def format_date(date)
      return nil unless date
      date.strftime('%e %B %Y')
    end

    def timeline_row(row_label, bar_label, date_or_range)
      case date_or_range
      when Date
        begins_on = ends_on = date_or_range
      when DateRange
        bar_label = "#{bar_label} (#{date_or_range.number_of_days} days)"
        begins_on, ends_on = date_or_range.begins_on, date_or_range.ends_on
      end
      "['#{row_label}', '#{bar_label}', new Date('#{begins_on}'), new Date('#{ends_on}')],".html_safe
    end
  end
end
