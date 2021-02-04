# turbo

This shard provides the server-side Turbo component of [Hotwire](https://hotwire.dev)

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     turbo:
       github: jgaskins/turbo
   ```

2. Run `shards install`

## Usage

There are several components to choose from:

- `turbo.js`: the client-side JavaScript bindings to tell the browser how to interpret the server-side functionality
- `Turbo`: Basic server-side bindings for rendering Turbo frames and streams
- `Cable`: ActionCable-compliant server-side library for propagating Turbo frames and streams to browser clients

| Feature | turbo.js | Turbo | Cable |
|-|-|-|-|
| Basic Turbo Frames | Necessary | Helpful | Unnecessary |
| 

```crystal
require "turbo"
```

### Load client-side JavaScript

Turbo's client-side JavaScript is what tells the browser how to interpret what we're rendering on the server side. If you have a JavaScript build tool, it's as simple as:

```javascript
import * as Turbo from "@hotwired/turbo"
```

If not, you can simply load it with a `<script>` tag:

```html
<script src="https://unpkg.com/@hotwired/turbo"></script>
```

### Rendering Turbo Frames into HTML

Turbo Frames are the basic building block of a Turbo-enhanced UI.

#### Rendering to a raw response

The `Turbo::Frames.render_turbo_frame` helper allows you to render to a basic `IO` object (such as an [`HTTP::Server::Response`](https://crystal-lang.org/api/0.35.1/HTTP/Server/Response.html))

#### With the Lucky framework

Write a Lucky component and include `Lucky::Turbo` into it:

```crystal
class LastRenderedAt < BaseComponent
  def render
    span "Last rendered at #{time}"
  end
end
```

Then from inside your `Page`, mount the component within a `turbo_frame`:

```crystal
require "turbo/lucky"

class Home::IndexPage < MainLayout
  include Lucky::Turbo

  def content
    div do
      turbo_frame "stuff" { mount LastRenderedAt }
    end
  end
end
```

## Contributing

1. Fork it (<https://github.com/jgaskins/turbo/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Jamie Gaskins](https://github.com/jgaskins) - creator and maintainer
