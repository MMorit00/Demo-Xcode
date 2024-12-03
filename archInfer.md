# 需求推动架构递推

身份认证故事组告诉我们:
- 新用户第一次进入需要注册
- 老用户需要登录
- 登录成功后才能使用核心功能
这暗示了一个重要的状态流转:未认证 -> 认证中 -> 已认证

推测出 

1. 需要一个LaunchView 作为App入口检查用户是否认证
2. 未认证用户需要注册或者登录
3. 进而推理出需要一个OnboardingView 作为登录或者注册的入口
4. 要有一个onboardingView的主要视图用来提供注册或者登录的按钮
5. 所以我们讲OnboardingView拆分成3个视图: WelcomeView, SignInView, SignUpView
6. 各个视图处理自己的逻辑，注册完或者登录完则视图跳转为MapView,来处理整个叫车流程 
7.  继续mainView -> 协调子视图切换(- LaunchView (启动检查)- OnboardingView (登录注册)- MapView (叫车主界面))
   - 从用户故事我们知道:
     - 用户需要在未认证时进入登录注册流程
     - 认证后需要进入地图叫车流程
     - 可能需要退出登录返回登录界面
8. MainView(LaunchView -> OnboardingView -> WelcomeView, SignInView, SignUpView -> MapView)
9.  这样我们就思考出了KooberApp的登录注册流程的视图架构 >>>> 视图架构 
10. 我们开始通过视图架构来思考KooberApp的ViewModel架构 
11. 我们先思考各个view的职责，进而推理出各个view的ViewModel的职责 
12. LaunchView
    1. 需要知道用户**是否认证**来决定跳转到哪个视图
13. OnboardingView 出现在LaunchView之后，是没有认证的用户
    1. WelcomeView 是OnboardingView的第一个视图，提供注册或者登录的按钮
    2. SignInView 是OnboardingView的第二个视图，提供登录的逻辑 -> 通过**表单处理登录**
    3. SignUpView 是OnboardingView的第三个视图，提供注册的逻辑 -> 通过**表单处理注册**
14. MapView 出现在OnboardingView之后，是认证的用户(我们先不讨论叫车流程)
15. 这就得出了相应视图对应的ViewModel的职责
    1. LaunchViewModel 需要知道用户是否认证来决定跳转到哪个视图
    2. WelcomeViewModel 需要提供注册或者登录的按钮，跳转视图 -> ==这个viewModel 是否需要砍掉== 
    3. SignInViewModel 需要提供登录的逻辑 -> 通过**表单处理登录**
    4. SignUpViewModel 需要提供注册的逻辑 -> 通过**表单处理注册**
    5. MainViewModel 需要协调子视图切换
16. 通过viewModel的职责，我们可以继续向底层架构推理
17. LaunchViewModel需要：
    1. 检查用户是否认证 -> 需要一个管理用户会话的组件
    2. 这个组件需要能够检查用户是否已经认证
    3. 这个组件需要能够持久化认证状态
    4. 我们需要一个Repository来管理用户会话
18. 深入思考UserSessionRepository的职责
    1. 需要检查用户认证状态
    2. 需要存储用户认证信息
    3. 需要更新用户认证状态
    4. 需要清除用户认证信息
19. UserSessionRepository要完成这些职责需要依赖什么？
    1. 检查用户认证状态 -> 需要从某个地方读取状态(RemoteAPI)
    2. 存储用户认证信息 -> 需要安全的存储机制
    3. 更新用户认证状态 -> 需要能修改存储的数据
    4. 清除用户认证信息 -> 需要能删除存储的数据
    所以需要一个KeychainUserSessionDataStore来安全存储这些信息
    和RemoteAPI来读取认证状态
20. KeychainUserSessionDataStore需要存储什么数据？
    1. 用户的认证令牌
    2. 用户的基本信息
    3. 认证的过期时间
    这些数据需要序列化和反序列化，所以需要一个UserSessionPropertyListCoder
21. SignInViewModel和SignUpViewModel需要处理登录注册
    1. 需要发送认证请求到服务器(RemoteAPI)
    2. 需要处理服务器响应
    3. 需要存储认证结果(UserSessionRepository)
    所以需要一个AuthRemoteAPI来处理远程认证
25. WelcomeViewModel的职责分析
    1. 从视图职责我们知道WelcomeView需要:
       - 提供注册按钮
       - 提供登录按钮
       - 处理按钮点击后的视图跳转
    2. 所以WelcomeViewModel需要:
       - 提供跳转到注册的方法
       - 提供跳转到登录的方法
       - 需要一个机制来通知视图切换(SignInResponder)

26. OnboardingViewModel的职责分析
    1. 从视图职责我们知道OnboardingView需要:
       - 管理子视图状态(Welcome/SignIn/SignUp)
       - 协调子视图之间的切换
       - 处理认证成功后的跳转
    2. 所以OnboardingViewModel需要:
       - 管理当前显示的子视图状态
       - 提供切换子视图的方法
       - 监听认证状态的变化(UserSessionRepository)
       - 处理认证成功后的视图跳转(SignedInResponder)
  
