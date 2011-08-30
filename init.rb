# encoding: utf-8
require 'redmine'
require_dependency 'campfire_notifications_hook'

Redmine::Plugin.register :campfire_notifications do
  name 'Redmine Campfire Notifications plugin'
  author 'Jack Chu'
  description 'A plugin to display issue modifications to a Campfire room'
  url 'https://github.com/kamui/redmine-campfire_notifications'
  author_url 'http://jackchu.com'
  version '0.0.9'

  requires_redmine :version_or_higher => '0.8.0'
end
