require 'mail/check_delivery_params'

module Mailgunner
  class DeliveryMethod
    attr_accessor :client, :settings

    def initialize(values)
      @settings = values
      @client = Client.new(values)
    end

    def deliver!(mail)
      check(mail)

      message = Message.new(mail)
      @client.send_message(message.to_json)
    end

    private

    if Mail::CheckDeliveryParams.respond_to?(:check) # mail v2.6.6+
      def check(mail)
        Mail::CheckDeliveryParams.check(mail)
      end
    else
      include Mail::CheckDeliveryParams

      def check(mail)
        check_delivery_params(mail)
      end
    end
  end

  if defined?(ActionMailer)
    ActionMailer::Base.add_delivery_method :mailgun, DeliveryMethod
  end
end
