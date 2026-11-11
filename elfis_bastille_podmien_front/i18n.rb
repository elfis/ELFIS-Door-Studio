# encoding: UTF-8
require 'json'
module Elfis
  module BastillePodmienFront
    extend self
    remove_const(:VERSION) if const_defined?(:VERSION,false) && const_get(:VERSION)!='2.9.3'
    VERSION='2.9.3' unless const_defined?(:VERSION,false)

    def language
      return @language if @language
      saved=Sketchup.read_default('ELFIS Door Profile Library','language','en')
      @language=%w[en pl].include?(saved) ? saved : 'en'
    end

    # Two explicit strings keep interpolated user data out of translation.
    def l(polish,english)
      language=='pl' ? polish : english
    end

    def ui_label(value)
      return value if language=='pl'
      @english_labels ||= JSON.parse(File.read(File.join(__dir__,'translations.en.json')))
      @english_labels.fetch(value,value)
    end

    def localized_html(name)
      File.join(__dir__,"#{name}#{language=='en' ? '.en' : ''}.html")
    end

    def change_language(value,origin)
      raise ArgumentError,'Unsupported language' unless %w[en pl].include?(value)
      Sketchup.write_default('ELFIS Door Profile Library','language',value)
      @language=value
      update_language_commands
      # Reopen only this window. Other open windows retain their unsaved inputs
      # and use the new language when next opened.
      if origin==:library
        @library_dialog.close if @library_dialog
        show_library
      else
        @order_dialog.close if @order_dialog
        show_order_list
      end
    end

    def update_language_commands
      if @command
        @command.menu_text=l('ELFIS — Zamień kliknięty front','ELFIS — Replace Clicked Front')
        @command.status_bar_text=l('Odczytuje wymiary frontu i podmienia wskazaną instancję aktywnym profilem.','Read front dimensions and replace the clicked occurrence using the active profile.')
        update_profile_command
      end
      if @library_command
        @library_command.menu_text=l('ELFIS — Biblioteka profili drzwi','ELFIS — Door Profile Library')
        @library_command.tooltip=l('Wybierz profil, dodaj przekrój lub utwórz drzwi','Choose a profile, add a cross-section or create a door')
      end
      if @order_command
        @order_command.menu_text=l('ELFIS — Lista frontów do zamówienia','ELFIS — Door Order List')
        @order_command.tooltip=l('Lista frontów: wymiary, rodzaj, ilość i kolor','Order list: dimensions, type, quantity and colour')
        @order_command.status_bar_text=l('Otwórz i odśwież zestawienie frontów z projektu. Kopiowanie tabeli do schowka.','Open and refresh the project order list. Copy the table to the clipboard.')
      end
      @rename_command.menu_text=l('Zmień nazwy drzwi','Rename doors') if @rename_command
      @keep_names_command.menu_text=l('Pozostaw nazwy drzwi','Keep original door names') if @keep_names_command
    end

    def install_public_help
      return if @help_command
      @help_command=UI::Command.new('ELFIS — Documentation / Dokumentacja') { show_public_help }
      UI.menu('Extensions').add_item(@help_command)
    end

    def show_public_help
      @help_dialog.close if @help_dialog
      dialog=UI::HtmlDialog.new(dialog_title:'ELFIS — Documentation',preferences_key:'ElfisDoorHelp',width:1000,height:800,resizable:true)
      @help_dialog=dialog
      dialog.set_file(File.join(__dir__,'docs',language=='pl' ? 'guide.pl.html' : 'guide.en.html'))
      dialog.set_on_closed { @help_dialog=nil if @help_dialog.equal?(dialog) }
      dialog.show
    end
  end
end
