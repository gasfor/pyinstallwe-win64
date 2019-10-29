# pyinstaller-win64
目的：将src目标文件的python程序编译为在windows 64bit上运行的exe程序，并且可以通过ssh发送指令到容器进行操作。基于cdrx/docker-pyinstaller的镜像修改完成

登陆方式：ssh，默认端口22

默认用户名：app-admin，密码app-admin。
            在docker容器的环境变量中，有SSH_USER和SSH_USER_PASSWORD可以设置使用的用户名及密码
            
root密码：随机生成16位密码，在容器的日志中会输出

其他：可以参考cdrx/docker-pyinstaller的readme.md
