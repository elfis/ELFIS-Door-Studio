# encoding: UTF-8
require 'sketchup.rb'
require 'extensions.rb'
unless file_loaded?(__FILE__)
  extension = SketchupExtension.new('ELFIS — Widok zabudowy BETA', File.join(__dir__, 'elfis_elevation_beta', 'main'))
  extension.description = 'Zwymiarowany podgląd zaznaczonej zabudowy, rzuty i widok 3D X-ray pojedynczej szafki, eksport SVG oraz wydruk/PDF. Beta 0.1.44.'
  extension.version = '0.1.44'
  extension.creator = 'ELFIS'
  Sketchup.register_extension(extension, true)
  file_loaded(__FILE__)
end
