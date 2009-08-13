require File.dirname(__FILE__) + '/spec_helper'

describe Parallel do
  describe :in_processes do
    before do
      @cpus = Parallel.processor_count
    end

    it "executes with detected cpus" do
      `ruby spec/cases/parallel_with_detected_cpus.rb`.should == "HELLO\n" * @cpus
    end

    it "set ammount of parallel processes" do
      `ruby spec/cases/parallel_with_set_processes.rb`.should == "HELLO\n" * 5
    end

    it "does not influence outside data" do
      `ruby spec/cases/parallel_influence_outside_data.rb`.should == "yes"
    end

    it "kills the processes when the main process gets killed through ctrl+c" do
      t = Time.now
      lambda{
        Thread.new do
          `ruby spec/cases/parallel_start_and_kill.rb`
        end
        sleep 1
        running_processes = `ps -f`.split("\n").map{|line| line.split(/\s+/)}
        parent = running_processes.detect{|line| line.include?("00:00:00") and line.include?("ruby") }[1]
        `kill -2 #{parent}` #simulates Ctrl+c
      }.should_not change{`ps`.split("\n").size}
      Time.now.should be_close(t, 3)
    end

    it "saves time" do
      t = Time.now
      `ruby spec/cases/parallel_sleeping_2.rb`
      Time.now.should be_close(t, 3)
    end
  end

  describe :in_threads do
    it "saves time" do
      t = Time.now
      Parallel.in_threads(3){ sleep 2 }
      Time.now.should be_close(t, 3)
    end

    it "does not create new processes" do
      lambda{ Thread.new{ Parallel.in_threads(2){sleep 1} } }.should_not change{`ps`.split("\n").size}
    end

    it "returns results as array" do
      Parallel.in_threads(4){|i| "XXX#{i}"}.should == ["XXX0",'XXX1','XXX2','XXX3']
    end
  end
end