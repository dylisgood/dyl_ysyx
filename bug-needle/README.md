# Bug Needle: 半自动化Bug注射器

可用于“一生一芯”在线调试考核的离线练习.

注意: 使用前尽可能保证ysyx-workbench中代码已经通过git commit提交, 否则你可能难以发现注入的bug.

使用流程:
1. 执行以下命令注入bug
   ```bash
   YSYX_HOME=ysyx-workbench的路径 python needle.py
   ```
1. 编译你的项目, 若编译报错, 跳转到最后一步
1. 运行你的项目, 若运行成功, 跳转到最后一步
1. 开始调试练习, 若调试成功, 本次练习通过, 结束本流程
1. 在ysyx-workbench目录下执行`git diff`观察并手动移除注入的bug, 可跳转到第一步重新练习

可通过定义环境变量`DEBUG`来输出`sed`命令和注入的bug, 供调试本工具使用. 如
```bash
DEBUG=1 YSYX_HOME=ysyx-workbench的路径 python needle.py
```

半自动化的原因: 目前尚无法保证注入的bug可以通过编译, 也无法保证注入的bug可以使得程序运行出错, 故需要手动介入.

TODO:
* 添加更多bug规则(欢迎大家贡献!)
* 支持NPC和环境bug的注入
