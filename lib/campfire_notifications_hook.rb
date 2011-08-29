# encoding: utf-8
require 'tinder'

class CampfireNotificationsHook < Redmine::Hook::ViewListener
  @@subdomain = nil
  @@token     = nil
  @@room      = nil

  def self.load_options
    options = YAML::load_file(File.join(Rails.root, 'config', 'campfire.yml'))
    @@subdomain = options[Rails.env]['subdomain']
    @@token = options[Rails.env]['token']
    @@room = options[Rails.env]['room']
    @@issues = options[Rails.env]['issues']
  end

  def controller_issues_new_after_save(context = { })
    issue = context[:issue]
    project = issue.project
    user = issue.author
    status = %Q{Status: #{issue.status.name}} unless issue.status.nil?
    speak %Q{#{user.name} created issue "#{issue.subject}" for #{project.name}. #{status} http://#{Setting.host_name}/issues/#{issue.id}}
    speak issue_notes(issue) if @@issues['notes']
    speak %Q{"#{truncate_words(issue.description)}"} if !issue.description.blank? && @@issues['more_info']
  end

  def controller_issues_edit_after_save(context = { })
    issue = context[:issue]
    project = issue.project
    journal = context[:journal]
    user = journal.user
    status = %Q{Status: #{issue.status.name}} unless issue.status.nil?
    speak %Q{#{user.name} edited issue "#{issue.subject}" for #{project.name}. #{status} http://#{Setting.host_name}/issues/#{issue.id}}
    speak issue_notes(issue) if @@issues['notes']
    speak %Q{#{truncate_words(journal.notes)}} if !journal.notes.blank? && @@issues['more_info']
  end

  def controller_messages_new_after_save(context = { })
    project = context[:project]
    message = context[:message]
    user = message.author
    speak %Q{#{user.name} wrote a new message "#{message.subject}" on #{project.name}: "#{truncate_words(message.content)}". http://#{Setting.host_name}/boards/#{message.board.id}/topics/#{message.root.id}#message-#{message.id}}
  end

  def controller_messages_reply_after_save(context = { })
    project = context[:project]
    message = context[:message]
    user = message.author
    speak %Q{#{user.name} replied a message "#{message.subject}" on #{project.name}: "#{truncate_words(message.content)}". http://#{Setting.host_name}/boards/#{message.board.id}/topics/#{message.root.id}#message-#{message.id}}
  end

  def controller_wiki_edit_after_save(context = { })
    project = context[:project]
    page = context[:page]
    user = page.content.author
    speak %Q{#{user.name} edited the wiki "#{page.pretty_title}" on #{project.name}. http://#{Setting.host_name}/projects/#{project.identifier}/wiki/#{page.title}}
  end

private
  def speak(message)
    CampfireNotificationsHook.load_options unless @@subdomain && @@token && @@room
    begin
      campfire = Tinder::Campfire.new @@subdomain, :token => @@token
      room = campfire.find_room_by_name(@@room)
      room.speak message
    rescue => e
      Rails.logger.error "Error during campfire notification: #{e.message}"
    end
  end

  def truncate_words(text, length = 40, end_string = '…')
    return if text == nil
    words = text.split()
    words[0..(length-1)].join(' ') + (words.length > length ? end_string : '')
  end

  def issue_notes(issue)
    version = %Q{Version: #{issue.fixed_version}} unless issue.fixed_version.nil?
    priority = %Q{Priority: #{issue.priority.name}} unless issue.priority.nil?
    assignee = %Q{Assignee: #{issue.assigned_to}} unless issue.assigned_to.nil?

    return [version, priority, assignee].compact.join(' | ')
  end
end