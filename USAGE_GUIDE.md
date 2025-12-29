# 记账本 App 数据层使用指南

## 📋 配置完成情况

✅ **ArkTS 兼容性修复**：重构所有代码以符合 OpenHarmony ArkTS 严格语法要求
- 移除所有 `any` 类型使用
- 修复对象字面量类型定义
- 规范错误处理方式
- 移除不支持的语法特性

✅ **数据库初始化**：在 `EntryAbility.ets` 的 `onCreate` 方法中自动初始化

✅ **资源清理**：在 `EntryAbility.ets` 的 `onDestroy` 方法中自动关闭数据库连接

✅ **测试界面**：`Index.ets` 页面提供数据库功能测试按钮

✅ **构建成功**：项目已通过 DevEco Studio 构建验证

## 🚀 如何使用

### 1. 直接运行项目

```bash
# 在 DevEco Studio 中点击运行按钮或使用命令行
hvigorw assembleHap --mode module -p product=default -p buildMode=debug
```

### 2. 在代码中使用数据层

```typescript
import { DatabaseHelper } from '../data/DatabaseHelper';

// 获取 Dao 实例
const categoryDao = DatabaseHelper.getCategoryDao();
const transactionDao = DatabaseHelper.getTransactionDao();

// 添加分类
const categoryId = await categoryDao.insertCategory({
  name: '餐饮',
  icon_name: 'food',
  type: 0  // 支出分类
});

// 添加交易记录
await transactionDao.insertTransaction({
  type: 0,        // 支出
  amount: 25.50,  // 金额
  category_id: categoryId,
  date: Date.now(),
  note: '午餐'
});

// 查询交易记录
const transactions = await transactionDao.getTransactions({
  type: 0,  // 只查支出
  limit: 20 // 限制20条
});
```

### 3. 测试功能

运行应用后，在主页面点击以下按钮测试：

- **测试数据库初始化**：验证数据库是否正常初始化
- **添加测试数据**：添加示例分类和交易记录
- **查询数据**：查看已添加的数据
- **月度统计测试**：测试聚合查询功能

## 🔧 核心 API 说明

### DatabaseHelper（统一入口）
```typescript
// 初始化（应用启动时自动调用）
await DatabaseHelper.initialize();

// 获取 Dao 实例
const categoryDao = DatabaseHelper.getCategoryDao();
const transactionDao = DatabaseHelper.getTransactionDao();

// 关闭连接（应用退出时自动调用）
await DatabaseHelper.close();
```

### CategoryDao（分类管理）
```typescript
// 新增分类
const id = await categoryDao.insertCategory({ name: '餐饮', icon_name: 'food', type: 0 });

// 查询所有分类
const categories = await categoryDao.getAllCategories();

// 按类型查询（0=支出，1=收入）
const expenseCategories = await categoryDao.getCategoriesByType(0);
```

### TransactionDao（交易管理）
```typescript
// 新增交易
await transactionDao.insertTransaction({
  type: 0,
  amount: 25.50,
  category_id: 1,
  date: Date.now(),
  note: '备注'
});

// 查询交易（支持多种条件）
const transactions = await transactionDao.getTransactions({
  type: 0,           // 交易类型
  startDate: timestamp, // 开始时间
  endDate: timestamp,   // 结束时间
  categoryId: 1,     // 分类ID
  limit: 50          // 限制条数
});

// 月度统计
const stats = await transactionDao.getMonthlyCategoryStats(2024, 1, 0);

// 支出占比（饼图数据）
const ratios = await transactionDao.getMonthlyExpenseRatio(2024, 1);
```

## 📊 数据结构

### 分类表 (T_Categories)
- `id`: 主键，自增
- `name`: 分类名称
- `icon_name`: 图标标识
- `type`: 0=支出分类，1=收入分类

### 交易表 (T_Transactions)
- `id`: 主键，自增
- `type`: 0=支出，1=收入
- `amount`: 交易金额
- `category_id`: 分类外键
- `date`: 时间戳（毫秒）
- `note`: 备注

## 🔧 ArkTS 兼容性说明

本数据层已完全适配 OpenHarmony 的 ArkTS 语法要求：

### ✅ 已实现的兼容性特性

1. **类型安全**
   - 移除所有 `any` 类型，全部使用明确的类型声明
   - 接口定义使用独立的 `interface` 声明
   - 函数参数和返回值都有明确的类型标注

2. **对象字面量规范**
   - 所有对象字面量都对应明确的接口类型
   - 避免使用 `Record<string, any>` 等不安全类型
   - 使用 `Record<string, number | string>` 进行精确类型控制

3. **错误处理规范**
   - `throw` 语句只接受 `Error` 对象，不接受任意类型
   - 异常信息使用明确的字符串消息
   - 所有异步操作都有 `try-catch` 保护

4. **语法限制遵守**
   - 不使用解构赋值 (`const {a, b} = obj`)
   - 不使用 `this` 在独立函数中
   - 避免使用不支持的对象属性名
   - 函数返回类型明确标注，不使用类型推断

5. **API 调用规范**
   - relationalStore API 调用使用明确的类型参数
   - ResultSet 操作使用正确的索引访问
   - 数据库连接管理使用明确的生命周期控制

## ⚠️ 注意事项

1. **权限配置**：确保 `module.json5` 中的权限配置正确
2. **初始化时机**：数据库会在应用启动时自动初始化，无需手动调用
3. **错误处理**：所有数据库操作都有完善的异常处理
4. **资源管理**：应用退出时会自动关闭数据库连接
5. **线程安全**：数据层操作是异步的，确保在正确的上下文中调用

## 🐛 故障排除

### 常见问题

**Q: 数据库初始化失败**
A: 检查权限配置是否正确，确认 `ohos.permission.DISTRIBUTED_DATASYNC` 已添加

**Q: 查询不到数据**
A: 确保数据已正确插入，可以通过测试页面验证

**Q: 应用启动慢**
A: 数据库初始化是异步的，不应该影响应用启动速度

## 📈 性能优化建议

1. **分页查询**：大量数据时使用 `limit` 和 `offset` 参数
2. **条件过滤**：查询时尽量使用具体的条件减少数据量
3. **索引优化**：时间戳和分类ID字段已优化为高效查询
4. **批量操作**：需要插入多条数据时可以考虑批量操作

---

🎉 **恭喜！** 您的记账本 App 数据层已配置完成，可以直接运行和使用了！

