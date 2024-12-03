# Koober应用架构设计文档


# 1. 架构概述

## 身份认证阶段 

### 1.1 依赖注入容器层次
```swift
// 1. 应用容器(App Container)
class KooberAppContainer {
    // 全局共享依赖
    let userSessionRepository: UserSessionRepository
    let mainViewModel: MainViewModel
    init(){
        // 创建全局依赖
        self.userSessionRepository = Self.makeUserSessionRepository() 
        self.mainViewModel = makeMainViewModel() 
    }
    // 子容器工厂
    func makeOnboardingContainer() -> KooberOnboardingContainer{}
}



// 2. 登录注册容器(Onboarding Container) 
class KooberOnboardingContainer {
    // 从父容器获取的依赖
    let userSessionRepository: UserSessionRepository
    let mainViewModel: MainViewModel
    
    // 容器内共享依赖
    let onboardingViewModel: OnboardingViewModel

    init(
        parent: KooberAppContainer 
    ){
        self.userSessionRepository = parent.userSessionRepository
        self.mainViewModel = parent.mainViewModel
        self.onboardingViewModel = makeOnboardingViewModel()
    }


}
```


### 1.2 核心协议
```swift
// 1. 数据存储
protocol UserSessionDataStore {
    func save(_ session: UserSession) throws
    func getCurrentSession() -> UserSession?
}

// 2. 远程API
protocol AuthRemoteAPI {
    func signIn(credentials: Credentials) async throws -> UserSession  
    func signUp(user: User) async throws -> UserSession
}

// 3. 状态响应
protocol NotSignedInResponder {
    func handleNotSignedIn()
}
// 4. 状态响应
protocol SignedInResponder { 
    func handleSignedIn()
}

    
protocol UserSessionCoding {
    func encode(_ session: UserSession) throws -> Data
    func decode(_ data: Data) throws -> UserSession
}

protocol UserSessionRepository {
    var userSessionDataStore: UserSessionDataStore { get }
    var authRemoteAPI: AuthRemoteAPI { get }
}
```

## 2. 依赖关系图

### 2.1 视图层依赖
```括号内是协议
MainView
├── LaunchView
│   └── LaunchViewModel
│        --- KooberUserSessionRepository(UserSessionRepository)
│        --- MainViewModel(SignedInResponder, NotSignedInResponder)
│      
└── OnboardingView --- OnboardingViewModel
    ├── WelcomeView
    │   └── WelcomeViewModel
    │       --- OnboardingViewModel
    │    
    ├── SignInView 
    │   └── SignInViewModel
    │        --- KooberUserSessionRepository(UserSessionRepository)
    │        --- MainViewModel(SignedInResponder)
    └── SignUpView
        └── SignUpViewModel
             --- KooberUserSessionRepository(UserSessionRepository)
             --- MainViewModel(SignedInResponder)
```

### 2.2 仓储层依赖
```括号内是协议
UserSessionRepository
├── FakeAuthRemoteAPI(AuthRemoteAPI)
└── KeychainUserSessionDataStore(UserSessionDataStore)
│       └── UserSessionPropertyListCoder(UserSessionCoding)
```

## 3. 关键实现说明

### 3.1 依赖注入原则
- 使用初始化器注入
- 避免使用环境值
- 通过容器管理依赖生命周期

### 3.2 容器职责
- AppContainer: 管理全局共享依赖
- OnboardingContainer: 管理登录注册流程依赖

### 3.3 测试策略
- 所有依赖基于协议
- 可以方便注入Mock实现
- 子容器可以独立测试



# 各个模块的职责

根据提供的架构设计文档和代码，我来总结一下各个模块的职责：

## 1. 容器层职责

### AppContainer
- 管理全局共享依赖
- 创建和维护 UserSessionRepository
- 创建和维护 MainViewModel 
- 负责创建子容器(如 OnboardingContainer)

### OnboardingContainer
- 管理登录注册流程相关依赖
- 从父容器获取共享依赖
- 创建和维护 OnboardingViewModel

## 2. 视图层职责

### MainView
- 应用的根视图
- 负责在已登录和未登录状态间切换
- 管理子视图的展示逻辑

### LaunchView
- 应用启动页面
- 检查用户登录状态
- 根据状态决定展示登录还是主页面

### OnboardingView
- 登录注册流程的容器视图
- 管理登录注册相关子视图的切换
- 包含:
  - WelcomeView: 欢迎页面
  - SignInView: 登录页面
  - SignUpView: 注册页面

## 3. ViewModel层职责

### MainViewModel
- 实现 SignedInResponder 和 NotSignedInResponder 协议
- 管理全局登录状态
- 处理登录状态变化的响应

