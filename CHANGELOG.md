## 0.2.0

### Improvements:

  - relax/bump up poison/httpoison versions
  - use Application.get_env dynamically for configuration (will prevent freezing configuration during compile-time)

## 0.1.0

### Improvements:

  - deprecate :elastic_url configuration variable in favor of extended signature of Elastix functions by an elastic_url parameter – this way multiple elastic servers can be used and it it up to the user to provide the configuration mechanism (for example use a library that can change configuration during runtime and not to freeze the configuration during compile time like Mix.Config does)
  - relax HTTPoison version dependency

### Breaking Changes:

  - :elastic_url can't be configured on App configuration level anymore
