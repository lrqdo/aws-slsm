# AWS Simple linux server monitoring

Ruby cron to AWS cloudwatch based monitoring.


## Introduction

If you
- do not want to manage your monitoring solution,
- you are using AWS

Then this simple script is probably something you are searching for.

No infrastructure to manage, you just need
- `ruby` and `cron` on your server
- `cloudwatch` `put_metric` right


## How to setup

Your instance should have the following AWS IAM policy:
```
cloudwatch:PutMetricData
cloudwatch:PutMetricAlarm
cloudwatch:DeleteAlarms
```

```sh
gem install aws-sdk-cloudwatch

mkdir -p /usr/local/shared/aws-simple-linux-server-monitoring/{lib,plugins}
mkdir -p /var/lib/aws-simple-linux-server-monitoring
mkdir -p /etc/aws-slsm

cp etc/aws-slsm/config.yml /etc/aws-slsm
cp src/aws-slsm /usr/local/bin
cp etc/init.d/aws-slsm /etc/init.d/
cp etc/cron.d/aws-slsm /etc/cron.d/

rsync -Wav lib/ /usr/local/shared/aws-simple-linux-server-monitoring/lib
rsync -Wav plugins/ /usr/local/shared/aws-simple-linux-server-monitoring/plugins
```

You should personnalize `/etc/aws-slsm/config.yml`
