s3backup:
	cd /Users/masui/Gyazz; /opt/local/bin/ruby /Users/masui/bin/s3backup data GyazzData/GyazzData
clean:
	/bin/rm -f *~ */*~ */*/*~
push:
	git push pitecan.com:/home/masui/git/Gyazz.git
	git push git@github.com:masui/Gyazz.git
testrun:
	bundle exec rackup config.ru -p 3000
test:
	bundle exec ruby tests/run_suite.rb
