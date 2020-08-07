module Chemistry
  class Ability
    include CanCan::Ability

    def initialize(user)

      can [:index, :home, :published, :latest], Chemistry::Page
      can [:read], Chemistry::Image
      can [:read], Chemistry::Video
      can [:read], Chemistry::Document
      can [:read], Chemistry::Social

      if user && user.persisted?
        # todo: perhaps be a little bit more fine-grained here.
        can :manage, :all
      end

    end
  end
end