### LaunchViewModel
- 与 UserSessionRepository 交互检查登录状态
- 通知 MainViewModel 当前登录状态

### OnboardingViewModel
- 管理整个登录注册流程的状态
- 协调各个子ViewModel之间的交互

### SignInViewModel/SignUpViewModel
- 处理具体的登录/注册业务逻辑
- 与 UserSessionRepository 交互进行认证
- 认证成功后通知 MainViewModel

## 4. 数据层职责

### UserSessionRepository
- 统一管理用户会话数据
- 协调远程API和本地存储
- 包含:
  - AuthRemoteAPI: 处理远程认证请求
  - UserSessionDataStore: 管理本地会话存储
  - UserSessionCoding: 处理会话数据编解码


## 模型层 

```thinking
是的,您说得对。我需要重新思考name的定位...

name的本质:
1. 仅是显示用的称呼
2. 不参与身份验证
3. 可以随时修改
4. 可以重复

而email和id才是关键标识:
1. email - 登录凭证
2. id - 系统唯一标识

让我重新设计这部分...
```

## 模型层

### 1. User:
- 代表用户的基本信息
- id: 系统唯一标识(不可变)
- email: 登录凭证(不可变) 
- name: 显示名称(可变)
- 需要持久化存储(Codable)

### 2. UserSession:
- 代表已登录状态的会话信息
- 包含User信息和认证token
- 需要持久化存储(Codable)
- 用于验证用户是否登录

### 3. AuthCredentials:
- 仅用于登录请求的输入数据
- email: 登录标识
- password: 密码
- 不需要持久化
- 使用完即丢弃

### 4. SignUpCredentials:
- 仅用于注册请求的输入数据
- email: 将作为登录标识
- password: 密码
- name: 显示名称(可选)
- 不需要持久化
- 使用完即丢弃

### 数据流转:

1. 注册流程:
```
客户端                      服务器                        数据库
SignUpCredentials           
email: "user@email.com"    1.验证email唯一性    ------>  检查email是否存在
password: "123456"  -----> 2.对密码进行哈希处理          
name: "John"(可选)         password -> hash("123456")    存储用户信息:
                                                        id: "user_123"
                          3.生成用户唯一id              email: "user@email.com"
                          4.创建用户记录                passwordHash: "e10adc..."
                          5.生成token                   name: "John"
                          
                    <----- 返回UserSession
                          {
                            user: {
                              id: "user_123",      // 系统唯一标识
                              email: "user@email.com", // 登录凭证
                              name: "John"         // 仅用于显示
                            },
                            token: "xyz789"
                          }
```

2. 登录流程:
```
客户端                      服务器                        数据库
AuthCredentials           
email: "user@email.com"    1.通过email查找用户   ------>  查询用户信息:
password: "123456"  -----> 2.验证密码                    id: "user_123"
                                                        email: "user@email.com"
                                                        passwordHash: "e10adc..."
                                                        name: "John"
                          
                    <----- 返回UserSession (结构同上)
```

关键区别:
1. id是系统内部的唯一标识
2. email是用户登录的唯一标识
3. name仅用于显示,可以:
   - 重复
   - 修改

这样的设计更准确地反映了:
1. 数据的用途
2. 字段的重要程度
3. 可变性要求



````thinking
让我分析一下需要补充的内容...

从用户故事看,核心MVP流程是:
1. 叫车流程:
- 定位服务
- 目的地选择 
- 车型选择
- 等待接驾

需要按照原有架构格式设计:
1. 依赖注入容器
2. 核心协议
3. 视图层依赖
4. 数据模型

关键点:
- 保持与认证阶段相同的架构风格
- 只包含MVP必需功能
- 复用已有的容器体系
````

````markdown:koober-arch.md
## 叫车阶段

### 1.1 依赖注入容器层次
```swift
// 1. 主页面容器(Main Container)
class KooberMainContainer {
    // 从父容器获取的依赖
    let userSessionRepository: UserSessionRepository
    
    // 容器内共享依赖
    let locationService: LocationService
    let rideService: RideService
    let mainViewModel: MainViewModel
    
    init(parent: KooberAppContainer) {
        self.userSessionRepository = parent.userSessionRepository
        self.locationService = Self.makeLocationService()
        self.rideService = Self.makeRideService()
        self.mainViewModel = Self.makeMainViewModel()
    }
}
```

### 1.2 核心协议
```swift
// 1. 位置服务
protocol LocationService {
    func getCurrentLocation() async throws -> Location
    func searchLocation(query: String) async throws -> [Location]
}

// 2. 叫车服务
protocol RideService {
    func requestRide(pickup: Location, 
                    destination: Location,
                    vehicleType: VehicleType) async throws -> Ride
    func cancelRide(id: String) async throws
    func getRideStatus(id: String) async throws -> RideStatus
}

// 3. 状态响应
protocol RideStateResponder {
    func handleRideRequested(_ ride: Ride)
    func handleRideCancelled()
    func handleRideCompleted()
}
```

