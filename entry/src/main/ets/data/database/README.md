# 记账本 App 数据层设计说明

## 概述

本数据层采用 **DBManager + Dao** 分层架构，基于 OpenHarmony relationalStore (RDB) 实现，为"记一笔"记账本 App 提供完整的数据持久化解决方案。

## 架构设计

### DBManager (数据库管理层)
- **职责**: 数据库初始化、表结构管理、版本控制
- **模式**: 单例模式，提供统一数据库访问入口
- **文件**: `DBManager.ets`

### Dao 层 (数据访问层)
- **TransactionDao**: 交易记录的 CRUD 操作及复杂聚合查询
- **CategoryDao**: 分类管理的 CRUD 操作
- **职责**: 纯粹的数据持久化逻辑，不涉及业务逻辑

## 数据模型

### 交易表 (T_Transactions)
```sql
CREATE TABLE T_Transactions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  type INTEGER NOT NULL CHECK(type IN (0, 1)),     -- 0=支出，1=收入
  amount REAL NOT NULL CHECK(amount > 0),           -- 交易金额
  category_id INTEGER NOT NULL,                     -- 分类外键
  date INTEGER NOT NULL,                           -- 时间戳（毫秒）
  note TEXT,                                        -- 备注
  FOREIGN KEY (category_id) REFERENCES T_Categories(id)
)
```

### 分类表 (T_Categories)
```sql
CREATE TABLE T_Categories (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,                               -- 分类名称
  icon_name TEXT,                                   -- 分类图标标识
  type INTEGER NOT NULL CHECK(type IN (0, 1))       -- 0=支出分类，1=收入分类
)
```

## SQL 查询示例

### 示例 1: 统计本月某分类的总支出金额

```sql
-- 统计 2024年1月 "餐饮" 分类的总支出金额
SELECT SUM(amount) as total
FROM T_Transactions
WHERE type = 0
  AND category_id = (SELECT id FROM T_Categories WHERE name = '餐饮')
  AND date >= 1704067200000  -- 2024-01-01 00:00:00
  AND date <= 1706745599999  -- 2024-01-31 23:59:59
```

**对应代码调用**:
```typescript
// 获取 2024年1月餐饮分类ID（假设为1）
const totalExpense = await transactionDao.getMonthlyCategoryExpense(2024, 1, 1);
console.log(`本月餐饮支出: ${totalExpense}元`);
```

### 示例 2: 按分类统计本月支出占比（饼图数据）

```sql
-- 统计 2024年1月各分类支出占比
SELECT
  c.id as category_id,
  c.name as category_name,
  c.icon_name as category_icon,
  SUM(t.amount) as amount,
  (SUM(t.amount) * 100.0 / (
    SELECT SUM(amount)
    FROM T_Transactions
    WHERE type = 0
      AND date >= 1704067200000
      AND date <= 1706745599999
  )) as percentage
FROM T_Transactions t
LEFT JOIN T_Categories c ON t.category_id = c.id
WHERE t.type = 0
  AND t.date >= 1704067200000
  AND t.date <= 1706745599999
GROUP BY c.id, c.name, c.icon_name
HAVING amount > 0
ORDER BY amount DESC
```

**对应代码调用**:
```typescript
// 获取 2024年1月支出占比数据
const expenseRatios = await transactionDao.getMonthlyExpenseRatio(2024, 1);
expenseRatios.forEach(ratio => {
  console.log(`${ratio.category_name}: ${ratio.amount}元 (${ratio.percentage.toFixed(1)}%)`);
});
```

### 示例 3: 按月份+分类统计金额

```sql
-- 统计 2024年1月各分类的收入/支出情况
SELECT
  c.id as category_id,
  c.name as category_name,
  c.icon_name as category_icon,
  SUM(t.amount) as total_amount,
  COUNT(t.id) as transaction_count
FROM T_Transactions t
LEFT JOIN T_Categories c ON t.category_id = c.id
WHERE t.type = 0  -- 0=支出，1=收入
  AND t.date >= 1704067200000
  AND t.date <= 1706745599999
GROUP BY c.id, c.name, c.icon_name
ORDER BY total_amount DESC
```

**对应代码调用**:
```typescript
// 获取 2024年1月支出分类统计
const stats = await transactionDao.getMonthlyCategoryStats(2024, 1, 0); // 0=支出
stats.forEach(stat => {
  console.log(`${stat.category_name}: ${stat.total_amount}元 (${stat.transaction_count}笔)`);
});
```

## 核心功能说明

### 1. 数据库初始化

```typescript
// 在应用启动时初始化数据库
await DBManager.getInstance().initDB();
```

### 2. 基础 CRUD 操作

```typescript
// 创建 Dao 实例
const categoryDao = new CategoryDao();
const transactionDao = new TransactionDao();

// 新增分类
const categoryId = await categoryDao.insertCategory({
  name: '餐饮',
  icon_name: 'food',
  type: 0  // 支出分类
});

// 新增交易记录
const transactionId = await transactionDao.insertTransaction({
  type: 0,  // 支出
  amount: 25.50,
  category_id: categoryId,
  date: Date.now(),
  note: '午餐'
});
```

### 3. 数据查询

```typescript
// 查询所有支出分类
const expenseCategories = await categoryDao.getCategoriesByType(0);

// 查询本月交易记录（支出）
const thisMonth = new Date();
const startOfMonth = new Date(thisMonth.getFullYear(), thisMonth.getMonth(), 1).getTime();
const endOfMonth = new Date(thisMonth.getFullYear(), thisMonth.getMonth() + 1, 0).getTime();

const transactions = await transactionDao.getTransactions({
  type: 0,  // 支出
  startDate: startOfMonth,
  endDate: endOfMonth,
  limit: 50
});
```

### 4. 聚合统计

```typescript
// 计算本月总支出
const totalExpense = await transactionDao.getTotalAmount(startOfMonth, endOfMonth, 0);

// 生成月度报告数据
const monthlyStats = await transactionDao.getMonthlyCategoryStats(
  thisMonth.getFullYear(),
  thisMonth.getMonth() + 1,
  0  // 支出
);
```

## 设计特点

### 1. 数据一致性保障
- 外键约束确保分类引用有效性
- 删除分类前检查是否被交易使用
- 交易类型与分类类型保持一致

### 2. 查询性能优化
- 时间戳字段支持高效的日期范围查询
- JOIN 查询减少数据访问次数
- 聚合查询直接在数据库层面完成

### 3. 扩展性设计
- DBManager 支持数据库版本管理
- Dao 层接口清晰，便于后续功能扩展
- SQL 查询参数化，防止注入攻击

### 4. 错误处理
- 完善的异常捕获和日志记录
- 返回值设计明确（成功/失败状态）
- 资源释放（ResultSet.close()）

## 使用建议

1. **初始化**: 在应用启动时尽早初始化数据库
2. **资源管理**: 使用完数据库连接后及时关闭
3. **事务处理**: 复杂业务操作考虑使用事务保证数据一致性
4. **性能监控**: 大数据量查询注意分页和索引优化

## 注意事项

- 所有金额字段使用 REAL 类型，支持小数点精度
- 时间戳统一使用毫秒级整数，便于日期计算
- 分类删除前必须检查引用关系，避免数据孤岛
- SQL 查询注意参数化使用，防止 SQL 注入

