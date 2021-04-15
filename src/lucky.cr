require "./turbo"

module Lucky::Turbo
  def turbo_frame(id : String)
    tag "turbo-frame", id: id do
      yield
    end
  end

  def turbo_frame(id : String, src : String)
    tag "turbo-frame", id: id, src: src do
      yield
    end
  end

  def turbo_stream_from(id : String)
    tag "turbo-cable-stream-source",
      channel: "Turbo::StreamsChannel",
      "signed-stream-name": ::Turbo::StreamsChannel.signed_stream_name({id})
  end
end
