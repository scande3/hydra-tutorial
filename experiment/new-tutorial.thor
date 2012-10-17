#! /usr/bin/env ruby

class App < Thor

  include Thor::Actions

  desc 'zzz', 'zzz'
  def zzz
    puts "zzz()"
  end
  
  desc 'aaa', 'aaa'
  def aaa
    puts "aaa()"
  end
  
  desc 'bbb', 'bbb'
  def bbb
    puts "bbb()"
  end
  
  desc 'ccc', 'ccc'
  def ccc
    puts "ccc()"
  end
  
end
