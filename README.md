# soundpad_helper
小键盘上的键发语音包都不够了，那就在手机上按吧，还能显示信息
- 添加web版
- 添加服务器
## 使用指南
#### 必须下载
- server.web.zip （服务器及web版）
#### 可选下载
- app-release.apk （安卓app）
- windows.zip （windows版）

### 使用
- 解压server.web.zip
- 双击或右击以管理员身份运行（在5E平台中）server.exe
- 在弹出的黑色窗口中找到类似`Running on http://192.168.71.247:24122`的信息（但不是`Running on http://127.0.0.1:24122`）
- 使用任何设备浏览器打开此地址（如`http://192.168.71.247:24122`）此即为控制端
- 在页面上方输入框中输入服务器地址 如`192.168.71.247:24122`注意不加`http://`！！！！注意不加`http://`！！！！注意不加`http://`！！！！，注意英文冒号`:`！！！！注意英文冒号`:`！！！！注意英文冒号`:`！！！！
- 点击右下角加号以添加控件
- 长按控件以编辑/删除/移动
- 右上角可保存配置到服务器/从服务器加载配置/切换每行显示的控件数
  

### 以下信息部分过期
### 使用时需安装python
- 双击lib\安装依赖.bat以安装所需库
- 双击lib\启动server.bat以启动服务端
- 请将显示出的地址之一填入手机app上方的输入框中
- 点击手机app右下角的+以添加控件
- 长按控件以编辑
- 标题随意，但副标题请填`不超过9位的数字`，且字串内`不可有重复数字`
- 单机控件以向服务器发送请求，服务器会按下`Alt+副标题对应的数字键`
- 请在soundpad-首选项-特殊热键中设置`Alt+0`为停止播放（app返回手势绑定到了此热键上
### 添加绑定大致流程
- 点击手机app右下角的`+`
- 在soundpad中打开`设置热键`页面
- 点击app中添加的控件
- 在soundpad中点击`确定`
- （按需在app中修改标题
### 更新
- 修改显示样式，增加移动位置功能
- 添加windows版
- ios及linux平台可自行编译
- 网页版由于跨域问题请自行探索
