#!/usr/bin/env python3

import logging
import os
import subprocess
import sys
import time
from logging import handlers


class Logger(object):
    level_relations = {
        'debug': logging.DEBUG,
        'info': logging.INFO,
        'warning': logging.WARNING,
        'error': logging.ERROR,
        'crit': logging.CRITICAL
    }  # 日志级别关系映射

    def __init__(self, filename, level='info', when='D', backCount=3, fmt='%(asctime)s - %(pathname)s[line:%(lineno)d] - %(levelname)s: %(message)s'):
        self.logger = logging.getLogger(filename)
        format_str = logging.Formatter(fmt)  # 设置日志格式
        self.logger.setLevel(self.level_relations.get(level))  # 设置日志级别
        sh = logging.StreamHandler()  # 往屏幕上输出
        sh.setFormatter(format_str)  # 设置屏幕上显示的格式
        th = handlers.TimedRotatingFileHandler(filename=filename, when=when, backupCount=backCount, encoding='utf-8')  # 往文件里写入#指定间隔时间自动生成文件的处理器
        # 实例化TimedRotatingFileHandler
        # interval是时间间隔，backupCount是备份文件的个数，如果超过这个个数，就会自动删除，when是间隔的时间单位，单位有以下几种：
        # S 秒
        # M 分
        # H 小时、
        # D 天、
        # W 每星期（interval==0时代表星期一）
        # midnight 每天凌晨
        th.setFormatter(format_str)  # 设置文件里写入的格式
        self.logger.addHandler(sh)  # 把对象加到logger里
        self.logger.addHandler(th)


def amd_fan_setting():
    process = subprocess.Popen("echo 123 | sudo -S bash amdgputools.sh -f 30", shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    process.wait()
    msg = str(process.stdout.read(), encoding='utf-8').lstrip().replace("\n", "")
    if 'error' in msg.lower():
        log.logger.critical('执行错误!')
        return False, 0
    elif process.returncode == 0:
        log.logger.info('执行成功!')
        return True, 1
    else:
        log.logger.error('未知错误!')
        log.logger.error(msg)
        log.logger.error(str(process.stderr.read(), encoding='utf-8').lstrip().replace("\n", ""))
        return False, -1


def run_amd_fan_setting():
    for try_num in range(1, 4):
        log.logger.info('开始第%s次设置风扇风速!' % try_num)
        result = amd_fan_setting()
        if result[0]:
            return True
        else:
            log.logger.warning('等待5s后重试...')
            time.sleep(5)
    log.logger.error('执行失败!')
    return False


def run_aria2():
    process = subprocess.Popen("/usr/bin/env aria2c -c /home/jlyy/.aria2/aria2.conf -D", shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    process.wait()
    if process.returncode == 0:
        log.logger.info("启动aria2c服务成功!")
    else:
        log.logger.error("启动aria2c服务失败!")
        log.logger.error(str(process.stdout.read(), encoding='utf-8').lstrip().replace("\n", ""))
        log.logger.error(str(process.stderr.read(), encoding='utf-8').lstrip().replace("\n", ""))


if __name__ == '__main__':
    os.chdir(os.path.abspath(os.path.dirname(sys.argv[0])))
    log = Logger('/tmp/setting_amd_fan.log', level='debug')
    # log.logger.debug('debug')
    # log.logger.info('info')
    # log.logger.warning('警告')
    # log.logger.error('报错')
    # log.logger.critical('严重')
    run_amd_fan_setting()  # 设置显卡风扇
    run_aria2()  # 启动下载服务
    exit(0)
