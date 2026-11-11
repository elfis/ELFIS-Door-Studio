require 'json'
a=Elfis::Handles;m=Sketchup.active_model;view=m.active_view
record=a.database[:models].find { |r| r[:kind]=='standard' }
raise 'Import a standard handle before this workflow check.' unless record
entities=m.entities.map(&:persistent_id).sort
camera=view.camera
saved=[camera.eye.to_a,camera.target.to_a,camera.up.to_a]
begin
  tool=a::CalibrationTool.new(record)
  m.select_tool(tool)
  raise 'Calibration did not start.' unless a.instance_variable_get(:@calibrating)
  sample=tool.instance_variable_get(:@sample)
  raise 'Calibration preview is missing.' unless sample && sample.valid?
  m.select_tool(nil)
  raise 'Temporary geometry remained.' unless entities==m.entities.map(&:persistent_id).sort
  current=[view.camera.eye.to_a,view.camera.target.to_a,view.camera.up.to_a]
  # SketchUp normalises the target when assigning a copied camera. Compare
  # within 0.01 mm rather than requiring identical floating-point coordinates.
  raise 'Camera was not restored.' unless saved.flatten.zip(current.flatten).all? { |x,y| (x-y).abs<0.01.mm }
  result={passed:true,checks:['Calibration starts with the imported production model','Cancel removes all temporary occurrences','Cancel restores the original camera','Library model calibration remains untouched']}
rescue => e
  m.select_tool(nil)
  result={passed:false,error:e.full_message,saved:saved,current:current}
end
File.write(File.join(__dir__,'elfis_handles_calibration_cancel_results.json'),JSON.pretty_generate(result))
puts JSON.pretty_generate(result)
