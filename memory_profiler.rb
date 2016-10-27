# -*- coding:utf-8 -*-
# メモリプロファイラ

Plugin.create :memory_profiler do
  def profile(output_dir)
    FileUtils.mkdir_p(output_dir)
    time = Reserver.new(60) do
      Plugin.call(:spectrum_set, lambda {
        notice "memory_profiler: start"
        ObjectSpace.garbage_collect
        objects = Hash.new(0) # :class => count

        notice "memory_profiler: counting objects..."
        ObjectSpace.each_object{|o| objects[o.class] += 1 unless (o.irregulareval? rescue nil) }

        output = File.join(output_dir, Time.now.strftime("%Y-%m-%d-%H%M"))
        notice "memory_profiler: done. writing file #{output}"

        File.open(output, 'w') do |ostream|
          Marshal.dump(objects.map{|k, v| [(k || 'nil').to_s.to_sym, v]}, ostream)
        end
        notice "memory_profiler: wrote #{output}."
        objects.clear
        profile(output_dir) }) end
    notice "reserve to next time " + time.to_s end

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









