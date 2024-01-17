defmodule Blogposts.Author do
  @moduledoc false
  @enforce_keys [:name, :image_url]
  defstruct [:name, :image_url]

  @type t() :: %__MODULE__{name: String.t(), image_url: String.t()}
end
