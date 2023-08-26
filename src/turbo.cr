require "xml"
require "http"

module Turbo
  def self.javascript_tag
    <<-HTML
      <script src="https://unpkg.com/@hotwired/turbo@7.3.0/dist/turbo.es2017-umd.js"></script>
    HTML
  end

  def self.cable_tag
    <<-HTML
      <script src="https://unpkg.com/actioncable@5.2.8-1/lib/assets/compiled/action_cable.js"></script>
      <script>
      (function() {
      let consumer

      async function getConsumer() {
        if (consumer) return consumer
        return setConsumer(ActionCable.createConsumer())
      }

      function setConsumer(newConsumer) {
        return consumer = newConsumer
      }

      async function subscribeTo(channel, mixin) {
        const { subscriptions } = await getConsumer()
        return subscriptions.create(channel, mixin)
      }

      class TurboCableStreamSourceElement extends HTMLElement {
        async connectedCallback() {
          Turbo.connectStreamSource(this)
          this.subscription = await subscribeTo(this.channel, { received: this.dispatchMessageEvent.bind(this) })
        }

        disconnectedCallback() {
          Turbo.disconnectStreamSource(this)
          if (this.subscription) this.subscription.unsubscribe()
        }

        dispatchMessageEvent(data) {
          const event = new MessageEvent("message", { data })
          return this.dispatchEvent(event)
        }

        get channel() {
          const channel = this.getAttribute("channel")
          const signed_stream_name = this.getAttribute("signed-stream-name")
          return { channel, signed_stream_name }
        }
      }

      customElements.define("turbo-cable-stream-source", TurboCableStreamSourceElement)
      })()
      </script>
    HTML
  end

  def self.stream_from(*streamables)
    String.build { |str| Frames.render_turbo_stream_from(*streamables, to: str) }
  end

  def self.response_type(context : HTTP::Server::Context)
    if turbo_stream_request? context
      context.response.headers["Content-Type"] = "text/vnd.turbo-stream.html"
    end
  end

  def self.turbo_stream_request?(context : HTTP::Server::Context) : Bool
    if context.request.headers["Turbo-Frame"]?
      true
    elsif accept = context.request.headers["Accept"]?
      accept.includes? "text/vnd.turbo-stream.html"
    else
      false
    end
  end

  struct Frame
    def self.new(id : String, src : String)
      new(id: id, src: src) {}
    end

    def initialize(@id : String, @src : String? = nil, &@body : IO ->)
    end

    def to_s(io : IO)
      Frames.render_turbo_frame id: @id, src: @src, to: io do
        @body.call io
      end
      # io << "<turbo-frame id="
      # @id.inspect io
      # if @src
      #   io << " src="
      #   @src.inspect io
      # end
      # io << '>'
      # @body.call io
      # io << "</turbo-frame>"
    end
  end

  struct Stream
    def self.new(target, action)
      new(target: target, action: action) {}
    end

    def initialize(@target : String, @action = "update", &@template : IO ->)
    end

    def to_s(io : IO)
      io << "<turbo-stream action="
      @action.inspect io
      io << " target="
      @target.inspect io
      io << "><template>"
      @template.call io
      io << "</template></turbo-stream>"
    end
  end

  module Frames
    extend self

    def render_turbo_frame(id : String, to response : IO, src : String? = nil)
      response << "<turbo-frame id="
      id.inspect response
      if src
        response << " src="
        src.inspect response
      end
      response << '>'
      yield
      response << "</turbo-frame>"
    end

    def render_turbo_frame(id : String, to response : IO, src : String)
      response << "<turbo-frame id="
      id.inspect response
      response << " src="
      src.inspect response
      response << "></turbo-frame>"
    end

    def render_turbo_stream_from(*streamables, to response : IO)
      response << %{<turbo-cable-stream-source channel="Turbo::StreamsChannel" signed-stream-name="}
      response << StreamsChannel.signed_stream_name(streamables)
      response << %{"></turbo-cable-stream-source>}
    end
  end

  class Handler
    include HTTP::Handler

    def call(context)
      request = context.request

      if (accept = request.headers["Accept"]?) && accept.includes?("turbo-stream")
        context.response.headers["Content-Type"] = "text/html; charset=utf-8"
      end

      if frame = request.headers["Turbo-Frame"]?
        response = Response.new(context.response)
        tc = HTTP::Server::Context.new(
          request: request,
          response: response,
        )
        call_next tc
        response.check_for_frame frame
      else
        call_next context
      end
    end

    class Response < HTTP::Server::Response
      def initialize(io : IO, @version = "HTTP/1.1")
        @io = IO::Memory.new
        super(@io, @version)
        @original_response = io
      end

      def check_for_frame(frame_name : String)
        @output.flush
        html = XML.parse_html(@io.rewind)
        if frame = html.xpath_node("//turbo-frame[contains(@id,#{frame_name.inspect})]")
          frame.to_xml @original_response
        else
          html.to_xml @original_response
          @original_response.flush
        end
      end

      def flush
        super
        io = @io.as(IO::Memory)
        io.rewind.to_s @original_response
        io.clear
      end
    end
  end
end
