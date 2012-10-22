s3backup:
	cd /Users/masui/Gyazz; /opt/local/bin/ruby /Users/masui/bin/s3backup data GyazzData/GyazzData
clean:
	/bin/rm -f *~ */*~ */*/*~
push:
	git push pitecan.com:/home/masui/git/Gyazz.git
	git push git@github.com:masui/Gyazz.git
test:
	ruby lib/contenttype.rb
	ruby lib/png.rb
	ruby tests/run_suite.rb
