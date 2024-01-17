defmodule ElixirPortsBlogpostWeb.PageController do
  use ElixirPortsBlogpostWeb, :controller

  def home(conn, params) do
    page = (params["page"] || "1") |> String.to_integer() |> max(1)
    dbg(page)
    blogposts = Blogposts.get_page(page)
    render(conn, :home, layout: false, blogposts: blogposts, page: page)
  end
end
