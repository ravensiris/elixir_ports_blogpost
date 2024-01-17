defmodule Blogposts.Tag do
  @moduledoc false
  @enforce_keys [:title]
  defstruct [:title]

  @type t() :: %__MODULE__{title: String.t()}
end
