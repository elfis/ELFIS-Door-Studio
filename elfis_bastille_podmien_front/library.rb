# encoding: UTF-8
require 'json'
require 'securerandom'
require 'fileutils'
require File.join(__dir__,'outline.rb')
module Elfis
  module BastillePodmienFront
    def library_path
      @library_path_override || File.join(ENV.fetch('APPDATA'), 'ELFIS','DoorProfileLibrary','profiles.json')
    end

    def library
      return @library if @library
      saved=File.file?(library_path) ? JSON.parse(File.read(library_path),symbolize_names:true) : {}
      bastille=JSON.parse(File.read(File.join(__dir__,'bastille.json')),symbolize_names:true)
      bastille.merge!(id:'bastille',name:'Bastille',panel:6.0,clearance:1.0,builtin:true)
      @library={profiles:[bastille]+Array(saved[:profiles]).reject { |p| p[:id]=='bastille' },active:saved[:active]||'bastille',favorites:Array(saved[:favorites])}
      @library[:active]='bastille' unless @library[:profiles].any? { |p| p[:id]==@library[:active] }
      @library
    end

    def active_profile
      library[:profiles].find { |p| p[:id]==library[:active] } || library[:profiles].first
    end

    def persist_library
      FileUtils.mkdir_p(File.dirname(library_path))
      temporary="#{library_path}.#{SecureRandom.hex(4)}.tmp"
      File.write(temporary,JSON.pretty_generate(library))
      File.rename(temporary,library_path)
      update_profile_command
    end

    def update_profile_command
      p=active_profile
      @command.tooltip="#{p[:name]} — #{p[:width].round(1)} × #{p[:thickness].round(1)} mm: kliknij front" if @command
    end

    def select_profile(id)
      raise 'Nie znaleziono profilu.' unless library[:profiles].any? { |p| p[:id]==id }
      library[:active]=id
      persist_library
    end

    def validate_profile(p)
      [:width,:thickness,:shoulder,:panel,:clearance].each do |key|
        value=Float(p.fetch(key))
        raise 'Wpisz prawidłowe wymiary.' unless value.finite?
        p[key]=value
      end
      raise 'Nieprawidłowy przekrój.' unless p[:width]>p[:thickness] && p[:thickness]>0 && p[:shoulder]>0 && p[:shoulder]<=p[:width]
      raise 'Nieprawidłowy luz lub grubość płyciny.' unless p[:clearance]>=0 && p[:panel]>=0
      if p[:panel]>0
        g=p[:groove]
        raise 'Brak prostokątnego rowka. Ustaw płycinę na 0 mm.' unless g
        raise 'Płycina jest za gruba do rowka.' unless p[:panel]<g[:high]-g[:low]
        raise 'Luz wysuwa płycinę z rowka.' unless g[:floor]+p[:clearance]<p[:width]
      end
      p
    end

    def add_selected_profile
      raw=ProfileOutline.normalize(ProfileOutline.selected_outline(Sketchup.active_model))
      raw.merge!(id:SecureRandom.uuid,name:'Nowy profil',panel:raw[:groove] ? [6.0,(raw[:groove][:high]-raw[:groove][:low])*0.8].min : 0.0,clearance:raw[:groove] ? [1.0,(raw[:width]-raw[:groove][:floor])*0.25].min : 1.0,builtin:false)
      raw[:draft]=true
      @draft_profile=raw
      raw
    end

    def save_profile_settings(data)
      candidate=data[:id]==@draft_profile&.dig(:id) ? @draft_profile.dup : library[:profiles].find { |p| p[:id]==data[:id] }&.dup
      raise 'Nie znaleziono profilu.' unless candidate
      [:name,:shoulder,:panel,:clearance].each { |k| candidate[k]=data.fetch(k) }
      candidate[:name]=candidate[:name].to_s.strip[0,80]
      raise 'Podaj nazwę profilu.' if candidate[:name].empty?
      candidate.delete(:draft)
      validate_profile(candidate)
      # Keep the bundled Bastille immutable; edits become a custom profile.
      if candidate[:builtin]
        candidate[:id]=SecureRandom.uuid
        candidate[:builtin]=false
      end
      library[:profiles].reject! { |p| p[:id]==candidate[:id] }
      library[:profiles]<<candidate
      library[:active]=candidate[:id]
      @draft_profile=nil
      persist_library
      candidate
    end

    def create_with_dimensions(height,width)
      p=validate_profile(active_profile.dup)
      height,width=Float(height),Float(width)
      raise 'Podaj dodatnie, skończone wymiary w mm.' unless [height,width].all? { |n| n.finite? && n>0 }
      m=Sketchup.active_model
      m.start_operation('ELFIS — drzwi z biblioteki',true)
      begin
        d=build(m,p,width,height,p[:shoulder],p[:panel],p[:clearance])
        d.name="#{p[:name]} #{height.round(2)}x#{width.round(2)} mm"
        door=m.active_entities.add_instance(d,IDENTITY)
        door.name=d.name
        door.set_attribute('ElfisBastillePodmien','generated',true)
        door.set_attribute('ElfisBastillePodmien','profile_id',p[:id])
        m.selection.clear
        m.selection.add(door)
        m.commit_operation
        door
      rescue
        m.abort_operation
        raise
      end
    end

    def library_state
      {profiles:library[:profiles],active:library[:active],favorites:library[:favorites],draft:@draft_profile}
    end

    def push_library
      @library_dialog.execute_script("renderLibrary(#{JSON.generate(library_state)})") if @library_dialog
    end

    def show_library
      if @library_dialog && @library_dialog.visible?
        @library_dialog.bring_to_front
        push_library
        return
      end
      @library_dialog=UI::HtmlDialog.new(dialog_title:'ELFIS — Biblioteka profili drzwi',preferences_key:'ElfisDoorProfilePicker',width:930,height:900,min_width:740,min_height:560,resizable:true)
      @library_dialog.set_file(File.join(__dir__,'library.html'))
      @library_dialog.add_action_callback('library_action') do |_,json|
        begin
          data=JSON.parse(json,symbolize_names:true)
          case data[:action]
          when 'ready' then push_library
          when 'select' then select_profile(data[:id]); push_library
          when 'favorite'
            id=data[:id]
            raise 'Nie znaleziono profilu.' unless library[:profiles].any? { |p| p[:id]==id }
            library[:favorites].include?(id) ? library[:favorites].delete(id) : library[:favorites]<<id
            persist_library
            push_library
          when 'add' then add_selected_profile; push_library
          when 'cancel_draft' then @draft_profile=nil; push_library
          when 'save' then save_profile_settings(data); push_library
          when 'replace'
            select_profile(data[:id])
            @library_dialog.close
            activate
          when 'create'
            select_profile(data[:id])
            create_with_dimensions(data[:height],data[:width])
            @library_dialog.close
          else raise 'Nieznane polecenie.'
          end
        rescue => e
          @library_dialog.execute_script("showError(#{JSON.generate(e.message)})") if @library_dialog
        end
      end
      @library_dialog.set_on_closed { @library_dialog=nil }
      @library_dialog.center
      @library_dialog.show
    end
  end
end
