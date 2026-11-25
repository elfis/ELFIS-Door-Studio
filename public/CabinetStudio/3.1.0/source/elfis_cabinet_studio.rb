# encoding: UTF-8
require 'sketchup.rb'
require 'extensions.rb'
unless file_loaded?(__FILE__)
  extension = SketchupExtension.new('ELFIS CABINET STUDIO 3.1', 'elfis_cabinet_studio/main')
  extension.description = 'Niezależne, uniwersalne narzędzia do obróbki szafek.'
  extension.version = '3.1.0'
  extension.creator = 'ELFIS'
  Sketchup.register_extension(extension, true)
  file_loaded(__FILE__)
end
