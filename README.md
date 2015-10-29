[![Build Status](https://travis-ci.org/leoniv/ass_updater.png)]
[![Inline docs](http://inch-ci.org/github/leoniv/ass_updater.png)](http://inch-ci.org/github/leoniv/ass_updater)
[![Code Climate](https://codeclimate.com/github/leoniv/ass_updater/badges/gpa.png)](https://codeclimate.com/github/leoniv/ass_updater)

# AssUpdater

This gem make easy monitoring of release and to get 1C configuration's updates
from service http://dounloads.v8.1c.ru.
For read more about 1C configurations see http://v8.1c.ru

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'ass_updater'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install ass_updater

## Usage

### Monitoring release configuration's update

Write your script `update_monitor.rb` like this:

```ruby
require 'ass_updater'

CONFIGS_ON_SUPPORT = ['HRM 3.0',
                      'Accounting 3.0',
                      'Accounting 2.0',
                      'AccountingKz 2.0'
                     ]
def tmplt_root
# Default path for windows:
  File.join ENV['APPDATA'].gsub('\\', '/'), '1c', '1cv8', 'tmplts'
# Or you can set other value
end

def secrets(conf_code_name)
  case conf_code_name
  when 'AccountingKz' then ['user_kz', 'pass_kz']
  else ['user','pass']
  end
end

def new_updates(updater)
  updater.update_history.all_versions.map do |v|
    max = updater.instaled_versions(tmplt_root).max ||\
          AssUpdater::AssVersion.zerro_version
    v if v > max
  end.compact
end

def send_mail(subject, message, attachments=nil)
  #FIXME puts your code
  puts "#{subject} #{message} #{attachments}"
end

def success_report(distrib)
  subject = '1C update monitor report'
  message = "Reseived update for '#{distrib.ass_updater.conf_code_name}' "\
    "version: #{distrib.version}"
  attachments = distrib.file_list.map do |file|
    file if file =~ /(.*readme.*|.*новое.*\.htm)/i
  end.compact
  [subject,message,attachments]
end

def error_report(e)
  subject = '1C update monitor report'
  message = "Error: #{e.to_s}"
  [subject, message]
end

CONFIGS_ON_SUPPORT.each do |i|
  conf_code_name, conf_redaction = *i.split(' ')
  updater = AssUpdater.new(conf_code_name,conf_redaction)
  begin
    updater.get_updates(*secrets(conf_code_name),
                        new_updates(updater),
                        tmplt_root) do |distrib|
      send_mail *success_report(distrib)
    end
  rescue Exception => e
    send_mail *error_report(e)
  end
end
```

and put string into `crontab`:

    0 */6 * * * ruby your_path/update_monitor.rb

### Get required upadates

If you whant get all updates for your 1C infobase from current version to last release:

```ruby
require 'ass_updater'

updater = AssUpdater.new 'HRM', '3.0'

updater.get_updates('user',
                    'password',
                    updater.required_versions_for_update(@curen_version),
                    @tmplt_root) do |disrib|
  puts "Reseived update #{disrib.version}"
end
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/leoniv/ass_updater.

