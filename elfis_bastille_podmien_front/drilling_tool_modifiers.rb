# encoding: UTF-8
module Elfis
  module DrillingToolModifiers
    def init_drilling_modifiers(type,remove)
      @drilling_type=type;@base_remove=remove;@held_drilling_modifiers={}
      @drilling_mode=remove ? :remove : :add;@remove=remove;@refresh=false
    end
    # HangerCutouts and the standalone Refresh tool inherit the joinery tool's
    # drawing code but retain their own commands and keyboard behaviour.
    def drilling_modifiers_enabled?
      self.class==ShelfPins::Tool || self.class==CarcassJoinery::Tool
    end
    def drilling_module;@drilling_type==:pin ? ShelfPins : CarcassJoinery;end
    def drilling_mode(flags=0)
      return :remove if @held_drilling_modifiers[ALT_MODIFIER_KEY] || (flags & ALT_MODIFIER_MASK)!=0
      return :refresh if @held_drilling_modifiers[COPY_MODIFIER_KEY] || (flags & COPY_MODIFIER_MASK)!=0
      @base_remove ? :remove : :add
    end
    def set_drilling_mode(flags)
      mode=drilling_mode(flags)
      if mode!=@drilling_mode
        @signature=nil;@plan=nil;@plan_mode=nil
      end
      @drilling_mode=mode;@remove=mode==:remove;@refresh=mode==:refresh
    end
    def show_drilling_mode
      type=@drilling_type==:pin ? drilling_module.l('Podpórki','Shelf pins') : drilling_module.l('Kołki i śruby','Dowels and screws')
      mode=case @drilling_mode
      when :remove;drilling_module.l('USUŃ powiązane wiercenia','REMOVE associated drilling')
      when :refresh;drilling_module.l('AKTUALIZUJ otwory po przesunięciu panelu','UPDATE holes after moving the panel')
      else;drilling_module.l('DODAJ wiercenia','ADD drilling')
      end
      Sketchup.set_status_text("#{type}: #{mode}. "+drilling_module.l('Alt: usuń · Ctrl: aktualizuj · puść klawisz: powrót · Esc: koniec.','Alt: remove · Ctrl: update · release key: return · Esc: finish.'))
    end
    def refresh_drilling_preview(view)
      flags=0
      flags|=ALT_MODIFIER_MASK if @held_drilling_modifiers[ALT_MODIFIER_KEY]
      flags|=COPY_MODIFIER_MASK if @held_drilling_modifiers[COPY_MODIFIER_KEY]
      set_drilling_mode(flags);show_drilling_mode
      @signature=nil;@plan=nil;@plan_mode=nil
      onMouseMove(flags,@drilling_x,@drilling_y,view) if @drilling_x && @drilling_y
      view.invalidate
    end
    def onKeyDown(key,repeat,flags,view)
      return false unless drilling_modifiers_enabled? && [ALT_MODIFIER_KEY,COPY_MODIFIER_KEY].include?(key)
      return true if @held_drilling_modifiers[key]
      @held_drilling_modifiers[key]=true;refresh_drilling_preview(view);true
    end
    def onKeyUp(key,repeat,flags,view)
      return false unless drilling_modifiers_enabled? && [ALT_MODIFIER_KEY,COPY_MODIFIER_KEY].include?(key)
      @held_drilling_modifiers.delete(key);refresh_drilling_preview(view);true
    end
    def build_drilling_plan(path,model=Sketchup.active_model)
      if @refresh
        DrillingRefresh.plan(path,model,kind:@drilling_type)
      elsif @remove
        {shelf:drilling_module.board(path,model),holes:drilling_module.removal_groups(path,model)}
      else
        drilling_module.plan(path,@settings,model)
      end
    end
    def perform_drilling_action(path,model=Sketchup.active_model,operation:true)
      if @refresh
        result=DrillingRefresh.apply([path],model,operation:operation,kind:@drilling_type)
        Sketchup.set_status_text(DrillingRefresh.status(result))
      else
        result=@remove ? drilling_module.remove([path],model,operation:operation) : drilling_module.apply([path],@settings,model,operation:operation)
        Sketchup.set_status_text(drilling_module.status(result))
      end
      result
    end
    def clear_drilling_modifiers
      @held_drilling_modifiers={};@drilling_mode=@base_remove ? :remove : :add
      @remove=!!@base_remove;@refresh=false;@signature=nil;@plan_mode=nil
    end
  end
end
