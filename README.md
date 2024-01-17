# ElixirPortsBlogpost

To setup the python env:

- Run `cd python && python -m venv venv && source venv/bin/activate && pip install -r requirements.txt && cd ..`
- Always source the `venv` before running the Phoenix server

To start your Phoenix server:

- Run `mix setup` to install and setup dependencies
- Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.
