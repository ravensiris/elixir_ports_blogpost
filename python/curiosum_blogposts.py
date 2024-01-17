import pickle
import re
from dataclasses import dataclass, field
from datetime import date, datetime, timedelta

from bs4 import BeautifulSoup
from bs4.element import Tag as BS4Tag
from requests import get


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


def blogpost_url(page: int = 1) -> str:
    return f"https://curiosum.com/blog/category/all/page/{page}"


def process_tag(tag_dom: BS4Tag) -> Tag:
    return Tag(title=tag_dom.text.strip())


def process_author(footer_dom: BS4Tag) -> Author:
    author_image_dom = footer_dom.select_one(".blog-card__author-image")
    author_image_url = author_image_dom.attrs.get("src")

    author_name_dom = footer_dom.select_one(".blog-card__author-name")
    author_name = author_name_dom.text.strip()

    return Author(name=author_name, image_url=author_image_url)


def process_read_time(footer_dom: BS4Tag) -> timedelta:
    read_time_dom = footer_dom.select_one(".blog-card__detail--reading")
    read_time = read_time_dom.text.strip()
    minutes_match = re.search("^[0-9]+", read_time)
    minutes = 0
    if minutes_match is not None:
        minutes = int(minutes_match.group())

    return timedelta(minutes=minutes)


def process_posted_at(footer_dom: BS4Tag) -> date:
    posted_at_dom = footer_dom.select_one(".blog-card__detail--date")
    posted_at_str = posted_at_dom.text.strip()
    return datetime.strptime(posted_at_str, "%d %b %Y").date()


def process_article(article: BS4Tag) -> Article:
    title_dom = article.select_one(".blog-card__title")
    title = title_dom.text.strip()

    tags_dom = article.select(".blog-card__category-link")
    tags = list(map(process_tag, tags_dom))

    teaser_dom = article.select_one(".blog-card__teaser")
    teaser = teaser_dom.text.strip()

    footer_dom = article.select_one(".blog-card__footer")

    author = process_author(footer_dom)

    read_time = process_read_time(footer_dom)

    posted_at = process_posted_at(footer_dom)

    return Article(
        title=title,
        tags=tags,
        teaser=teaser,
        author=author,
        read_time=read_time,
        posted_at=posted_at,
    )


def get_blog_page(page: int = 1) -> list[Article]:
    resp = get(blogpost_url(page))
    dom = BeautifulSoup(resp.text, "lxml")
    articles_dom = dom.select("article.blog-card")
    articles = list(map(process_article, articles_dom))
    return pickle.dumps(articles)
