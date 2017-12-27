class State
  FIELDS = {}

  def self.add_field name, kls, combiner=lambda { |s,o| s+o }
    attr_accessor name
    FIELDS[name.to_sym] = OpenStruct.new(kls: kls, combiner: combiner)
  end

  def initialize
    FIELDS.each do |name, opts|
      self.send "#{name}=", kls.new
    end
  end

  def to_s
    "<State #{FIELDS.keys.map{|f| "#{f}:#{self.send(f)}" }.join(',')}>"
  end

  def inspect
    inspect
  end

  def marshal_dump
    d = Hash[FIELDS.to_a.map do |(name, _)|
      [name, self.send(name)]
    end]
    d
  end

  def marshal_load data_hash
    FIELDS.each do |name, _|
      self.send "#{name}=", data_hash[name]
    end
  end

  def + other
    new_obj = self.class.new
    FIELDS.each do |name, opts|
      new_obj.send "#{name}=", opts.combiner.call(self, other)
    end
    new_obj
  end
end

STATE_DIR = './state'
class StateLoader
  def self.load state_class
    states = Dir.glob("#{STATE_DIR}/*.rmarshal").map do |file_path|
      Marshal.load File.read(file_path)
    end
    state = states.reduce(&:+)
    state = state || state_class.new
    puts "loaded: #{state}"
    state
  end
end

class StateSaver
  def self.save state_object
    puts "saving: #{state_object}"
    pid = Process.pid
    @time ||= Time.now.to_f
    filename = Pathname.new File.join(STATE_DIR, "#{@time}-#{pid}.rmarshal")
    File.open(filename, 'wb') do |fh|
      fh.write Marshal.dump(state_object)
    end
    filename
  end
end
