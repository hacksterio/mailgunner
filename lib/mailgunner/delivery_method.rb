require 'mail/check_delivery_params'

module Mailgunner
  class DeliveryMethod
    include Mail::CheckDeliveryParams

    attr_accessor :settings

    def initialize(values)
      @settings = values
      @client = Client.new(values)
    end

    def deliver!(mail)
      check_delivery_params(mail)

      message = Mailgunner::Message.new(mail)
      @client.send_message(message.to_json)
    end
  end

  if defined?(ActionMailer)
    ActionMailer::Base.add_delivery_method :mailgun, DeliveryMethod
  end
end
