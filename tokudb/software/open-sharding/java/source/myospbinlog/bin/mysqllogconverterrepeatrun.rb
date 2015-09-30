#!/usr/bin/env ruby

# runscript
#
# Copyright (c) 2011 CodeFutures Corporation. All rights reserved.
#

require 'fileutils'
require 'pathname'

#
# set the classpath for the java program
#

# Set the base dir. Expand path gives the absolute path of the current file, dirname gives the bin dir, and dirname again gives the parent dir.
BASEDIR = File.dirname(File.dirname(Pathname.new(__FILE__).realpath))

JAVA = "java"
CLASS = "org.opensharding.myospbinlog.MysqlLogConverterRepeatRun"
HEAPSIZE = "128m"
XMS = "-Xms16m"
XMX = "-Xmx#{HEAPSIZE}"

jars = "#{BASEDIR}/jars/*.jar"
user_jars = "#{BASEDIR}/user-jars/*.jar"

class_path = "-classpath #{BASEDIR}/conf:#{Dir.glob(jars).join(':')}"
@control_file = nil

# Shutdown hook.
def do_at_exit()
  if !@control_file.nil? && !@control_file.closed?
    @control_file.close
  end
  
  puts "Terminating MySQL binlog Converter..."
  sleep(1)
  
end

# Shutdown hook.
at_exit {
  do_at_exit
}

#
# get the properties
#

char_set = nil
log_dir = nil
converted_log_dir = nil
osp_log_dir = nil
log_pattern = nil
processed_file_num = -1

properties_file = File.new("#{BASEDIR}/conf/mysqllogconverterrepeatrun.properties", "r")

while (property = properties_file.gets)
  char_set_name = "character.set="
  log_dir_name = "log.dir="
  converted_log_dir_name = "converted.log.dir="
  log_pattern_name = "log.file.pattern="
  osp_log_dir_name = "osp.log.dir="

  if(property.include?(char_set_name))
    char_set = property.sub(/#{char_set_name}/, "")
    char_set = char_set.strip
  elsif (property.include?(converted_log_dir_name)) 
    converted_log_dir = property.sub(/#{converted_log_dir_name}/, "")
    converted_log_dir = converted_log_dir.strip
  elsif (property.include?(osp_log_dir_name))
    osp_log_dir = property.sub(/#{osp_log_dir_name}/, "")
    osp_log_dir = osp_log_dir.strip
  elsif (property.include?(log_dir_name)) 
    log_dir = property.sub(/#{log_dir_name}/, "")
    log_dir = log_dir.strip
  elsif (property.include?(log_pattern_name))
    log_pattern = property.sub(/#{log_pattern_name}/, "")
    log_pattern = log_pattern.strip
  end
end
  

properties_file.close()

nil_property = false

if (char_set == nil)
  puts "Please provide a value for #{char_set_name}"
nil_property = true
end
if (log_dir == nil)
  puts "Please provide a value for #{log_dir_name}"
nil_property = true
end
if (converted_log_dir == nil)
  puts "Please provide a value for #{converted_log_dir_name}"
nil_property = true
end
if (osp_log_dir == nil)
  puts "Please provide a value for #{osp_log_dir_name}"
nil_property = true
end
if (log_pattern == nil)
  puts "Please provide a value for #{log_pattern_name}"
nil_property = true
end
if (nil_property)
  exit 1
end

#
# Check that the directories exist
#

if(!File.directory?(log_dir))
  puts "The specified directory for MySQL logs does not exist"
  exit 1
end

if(!File.directory?(converted_log_dir))
  system("mkdir -p #{converted_log_dir}text/")
  system("mkdir -p #{converted_log_dir}sql_temp/")
end

if(!File.directory?(osp_log_dir))
  system("mkdir -p #{osp_log_dir}")
end

#
# Run the program many times in an infinite loop
#

while(true)
  # Get the current file number
  processed_file_num_name = "processed.file.number="
  @control_file = File.new("#{BASEDIR}/conf/mysqllogconverterrepeatruncontrol.properties", "r")
  while (property = @control_file.gets)
    if (property.include?(processed_file_num_name))
      temp = property.sub(/#{processed_file_num_name}/, "")
      temp = temp.strip
      processed_file_num = temp.to_i
    end
  end
  @control_file.close()

  # get the log directory
  logs = Dir.new(log_dir).sort()

  @control_file = File.new("#{BASEDIR}/conf/mysqllogconverterrepeatruncontrol.properties", "a")
  # for each file
  logs.each{ |name|
    if name.match(log_pattern)
      num = name[/\d+/]
      # if it's a newer file than the last one worked with
      current_file_num = num.to_i
      if(current_file_num > processed_file_num)
        file_path = "#{log_dir}#{name}"

        is_in_use = false
        is_in_use = system("lsof #{file_path}")

        if(!is_in_use)
          new_file_name = "osp_tx_log.#{num}"
          text_file = "#{converted_log_dir}text/#{new_file_name}.txt"

          # Run mysqlbinlog
          system("mysqlbinlog --result-file=#{text_file} #{file_path}")

          # Run the java program
          new_file_abs = "#{converted_log_dir}sql_temp/#{new_file_name}"
          lock_file_name = "#{new_file_abs}.lock"
          system("touch #{lock_file_name}")

          cmd = [JAVA, XMS, XMX, class_path, CLASS].join(' ')
          cmd += " #{char_set} #{converted_log_dir} #{new_file_name}"
          system(cmd)

          system("rm #{lock_file_name}")
          
          # move the completed OSP log to the proper directory
          osp_file_abs = "#{osp_log_dir}#{new_file_name}"
          if (File.exists?(new_file_abs))
            system("mv #{new_file_abs} #{osp_file_abs}")
          
            if (File.exists?(osp_file_abs))
              # Append the log number to the control file
              @control_file.puts "#{processed_file_num_name}#{num}"
            end
          end
        end
      end
    end
  }
  @control_file.close

  sleep(1)
end


