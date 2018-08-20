module Chemistry
  class Enquiry < ApplicationRecord
    include MailForm::Shim
    include MailForm::Delivery

    attributes :robot, :captcha => true
    attributes :email, :name, :message, :created_at
    append :remote_ip, :user_agent

    validates :name, presence: true
    validates :message, presence: true
    validates :email, format: /\A([\w\.%\+\-]+)@([\w\-]+\.)+([\w]{2,})\z/i

    scope :unclosed, -> { where(closed: false) }
    scope :closed, -> { where(closed: true) }
    default_scope -> { order(created_at: :desc) }

    def headers
      {
        :to => Settings.enquiries.mail_to,
        :subject => Settings.enquiries.mail_subject,
        :from => Settings.enquiries.mail_from
      }
    end

  end
end