# encoding: UTF-8
require 'sketchup.rb'
require 'extensions.rb'
module Elfis
  module HandlesLoader
    unless file_loaded?(__FILE__)
      extension = SketchupExtension.new('ELFIS — Handles', 'elfis_handles/main')
      extension.description = 'Independent handle library, click placement, replacement and ordering. Requires ELFIS Door Studio 2.9.1.'
      extension.version = '1.1.0-beta'
      extension.creator = 'ELFIS'
      Sketchup.register_extension(extension, true)
      file_loaded(__FILE__)
    end
  end
end
