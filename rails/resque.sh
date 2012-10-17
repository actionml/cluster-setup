rake resque:work QUEUE=cron --trace RAILS_ENV=production >> work.log &
rake resque:scheduler --trace RAILS_ENV=production >> schedule.log &

ps -fea | grep resque > resque_info.log
