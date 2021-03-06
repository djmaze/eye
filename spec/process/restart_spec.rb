require File.dirname(__FILE__) + '/../spec_helper'

describe "Process Restart" do
  [C.p1, C.p2].each do |cfg|
    it "restart by default command #{cfg[:name]}" do
      start_ok_process(cfg)
      old_pid = @pid

      dont_allow(@process).check_crash
      @process.restart

      @process.pid.should_not == old_pid
      @process.pid.should > 0

      Eye::System.pid_alive?(@pid).should == false
      Eye::System.pid_alive?(@process.pid).should == true

      @process.state_name.should == :up
      @process.states_history.seq?(:up, :restarting, :stopping, :down, :starting, :up).should == true
      @process.watchers.keys.should == [:check_alive]

      @process.load_pid_from_file.should == @process.pid
    end

    it "stop_command is #{cfg[:name]}" do
      start_ok_process(cfg.merge(:stop_command => "kill -9 {{PID}}"))
      old_pid = @pid

      dont_allow(@process).check_crash
      @process.restart

      @process.pid.should_not == old_pid
      @process.pid.should > 0

      Eye::System.pid_alive?(@pid).should == false
      Eye::System.pid_alive?(@process.pid).should == true

      @process.state_name.should == :up
      @process.watchers.keys.should == [:check_alive]

      @process.load_pid_from_file.should == @process.pid
    end

    it "emulate restart_command that cant kill (USR1)" do
      # not trully test, but its ok as should send signal (unicorn case)
      start_ok_process(cfg.merge(:restart_command => "kill -USR1 {{PID}}"))
      old_pid = @pid

      dont_allow(@process).check_crash
      @process.restart

      sleep 3
      @process.pid.should == old_pid

      Eye::System.pid_alive?(@pid).should == true      

      @process.state_name.should == :up
      @process.watchers.keys.should == [:check_alive]

      @process.load_pid_from_file.should == @process.pid
      @process.states_history.end?(:up, :restarting, :up).should == true

      File.read(@log).should include("USR1")
    end

    it "emulate restart as stop,start where stop command does not kill" do
      # should send command, than wait grace time,
      # and than even if old process doesnot die, start another one, (looks like bug, but this is not, it just bad using, commands)

      # same situation, when stop command kills so long time, that process cant stop
      start_ok_process(cfg.merge(:stop_command => "kill -USR1 {{PID}}"))
      old_pid = @pid

      dont_allow(@process).check_crash
      @process.restart

      sleep 3
      @process.pid.should_not == old_pid

      Eye::System.pid_alive?(@pid).should == true      

      @process.state_name.should == :up
      @process.watchers.keys.should == [:check_alive]

      @process.load_pid_from_file.should == @process.pid
      @process.states_history.end?(:up, :restarting, :stopping, :unmonitored, :starting, :up).should == true

      File.read(@log).should include("USR1")
    end

    it "bad restart_command is #{cfg[:name]} and its kills" do
      # not really restartin, just killing
      # so monitor should see that process died, and up it
      start_ok_process(cfg.merge(:restart_command => "kill -9 {{PID}}"))

      mock(@process).check_crash

      @process.restart
      Eye::System.pid_alive?(@pid).should == false      
      @process.states_history.seq?(:up, :restarting, :down).should == true
    end

    it "Bad restart command, invalid" do
      start_ok_process(cfg.merge(:restart_command => "asdfasdf sdf asd fasdf asdf"))

      dont_allow(@process).check_crash

      @process.restart
      Eye::System.pid_alive?(@pid).should == true
      @process.states_history.seq?(:up, :restarting, :up).should == true
    end

    it "restart command timeouted" do
      start_ok_process(cfg.merge(:restart_command => "sleep 5", :restart_timeout => 3))
      @process.restart

      sleep 1
      @process.pid.should == @pid

      Eye::System.pid_alive?(@pid).should == true      

      @process.state_name.should == :up
      @process.watchers.keys.should == [:check_alive]

      @process.load_pid_from_file.should == @process.pid
      @process.states_history.end?(:up, :restarting, :up).should == true
    end
  end

  it "restart eye-daemonized lock-process from unmonitored status, and process realy running (WAS a problem)" do
    start_ok_process(C.p4)
    @pid = @process.pid
    @process.unmonitor
    Eye::System.pid_alive?(@pid).should == true

    @process.restart
    @process.state_name.should == :up

    Eye::System.pid_alive?(@pid).should == false
    @process.load_pid_from_file.should_not == @pid
  end

  [:down, :unmonitored, :up].each do |st|
    it "ok restart from #{st}" do
      start_ok_process(C.p1)
      @process.state = st.to_s
      old_pid = @pid

      dont_allow(@process).check_crash
      @process.restart

      @process.pid.should_not == old_pid
      @process.pid.should > 0

      Eye::System.pid_alive?(@pid).should == false
      Eye::System.pid_alive?(@process.pid).should == true

      @process.state_name.should == :up
      @process.watchers.keys.should == [:check_alive]
      @process.states_history.seq?(:restarting, :stopping, :down, :starting, :up).should == true

      @process.load_pid_from_file.should == @process.pid
    end
  end

  [:starting, :restarting, :stopping].each do |st|
    it "not restart from #{st}" do
      @process = process(C.p1)
      @process.state = st.to_s # force set state

      dont_allow(@process).stop
      dont_allow(@process).start      

      @process.restart.should == nil
      @process.state_name.should == st
    end
  end

  it "restart process without start command" do
    @process = process(C.p2.merge(:start_command => nil))
    @process.restart
    sleep 1
    @process.unmonitored?.should == true
  end

end