module PeriodicRecords
  module Associations
    extend ActiveSupport::Concern

    module ClassMethods
      def has_periodic(association, as: nil)
        as ||= association
        define_periodic_preload_method(association, as)
        define_periodic_default_method(association, as)
        define_periodic_current_method(association, as)
      end

      private

      def define_periodic_preload_method(association, as)
        method_name = "preload_current_#{as}"
        accessor_name = "current_#{as.to_s.singularize}"
        define_singleton_method method_name do |records, *associations|
          reflection = reflect_on_association(association)
          records_hash = {}
          records.each do |record|
            record.send("#{accessor_name}=", nil)
            records_hash[record.id] = record
          end
          states = reflection.klass.current.
            where(reflection.foreign_key => records_hash.keys)
          states.each do |state|
            record = records_hash[state.send(reflection.foreign_key)]
            record.send("#{accessor_name}=", state)
            state.send("#{reflection.inverse_of.name}=", record)
          end
          unless associations.empty?
            ActiveRecord::Associations::Preloader.new.
              preload(states, associations)
          end
        end
      end

      # def default_assignment
      #   @default_assignment ||= employee_assignments.new
      # end
      def define_periodic_default_method(association, as)
        accessor_name = "default_#{as.to_s.singularize}"
        define_method accessor_name do
          instance_variable_get("@#{accessor_name}") ||
          instance_variable_set("@#{accessor_name}", send(association).new)
        end
      end

      # attr_writer :current_assignment
      # def current_assignment
      #   unless defined?(@current_assignment)
      #     @current_assignment = \
      #       employee_assignments.to_a.find(&:current?) ||
      #       default_assignment
      #   end
      #   @current_assignment
      # end
      def define_periodic_current_method(association, as)
        accessor_name = "current_#{as.to_s.singularize}"
        attr_writer accessor_name
        define_method accessor_name do
          unless instance_variable_defined?("@#{accessor_name}")
            current = send(association).to_a.find(&:current?)
            value = current || send("default_#{as.to_s.singularize}")
            instance_variable_set("@#{accessor_name}", value)
          end
          instance_variable_get("@#{accessor_name}")
        end
      end
    end
  end
end
