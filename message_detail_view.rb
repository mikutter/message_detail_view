# -*- coding: utf-8 -*-

require_relative 'tweet_header_widget'

Plugin.create(:message_detail_view) do
  intent :twitter_tweet, label: _('ツイートの詳細') do |intent_token|
    show_message(intent_token.model, intent_token)
  end

  command(:message_detail_view_show,
          name: _('詳細'),
          condition: lambda{ |opt| opt.messages.size == 1 && opt.messages.first.is_a?(Message) },
          visible: true,
          role: :timeline) do |opt|
    Plugin.call(:open, opt.messages.first)
  end

  # 互換性のため。
  # openイベントを使おう
  on_show_message do |message|
    Plugin.call(:open, message)
  end

  def show_message(message, token, force=false)
    slug = "message_detail_view-#{message.uri}".to_sym
    if !force and Plugin::GUI::Tab.exist?(slug)
      Plugin::GUI::Tab.instance(slug).active!
    else
      container = Plugin::MessageDetailView::TweetHearderWidget.new(message, intent_token: token)
      i_cluster = tab slug, _("詳細タブ") do
        set_icon Skin[:message]
        set_deletable true
        temporary_tab
        shrink
        nativewidget container
        expand
        cluster nil end
      Thread.new {
        Plugin.filtering(:message_detail_view_fragments, [], i_cluster, message).first
      }.next { |tabs|
        tabs.map(&:last).each(&:call)
      }.next {
        if !force
          i_cluster.active! end
      }.trap{ |exc|
        error exc
      }
    end
  end

  message_fragment :body, "body" do
    set_icon Skin[:message]
    container = Gtk::EventBox.new
    textview = Gtk::IntelligentTextview.new(model.description, { 'font' => :twitter_tweet_basic_font })
    textview.style_generator = get_style_provider
    textview.bg_modifier
    scrolledwindow = Gtk::ScrolledWindow.new
    scrolledwindow.set_policy(:automatic, :automatic)
    scrolledwindow.add(textview)
    container.add(scrolledwindow)
    nativewidget container
  end

  def get_style_provider
    fgcolor = UserConfig[:twitter_tweet_basic_color]
    bgcolor = UserConfig[:twitter_tweet_basic_bg]
    Gtk::CssProvider.new.tap do |provider|
      provider.load_from_data(<<~CSS)
        *, *:active, *:disabled, *:hover, *:focus {
          color: rgb(#{fgcolor[0] / 256}, #{fgcolor[1] / 256}, #{fgcolor[2] / 256});
          background-color: rgb(#{bgcolor[0] / 256}, #{bgcolor[1] / 256}, #{bgcolor[2] / 256});
        }
      CSS
    end
  end

end
