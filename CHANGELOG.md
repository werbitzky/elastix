# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## 0.10.1 - 2024-07-26

- Update all dependencies to remove warnings
- Update to the latest elixir version.

## 0.10.0 - 2021-05-20

- Documentation changes
- Add support to the Get index alias API.

## 0.9.0 - 2021-03-20

- Add ability to pass httpoison options to get, status and restore snapshot functions

## 0.8.0 - 2020-03-10

### Breaking changes

- Drop support for Elixir <1.6

### Improvements

- Add support for custom httpoison options in snapshot delete function

## 0.7.1 - 2018-11-19

### Package improvements

- Improve package description

## 0.7.0 - 2018-11-16

### Improvements

- Add support for custom httpoison options on bulk calls
- Support HTTPoison 1.4

## 0.6.0 - 2018-04-27

### Improvements

- Add a JSON wrapper module allowing to use any JSON codec library
- Add functions to handle snapshots
- Add `open` and `close` to the Index module
- Improve documentation and add specs to public functions
- Allow to use the `_msearch` endpoint via `Elastix.Search.search`.
- Deprecate `Elastix.Bulk.post_to_iolist/4` as `Elastix.Bulk.post` does mostly the same thing
- Add `count` to the Search module
- Allow trailing slashes in URL

## 0.5.0 - 2017-10-04

### Improvements

- fix Hackney options when searching
- add support for custom headers
- use regular strings for headers
- add delete by query functionality
- add multi-get functionality
- remove double backslash from Document.make_path
- add basic scrolling api

## 0.4.0 - 2017-04-04

### Improvements

- Allow options in Search API calls
- don't strip return atoms
- add update api support

### Breaking Changes

- don't strip return atoms

## 0.3.0 - 2017-02-28

### Improvements

- add support for mappings
- add support for bulk requests
- bump up library versions (credo, httpoison, mix_test_watch)

## 0.2.0 - 2016-05-20

### Improvements:

- add support for index_new
- add support for poison options
- add support for index refresh
- add shield support

## 0.1.1 - 2016-04-06

### Improvements:

- relax/bump up poison/httpoison versions
- use Application.get_env dynamically for configuration (will prevent Elastix from freezing configuration during compile-time)
- make code credo-conform

## 0.1.0 - 2015-11-12

### Improvements:

- deprecate :elastic_url configuration variable in favor of extended signature of Elastix functions by an elastic_url parameter – this way multiple elastic servers can be used and it it up to the user to provide the configuration mechanism (for example use a library that can change configuration during runtime and not to freeze the configuration during compile time like Mix.Config does)
- relax HTTPoison version dependency

### Breaking Changes:

- :elastic_url can't be configured on App configuration level anymore
