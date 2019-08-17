# frozen_string_literal: true

require 'csv'

Plugin.create :memory_profiler do
  def object_counts(output_dir)
    notice "memory_profiler: start"
    ObjectSpace.garbage_collect
    objects = Hash.new(0) # :class => count

    notice "memory_profiler: counting objects..."
    ObjectSpace.each_object.to_a.each{|o|
      objects[o.class.name || o.class.to_s] += 1 unless (o.irregulareval? rescue nil)
    }
    data_csv_fn = File.join(output_dir, 'data.csv')
    header_csv_fn = File.join(output_dir, 'header.csv')
    notice "memory_profiler: done. writing file #{data_csv_fn}"

    header = if FileTest.exist?(header_csv_fn)
               CSV.parse(File.open(header_csv_fn).readline).first.cdr
             else
               [*objects.keys.sort]
             end

    CSV.open(data_csv_fn, 'ab') do |ostream|
      new_keys = objects.keys.reject(&header.method(:include?))
      header = [*header, *new_keys]
      CSV.open(header_csv_fn, 'wb') do |oheader|
        oheader << ['timestamp', *header]
      end
      ostream << [Time.now.iso8601, *objects.values_at(*header)]
    end
    notice "memory_profiler: wrote #{data_csv_fn}."
    objects.clear
    profile(output_dir)
  end

  def profile(output_dir)
    FileUtils.mkdir_p(output_dir)
    time = Reserver.new(60){ Plugin.call(:spectrum_set, -> { object_counts(output_dir) }) }
    notice "reserve to next time " + time.to_s
  end

  on_spectrum_set do |spectrum|
    notice "receive spectrum_set"
    @lock << spectrum end

  @lock = Queue.new

  Thread.new{
    loop{
      begin
        @lock.pop.call
      rescue => e
        error e end } }

  profile(File.join(Environment::LOGDIR, self.spec[:slug].to_s, defined_time.strftime("%Y/%m/%d/#{Environment::VERSION}-#{Process.pid}")).freeze)
end









