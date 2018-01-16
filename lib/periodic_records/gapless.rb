module PeriodicRecords
  module Gapless
    extend ActiveSupport::Concern

    included do
      validate :validate_gapless_start_at, if: :gapless?
      validate :validate_gapless_end_at, if: :gapless?
      after_save :adjust_gaps, if: :gapless?
      before_destroy :before_gapless_destroy, if: :gapless?
      after_destroy :after_gapless_destroy, if: :gapless?
    end

    private

    def gapless?
      true
    end

    def validate_gapless_start_at
      if start_at_changed? && start_at_was == self.class::MIN
        errors.add :start_at, :invalid
      end
    end

    def validate_gapless_end_at
      if end_at_changed? && end_at_was == self.class::MAX
        errors.add :end_at, :invalid
      end
    end

    def adjust_gaps
      adjust_previous_gap
      adjust_next_gap
    end

    def adjust_previous_gap
      if saved_change_to_start_at? && start_at && start_at_before_last_save && start_at > start_at_before_last_save
        previous_record = siblings.where(end_at: start_at_before_last_save - 1.day).first
        if previous_record
          previous_record.end_at = start_at - 1.day
          previous_record.save(validate: false)
        end
      end
    end

    def adjust_next_gap
      if saved_change_to_end_at? && end_at && end_at_before_last_save && end_at_before_last_save > end_at
        next_record = siblings.where(start_at: end_at_before_last_save + 1.day).first
        if next_record
          next_record.start_at = end_at + 1.day
          next_record.save(validate: false)
        end
      end
    end

    def before_gapless_destroy
      if start_at == self.class::MIN
        errors.add :start_at, :invalid
      end
      if end_at == self.class::MAX
        errors.add :end_at, :invalid
      end
      unless errors.empty?
        throw :abort
      end
    end

    def after_gapless_destroy
      previous_record = siblings.where(end_at: start_at - 1.day).first
      if previous_record
        previous_record.end_at = end_at
        previous_record.save(validate: false)
      end
    end
  end
end
