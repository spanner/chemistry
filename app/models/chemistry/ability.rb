module Chemistry
  class Ability
    include CanCan::Ability

    def initialize(user)

      can [:home, :published], Chemistry::Page
      can :create, Chemistry::Enquiry

      if user && user.persisted?

        # todo: perhaps be a little bit more fine-grained here.
        can :manage, :all

      end

    end
  end
end