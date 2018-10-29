require 'fluent/plugin/output'

module Fluent::Plugin
    class DogstatsdOutput < Output
        Fluent::Plugin.register_output('dogstatsd', self)

        helpers :compat_parameters

        config_param :host, :string, :default => nil
        config_param :port, :integer, :default => nil
        config_param :key, :string, :default => nil
        config_param :use_tag_as_key, :bool, :default => false
        config_param :use_tag_as_key_if_missing, :bool, :default => false
        config_param :flat_tags, :bool, :default => false
        config_param :flat_tag, :bool, :default => false # obsolete
        config_param :metric_type, :string, :default => nil
        config_param :value_key, :string, :default => nil
        config_param :sample_rate, :float, :default => nil
        config_param :discard_nil, :bool, :default => false
        config_param :multi_key_value, :hash, :default => nil

        config_section :buffer do
            config_set_default :@type, "memory"
            config_set_default :flush_mode, :immediate
            config_set_default :chunk_keys, ["tag"]
        end

        unless method_defined?(:log)
            define_method(:log) { $log }
        end

        attr_accessor :statsd

        def configure(conf)
            super

            compat_parameters_convert(conf, :buffer)
            raise Fluent::ConfigError, "'tag' in chunk_keys is required." if not @chunk_key_tag
        end

        def initialize
            super
            require 'datadog/statsd' # dogstatsd-ruby
        end

        def start
            super

            host = @host || Datadog::Statsd::DEFAULT_HOST
            port = @port || Datadog::Statsd::DEFAULT_PORT
            @statsd ||= Datadog::Statsd.new(host, port)
        end

        def write(chunk)
            tag = chunk.metadata.tag
            key = @key
            if key != nil
                key = extract_placeholders(key, chunk)
            end

            @statsd.batch do |s|
                chunk.each do |time, record|

                    title = record.delete('title')
                    text  = record.delete('text')
                    type  = @metric_type || record.delete('type')
                    sample_rate = @sample_rate || record.delete('sample_rate')

                    if !key
                        key = if @use_tag_as_key
                            tag
                        else
                            record.delete('key')
                        end
                    end

                    if !key && @use_tag_as_key_if_missing
                        key = tag
                    end

                    unless key
                        if @multi_key_value != nil
                            @multi_key_value.each do |metric_key, value_key|
                                send_to_dogstatsd(s, type, metric_key, value_key, title, text, sample_rate, record)
                            end
                            next
                        else
                            log.warn "'key' and 'multi_key_value' are not specified. skip this record:", key: key, multi_key_value: @multi_key_value, tag: tag
                            next
                        end
                    end

                    send_to_dogstatsd(s, type, key, @value_key, title, text, sample_rate, record)
                end
            end
        end

        def send_to_dogstatsd(s, type, key, value_key, title, text, sample_rate, record)
            value = record.delete(value_key || 'value')

            options = {}
            discard_nil = @discard_nil

            if discard_nil == true and value.nil?
                return
            end

            if sample_rate
                options[:sample_rate] = sample_rate
            end

            tags = if @flat_tags || @flat_tag
                        record
                    else
                        record['tags']
                    end
            if tags
                options[:tags] = tags.map do |k, v|
                "#{k}:#{v}"
                end
            end

            case type
            when 'increment'
                s.increment(key, options)
            when 'decrement'
                s.decrement(key, options)
            when 'count'
                s.count(key, value, options)
            when 'gauge'
                s.gauge(key, value, options)
            when 'histogram'
                s.histogram(key, value, options)
            when 'timing'
                s.timing(key, value, options)
            when 'set'
                s.set(key, value, options)
            when 'event'
                options[:alert_type] = record['alert_type']
                s.event(title, text, options)
            when nil
                log.warn "type is not provided (You can provide type via `metric_type` in config or `type` field in a record."
            else
                log.warn "Type '#{type}' is unknown."
            end
        end
    end
end
