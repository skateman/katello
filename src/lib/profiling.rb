module Profiling

  def self.included(controller)
    if profiling_enabled? && load_ruby_prof_gem
      FileUtils.mkdir_p "#{Rails.root}/tmp/profiles"
      controller.around_filter :do_profiling, :if => :run_profiling?
    end
  end

  private

  def self.load_ruby_prof_gem
    @loaded ||= begin
      require 'ruby-prof'
      true
    end
  rescue LoadError
    warn 'install ruby-prof gem'
    return false
  end

  def do_profiling
    action_name = "#{params[:controller]}##{params[:action]}"
    RubyProf.start
    Rails.logger.info "started profiling #{action_name}"
    yield
  ensure
    result = RubyProf.stop
    Rails.logger.info "stopped profiling #{action_name}"
    printer = RubyProf::GraphHtmlPrinter.new(result)
    path    = "#{Rails.root}/tmp/profiles/#{params[:controller].gsub('/', '-')}." +
        "#{params[:action]}.#{Time.now.to_i.to_s}.html"
    File.open(path, 'w') do |f|
      printer.print(f, :min_percent => 0)
    end
    Rails.logger.info "profile was written to #{path}"
    #RubyProf::FlatPrinter.new(result).print($stdout)
  end

  def run_profiling?
    Src::Application.config.do_profiles.include? "#{params[:controller]}##{params[:action]}"
  end

  def self.profiling_enabled?
    Src::Application.config.respond_to?(:do_profiles) && !Src::Application.config.do_profiles.blank?
  end
end
