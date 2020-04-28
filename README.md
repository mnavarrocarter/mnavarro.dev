Personal Blog
=============

This is the source code of my blog. You can check it out and use it for your own benefit. Just keep in mind the licensing constraints.

## License
Everything in the codebase is MIT licensed, **except for what it lives in the `/content` folder** and the product generated out of it via automated tools.

The content of the blog is under [CC BY-SA 4.0][cc-by-sa].

Please stick to the usage allowed by the licenses.

## Structure
The files in this repository are processed by a program called Hugo, an static site generation written in Go. This program takes this markdown, css, js and layouts and transforms it into an static html website that is extremely performant.

The CSS is built by myself from the ground up, but inspired in [Wordpress' Monostack theme][monostack-theme].

There are still some features I would love to implement. If you know a bit about how Hugo works and a bit of Go, then maybe you can help me.

## TODO:
- [ ] Add social networks
- [ ] Improve SEO tags
- [ ] Create Giphy shortcode
- [ ] Support i18n
- [ ] Social share support
- [ ] External urls link
- [ ] Improve `/categories` and `/tags` pages

## Run the blog locally
Clone it with git and then boot up a dev environment with `docker-compose`:

```bash
docker-compose up -d
```

You can check the logs with:

```bash
docker-compose logs -t
```

[cc-by-sa]: https://creativecommons.org/licenses/by-sa/4.0/
[monostack-theme]: https://wordpress.org/themes/monostack/