27. MainViewModel需要协调子视图切换
    1. 需要管理子视图状态
       - LaunchView状态
       - OnboardingView状态
       - MapView状态
    2. 需要处理视图切换逻辑
       - 未认证 -> 显示OnboardingView
       - 已认证 -> 显示MapView
       - 退出登录 -> 返回OnboardingView
    3. 需要响应认证状态变化
       - 监听UserSessionRepository的认证状态(userSessionRepository)
       - 根据状态变化切换相应视图(SignInResponder, NotSignedInResponder)
28. 梳理完整的认证流程
    1. 用户输入认证信息
    2. ViewModel调用AuthRemoteAPI
    3. AuthRemoteAPI返回认证结果
    4. ViewModel将结果交给UserSessionRepository
    5. UserSessionRepository使用KeychainUserSessionDataStore存储
    6. UserSessionRepository使用UserSessionPropertyListCoder编码数据



## 整理ViewModel依赖关系 

24. 我们得到大概得流程后- > 梳理一下各个viewModel 的依赖关系 




1. MainViewModel的核心职责:
   - 实现SignedInResponder和NotSignedInResponder
   - 控制三个主要视图的跳转(Launch/Onboarding/Map)
   - 监听UserSessionRepository的认证状态

2. LaunchViewModel的依赖:
   - 依赖MainViewModel(通过SignedInResponder和NotSignedInResponder)
   - 依赖UserSessionRepository(检查认证状态)
   所以LaunchViewModel在启动时:
   - 通过UserSessionRepository检查状态
   - 通过MainViewModel提供的Responder处理跳转

3. SignInViewModel的依赖:
   - 依赖MainViewModel(通过SignedInResponder)
   - 依赖AuthRemoteAPI()
   - 依赖UserSessionRepository(存储认证结果)
   - 退回WelcomeView
   所以SignInViewModel在登录时:
   - 通过AuthRemoteAPI发送请求
   - 通过UserSessionRepository保存结果
   - 通过MainViewModel的Responder处理跳转
   - 退回WelcomeView(依赖于OnboardingViewModel)

4. SignUpViewModel的依赖:
   - 依赖MainViewModel(通过SignedInResponder)
   - 依赖AuthRemoteAPI(处理注册请求)
   - 依赖UserSessionRepository(存储认证结果)
   - 退回WelcomeView(依赖于OnboardingViewModel)
   所以SignUpViewModel在注册时:
   - 通过AuthRemoteAPI发送请求
   - 通过UserSessionRepository保存结果
   - 通过MainViewModel的Responder处理跳转
   - 退回WelcomeView(依赖于OnboardingViewModel)


5. OnboardingViewModel的特殊性:
   - 不依赖其他组件
   - 只负责Welcome/SignIn/SignUp三个子视图间的切换
   - 纯粹的视图状态管理和导航控制

6. 所以WelcomeViewModel需要:
    - 依赖于OnboardingViewModel
   - 提供跳转到注册的方法
   - 提供跳转到登录的方法



## 整理Service

1. 分析UserSessionRepository的职责:
   1. 需要检查用户认证状态
   2. 需要存储用户认证信息
   3. 需要更新用户认证状态
   4. 需要清除用户认证信息
   所以UserSessionRepository需要:
   - 提供检查认证状态的方法
   - 提供存储和更新认证信息的方法
   - 提供清除认证信息的方法
   - 依赖AuthRemoteAPI进行远程认证
   - 依赖SessionDataStore进行本地存储

2. 分析AuthRemoteAPI的职责:
   1. 需要处理登录请求
   2. 需要处理注册请求
   3. 需要处理认证状态验证
   所以AuthRemoteAPI需要:
   - 提供登录方法
   - 提供注册方法
   - 提供验证token方法
   - 处理网络请求和响应
   - 处理错误情况

3. 分析SessionDataStore的职责:
   1. 需要安全存储认证信息
   2. 需要读取存储的认证信息
   3. 需要删除认证信息
   所以SessionDataStore需要:
   - 提供存储方法
   - 提供读取方法
   - 提供删除方法
   - 内部处理数据编解码
   - 处理错误情况

4. 分析SessionCoding的职责:
   1. 需要序列化用户会话数据
   2. 需要反序列化用户会话数据
   所以SessionCoding需要:
   - 提供编码方法
   - 提供解码方法
   - 定义数据结构

5. 服务层之间的依赖关系:
   1. UserSessionRepository依赖:
      - AuthRemoteAPI (远程认证)
      - SessionDataStore (本地存储)
   2. SessionDataStore依赖:
      - SessionCoding (内部使用)
   3. AuthRemoteAPI独立:
      - 不依赖其他服务
      - 只负责网络请求



