# encoding: UTF-8
require 'sketchup.rb'
require 'extensions.rb'
unless file_loaded?(__FILE__)
  extension=SketchupExtension.new('ELFIS — Synchronizacja zawiasów 3D',File.join(__dir__,'elfis_hinge_hardware_sync','main'))
  extension.version='0.1.2'
  extension.creator='ELFIS'
  extension.description='Wiąże istniejące modele Blum z puszkami i prowadnikami. Aktualizuje modele wraz z wierceniami.'
  Sketchup.register_extension(extension,true)
  file_loaded(__FILE__)
end
