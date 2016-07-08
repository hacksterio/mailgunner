require 'base64'

module Mailgunner
  class Message # rubocop:disable ClassLength
    attr_reader :mail

    def initialize(mail)
      @mail = mail
    end

    # # Returns a Mandrill API compatible attachment hash
    # def attachments
    #   regular_attachments = mail.attachments.reject(&:inline?)
    #   regular_attachments.collect do |attachment|
    #     {
    #       name: attachment.filename,
    #       type: attachment.mime_type,
    #       content: Base64.encode64(attachment.body.decoded)
    #     }
    #   end
    # end

    # # Mandrill uses a different hash for inlined image attachments
    # def images
    #   inline_attachments = mail.attachments.select(&:inline?)
    #   inline_attachments.collect do |attachment|
    #     {
    #       name: attachment.cid,
    #       type: attachment.mime_type,
    #       content: Base64.encode64(attachment.body.decoded)
    #     }
    #   end
    # end

    def bcc
      hash_addresses(mail['bcc'])
    end

    def campaign_id
      return_string_value(:campaign_id)
    end

    def cc
      hash_addresses(mail['cc'])
    end

    # Returns a formatted address
    def from
      mail[:from].formatted.first
    end

    def html
      return mail.html_part.body.decoded if mail.html_part
      return mail.body.decoded unless mail.text?
    end

    def recipient_variables
      get_value(:recipient_variables)
    end

    def reply_to
      mail[:reply_to].formatted.first
    end

    def subject
      mail.subject
    end

    def tags
      collect_tags
    end

    def test_mode
      nil_true_false?(:test_mode)
    end

    def text
      return mail.text_part.body.decoded if mail.multipart? && mail.text_part
      return mail.body.decoded if mail.text?
    end

    def to
      hash_addresses(mail['to'])
    end

    def track_clicks
      nil_true_false?(:track_clicks)
    end

    def track_opens
      nil_true_false?(:track_opens)
    end

    def to_json # rubocop:disable MethodLength, AbcSize
      json_hash = {
        from: from,
        to: to,
        cc: cc,
        bcc: bcc,
        subject: subject,
        text: text,
        html: html,
        'h:Reply-To' => reply_to,
        'o:tag' => tags,
        'o:tracking-clicks' => track_clicks,
        'o:tracking-opens' => track_opens,
        'o:testmode' => test_mode,
        'X-Mailgun-Campaign-Id' => campaign_id,
        'recipient-variables' => recipient_variables.to_json,
      }

      # json_hash[:attachments] = attachments if attachments?
      # json_hash[:images] = images if inline_attachments?
      json_hash
    end

  private

    # Returns an array of tags
    def collect_tags
      mail[:tags].to_s.split(', ').map { |tag| tag }
    end

    # Returns an array of values e.g. merge_vars or gobal_merge_vars
    # `mail[:merge_vars].value` returns the variables pre-processed,
    # `instance_variable_get('@value')` returns them exactly as they were passed in
    def get_value(field)
      mail[field] ? mail[field].instance_variable_get('@value') : nil
    end

    # Returns a Mailgun API compatible email address
    def hash_addresses(address_field)
      return [] unless address_field

      address_field.formatted.map do |address|
        address
      end
    end

    # def attachments?
    #   mail.attachments.any? { |a| !a.inline? }
    # end

    # def inline_attachments?
    #   mail.attachments.any?(&:inline?)
    # end

    def return_string_value(field)
      mail[field] ? mail[field].to_s : nil
    end

    def nil_true_false?(field)
      return nil if mail[field].nil?
      mail[field].to_s == 'true' ? true : false
    end
  end
end