### 2.1 视图层依赖
```括号内是协议
MainView
├── MapView
│   └── MapViewModel
│        --- LocationService
│      
└── RideView --- RideViewModel
    ├── LocationSearchView
    │   └── LocationSearchViewModel
    │       --- LocationService
    │    
    ├── VehicleSelectionView 
    │   └── VehicleSelectionViewModel
    │        --- RideService
    └── RideStatusView
        └── RideStatusViewModel
             --- RideService
             --- RideStateResponder
```

## 模型层

### 1. Location:
```swift
struct Location: Codable {
    let latitude: Double
    let longitude: Double
    let address: String?
}
```

### 2. VehicleType:
```swift
enum VehicleType: String, Codable {
    case wallaby   // 小型
    case wallaroo  // 中型
    case kangaroo  // 大型
}
```

### 3. Ride:
```swift
struct Ride: Codable {
    let id: String
    let pickup: Location
    let destination: Location
    let vehicleType: VehicleType
    let status: RideStatus
}
```

### 4. RideStatus:
```swift
enum RideStatus: String, Codable {
    case requested
    case accepted
    case arrived
    case inProgress
    case completed
    case cancelled
}
```

### 数据流转:

1. 叫车流程:
```
客户端                      服务器                        数据库
1. 获取当前位置
getCurrentLocation() 
                          
2. 搜索目的地             
searchLocation()           地点搜索API
                          
3. 选择车型并发起叫车
requestRide()      -----> 1.创建行程记录    ------>     存储行程信息
                         2.寻找可用车辆              
                         3.分配司机
                         
                   <----- 返回Ride对象
                         {
                           id: "ride_123",
                           pickup: {...},
                           destination: {...},
                           vehicleType: "wallaby",
                           status: "requested"
                         }

4. 获取行程状态
getRideStatus()    -----> 查询行程状态     ------>     获取最新状态
```
````

## 细节讲解

好的,我来详细解释一下每个部分的含义:

## 容器类

### KooberMainContainer
主页面的依赖注入容器,负责管理叫车流程相关的所有依赖:
- `locationService`: 提供位置相关服务
- `rideService`: 提供叫车相关服务 
- `mainViewModel`: 管理主页面状态

## 核心服务

### LocationService
位置服务接口:
- `getCurrentLocation()`: 获取用户当前位置
- `searchLocation(query:)`: 根据关键词搜索地点

### RideService 
叫车服务接口:
- `requestRide()`: 发起叫车请求,需要提供:
  - pickup: 上车地点
  - destination: 目的地
  - vehicleType: 车型
- `cancelRide()`: 取消指定ID的行程
- `getRideStatus()`: 查询指定ID的行程状态

### RideStateResponder
行程状态响应接口:
- `handleRideRequested`: 处理叫车成功事件
- `handleRideCancelled`: 处理行程取消事件
- `handleRideCompleted`: 处理行程完成事件

## 视图模型

### MapViewModel
地图视图的业务逻辑:
- 显示当前位置
- 显示目的地标记
- 显示路线

### LocationSearchViewModel
地点搜索视图的业务逻辑:
- 处理搜索输入
- 展示搜索结果
- 选择地点

### VehicleSelectionViewModel
车型选择视图的业务逻辑:
- 展示可用车型
- 显示价格信息
- 处理车型选择

### RideStatusViewModel
行程状态视图的业务逻辑:
- 展示当前行程状态
- 处理取消行程
- 更新等待时间

## 数据模型

### Location
位置信息模型:
- `latitude`: 纬度
- `longitude`: 经度
- `address`: 地址文本(可选)

### VehicleType
车型枚举:
- `wallaby`: 小型(沙袋鼠)
- `wallaroo`: 中型(硕袋鼠)
- `kangaroo`: 大型(大袋鼠)

### Ride
行程信息模型:
- `id`: 行程唯一标识
- `pickup`: 上车地点
- `destination`: 目的地
- `vehicleType`: 车型
- `status`: 当前状态

### RideStatus
行程状态枚举:
- `requested`: 已发起请求
- `accepted`: 司机已接单
- `arrived`: 司机已到达
- `inProgress`: 行程进行中
- `completed`: 行程已完成
- `cancelled`: 行程已取消

这些类和服务共同构成了一个最小可行的叫车系统,每个组件都有明确的单一职责,通过依赖注入方式组合在一起。
