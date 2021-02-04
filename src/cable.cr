require "turbo"
require "cable"
require "base64"
require "openssl/hmac"

module Turbo
  class StreamsChannel < ::Cable::Channel
    DEFAULT_SIGNING_KEY = "Turbo::StreamsChannel"
    class_property signing_key = DEFAULT_SIGNING_KEY
    class_property signing_algorithm = OpenSSL::Algorithm::SHA256

    # :nodoc:
    def subscribed
      if (signed = params["signed_stream_name"]?) && (name = signed.as?(String)) && (stream_name = self.class.verified_stream_name(name))
        stream_from stream_name
      end
    end

    def self.broadcast_replace_to(stream_name : String, message : String)
      broadcast_action "replace", to: stream_name, message: message
    end

    def self.broadcast_update_to(stream_name : String, message : String)
      broadcast_action "update", to: stream_name, message: message
    end

    def self.broadcast_append_to(stream_name : String, message : String)
      broadcast_action "append", to: stream_name, message: message
    end

    def self.broadcast_prepend_to(stream_name : String, message : String)
      broadcast_action "prepend", to: stream_name, message: message
    end

    def self.broadcast_remove_to(stream_name : String)
      broadcast_action "remove", to: stream_name, message: ""
    end

    def self.broadcast_action(action : String, to stream_name : String, message : String)
      broadcast_to stream_name, 
        "<turbo-stream action=#{action.inspect} target=#{stream_name.inspect}><template>#{message}</template></turbo-stream>"
    end

    def self.signed_stream_name(streamables : Enumerable(String)) : String
      encoded = Base64.strict_encode(streamables.join(':'))
      "#{encoded}--#{sign(encoded)}"
    end

    def self.verified_stream_name(name : String) : String?
      encoded, signature = name.split("--", 2)

      if sign(encoded) == signature
        Base64.decode_string(encoded)
      end
    rescue ex
      nil
    end

    private def self.sign(string : String) : String
      OpenSSL::HMAC.hexdigest(signing_algorithm, signing_key, string)
    end
  end
end
