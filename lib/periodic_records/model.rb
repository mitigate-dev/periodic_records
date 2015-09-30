module PeriodicRecords
  module Model
    extend ActiveSupport::Concern

    MIN = Date.new(0001, 1, 1)
    MAX = Date.new(9999, 1, 1)

    included do
      validates_presence_of :start_at, :end_at
      validate :validate_dates

      after_initialize :set_default_period, if: :set_default_period_after_initialize?
      after_save :adjust_overlaping_records
    end

    module ClassMethods
      def within_interval(start_date, end_date)
        t = arel_table
        where(t[:start_at].lteq(end_date)).
        where(t[:end_at].gteq(start_date))
      end

      def within_date(date)
        within_interval(date, date)
      end

      def current
        date = Date.current
        within_date(date)
      end

      def from_date(date)
        t = arel_table
        where(t[:end_at].gteq(date))
      end
    end

    def current?
      date = Date.current
      within_interval?(date, date)
    end

    def within_interval?(start_date, end_date)
      start_at && end_at && start_at <= end_date && end_at >= start_date
    end

    def siblings
      raise NotImplementedError
    end

    def overlaping_records
      @overlaping_records ||= siblings.within_interval(start_at, end_at)
    end

    def adjust_overlaping_records
      overlaping_records.each do |overlaping_record|
        if overlaping_record.start_at >= start_at &&
             overlaping_record.end_at <= end_at
          destroy_overlaping_record(overlaping_record)
        elsif overlaping_record.start_at < start_at &&
                overlaping_record.end_at > end_at
          split_overlaping_record(overlaping_record)
        elsif overlaping_record.start_at < start_at
          adjust_overlaping_record_end_at(overlaping_record)
        elsif overlaping_record.end_at > end_at
          adjust_overlaping_record_start_at(overlaping_record)
        end
      end
    end

    def set_default_period_after_initialize?
      new_record?
    end

    private

    def set_default_period
      self.start_at ||= Date.current
      self.end_at   ||= MAX
    end

    def destroy_overlaping_record(overlaping_record)
      overlaping_record.destroy
    end

    def split_overlaping_record(overlaping_record)
      overlaping_record_end = overlaping_record.dup
      overlaping_record_end.start_at = end_at + 1.day
      overlaping_record_end.end_at   = overlaping_record.end_at

      overlaping_record_start = overlaping_record
      overlaping_record_start.end_at = start_at - 1.day

      overlaping_record_start.save(validate: false)
      overlaping_record_end.save(validate: false)
    end

    def adjust_overlaping_record_end_at(overlaping_record)
      overlaping_record.end_at = start_at - 1.day
      overlaping_record.save(validate: false)
    end

    def adjust_overlaping_record_start_at(overlaping_record)
      overlaping_record.start_at = end_at + 1.day
      overlaping_record.save(validate: false)
    end

    def validate_dates
      if start_at && end_at && end_at < start_at
        errors.add :end_at, :invalid
      end
    end
  end
end
