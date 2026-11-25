require_relative '../elfis_menu'
# encoding: UTF-8
require 'sketchup.rb'
require_relative 'settings'
require_relative 'geometry'
require_relative 'writer'
require_relative 'multi_joint_tool'
module ElfisCabinetStudio
  VERSION='3.1.0'.freeze unless const_defined?(:VERSION)
  def self.start
    Geometry.require_edit_context
    self.active_tool=MultiJointTool.new
    Sketchup.active_model.selection.clear
    Sketchup.active_model.select_tool(@active_tool)
  rescue RuntimeError=>e;UI.messagebox(e.message);end
  def self.confirm;@active_tool ? @active_tool.confirm : UI.beep;end
  def self.active_tool=(tool);@active_tool=tool;end
  unless @ui_registered
    menu=ElfisMenu.category('Drilling').add_submenu('Cabinet Studio 3.1')
    command=UI::Command.new('Połączenia paneli') { start }
    command.tooltip='Wybierz wiele paneli wierconych i odniesienia'
    command.small_icon=command.large_icon=File.join(__dir__,'joint_profiles.svg')
    confirm_command=UI::Command.new('Zatwierdź połączenia') { confirm }
    confirm_command.tooltip='Zatwierdź pokazane wiercenia'
    confirm_command.small_icon=confirm_command.large_icon=File.join(__dir__,'confirm.svg')
    menu.add_item(command);menu.add_item(confirm_command)
    toolbar=UI::Toolbar.new('ELFIS CABINET STUDIO 3.1')
    toolbar.add_item(command);toolbar.add_item(confirm_command)
    toolbar.get_last_state==TB_NEVER_SHOWN ? toolbar.show : toolbar.restore
    @toolbar=toolbar;@ui_registered=true
  end
end
