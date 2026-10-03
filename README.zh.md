<p align="center">
  <img src="docs/images/logo.svg" alt="OryxOS" width="256"/>
</p>

<p align="center">
  <strong>分布式 AI Agent OS — 让 Agent 像操作系统里的进程一样运行和协作</strong>
</p>

<p align="center">
  <a href="https://github.com/xkmeng/oryxos/actions"><img src="https://img.shields.io/badge/build-maven-blue?style=flat-square&logo=apachemaven" alt="Build"/></a>
  <a href="https://www.java.com"><img src="https://img.shields.io/badge/Java-21-007396?style=flat-square&logo=openjdk&logoColor=white" alt="Java 21"/></a>
  <a href="https://spring.io/projects/spring-boot"><img src="https://img.shields.io/badge/Spring%20Boot-3.x-6DB33F?style=flat-square&logo=springboot&logoColor=white" alt="Spring Boot 3"/></a>
  <a href="https://modelcontextprotocol.io"><img src="https://img.shields.io/badge/MCP-compatible-8A2BE2?style=flat-square" alt="MCP"/></a>
  <a href="https://www.apache.org/licenses/LICENSE-2.0"><img src="https://img.shields.io/badge/license-Apache%202.0-blue?style=flat-square" alt="Apache 2.0"/></a>
</p>

<p align="center">
  <a href="README.md">English</a> · <strong>中文</strong>
</p>

---

OryxOS 是一个开源的**分布式 AI Agent OS**，基于 Java 21 构建。一份配置文件定义一个 Agent，一个平台运行一群 Agent。可以私有部署在企业自己的 K8s 或服务器上——Agent 像操作系统里的进程一样运行和协作，共享渠道接入、LLM 路由、工具调用、记忆和沙箱执行能力。你的数据永远不会离开你的基础设施。

> **长期愿景：** 进入 Apache 软件基金会，成为顶级项目。

## 为什么选择 OryxOS

开源 Agent 生态已经有成熟的运行时——但几乎全部基于 Python 或 Node.js，且面向个人或小团队。对于以 Java 为后端标准、私有部署是合规硬要求的企业来说，Java 生态中没有一个原生的、生产可用的 Agent OS。OryxOS 填补了这个空白。

更根本的是：**Agent 在生产中可靠的瓶颈不是模型，而是运行环境。** Agent 能否真正干活，取决于它是否能可靠地获取正确的上下文、受控的工具、隔离可审计的执行、可靠的消息投递。OryxOS 不是另一个 Agent——它是让一群 Agent 可靠运行的 OS 级底座。

### Agent OS vs Agent Runtime

| | Agent Runtime | Agent OS |
| --- | --- | --- |
| 范围 | 运行**一个** Agent | 运行并管理**一群** Agent |
| 类比 | 单个进程的执行环境 | 管理进程、调度资源、提供共享服务的 OS 层 |
| 提供 | 模型调用、工具执行、上下文管理、循环控制 | 生命周期、统一渠道、共享记忆、多租户、审计、跨节点协调 |

OryxOS 是后者。

## 核心特性

