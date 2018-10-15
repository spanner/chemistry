module Chemistry
  class ApplicationRecord < ActiveRecord::Base
    self.abstract_class = true

    # Minimal collection-assignment,
    # without the fragility and sudden rages of accepts_nested_attributes_for.
    #
    def self.accepts_collected_attributes_for(association, options={})
      klass = association.to_s.singularize.classify
      define_method :"#{association}_data=" do |associate_data|
        if persisted?
          if associate_data
            old_associate_ids = send(association).map(&:id)
            new_associate_ids = []
            updated_associate_ids = []
            associate_data.each do |datum|
              if associate_id = datum.delete(:id)
                # if already associated, update associate attributes
                if associate = send(association).find_by(id: associate_id)
                  associate.update_attributes(datum)
                  new_associate_ids.push associate_id

                # if newly associated, attach _and_ update attributes
                elsif associate = klass.find_by(id: associate_id)
                  associate.update_attributes(datum)
                  send(association) << associate
                  new_associate_ids.push associate_id
                else
                  # raise not found
                end

              else
                if options[:allow_all_blank] || datum.any?(&:present?)
                  new_associate = send(association).create(datum)
                  if new_associate.valid?
                    new_associate_ids.push new_associate.id
                  else
                    Rails.logger.warn "INVALID: #{new_associate.errors.inspect}"
                    # raise not valid
                  end
                end
              end
            end
            deleted_associate_ids = old_associate_ids - new_associate_ids
            if deleted_associate_ids.any?
              send(association).find(deleted_associate_ids).each do |associate|
                send(association).delete(associate) # will destroy only if `dependent: :destroy` is set. Safe with :through associations.
              end
              # send(association).reload
              self.touch
            end
          else
            send(association).clear
          end
        else
          associate_data.each do |datum|
            if associate_id = datum.delete(:id)
              # attach existing associate to new model, let activemodel do right thing.
              send(association) << klass.find_by(id: associate_id)
            else
              if options[:allow_all_blank] || datum.any?(&:present?)
                # build but do not save new associate
                send(association).build(datum)
              end
            end
          end
        end
      end
    end
  end
end
