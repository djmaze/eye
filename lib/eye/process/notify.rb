module Eye::Process::Notify

  # notify to user:
  # 1) process crashed by itself, and we restart it [:info]
  # 2) checker bounded to restart process [:warn]
  # 3) flapping + switch to unmonitored [:error]

  LEVELS = {:debug => 0, :info => 1, :warn => 2, :error => 3, :fatal => 4}

  def notify(level, msg)
    # logging it
    error "NOTIFY: #{msg}" if ilevel(level) > ilevel(:info)

    # send notifies
    if self[:notify].present?
      message = {:message => msg, :name => name, 
        :full_name => full_name, :pid => pid, :host => Eye::System.host, :level => level,
        :at => Time.now }

      self[:notify].each do |contact, not_level|
        Eye::Notify.notify(contact, message) if ilevel(level) >= ilevel(not_level)
      end
    end
  end

private

  def ilevel(level)
    LEVELS[level].to_i
  end

end