# switchcc
claude code config switch tool

## usage
在`~/.claude`下创建配置，以`settings.json.`开头，比如`settings.json.instc` `settings.json.yes`
### 全局配置
```
./main.exe       # 列出所有配置
./main.exe ins    # 不需要完全匹配，会自动选择 settings.json.instc
./main.exe instc    # 切换到 settings.json.instc
./main.exe yes    # 切换到 settings.json.yes
```
### 目录配置
```
./main.exe -p ins      # 会把对应的配置文件复制过来,只对当前目录生效
```

## build
```
nim c -d:release main.nim
```
ps: 我本地使用zigcc交叉编译
