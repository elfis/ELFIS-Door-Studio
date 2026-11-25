# encoding: UTF-8
require 'sketchup.rb'

# Shared by independent ELFIS extensions. No interception of SketchUp's UI API.
module ElfisMenu
  extend self
  CATEGORIES = ['Doors', 'Handles', 'Orders', 'Drilling', 'Cabinet tools',
                'Display & visibility', 'Settings', 'Help & integration'].freeze unless const_defined?(:CATEGORIES)
  def root
    unless @root
      @root = UI.menu('Extensions').add_submenu('ELFIS')
      @categories = {}
      CATEGORIES.each { |name| @categories[name] = @root.add_submenu(name) }
    end
    @root
  end
  def category(name)
    root
    @categories.fetch(name)
  end
end
