s3backup:
	cd /Users/masui/Gyazz; /opt/local/bin/ruby /Users/masui/bin/s3backup data GyazzData/GyazzData
clean:
	/bin/rm -f *~ */*~ */*/*~
push:
	git push pitecan.com:/home/masui/git/Gyazz.git
	git push git@github.com:masui/Gyazz.git
testrun:
	rackup config.ru -p 3000
test:
	ruby -Ilib lib/lib.rb
#	ruby lib/contenttype.rb
#	ruby lib/png.rb
#	ruby lib/keyword.rb
#	ruby lib/pair.rb
#	ruby tests/run_suite.rb
