## 0.8.0

### Breaking changes

 - Drop support for Elixir <1.6
 
### Improvements

 - Add support for custom httpoison options in snapshot delete function

## 0.7.1

### Package improvements

 - Improve package description

## 0.7.0

### Improvements

 - Add support for custom httpoison options on bulk calls
 - Support HTTPoison 1.4

## 0.6.0

### Improvements

  - Add a JSON wrapper module allowing to use any JSON codec library
  - Add functions to handle snapshots
  - Add `open` and `close` to the Index module
  - Improve documentation and add specs to public functions
  - Allow to use the `_msearch` endpoint via `Elastix.Search.search`.
  - Deprecate `Elastix.Bulk.post_to_iolist/4` as `Elastix.Bulk.post` does mostly the same thing
  - Add `count` to the Search module
  - Allow trailing slashes in URL

## 0.5.0

### Improvements

  - fix Hackney options when searching
  - add support for custom headers
  - use regular strings for headers
  - add delete by query functionality
  - add multi-get functionality
  - remove double backslash from Document.make_path
  - add basic scrolling api

## 0.4.0

### Improvements

  - Allow options in Search API calls
  - don't strip return atoms
  - add update api support

### Breaking Changes

  - don't strip return atoms

## 0.3.0

### Improvements
  - add support for mappings
  - add support for bulk requests
  - bump up library versions (credo, httpoison, mix_test_watch)

## 0.2.0

### Improvements:

  - add support for index_new
  - add support for poison options
  - add support for index refresh
  - add shield support

## 0.1.1

### Improvements:

  - relax/bump up poison/httpoison versions
  - use Application.get_env dynamically for configuration (will prevent Elastix from freezing configuration during compile-time)
  - make code credo-conform

## 0.1.0

### Improvements:

  - deprecate :elastic_url configuration variable in favor of extended signature of Elastix functions by an elastic_url parameter – this way multiple elastic servers can be used and it it up to the user to provide the configuration mechanism (for example use a library that can change configuration during runtime and not to freeze the configuration during compile time like Mix.Config does)
  - relax HTTPoison version dependency

### Breaking Changes:

  - :elastic_url can't be configured on App configuration level anymore
