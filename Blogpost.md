# Borrowing libs and skills from Python in Elixir

Everyone learning a new programming language has probably been there.
There's a missing piece in the new programming language, probably a library.

You search for alternatives:

- Library A (last commit 7 years ago)
- Library B (one commit in the repository)
- Library C (paywalled, can be only accessed by paying bitcoin)
- Library D (GPLv3, can't use it commercially)
- Library E (requires a PhD in that library to write a hello world)

Or maybe you can't find anything that would fill the void.
Or maybe the new library is much more complex and you wish to use the abstractions
from your old one.

One thing that comes to mind is just to start developing your own.
But not everyone has the time or can commit into what essentially would be a
rewrite of an already existing library in another programming language.

If that's you, there's no need to lose hope.
You can:

- create a [REST](https://en.wikipedia.org/wiki/Application_binary_interface)/[GQL](https://en.wikipedia.org/wiki/Application_binary_interface) API using the language and library of your choice and connect to your project(takes a lot of time)
- create an [ABI](https://en.wikipedia.org/wiki/Application_binary_interface) and connect your programs through that(not applicable to interpreted languages like Python)
- communitate through stdin/stdout

In this article we'll focus on the last option.

# What's a 'Port' in Elixir/Erlang

Here's an excerpt from [Erlang docs](https://www.erlang.org/doc/reference_manual/ports):

> Ports provide the basic mechanism for communication with the external world, from Erlang's point of view.  
> They provide a byte-oriented interface to an external program.  
> When a port has been created, Erlang can communicate with it by sending and receiving lists of bytes, including binaries.

Here's more info from the [Erlang tutorial](https://www.erlang.org/doc/tutorial/c_port)(example with a C program):

> The Erlang process that creates a port is said to be the connected process of the port.  
> All communication to and from the port must go through the connected process.  
> If the connected process terminates, the port also terminates (and the external program, if it is written properly).

In essence as a developer what you'll need to do is communicate through stdin/stdout:

> On the C side, it is necessary to write functions for receiving and sending data with 2 byte length indicators from/to Erlang.  
> By default, the C program is to read from standard input (file descriptor 0) and write to standard output (file descriptor 1).

# Erlport to the rescue

Implementing this could be another headache that could push you back from working on your project.

Fret not! Someone already did all the grunt work.

From the [ErlPort's home page](http://erlport.org/):

> ErlPort is a library for Erlang which helps connect Erlang to a number of other programming languages.  
> Currently supported external languages are Python and Ruby.  
> The library uses Erlang port protocol to simplify connection between languages and Erlang external term format to set the common data types mapping.

Essentially ErlPort is a library not only for Elixir but also for the respective supported languages(Python and Ruby).
This way you get to easily represent things like `atoms` in the connected language.

# Example project

I think the best way to try it out is through an example project.

Here I'll demonstrate the power of `ErlPort` by showing an example of a web scraper for our [blogposts](https://curiosum.com/blog) in Python and
connecting to it with a Phoenix app.

Here's the [completed project](https://github.com/ravensiris/elixir_ports_blogpost).

# The scraper

Scraper's source can be found [here](https://github.com/ravensiris/elixir_ports_blogpost/blob/master/python/curiosum_blogposts.py).

I'll skip over the implementation of the scraper and focus on the glue.

Here's how we store an [article](https://github.com/ravensiris/elixir_ports_blogpost/blob/master/python/curiosum_blogposts.py#L23) in our Python code:

```python
@dataclass
class Author:
    name: str
    image_url: str


@dataclass
class Tag:
    title: str


@dataclass
class Article:
    title: str
    tags: list[Tag] = field(default_factory=lambda: [])
    teaser: str = ""
    author: Author = field(default_factory=lambda: Author("John Doe", ""))
    read_time: timedelta = timedelta(seconds=0)
    posted_at: date = date(year=2024, month=1, day=1)

```

And here's the function we'll be interested in calling from our Elixir code:

```python
def get_blog_page(page: int = 1) -> list[Article]:
    resp = get(blogpost_url(page))
    dom = BeautifulSoup(resp.text, "lxml")
    articles_dom = dom.select("article.blog-card")
    articles = list(map(process_article, articles_dom))
    return pickle.dumps(articles)
```

The interesting part here would be `pickle.dumps(articles)`.
Pickles a way of serializing Python objects(just like JSON, but python specific).
ErlPort thankfully supports pickled objects, but you will need to deserialize them later(we'll get to that).

So why the pickle? There's where we take a look at the [data types mapping table](http://erlport.org/docs/python.html#data-types-mapping) in ErlPort's docs.
There's no Erlang type that would represent an instance of our `Article` class.
Our article class would show up as a list of "Opaque Python data type container" which would be represented by a `binary` type.
Which would be non trivial to convert back to an Elixir struct.
Much easier way is to just serialize and then deserialize this type of data.
You could use JSON or pickle which is actually easier to implement on both sides.

# The Elixir context

Here's are the relevant libraries that we'll be using in this project(the ones added by default with `mix phx.new` are omitted)

```elixir
  defp deps do
    [
      # ...
      {:erlport, "~> 0.11.0"},
      {:unpickler, "~> 0.1.0"},
      {:timex, "~> 3.7"}
    ]
  end
```

Elixir part of the project can be found [here](https://github.com/ravensiris/elixir_ports_blogpost/blob/master/lib/elixir_ports_blogpost/blogposts.ex#L44)

I'll explain each line of the `get_page/1` function:

```elixir
py_project_path = Path.join(File.cwd!(), "python")
```

Here we get the path of the `python/` directory in the root of our project. This is important for the next step to find our Python module.

```elixir
{:ok, python} = :python.start(python_path: String.to_charlist(py_project_path))
```

Here we start the Python interpreter process and assign the [PID](https://www.erlang.org/doc/reference_manual/data_types#pid) to `python` variable. `:python.start/1` doesn't support binary strings and thus you have to convert your python path to a charlist.

```elixir
    {blogs, ""} =
      python
      |> :python.call(:curiosum_blogposts, :get_blog_page, [page])
      |> Unpickler.load!(object_resolver: &object_resolver/1)
```

Here's where the actual call to our `get_blog_page` Python function happens.

`:curiosum_blogposts` is the python module name, which coincides with the `curiosum_blogposts.py` filename.

`:get_blog_page` is the function name.

The last argument is a list of positional arguments to be passed to the function.

Interesting part on the last line is:

```elixir
      |> Unpickler.load!(object_resolver: &object_resolver/1)
```

where we pass the result to the [unpickler](https://hex.pm/packages/unpickler) library's `load/2` function.

Normally the library would return a list of nested [Unpickler.Object](https://hexdocs.pm/unpickler/Unpickler.Object.html).
Here we make use of the `:object_resolver` option, which takes a function that converts a `Unpickler.Object` into whatever we want.

Here's an example for `datetime.date` object:

```elixir
  defp object_resolver(%Unpickler.Object{constructor: "datetime.date"} = obj) do
    [<<year_hi, year_lo, month, day>>] = obj.args
    Date.new(year_hi * 256 + year_lo, month, day)
  end
```

As you can see sometimes for values that dont fit in a `char` size(byte) the value gets split into 2 or more chars and needs to be converted.

# To finish it up

I generated a cool UI using [Vercel's V0](https://v0.dev/) generative UI AI tool.

![Screenshot](screenshot.png)

I hope you have some fun and save some time by utilizing libraries you love.

See ya!
