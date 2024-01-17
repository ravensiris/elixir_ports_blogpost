defmodule Blogposts do
  @moduledoc false
  alias Blogposts.Author
  alias Blogposts.Blogpost
  alias Blogposts.Tag

  defp object_resolver(%Unpickler.Object{constructor: "datetime.timedelta"} = obj) do
    [days, sec, _usec] = obj.args
    sec = days * 86_400 + sec
    {:ok, Timex.Duration.from_seconds(sec)}
  end

  defp object_resolver(%Unpickler.Object{constructor: "curiosum_blogposts.Author.__new__"} = obj) do
    %{"name" => name, "image_url" => image_url} = obj.state
    {:ok, %Author{name: name, image_url: image_url}}
  end

  defp object_resolver(%Unpickler.Object{constructor: "datetime.date"} = obj) do
    [<<year_hi, year_lo, month, day>>] = obj.args
    Date.new(year_hi * 256 + year_lo, month, day)
  end

  defp object_resolver(%Unpickler.Object{constructor: "curiosum_blogposts.Tag.__new__"} = obj) do
    %{"title" => title} = obj.state
    {:ok, %Tag{title: title}}
  end

  defp object_resolver(%Unpickler.Object{constructor: "curiosum_blogposts.Article.__new__"} = obj) do
    %{
      "author" => author,
      "posted_at" => posted_at,
      "read_time" => read_time,
      "tags" => tags,
      "teaser" => teaser,
      "title" => title
    } = obj.state

    {:ok, %Blogpost{author: author, posted_at: posted_at, read_time: read_time, tags: tags, teaser: teaser, title: title}}
  end

  defp object_resolver(other), do: {:ok, other}

  @spec get_page(page :: non_neg_integer()) :: Blogpost.t()
  def get_page(page \\ 1) do
    py_project_path = Path.join(File.cwd!(), "python")
    {:ok, python} = :python.start(python_path: String.to_charlist(py_project_path))

    {blogs, ""} =
      python
      |> :python.call(:curiosum_blogposts, :get_blog_page, [page])
      |> Unpickler.load!(object_resolver: &object_resolver/1)

    :python.stop(python)

    blogs
  end
end
