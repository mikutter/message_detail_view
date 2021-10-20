# -*- coding: utf-8 -*-

module Plugin::MessageDetailView
  # ヘッダ部分のユーザ情報。
  # コンストラクタにはUserではなくMessageなど、userを保持しているDivaを渡すことに注意。
  # このウィジェットによって表示されるタイムスタンプをクリックすると、
  # コンストラクタに渡されたModelのperma_linkを開くようになっている。
  class TweetHearderWidget < Gtk::EventBox
    extend Memoist

    def initialize(model, *args, intent_token: nil)
      type_strict model => Diva::Model
      super(*args)
      ssc_atonce(:visibility_notify_event, &widget_style_setter)
      add(Gtk::Box.new(:vertical, 0).
           pack_start(Gtk::Box.new(:horizontal, 0).
                     pack_start(icon(model.user).set_valign(:start), expand: false).
                     pack_start(Gtk::Box.new(:vertical, 0).
                              pack_start(idname(model.user).set_halign(:start), expand: false).
                              pack_start(Gtk::Label.new(model.user[:name]).set_halign(:start), expand: false), expand: false).
           pack_start(post_date(model, intent_token).set_halign(:end)), expand: false))
    end

    private

    def background_color
      style = Gtk::Style.new()
      style.set_bg(Gtk::STATE_NORMAL, 0xFFFF, 0xFFFF, 0xFFFF)
      style end

    def icon(user)
      icon_alignment = Gtk::Alignment.new(0.5, 0, 0, 0)
                       .set_padding(*[UserConfig[:profile_icon_margin]]*4)

      icon = Gtk::EventBox.new.
             add(icon_alignment.add(Gtk::WebIcon.new(user.icon_large, UserConfig[:profile_icon_size], UserConfig[:profile_icon_size])))
      icon.ssc(:button_press_event, &icon_opener(user.icon_large))
      icon.ssc_atonce(:realize, &cursor_changer(Gdk::Cursor.new(:hand2)))
      icon.ssc_atonce(:visibility_notify_event, &widget_style_setter)
      icon end

    def idname(user)
      label = Gtk::EventBox.new.
              add(Gtk::Label.new.
                   set_markup("<b><u><span foreground=\"#0000ff\">#{Pango.escape(user.idname)}</span></u></b>"))
      label.ssc(:button_press_event, &profile_opener(user))
      label.ssc_atonce(:realize, &cursor_changer(Gdk::Cursor.new(:hand2)))
      label.ssc_atonce(:visibility_notify_event, &widget_style_setter)
      label end

    def post_date(model, intent_token)
      label = Gtk::EventBox.new.
                add(Gtk::Label.new(model.created.strftime('%Y/%m/%d %H:%M:%S')))
      label.ssc(:button_press_event, &(intent_token ? intent_forwarder(intent_token) : message_opener(model)))
      label.ssc_atonce(:realize, &cursor_changer(Gdk::Cursor.new(:hand2)))
      label.ssc_atonce(:visibility_notify_event, &widget_style_setter)
      label end

    def icon_opener(url)
      proc do
        Plugin.call(:open, url)
        true end end

    def profile_opener(user)
      type_strict user => Diva::Model
      proc do
        Plugin.call(:open, user)
        true end end

    def intent_forwarder(token)
      proc do
        token.forward
        true
      end
    end

    def message_opener(token)
      proc do
        Plugin.call(:open, token)
        true
      end
    end

    memoize def cursor_changer(cursor)
      proc do |w|
        w.window.cursor = cursor
        false end end

    memoize def widget_style_setter
      ->(widget, *_rest) do
        widget.style = background_color
        false end end

  end
end