- 🤖 **配置即 Agent** — 一个 Profile YAML 定义一个 Agent，无需写代码。多个 Agent 可以在单个实例上共存。
- ☕ **Java 原生** — Java 21 + Virtual Thread。单个可执行 JAR。接入你现有的 Java 运维工具链——不需要 Python，不需要 Node.js。
- 🔒 **私有且合规** — 运行在你自己的 K8s、虚拟机或裸机上。数据不出环境。不锁定任何云生态。密钥来自环境变量/企业密钥管理——绝不写入配置文件。
- 🛡️ **安全是地基** — 每次工具调用都经过路径/命令/域名白名单检查。从第一天起就有完整的审计追踪：每次工具调用和 LLM 调用都持久化到审计数据库，不只是写日志。
- 🧠 **自实现 ReAct Loop** — 核心推理引擎手写实现，不委托给框架。循环行为完全由你掌控。
- 🔌 **开放标准** — 工具用 [MCP](https://modelcontextprotocol.io)，Agent 协作用 A2A，技能用 SKILL.md。与生态互操作，而不是发明新协议。
- 🧩 **三档工具扩展** — 从零代码 SKILL.md，到自定义 MCP Server，到原生 `@Tool` Java Bean。选择适合你的门槛。
- 💾 **跨对话记忆** — 会话记忆 + 长期记忆（MEMORY.md），Agent 能记住跨对话的偏好、项目和决策。
- 🌐 **无状态设计** — 实例不持有不可替代的状态，状态外置。这是走向分布式部署而不需要重新设计的前提。

## 架构

<p align="center">
  <img src="docs/images/architecture.svg" alt="OryxOS Architecture" width="100%"/>
</p>

> 🖱️ 想交互式浏览？打开 [docs/images/architecture.html](docs/images/architecture.html) — 支持主题切换、平移缩放和引导视图（ReAct 主路径 / 工具执行链 / 状态与审计）。

OryxOS 是一个 Spring Boot 应用，有两个入口——CLI 渠道和 REST API——都通向同一个引擎。**ReAct Loop** 就是引擎：组装 Prompt、通过 Provider 调用 LLM、通过沙箱检查的工具层执行工具、把结果反馈回去、重复直到得到最终回答（或达到迭代上限）。底层，会话和审计数据落在 SQLite；Profile、Bootstrap 文件、记忆和技能放在文件系统上，方便直接编辑和 git 追踪。

<p align="center">
  <img src="docs/images/react-loop.svg" alt="ReAct Loop" width="640"/>
</p>

## 五大核心能力

| 能力 | 你能得到什么 |
| --- | --- |
| **LLM 路由** | Provider 抽象统一主流模型（DeepSeek、Qwen、Kimi、OpenAI、Anthropic、Ollama、…）。Agent 与 Provider 解耦，改配置换模型，零代码改动。 |
| **ReAct Loop** | 自实现的推理引擎。LLM 决定是否调用哪个工具，OryxOS 执行并反馈结果，直到最终响应。每个 Profile 可配置最大迭代次数。 |
| **Memory** | 会话记忆 + 长期记忆。MEMORY.md 注入到每个 system prompt；Agent 通过 `save_memory` / `recall_memory` 工具读写。当前是关键词检索，接口已预留向量检索升级。 |
| **工具体系** | 8 个内置工具（文件、Shell、HTTP、记忆）。三种扩展方式：SKILL.md + 现有 MCP Server（零代码）、自定义 MCP Server（任意语言）、Java `@Tool` Bean（进程内）。 |
| **REST API** | 所有能力通过 HTTP 暴露在 `/api/v1`。任何能发 HTTP 请求的语言都能接入。 |

## 快速开始

**前提条件：** Java 21、Maven 3.9+、一个 LLM API key（如 DeepSeek）或本地推理端点（Ollama / vLLM）。

```bash
# 1. 构建
git clone https://github.com/xkmeng/oryxos.git
cd oryxos
mvn package -DskipTests

# 2. 初始化工作区（在当前目录创建 .oryxos/）
java -jar oryxos-boot/target/oryxos-boot-*.jar init

# 3. 提供 LLM API key
export DEEPSEEK_API_KEY=your-key-here

# 4. 和你的 Agent 对话
java -jar oryxos-boot/target/oryxos-boot-*.jar chat --profile default

# 或者启动 REST API
java -jar oryxos-boot/target/oryxos-boot-*.jar serve --port 8080
```

## 定义一个 Agent

每个 Agent 就是 `.oryxos/profiles/` 下的一个 YAML 文件——不需要写代码：

```yaml
name: ops-agent
description: 运维助手
identity:
  agent_name: 运维小欧
  prompt: 你是一个专业的运维助手...
provider:
  name: deepseek          # 换成 qwen / kimi / ollama — 零代码改动
  model: deepseek-chat
  temperature: 0.7
  api_key: ${DEEPSEEK_API_KEY}   # 通过环境变量注入
tools:
  - shell
  - read_file
  - http_get
  - save_memory
  - recall_memory
skills:
  - daily-pr-digest       # → .oryxos/skills/daily-pr-digest.md
mcp_servers:
  - github-mcp
bootstrap:
  - AGENTS.md             # 项目级 Agent 指导
  - SOUL.md               # Agent 人格定义
  - USER.md               # 用户偏好（只读）
settings:
  max_iterations: 10
  max_history_turns: 20
```

## 内置工具

| 工具 | 类 | 说明 |
| --- | --- | --- |
| `read_file` | `FileTools` | 读文件（路径白名单） |
| `write_file` | `FileTools` | 写文件（路径白名单） |
| `list_dir` | `FileTools` | 列目录（路径白名单） |
| `shell` | `ShellTools` | 执行 bash 命令（命令白名单 + 超时） |
| `http_get` | `HttpTools` | HTTP GET（域名白名单） |
| `http_post` | `HttpTools` | HTTP POST（域名白名单） |
| `save_memory` | `MemoryTools` | 追加到长期记忆（MEMORY.md） |
| `recall_memory` | `MemoryTools` | 关键词检索 MEMORY.md |

## 扩展 OryxOS

三档，选最低门槛够用的：

| 档位 | 门槛 | 方式 | 适用场景 |
| --- | --- | --- | --- |
| **零代码** ⭐ | 最低 | 写 SKILL.md 描述任务 + 复用社区 MCP Server | 大多数场景——LLM 自己组合现有工具 |
| **轻代码** | 中 | 用任意语言写 MCP Server，注册到 `mcp_servers.yaml` | 对接你的 ERP、CRM、内部系统 |
| **重代码** | 高 | Java 方法加 `@Tool` 注解，进程内直接调用 | 深度集成，最佳性能 |

## REST API

所有端点前缀为 `/api/v1`：

| 方法 | 路径 | 说明 |
| --- | --- | --- |
| `POST` | `/sessions` | 创建会话 |
| `POST` | `/sessions/{id}/messages` | 发消息（触发 ReAct Loop） |
| `GET` | `/sessions/{id}` | 查会话历史 |
| `DELETE` | `/sessions/{id}` | 归档会话 |
| `POST` | `/agents/{name}/invoke` | 无状态调用 Agent |
| `GET` | `/profiles` | 列所有 Profile |
| `GET` | `/memory` | 读长期记忆 |
| `GET` | `/tools` | 列可用工具 |
| `GET` | `/health` | 健康检查 |
| `GET` | `/info` | 运行信息 + Provider 状态 |

## CLI

```bash
oryxos init                      # 初始化 .oryxos/ 工作区
oryxos status                    # 查看配置和运行状态
oryxos chat [--profile <name>]   # 交互式多轮对话
oryxos serve [--port 8080]       # 启动 REST API 服务
oryxos gateway                   # 守护进程模式（多 Channel）

oryxos profile list | create | show | delete
oryxos provider list
oryxos tool list
oryxos session list
```

## 技术栈

| 组件 | 选型 |
| --- | --- |
| 语言 / 运行时 | Java 21（Virtual Thread） |
| 框架 | Spring Boot 3.x |
| LLM 集成 | Spring AI Alibaba（仅协议转换 + `@Tool` schema 生成） |
| HTTP | Spring MVC + Java 21 Virtual Thread |
| CLI | Picocli |
| YAML | SnakeYAML |
| 持久化 | SQLite + Spring Data JPA |
| 日志 | Logback + SLF4J（结构化 JSON） |
| 构建 | Maven 多模块 |

## 模块结构

```text
oryxos/
├── oryxos-core          # OryxTool 接口、Session、ReActLoop、PromptBuilder、ToolExecutor
├── oryxos-provider      # ProviderService、Function Calling 适配、多 Provider 显式映射
├── oryxos-memory        # MemoryService、LongTermMemory、MemoryTools (save/recall)
├── oryxos-tool          # 内置工具（文件/Shell/HTTP）、MCP Client、ToolRegistry、SandboxChecker
├── oryxos-channel-cli   # CLI 渠道：oryxos chat 实现
├── oryxos-web           # REST Controller、GlobalExceptionHandler、OpenAPI
├── oryxos-storage       # SQLite 仓库：sessions、tool_invocations、llm_calls
├── oryxos-cli           # Picocli 入口、12 个子命令、ConfigLoader
└── oryxos-boot          # Spring Boot 主类、自动配置、依赖聚合
```

模块之间通过接口解耦。新增 Channel 或 Tool 只加新模块——`oryxos-core` 不需要改。

## 与其他方案对比

| | **OryxOS** | Agent 框架（LangChain、Spring AI、…） | 编排平台（Dify、Coze、…） |
| --- | --- | --- | --- |
| 交付物 | 自托管的运行时底座，Agent 在里面运行 | 库/SDK——你写代码自己运行 | 拖拽节点构建的可视化工作流 |
| 用户 | 业务团队配置 Agent，开发者写工具 | 开发者 | 业务用户 / 开发者 |
| 部署 | 自己的机器，私有，开源 | 自己的运行环境 | 厂商云或自托管平台 |

它们是互补而非竞争：OryxOS 内部*使用*框架（Spring AI 做 LLM 协议转换），编排平台可以运行在 OryxOS 的 API *之上*。

## 路线图

> 我们的哲学：**慢就是快——克制且专注。** 先把单机运行时内核做扎实，让单节点上运行和管理一群 Agent 真正可用，再在此之上生长分布式能力。分布式是目标，但工程上先单机，一步一个脚印。

**第一阶段 — 单机运行时内核** *（当前）*
五大核心能力可用：配置即 Agent、多 Agent 共存、REST API、MCP 集成。目标：单节点运行和管理一群 Agent——真正可用。

**第二阶段 — 分布式底座** *（规划中）*
无状态实例，状态外置（Redis / PostgreSQL / 对象存储），多副本部署。更大规模和高可用。

**第三阶段 — 跨节点 Agent 协作** *（愿景）*
Agent 通信基础设施，A2A 协议集成。跨节点 Agent 发现、委托和可靠的异步协调。

*横向能力跨阶段落地：多租户、SSO、完整审计、工具策略、可观测性、Web 管理控制台。*

## 设计原则

- **底座优先于 Agent** — 最重要的交付不是某个强大的 Agent，而是让任意 Agent 可靠运行的环境
- **自实现核心，复用管道** — 推理循环手写；成熟库只用于协议适配，不重复造轮子
- **配置即 Agent** — 一个 Agent 由一份配置文件定义，而不是代码
- **对接开放标准** — 工具用 MCP，协作用 A2A，技能用 SKILL.md；与生态互操作，而不是发明协议
- **无状态实例，状态外置** — 走向分布式而不需要重新设计的前提
- **安全是地基，不是补丁** — 工具来源管控、最小权限、强制沙箱白名单、凭证不落盘、完整审计从第一天开始
- **分阶段克制** — 现在构建最小完整内核；治理和重型分布式基础设施必须被真实使用数据验证后再做

## 文档

| 文档 | 说明 |
| --- | --- |
| [docs/oryxos.md](docs/oryxos.md) | 项目概览：愿景、路线图、设计原则 |
| [docs/DemandAnalysis.md](docs/DemandAnalysis.md) | 需求分析：能力、范围档位、验收 Demo |
| [docs/TechnicalSolution.md](docs/TechnicalSolution.md) | 技术方案：关键决策、模块、数据模型 |
| [docs/IndustryResearch.md](docs/IndustryResearch.md) | 业界调研：Agent OS 格局和 Java 生态缺位 |
| [docs/AiProgrammingGuide.md](docs/AiProgrammingGuide.md) | AI 辅助开发指南：这个项目是如何构建的 |

## 贡献

欢迎贡献！OryxOS 以 AI 编程优先的方式开发——传统工作流也完全没问题：

1. Fork 仓库，从 `main` 创建你的分支
2. 做出你的改动（如适用，带测试）
3. `mvn verify` 通过
4. 提交一个描述清晰的 Pull Request

Good first issue 标记为 `good-first-issue`。较大的功能请先开 issue 讨论设计。

> "自实现 ReAct Loop" 和 "禁用 Spring AI 自动 tool 执行" 等工程原则在 [CLAUDE.md](CLAUDE.md) 中强制执行——动核心模块时请留意。

## 社区

OryxOS 是 [**oryx-labs**](docs/oryx-labs.md) 的旗舰项目——一个 AI 编程驱动的构建者社区，探索 AI 基础设施、Agent、AI 应用和 AI 工具，纯粹由好奇心驱动。

## 许可证

[Apache License 2.0](LICENSE) © oryx-labs
