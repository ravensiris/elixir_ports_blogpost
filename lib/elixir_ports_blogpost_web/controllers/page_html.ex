defmodule ElixirPortsBlogpostWeb.PageHTML do
  use ElixirPortsBlogpostWeb, :html

  alias Blogposts.Author

  defp uppercase?(x), do: x =~ ~r/^\p{Lu}$/u

  defp author_initials(%Author{} = author) do
    author.name |> String.graphemes() |> Enum.filter(&uppercase?/1) |> Enum.join()
  end

  embed_templates "page_html/*"
end
