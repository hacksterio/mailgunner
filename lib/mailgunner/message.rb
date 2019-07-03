require 'base64'

module Mailgunner
  class Message # rubocop:disable ClassLength
    attr_reader :mail

    def initialize(mail)
      @mail = mail
    end

    def bcc
      hash_addresses(mail['bcc'])
    end

    def campaign_id
      return_string_value(:campaign_id)
    end

    def cc
      hash_addresses(mail['cc'])
    end

    # Returns a hash with `h:` prefixed to the keys
    def custom_headers
      (get_value(:custom_headers) || {}).each_with_object({}) do |(k, v), mem|
        mem['h:%s' % k] = v
      end
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
      {
        bcc: bcc,
        cc: cc,
        from: from,
        html: html,
        subject: subject,
        text: text,
        to: to,
        'h:Reply-To' => reply_to,
        'o:tag' => tags,
        'o:testmode' => test_mode,
        'o:tracking-clicks' => track_clicks,
        'o:tracking-opens' => track_opens,
        'recipient-variables' => recipient_variables.to_json,
        'X-Mailgun-Campaign-Id' => campaign_id,
      }.merge(custom_headers).tap do |json_hash|
        # json_hash[:attachments] = attachments if attachments?
        # json_hash[:images] = images if inline_attachments?
      end
    end

  private

    # Returns an array of tags
    def collect_tags
      mail[:tags].to_s.split(', ').map { |tag| tag }
    end

    # Returns an array of values e.g. merge_vars or gobal_merge_vars
    # `mail[:merge_vars].value` returns the variables pre-processed,
    # `unparsed_value` returns them exactly as they were passed in
    def get_value(field)
      mail[field] ? mail[field].unparsed_value : nil
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