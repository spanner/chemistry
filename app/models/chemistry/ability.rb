module Chemistry
  class Ability
    include CanCan::Ability

    def initialize(user)

      can [:home, :published], Chemistry::Page
      can [:index, :show, :archive, :features], Chemistry::PageCollection
      can [:read], Chemistry::Image
      can [:read], Chemistry::Video
      can [:read], Chemistry::Document
      can [:read], Chemistry::PageCategory

      # application Ability should subclass Chemistry::Ability and add management permissions. Eg:
      # if user.author?
      #   can [:index, :create, :update], Chemistry::Page
      #   can :create, Chemistry::Image
      #   can :create, Chemistry::Video
      #   can :create, Chemistry::Document
      # end
      #
      # if user.publisher?
      #   can :manage, [Chemistry::Page, Chemistry::PageCollection, Chemistry::PageCategory, Chemistry::Image, Chemistry::Video, Chemistry::Document]
      # end

    end
  end
end