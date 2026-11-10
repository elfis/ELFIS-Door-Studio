# encoding: UTF-8
module Elfis
  module BastillePodmienFront
    class PerformanceObserver < Sketchup::ModelObserver
      def initialize(session);@session=session;end
      def onTransactionCommit(model);@session.changed;end
      def onTransactionAbort(model);@session.changed;end
      def onTransactionUndo(model);@session.changed(true);end
      def onTransactionRedo(model);@session.changed(true);end
      def onActivePathChanged(model);@session.changed;end
    end

    class PerformanceSession
      attr_reader :model,:revision,:geometry_cache
      attr_accessor :internal_depth
      def initialize(model)
        @model=model;@revision=0;@internal_depth=0;@geometry_cache={}
        @observer=PerformanceObserver.new(self)
        model.add_observer(@observer)
      end
      def changed(force=false)
        @revision+=1
        if force || internal_depth==0
          @geometry_cache.clear
        end
      end
      def detach
        model.remove_observer(@observer)
        @geometry_cache.clear
      rescue;end
    end

    def performance_session(model=Sketchup.active_model)
      if !@performance_session || @performance_session.model!=model
        @performance_session&.detach
        @performance_session=PerformanceSession.new(model)
      end
      @performance_session
    end

    def geometry_cache_key(p,width,height)
      fields=[:kind,:width,:thickness,:points,:shoulder,:panel,:clearance,:groove,:handle_edge,:cavity,:lip,:radius,:source,:section,:reference_length,:flip_front,:flip_end]
      JSON.generate([width,height,fields.map { |key| p[key] },p[:drawer_section]])
    end

    def cached_door_definition(model,p,width,height)
      cache=performance_session(model).geometry_cache
      key=geometry_cache_key(p,width,height)
      entry=cache.delete(key)
      if entry && entry[:parts].all? { |part| part[:definition].valid? }
        cache[key]=entry
        d=model.definitions.add('ELFIS door')
        d.description=entry[:description]
        entry[:attributes].each { |dictionary,values| values.each { |k,v| d.set_attribute(dictionary,k,v) } }
        entry[:parts].each do |part|
          group=d.entities.add_group
          group.entities.add_instance(part[:definition],IDENTITY).explode
          group.transformation=part[:transform]
          group.name=part[:name]
          group.set_attribute('ElfisBastillePodmien','geometry',true)
        end
        d
      else
        d=yield
        # Keep references only to existing, clean geometry-part definitions.
        # CNC containers and the mutable outer door definition are never cached.
        attributes={}
        d.attribute_dictionaries&.each do |dict|
          values={};dict.each_pair { |k,v| values[k]=v };attributes[dict.name]=values
        end
        cache[key]={description:d.description,attributes:attributes,parts:d.entities.grep(Sketchup::Group).map { |g| {definition:g.definition,transform:g.transformation,name:g.name} }}
        cache.shift while cache.length>12
        d
      end
    end
  end
end
