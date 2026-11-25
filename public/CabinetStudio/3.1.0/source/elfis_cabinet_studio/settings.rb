# encoding: UTF-8
module ElfisCabinetStudio
  module Settings
    extend self
    PREF = 'ELFIS Cabinet Studio'.freeze
    DEFAULTS = { diameter: 8.0, source_depth: 28.0, target_depth: 14.0,
                 start_margin: 30.0, end_margin: 30.0, count: 2,
                 pitch: 32.0, layout: 'pattern', tolerance: 0.2,
                 pattern: 'S D S - D - S D S - D - S D - - - - - - -',
                 screw_diameter: 3.0, screw_depth: 18.0, screw_margin: 55.0, screw_spacing: 220.0 }.freeze
    def validate(input)
      c = DEFAULTS.merge(input.transform_keys(&:to_sym))
      (DEFAULTS.keys - [:layout, :pattern]).each do |key|
        c[key] = Float(c[key])
        raise 'Wymiary muszą być skończonymi liczbami.' unless c[key].finite?
      end
      raise 'Średnica, głębokości i rozstaw muszą być dodatnie.' unless %i[diameter source_depth target_depth pitch screw_diameter screw_depth screw_spacing].all? { |k| c[k] > 0 }
      raise 'Marginesy nie mogą być mniejsze od promienia kołka.' unless %i[start_margin end_margin].all? { |k| c[k] >= c[:diameter] / 2.0 }
      raise 'Liczba kołków: od 1 do 100, liczba całkowita.' unless c[:count] == c[:count].to_i && c[:count].between?(1, 100)
      raise 'Tolerancja styku: od 0 do 2 mm.' unless c[:tolerance].between?(0, 2)
      raise 'Margines śrub musi być większy od promienia otworu.' unless c[:screw_margin] > c[:screw_diameter] / 2
      raise 'Nieznany sposób rozmieszczenia.' unless %w[count pitch pattern].include?(c[:layout])
      cells = c[:pattern].to_s.upcase.split(/[\s,;]+/).reject(&:empty?)
      raise 'Wzór musi zawierać 21 pozycji: D = kołek, S = śruba, - = pomiń.' unless cells.length == 21 && cells.all? { |v| %w[D S -].include?(v) } && cells.any? { |v| v != '-' }
      c[:pattern] = cells.join(' ')
      c[:count] = c[:count].to_i
      c
    end
    def read
      validate(DEFAULTS.to_h { |k, v| [k, Sketchup.read_default(PREF, k.to_s, v)] })
    rescue ArgumentError, TypeError, RuntimeError
      DEFAULTS.dup
    end
    def save(input)
      c = validate(input)
      c.each { |k, v| Sketchup.write_default(PREF, k.to_s, v) }
      c
    end
    # Positions use the source panel's own axes, never the enclosing cabinet axes.
    def positions(length_mm, c)
      c = validate(c)
      first = c[:start_margin]; last = length_mm - c[:end_margin]
      raise 'Za krótka krawędź dla ustawionych marginesów.' if last < first - 0.001
      if c[:layout] == 'pattern'
        c[:pattern].split.each_with_index.filter_map do |kind, i|
          pos = first + i * c[:pitch]
          pos if kind != '-' && pos <= last + 0.001
        end
      elsif c[:layout] == 'count'
        n = c[:count]
        raise 'Brak miejsca na kilka kołków.' if n > 1 && last - first < c[:diameter] * (n - 1) + 0.1
        n == 1 ? [(first + last) / 2.0] : Array.new(n) { |i| first + (last - first) * i / (n - 1) }
      else
        n = ((last - first + 0.001) / c[:pitch]).floor + 1
        raise 'Zbyt dużo kołków. Zwiększ rozstaw.' if n > 100
        raise 'Kołki nachodzą na siebie.' if n > 1 && c[:pitch] <= c[:diameter] + 0.1
        Array.new(n) { |i| first + i * c[:pitch] }
      end
    end
    def row(length_mm, c)
      c = validate(c)
      return positions(length_mm, c).map { |v| { position: v, type: :dowel } } unless c[:layout] == 'pattern'
      c[:pattern].split.each_with_index.filter_map do |kind, i|
        next if kind == '-'
        v = c[:start_margin] + i * c[:pitch]
        next unless v <= length_mm - c[:end_margin] + 0.001
        { position: v, type: kind == 'D' ? :dowel : :screw }
      end
    end
    def screws(lo_mm, hi_mm, c)
      first = lo_mm + c[:screw_margin]; last = hi_mm - c[:screw_margin]
      return [] if last < first - 0.001
      n = last - first < 0.001 ? 1 : ((last - first) / c[:screw_spacing]).ceil + 1
      raise 'Za dużo śrub. Zwiększ rozstaw.' if n > 100
      Array.new(n) { |i| n == 1 ? first : first + (last - first) * i / (n - 1) }
    end
    def edit
      c = read
      prompts = ['Średnica kołka [mm]', 'Głębokość w krawędzi wskazanego panelu [mm]',
                 'Głębokość w powierzchni sąsiedniego panelu [mm]', 'Odsunięcie od początku krawędzi [mm]',
                 'Odsunięcie od końca krawędzi [mm]', 'Rozmieszczenie', 'Liczba kołków na połączenie',
                 'Rozstaw wrzecion / otworów [mm]', 'Tolerancja styku paneli [mm]', 'Wzór 21 pozycji: D kołek, S śruba, - pomiń']
      values = c.values_at(:diameter, :source_depth, :target_depth, :start_margin, :end_margin) +
               [{ 'count' => 'Według liczby', 'pitch' => 'Co rozstaw', 'pattern' => 'Wzór D/S' }[c[:layout]], c[:count], c[:pitch], c[:tolerance], c[:pattern]]
      result = UI.inputbox(prompts, values, ['', '', '', '', '', 'Wzór D/S|Według liczby|Co rozstaw', '', '', '', ''], 'ELFIS CABINET STUDIO — Kołki i wzór D/S')
      return false unless result
      save(c.merge(diameter: result[0], source_depth: result[1], target_depth: result[2], start_margin: result[3],
           end_margin: result[4], layout: { 'Według liczby' => 'count', 'Co rozstaw' => 'pitch', 'Wzór D/S' => 'pattern' }.fetch(result[5]), count: result[6], pitch: result[7], tolerance: result[8], pattern: result[9]))
      true
    rescue ArgumentError, TypeError, RuntimeError => e
      UI.messagebox(e.message)
      false
    end
    def edit_screws
      c = read
      result = UI.inputbox(['Średnica otworu pod śrubę [mm]', 'Głębokość wiercenia [mm]',
                            'Margines od rzeczywistego końca materiału / wycięcia [mm]', 'Maksymalny rozstaw śrub (Shift) [mm]'],
                           c.values_at(:screw_diameter, :screw_depth, :screw_margin, :screw_spacing), 'ELFIS CABINET STUDIO — Śruby')
      return false unless result
      save(c.merge(%i[screw_diameter screw_depth screw_margin screw_spacing].zip(result).to_h))
      true
    rescue ArgumentError, TypeError, RuntimeError => e
      UI.messagebox(e.message); false
    end
  end
end
