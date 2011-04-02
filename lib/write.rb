# -*- coding: utf-8 -*-

require 'config'
require 'lib'

def write(postdata)
  #postdata = params[:data].split(/\n/)
  wikiname = postdata.shift
  pagetitle = postdata.shift
  browser_md5 = postdata.shift
  newdata = postdata.join("\n")+"\n"

  curfile = datafile(wikiname,pagetitle,0)
  server_md5 = ""
  curdata = ""
  if File.exist?(curfile) then
    curdata = File.read(curfile)
    server_md5 = md5(curdata)
  end

  Dir.mkdir(backupdir(wikiname)) unless File.exist?(backupdir(wikiname))
  Dir.mkdir(backupdir(wikiname,pagetitle)) unless File.exist?(backupdir(wikiname,pagetitle))

  if curdata != "" && curdata != newdata then
    File.open(newbackupfile(wikiname,pagetitle),'w'){ |f|
      f.print(curdata)
    }
  end

  if server_md5 == browser_md5 then
    File.open(curfile,"w"){ |f|
      f.print(newdata)
    }
    'noconflict'
  else
    # ブラウザが指定したMD5のファイルを捜す
    oldfile = backupfiles(wikiname,pagetitle).find { |f|
      md5(File.read(f)) == browser_md5
    }
    if oldfile then
      newfile = "/tmp/newfile#{$$}"
      patchfile = "/tmp/patchfile#{$$}"
      File.open(newfile,"w"){ |f|
        f.print newdata
      }
      system "diff -c #{oldfile} #{newfile} > #{patchfile}"
      system "patch #{curfile} < #{patchfile}"
      File.delete newfile, patchfile
    else
      File.open(curfile,"w"){ |f|
        f.print newdata
      }
    end
    'conflict'
  end
end

