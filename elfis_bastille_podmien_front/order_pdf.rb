# encoding: UTF-8
require 'zlib'
require 'tempfile'

module Elfis
  module BastillePodmienFront
    # Dependency-free PDF with embedded system TrueType fonts, selectable
    # Unicode text, measured wrapping and repeated table headings.
    class OrderPDF
      W=595.28;H=841.89;M=30.0;BOTTOM=794.0
      class Font
        attr_reader :bytes,:chars
        def initialize(path)
          @bytes=File.binread(path);@tables={};@chars={}
          u16(4).times do |i|
            at=12+i*16
            @tables[@bytes[at,4]]=[u32(at+8),u32(at+12)]
          end
          @units=u16(@tables.fetch('head')[0]+18)
          @metrics=u16(@tables.fetch('hhea')[0]+34)
          base=@tables.fetch('cmap')[0];choices=[]
          u16(base+2).times do |i|
            at=base+4+i*8;offset=base+u32(at+4);format=u16(offset)
            choices<<[format==12 ? 2 : 1,offset] if [4,12].include?(format) && [0,3].include?(u16(at))
          end
          @cmap=choices.max_by(&:first)&.last
          raise 'No Unicode character map in PDF font.' unless @cmap
        end
        def u16(at);@bytes[at,2].unpack1('n');end
        def u32(at);@bytes[at,4].unpack1('N');end
        def glyph(code)
          if u16(@cmap)==12
            low=0;high=u32(@cmap+12)-1
            while low<=high
              mid=(low+high)/2;at=@cmap+16+mid*12;first=u32(at);last=u32(at+4)
              if code<first;high=mid-1
              elsif code>last;low=mid+1
              else return u32(at+8)+code-first
              end
            end
          else
            n=u16(@cmap+6)/2;ending=@cmap+14;starting=ending+2*n+2;delta=starting+2*n;ranges=delta+2*n
            n.times do |i|
              next if code>u16(ending+2*i)
              return 0 if code<u16(starting+2*i)
              range=u16(ranges+2*i)
              return (code+u16(delta+2*i))&65535 if range==0
              g=u16(ranges+2*i+range+2*(code-u16(starting+2*i)))
              return g==0 ? 0 : (g+u16(delta+2*i))&65535
            end
          end
          0
        end
        def entry(char)
          @chars[char] ||= begin
            g=glyph(char.ord);g=glyph(63) if g==0 && char!=' '
            width=u16(@tables.fetch('hmtx')[0]+[g,@metrics-1].min*4)*1000.0/@units
            {cid:@chars.length+1,glyph:g,width:width.round}
          end
        end
        def width(text,size);text.each_char.sum { |c| entry(c)[:width] }*size/1000.0;end
        def encode(text);text.each_char.map { |c| '%04X'%entry(c)[:cid] }.join;end
      end

      def initialize(data,language='en')
        @data=data;@pl=language=='pl';@pages=[];@objects=[]
        windir=ENV.fetch('WINDIR','C:/Windows')
        choices=[[File.join(windir,'Fonts','arial.ttf'),File.join(windir,'Fonts','arialbd.ttf')],['/Library/Fonts/Arial.ttf','/Library/Fonts/Arial Bold.ttf'],['/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf','/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf']]
        pair=choices.find { |p| p.all? { |f| File.file?(f) } }
        raise 'PDF export needs the Arial or DejaVu Sans system font.' unless pair
        @fonts=pair.map { |path| Font.new(path) }
      end
      def l(pl,en);@pl ? pl : en;end
      def number(value)
        value.is_a?(Numeric) ? ('%.2f'%value).sub(/\.?0+$/,'') : value
      end
      def clean(value);value.to_s.encode('UTF-8',invalid: :replace,undef: :replace).gsub(/[\x00-\x08\x0B\x0C\x0E-\x1F]/,'').tr("\u2011",'-');end
      def text(value,x,y,size=9,bold=false,colour='0 0 0')
        font=@fonts[bold ? 1 : 0]
        @stream<<"#{colour} rg BT /F#{bold ? 2 : 1} #{size} Tf 1 0 0 1 #{x.round(2)} #{(H-y).round(2)} Tm <#{font.encode(clean(value))}> Tj ET\n"
      end
      def rect(x,y,w,h,colour)
        @stream<<"#{colour} rg #{x.round(2)} #{(H-y-h).round(2)} #{w.round(2)} #{h.round(2)} re f\n"
      end
      def rule(x1,y1,x2,y2,grey='0.65',width=0.35)
        @stream<<"#{grey} G #{width} w #{x1.round(2)} #{(H-y1).round(2)} m #{x2.round(2)} #{(H-y2).round(2)} l S\n"
      end
      def wrap(value,width,size=8.5,bold=false)
        font=@fonts[bold ? 1 : 0];lines=['']
        clean(value).split(/\s+/).each do |word|
          if font.width(word,size)>width
            lines<<'' unless lines.last.empty?
            word.each_char do |char|
              if font.width(lines.last+char,size)>width && !lines.last.empty?;lines<<'';end
              lines[-1]+=char
            end
          elsif lines.last.empty? || font.width(lines.last+' '+word,size)<=width
            lines[-1]+=(lines.last.empty? ? '' : ' ')+word
          else
            lines<<word
          end
        end
        lines
      end
      def new_page(title,continued=false)
        @stream=''.b;@pages<<@stream
        text('ELFIS / '+l('ZAMÓWIENIE','ORDER'),M,33,10,true)
        text(title+(continued ? l(' - ciąg dalszy',' - continued') : ''),M,64,22,true)
        project=wrap(l('Projekt: ','Project: ')+@data[:model].to_s,W-2*M-160,9)
        project.first(3).each_with_index { |line,i| text(line,M,84+i*12,9) }
        text(Time.now.strftime('%Y-%m-%d %H:%M'),W-M-130,32,9)
        @y=[115,91+project.first(3).length*12].max
      end
      def table_header(headings,widths)
        @headings=headings;@widths=widths
        lines=headings.each_with_index.map { |v,i| wrap(v,widths[i]-12,8,true) }
        height=lines.map(&:length).max*11+14
        rule(M,@y+height,W-M,@y+height,'0.35',0.5)
        x=M
        lines.each_with_index do |column,i|
          column.each_with_index { |line,j| text(line,x+6,@y+14+j*11,8,true) };x+=widths[i]
        end
        @y+=height
      end
      def row(values,index,title)
        columns=values.each_with_index.map { |value,i| wrap(value,@widths[i]-12,8.5,@quantity_column==i) }
        offset=0;count=columns.map(&:length).max
        # Keep ordinary rows together. Split only a cell taller than a page.
        if count*11+12<=BOTTOM-190 && @y+count*11+12>BOTTOM
          new_page(title,true);table_header(@headings,@widths)
        end
        while offset<count
          if BOTTOM-@y<25
            new_page(title,true);table_header(@headings,@widths)
          end
          take=[((BOTTOM-@y-12)/11).floor,count-offset].min
          height=take*11+12
          x=M
          columns.each_with_index do |lines,i|
            (lines.slice(offset,take)||[]).each_with_index { |line,j| text(line,x+6,@y+14+j*11,8.5,@quantity_column==i) };x+=@widths[i]
          end
          rule(M,@y+height,W-M,@y+height,'0.75',0.3)
          @y+=height;offset+=take
        end
      end
      def section(title,headings,widths,rows,quantity)
        @quantity_column=headings.index(l('Ilość','Qty'))
        new_page(title)
        text(l('Razem: ','Total: ')+quantity.to_s+l(' szt. / Pozycje: ',' pcs / Items: ')+rows.length.to_s,M,@y-7,10,true)
        @y+=8;table_header(headings,widths)
        if rows.empty?;text(l('Brak pozycji do zamówienia.','No items to order.'),M+8,@y+24,10)
        else rows.each_with_index { |values,i| row(values,i,title) }
        end
      end
      def build
        api=Elfis::BastillePodmienFront
        headings=[l('Profil / element','Profile / item'),l('Rodzaj','Type'),l('Ilość','Qty'),l('Wymiary [mm]','Dimensions [mm]'),l('Kolor / materiał','Colour / material'),l('Uchwyt','Handle'),l('Producent / źródło','Supplier / source')]
        widths=[105,55,32,88,105,65,W-2*M-450]
        (['fronts']+FINISHING_GROUPS).each do |group|
          rows=api.sorted_order_rows(@data[:rows].select { |r| api.order_group(r)==group })
          next if rows.empty? && group!='fronts'
          title={'fronts'=>l('Fronty','Fronts'),'plinths'=>l('Cokoły','Plinths'),'endpanels'=>l('Panele kończące','End Panels'),'pelmets'=>l('Pelmety','Pelmets'),'crowns'=>l('Gzymsy','Crowns'),'other'=>l('Pozostałe Finishing','Other Finishing')}[group]
          if group=='plinths'
            stock=api.order_stock_plan(rows);values=[]
            stock[:groups].each do |g|
              values<<[g[:product],l('Listwy','Stock'),g[:quantity],[stock[:settings][:length],g[:section],g[:thickness]].map { |n| number(n) }.join(' × '),g[:colours].map { |c| c[:name] }.join(' / '),'—',g[:source]]
              g[:bars].each_with_index do |bar,i|
                values<<[l('Listwa ','Stock ')+(i+1).to_s,l('Cięcie','Cuts'),'',bar[:parts].map { |p| [p[:length],p[:section]].map { |n| number(n) }.join(' × ') }.join(' + '),l('Odpad: ','Waste: ')+number(bar[:waste]).to_s+' mm',l('Rzaz: ','Kerf: ')+number(bar[:cutting_loss]).to_s+' mm','']
              end
              g[:oversize].each { |part| values<<[g[:product],l('ZA DŁUGI','OVERSIZE'),1,number(part[:length]),l('Nie mieści się w listwie','Does not fit stock'),'',''] }
              values<<[l('Układ przybliżony','Approximate layout'),'','','','','',''] unless g[:optimal]
            end
            section(title+" (#{number(stock[:settings][:length])} mm)",headings,widths,values,stock[:groups].sum { |g| g[:quantity] })
          else
            values=rows.map { |r| [r[:profile],api.ui_label(r[:type]),r[:quantity],[r[:height],r[:width],r[:thickness]].map { |n| number(n) }.join(' × '),r[:colours].map { |c| c[:name] }.join(' / '),api.ui_label(r[:handle]),r[:source]] }
            section(title,headings,widths,values,rows.sum { |r| r[:quantity] })
          end
        end
        handles=Array(@data[:handles])
        heads=[l('Model','Model'),l('Rodzaj','Type'),l('Ilość','Qty'),l('Rozstaw [mm]','Pitch [mm]'),l('Długość [mm]','Length [mm]'),l('Wykończenie','Finish'),l('Dostawca','Supplier'),l('Kod','Code')]
        kinds={'edge'=>l('Krawędziowy','Edge pull'),'standard'=>l('Standardowy','Standard'),'knob'=>l('Gałka','Knob')}
        field=(@data[:sort] || {})[:field];direction=(@data[:sort] || {})[:direction]=='desc' ? -1 : 1
        handles=handles.sort_by { |r| [direction*(r[field=='width' ? :length : :pitch] || 0).to_f,r[:name]] }
        values=handles.map { |r| [r[:name],kinds.fetch(r[:kind],r[:kind]),r[:quantity],number(r[:pitch]),number(r[:length]),r[:finish],r[:supplier],r[:code]] }
        section(l('Uchwyty','Handles'),heads,[110,55,32,45,45,80,85,W-2*M-452],values,handles.sum { |r| r[:quantity] })
        @quantity_column=nil
        notes=Array(@data[:warnings]).dup
        notes.unshift(l('Pozycje wymagające sprawdzenia: ','Items requiring review: ')+@data[:review_count].to_s) if @data[:review_count].to_i>0
        @data[:rows].select { |r| r[:review] }.each do |r|
          notes<<"#{r[:profile]} / #{number(r[:height])} x #{number(r[:width])} mm / #{r[:colours].map { |c| c[:name] }.join(' / ')}"
        end
        unless notes.empty?
          title=l('Uwagi do zamówienia','Order review notes');new_page(title)
          table_header([l('Sprawdź przed zamówieniem','Check before ordering')],[W-2*M])
          notes.each_with_index { |note,i| row([note],i,title) }
        end
        @pages.each_with_index do |stream,i|
          @stream=stream;rule(M,H-30,W-M,H-30,'0.65',0.35)
          text(l('Wymiary w mm. Sprawdź zamówienie przed wysłaniem.','Dimensions in mm. Review the order before sending.'),M,H-14,8)
          text("#{i+1} / #{@pages.length}",W-M-46,H-14,8,true)
        end
        serialize
      end
      def object(value);@objects<<value.b;@objects.length;end
      def stream(bytes,extra='')
        compressed=Zlib::Deflate.deflate(bytes.b)
        object("<< /Length #{compressed.bytesize} /Filter /FlateDecode #{extra} >>\nstream\n".b+compressed+"\nendstream")
      end
      def font_object(font,index)
        file=stream(font.bytes,"/Length1 #{font.bytes.bytesize}")
        name=index==0 ? 'ElfisRegular' : 'ElfisBold'
        descriptor=object("<< /Type /FontDescriptor /FontName /#{name} /Flags 32 /FontBBox [-1000 -500 2500 1500] /ItalicAngle 0 /Ascent 1000 /Descent -300 /CapHeight 750 /StemV 80 /FontFile2 #{file} 0 R >>")
        cmap="/CIDInit /ProcSet findresource begin 12 dict begin begincmap /CIDSystemInfo << /Registry (Adobe) /Ordering (UCS) /Supplement 0 >> def /CMapName /ElfisUnicode def /CMapType 2 def 1 begincodespacerange <0000> <FFFF> endcodespacerange\n"
        chars=font.chars.to_a.sort_by { |_,e| e[:cid] }
        chars.each_slice(100) do |group|
          cmap<<"#{group.length} beginbfchar\n"
          group.each { |char,e| cmap<<"<#{'%04X'%e[:cid]}> <#{char.encode('UTF-16BE').unpack1('H*')}>\n" }
          cmap<<"endbfchar\n"
        end
        cmap<<'endcmap CMapName currentdict /CMap defineresource pop end end'
        unicode=stream(cmap)
        mapping=stream(([0]+chars.map { |_,e| e[:glyph] }).pack('n*'))
        descendant=object("<< /Type /Font /Subtype /CIDFontType2 /BaseFont /#{name} /CIDSystemInfo << /Registry (Adobe) /Ordering (Identity) /Supplement 0 >> /FontDescriptor #{descriptor} 0 R /CIDToGIDMap #{mapping} 0 R /W [1 [#{chars.map { |_,e| e[:width] }.join(' ')}]] >>")
        object("<< /Type /Font /Subtype /Type0 /BaseFont /#{name} /Encoding /Identity-H /DescendantFonts [#{descendant} 0 R] /ToUnicode #{unicode} 0 R >>")
      end
      def serialize
        catalog=object('');parent=object('')
        fonts=@fonts.each_with_index.map { |font,i| font_object(font,i) }
        pages=@pages.map do |content|
          ref=stream(content)
          object("<< /Type /Page /Parent #{parent} 0 R /MediaBox [0 0 #{W} #{H}] /Resources << /Font << /F1 #{fonts[0]} 0 R /F2 #{fonts[1]} 0 R >> >> /Contents #{ref} 0 R >>")
        end
        @objects[catalog-1]="<< /Type /Catalog /Pages #{parent} 0 R >>"
        @objects[parent-1]="<< /Type /Pages /Count #{pages.length} /Kids [#{pages.map { |id| "#{id} 0 R" }.join(' ')}] >>"
        result="%PDF-1.7\n%\xE2\xE3\xCF\xD3\n".b;offsets=[0]
        @objects.each_with_index { |content,i| offsets<<result.bytesize;result<<"#{i+1} 0 obj\n".b<<content.b<<"\nendobj\n" }
        at=result.bytesize;result<<"xref\n0 #{@objects.length+1}\n0000000000 65535 f \n"
        offsets.drop(1).each { |offset| result<<'%010d 00000 n '%offset<<"\n" }
        result<<"trailer\n<< /Size #{@objects.length+1} /Root #{catalog} 0 R >>\nstartxref\n#{at}\n%%EOF\n"
      end
    end

    def export_order_pdf
      # Export the entire order, independent of table selection/front filters.
      model=Sketchup.active_model
      data=collect_order_list(model,@order_include_hidden==true,@order_include_facade==true,true,true)
      raise l('Lista jest pusta.','The order is empty.') if data[:rows].empty? && data[:handles].empty?
      name=(model.title.empty? ? 'ELFIS' : model.title).gsub(/[<>:"\/\\|?*]/,'_')
      path=UI.savepanel(l('Zapisz całe zamówienie jako PDF','Save complete order as PDF'),nil,"#{name}_order.pdf")
      return false unless path
      path+='.pdf' unless File.extname(path).casecmp('.pdf').zero?
      bytes=OrderPDF.new(data,language).build
      # Build fully before touching the destination; replace atomically.
      temp=Tempfile.new(['elfis-order-','.pdf'],File.dirname(path));temp.binmode
      begin
        temp.write(bytes);temp.close
        File.rename(temp.path,path)
      ensure
        temp.close! rescue nil
      end
      @order_dialog.execute_script("setOrderStatus(#{JSON.generate(l("Zapisano całe zamówienie: #{path}","Complete order saved: #{path}"))})") if @order_dialog
      true
    end
  end
end
