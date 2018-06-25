# fluent-plugin-dogstatsd

(Forked) Fluend plugin for Dogstatsd, that is statsd server for Datadog.

## Installation (from original source)

    $ gem install fluent-plugin-dogstatsd


## Installation (from this fork)

```bash
    gem install specific_install
    gem specific_install https://github.com/dsouzajude/fluent-plugin-dogstatsd.git
```


## Usage

```
$ echo '{"type": "increment", "key": "apache.requests", "tags": {"url": "/"}}' | fluent-cat dogstatsd.hello
$ echo '{"type": "histogram", "key": "apache.response_time", "value": 10.5, "tags": {"url": "/hello"}}' | fluent-cat dogstatsd.hello
$ echo '{"type": "event", "title": "Deploy", "text": "New revision"}' | fluent-cat dogstatsd.hello
```

Supported types are `increment`, `decrement`, `count`, `gauge`, `histogram`, `timing`, `set` and `event`.

## Configuration

```
<match dogstatsd.*>
  type dogstatsd

  # Dogstatsd host
  host localhost

  # Dogstatsd port
  port 8125

  # Use tag of fluentd record as key sent to Dogstatsd
  use_tag_as_key false

  # Optionally use a fixed key name for the metric name
  key haproxy.services.api.num_requests

  # Optionally use dynamic key that's implemented via `Fluent::Plugin::Output#extract_placeholders`
  # key haproxy.services.${service}.num_requests

  # (Treat fields in a record as tags)
  # flat_tags true

  # (Metric type in Datadog.)
  # metric_type increment

  # Default: "value"
  # value_key Value
</match>
```

## Example

### Count log lines

```apache
<source>
  type tail
  path /tmp/sample.log
  tag datadog.increment.sample
  format ...
</source>

<match datadog.increment.*>
  type dogstatsd
  metric_type increment
  flat_tags true
  use_tag_as_key true
</match>
```

### Histogram

```apache
<source>
  type tail
  path /tmp/sample.log
  tag datadog.histogram.sample
  format /^(?<value>[^ ]*) (?<host>[^ ]*)$/
</source>

<match datadog.histogram.*>
  type dogstatsd
  metric_type histogram
  flat_tags true
  use_tag_as_key true
</match>
```

```haproxy
<source>
  type tail
  path /var/log/haproxy.requests.log
  pos_file /var/log/haproxy-requests.log.pos
  tag haproxy.requests
  format json
</source>

<match haproxy.requests>
  type dogstatsd
  metric_type histogram
  key haproxy.services.${service}.response_time
  value_key response_time
  <buffer ["tag", "service"]>
  </buffer>
</match>
```

```haproxy
<source>
  type tail
  path /var/log/haproxy.requests.log
  pos_file /var/log/haproxy-requests.log.pos
  tag haproxy.requests
  format json
</source>

<match haproxy.requests>
  type dogstatsd
  metric_type histogram
  key haproxy.overall.response_time
  value_key response_time
  <buffer ["tag"]>
  </buffer>
</match>
```

### MySQL threads

```apache
<source>
  type mysql_query
  tag datadog.histogram.mysql_threads
  query SHOW VARIABLES LIKE 'Thread_%'
</source>

<match datadog.histogram.mysql_threads>
  type dogstatsd
  metric_type histogram
  value_key Value
  flat_tags true
  use_tag_as_key true
</match>
```

## Contributing

1. Fork it ( https://github.com/ryotarai/fluent-plugin-dogstatsd/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
