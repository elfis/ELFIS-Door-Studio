# encoding: UTF-8
require 'json'
require 'base64'
module Elfis
  module ToolbarLayout
    extend self
    PREF='ELFIS Toolbar Layout' unless const_defined?(:PREF)
    CATALOG={
      doors:[
        ['front','Kliknij front','Click Front','podmien.svg'],
        ['profiles','Biblioteka profili','Profile Library','library.svg'],
        ['orders','Lista zamówienia','Order List','order_list.svg'],
        ['separator:1'],
        ['hinges','Wiercenia zawiasów','Hinge Drilling','hinge_drilling.svg'],
        ['drawers','Wiercenia szuflad','Drawer Drilling','drawer_drilling.svg'],
        ['pins','Podpórki półek','Shelf Pin Rows','shelf_pins.svg'],
        ['shelves','Rozmieszczenie półek','Arrange Shelves','shelf_spacing.svg'],
        ['shelves2','Rozmieszczenie półek 2.0','Arrange Shelves 2.0','shelf_spacing_v2.svg'],
        ['joints','Kołki i śruby','Dowels and Screws','carcass_joinery.svg'],
        ['joints2','Kołki i śruby 2.0','Dowels and Screws 2.0','carcass_joinery_v2.svg'],
        ['hangers','Wycięcia pod zawieszki','Hanger Cutouts','hanger_cutouts.svg'],
        ['refresh','Odśwież wiercenia','Refresh drilling','drilling_refresh.svg'],
        ['separator:2'],
        ['settings','Ustawienia domyślne','Default settings','studio_settings.svg']
      ],
      handles:[['add','Dodaj uchwyt','Add Handle','handle_add.svg'],['remove','Usuń uchwyt','Remove Handle','handle_remove.svg'],['library','Biblioteka uchwytów','Handles Library','handle.svg']],
      visibility:[['room','Pomieszczenie','Room'],['separator:1'],['facade','Fronty','Facade'],['body','Korpus','Body'],['back_wall','Plecy','Back Wall'],['worktops','Blaty','Worktops'],['finishing','Wykończenie','Finishing Parts'],['separator:2'],['handles','Uchwyty','Handles'],['hardware','Okucia','Hardware'],['appliances','Sprzęt AGD','Appliances'],['separator:3'],['operations','Operacje Blum','Blum Operations'],['separator:4'],['dimensions','Wymiary','Dimensions'],['separator:5'],['cleanup','Usuń ABFBlocked','Remove ABFBlocked']]
    }.freeze unless const_defined?(:CATALOG)
    def defaults
      CATALOG.to_h { |key,items|[key,{enabled:true,items:items.map { |row|{id:row[0],visible:true} }}] }
    end
    def separator?(id);id.is_a?(String) && id.match?(/\Aseparator:[1-9]\d{0,3}\z/);end
    def validate(input)
      raise ArgumentError,'Invalid toolbar settings.' unless input.is_a?(Hash)
      CATALOG.to_h do |key,catalog|
        bar=input[key] || input[key.to_s]
        raise ArgumentError,'Missing toolbar settings.' unless bar.is_a?(Hash)
        bar=bar.transform_keys(&:to_sym);items=bar[:items]
        raise ArgumentError,'Invalid toolbar settings.' unless [true,false].include?(bar[:enabled]) && items.is_a?(Array) && items.length<=80
        ids=catalog.reject { |row|separator?(row[0]) }.map(&:first);seen=[]
        clean=items.map do |item|
          raise ArgumentError,'Invalid toolbar item.' unless item.is_a?(Hash)
          item=item.transform_keys(&:to_sym);id=item[:id]
          raise ArgumentError,'Invalid or duplicate toolbar item.' unless (ids.include?(id)||separator?(id)) && !seen.include?(id) && [true,false].include?(item[:visible])
          seen<<id;{id:id,visible:item[:visible]}
        end
        # New commands added by later versions are not lost in an older layout.
        (ids-seen).each do |id|
          previous_id={'joints2'=>'joints','shelves2'=>'shelves'}[id]
          at=if previous_id && (previous=clean.index { |row|row[:id]==previous_id });previous+1;else;clean.index { |row|row[:id]=='settings' } || clean.length;end
          clean.insert(at,{id:id,visible:true})
        end
        [key,{enabled:bar[:enabled],items:clean}]
      end
    end
    def settings
      return @settings if @settings
      encoded=Sketchup.read_default(PREF,'layout_base64','')
      @settings=encoded.to_s.empty? ? defaults : validate(JSON.parse(Base64.strict_decode64(encoded),symbolize_names:true))
    rescue ArgumentError,JSON::ParserError,SyntaxError
      @settings=defaults
    end
    def save(value)
      value=validate(value)
      Sketchup.write_default(PREF,'layout_base64',Base64.strict_encode64(JSON.generate(value)))
      @settings=value
    end
    def catalog
      CATALOG.to_h { |key,items|[key,items.reject { |row|separator?(row[0]) }.map { |row|{id:row[0],pl:row[1],en:row[2]} }] }
    end
    def sequence(key,commands)
      bar=settings.fetch(key.to_sym);result=[];pending=false
      bar[:items].each do |item|
        next unless item[:visible]
        if separator?(item[:id]);pending=true unless result.empty?;next;end
        command=commands[item[:id]];next unless command
        result<<nil if pending && !result.empty?;result<<command;pending=false
      end
      result
    end
    # Collect commands first, then create the native toolbar once at startup.
    # Saving preferences never recreates a live toolbar or duplicates commands.
    class Builder
      attr_reader :native,:commands
      def initialize(key,title);@key=key.to_sym;@title=title;@commands={};end
      def add_item(command,id=nil)
        id ||= ToolbarLayout::CATALOG.fetch(@key).find { |row|row[3] && row[3]==File.basename(command.small_icon.to_s) }&.first
        raise ArgumentError,'Unknown ELFIS toolbar command.' unless id
        @commands[id.to_s]=command
      end
      def add_separator;end
      def build(toolbar_class:UI::Toolbar)
        return @native if @native
        @native=toolbar_class.new(@title)
        ToolbarLayout.sequence(@key,@commands).each { |cmd|cmd ? @native.add_item(cmd) : @native.add_separator }
        bar=ToolbarLayout.settings.fetch(@key)
        if bar[:enabled] && !ToolbarLayout.sequence(@key,@commands).empty?
          @native.get_last_state==-1 ? @native.show : @native.restore
          @native.show unless @native.visible?
        else
          @native.hide
        end
        @native
      end
      def visible?;@native && @native.visible?;end
      def hide;@native.hide if @native;end
    end
  end
end
