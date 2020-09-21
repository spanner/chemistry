module Chemistry
  class Ability
    include CanCan::Ability

    def initialize(user)

      can [:home, :index, :published], Chemistry::Page
      can [:index, :show, :archive, :features], Chemistry::PageCollection
      can [:read], Chemistry::Image
      can [:read], Chemistry::Video
      can [:read], Chemistry::Document
      can [:read], Chemistry::Social
      can [:read], Chemistry::PageCategory

      # application Ability should subclass Chemistry::Ability and add management permissions. Eg:
      # if user.author?
      #   can [:create, :update], Chemistry::Page
      #   can :create, Chemistry::Image
      #   can :create, Chemistry::Video
      #   can :create, Chemistry::Document
      #   can :create, Chemistry::Social
      # end
      #
      # if user.publisher?
      #   can :manage, [Chemistry::Page, Chemistry::PageCollection, Chemistry::PageCategory, Chemistry::Image, Chemistry::Video, Chemistry::Document, Chemistry::Social]
      # end

    end
  end
end