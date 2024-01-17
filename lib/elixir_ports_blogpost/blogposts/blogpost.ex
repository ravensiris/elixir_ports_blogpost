defmodule Blogposts.Blogpost do
  @moduledoc false
  alias Blogposts.Author
  alias Blogposts.Tag

  @enforce_keys [:title, :tags, :teaser, :author, :read_time, :posted_at]
  defstruct [:title, :tags, :teaser, :author, :read_time, :posted_at]

  @type t() :: %__MODULE__{
          title: String.t(),
          tags: [Tag.t()],
          teaser: String.t(),
          author: Author.t(),
          read_time: Timex.Duration.t(),
          posted_at: Date.t()
        }
end
