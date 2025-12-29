import relationalStore from '@ohos.data.relationalStore';
import { DBManager } from './DBManager';

/**
 * 交易记录数据模型接口
 */
interface Transaction {
  id?: number;
  type: number; // 0=支出，1=收入
  amount: number;
  category_id: number;
  date: number; // 时间戳（毫秒）
  note?: string;
}

/**
 * 查询选项接口
 */
interface QueryOptions {
  type?: number;
  startDate?: number;
  endDate?: number;
  categoryId?: number;
  limit?: number;
  offset?: number;
}

/**
 * 交易记录与分类的联合查询结果接口
 */
interface TransactionWithCategory extends Transaction {
  category_name: string;
  category_icon: string;
}

/**
 * 按月分类统计结果接口
 */
interface MonthlyCategoryStats {
  category_id: number;
  category_name: string;
  category_icon: string;
  total_amount: number;
  transaction_count: number;
}

/**
 * 分类支出占比统计接口
 */
interface CategoryExpenseRatio {
  category_id: number;
  category_name: string;
  category_icon: string;
  amount: number;
  percentage: number;
}

/**
 * 交易记录数据访问对象
 * 负责 T_Transactions 表的 CRUD 操作及复杂聚合查询
 */
export class TransactionDao {
  private rdbStore: relationalStore.RdbStore;

  constructor() {
    this.rdbStore = DBManager.getInstance().getRdbStore();
  }

  /**
   * 插入交易记录
   * @param transaction 交易记录对象
   * @returns 新增交易的ID
   */
  public async insertTransaction(transaction: Transaction): Promise<number> {
    const valueBucket: relationalStore.ValuesBucket = {
      type: transaction.type,
      amount: transaction.amount,
      category_id: transaction.category_id,
      date: transaction.date,
      note: transaction.note || ''
    };

    try {
      const result: number = await this.rdbStore.insert(DBManager.TABLE_TRANSACTIONS, valueBucket);
      console.log(`新增交易记录成功，ID: ${result}`);
      return result;
    } catch (error) {
      console.error('新增交易记录失败');
      throw new Error('新增交易记录失败');
    }
  }

  /**
   * 根据ID删除交易记录
   * @param transactionId 交易ID
   * @returns 是否删除成功
   */
  public async deleteTransaction(transactionId: number): Promise<boolean> {
    try {
      const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates(DBManager.TABLE_TRANSACTIONS);
      predicates.equalTo('id', transactionId);

      const result: number = await this.rdbStore.delete(predicates);
      console.log(`删除交易记录成功，影响行数: ${result}`);
      return result > 0;
    } catch (error) {
      console.error('删除交易记录失败');
      throw new Error('删除交易记录失败');
    }
  }

  /**
   * 查询交易记录列表 - 基础查询
   * @param options 查询选项
   * @returns 交易记录列表
   */
  public async getTransactions(options: QueryOptions): Promise<TransactionWithCategory[]> {
    let sql: string = `
      SELECT
        t.id, t.type, t.amount, t.category_id, t.date, t.note,
        c.name as category_name, c.icon_name as category_icon
      FROM ${DBManager.TABLE_TRANSACTIONS} t
      LEFT JOIN ${DBManager.TABLE_CATEGORIES} c ON t.category_id = c.id
      WHERE 1=1
    `;

    const params: (number | string)[] = [];

    if (options.type !== undefined) {
      sql += ' AND t.type = ?';
      params.push(options.type);
    }

    if (options.startDate !== undefined) {
      sql += ' AND t.date >= ?';
      params.push(options.startDate);
    }

    if (options.endDate !== undefined) {
      sql += ' AND t.date <= ?';
      params.push(options.endDate);
    }

    if (options.categoryId !== undefined) {
      sql += ' AND t.category_id = ?';
      params.push(options.categoryId);
    }

    sql += ' ORDER BY t.date DESC';

    if (options.limit !== undefined) {
      sql += ' LIMIT ?';
      params.push(options.limit);

      if (options.offset !== undefined) {
        sql += ' OFFSET ?';
        params.push(options.offset);
      }
    }

    try {
      const resultSet: relationalStore.ResultSet = await this.rdbStore.querySql(sql, params);
      const transactions: TransactionWithCategory[] = [];

      while (resultSet.goToNextRow()) {
        const transaction: TransactionWithCategory = {
          id: resultSet.getLong(0),
          type: resultSet.getLong(1),
          amount: resultSet.getDouble(2),
          category_id: resultSet.getLong(3),
          date: resultSet.getLong(4),
          note: resultSet.getString(5),
          category_name: resultSet.getString(6),
          category_icon: resultSet.getString(7)
        };
        transactions.push(transaction);
      }

      resultSet.close();
      return transactions;
    } catch (error) {
      console.error('查询交易记录失败');
      throw new Error('查询交易记录失败');
    }
  }

  /**
   * 按月份和分类统计交易金额
   * 用于生成月度分类统计报告
   * @param year 年份
   * @param month 月份 (1-12)
   * @param type 交易类型 (0=支出，1=收入)
   * @returns 按分类统计的结果
   */
  public async getMonthlyCategoryStats(year: number, month: number, type: number): Promise<MonthlyCategoryStats[]> {
    // 计算月份的开始和结束时间戳
    const startDate: number = new Date(year, month - 1, 1).getTime();
    const endDate: number = new Date(year, month, 1).getTime() - 1;

    const sql: string = `
      SELECT
        c.id as category_id,
        c.name as category_name,
        c.icon_name as category_icon,
        SUM(t.amount) as total_amount,
        COUNT(t.id) as transaction_count
      FROM ${DBManager.TABLE_TRANSACTIONS} t
      LEFT JOIN ${DBManager.TABLE_CATEGORIES} c ON t.category_id = c.id
      WHERE t.type = ?
        AND t.date >= ?
        AND t.date <= ?
      GROUP BY c.id, c.name, c.icon_name
      ORDER BY total_amount DESC
    `;

    try {
      const resultSet: relationalStore.ResultSet = await this.rdbStore.querySql(sql, [type, startDate, endDate]);
      const stats: MonthlyCategoryStats[] = [];

      while (resultSet.goToNextRow()) {
        const stat: MonthlyCategoryStats = {
          category_id: resultSet.getLong(0),
          category_name: resultSet.getString(1),
          category_icon: resultSet.getString(2),
          total_amount: resultSet.getDouble(3),
          transaction_count: resultSet.getLong(4)
        };
        stats.push(stat);
      }

      resultSet.close();
      return stats;
    } catch (error) {
      console.error('按月分类统计失败');
      throw new Error('按月分类统计失败');
    }
  }

  /**
   * 统计某月某分类的总支出金额
   * @param year 年份
   * @param month 月份 (1-12)
   * @param categoryId 分类ID
   * @returns 总金额
   */
  public async getMonthlyCategoryExpense(year: number, month: number, categoryId: number): Promise<number> {
    const startDate: number = new Date(year, month - 1, 1).getTime();
    const endDate: number = new Date(year, month, 1).getTime() - 1;

    const sql: string = `
      SELECT SUM(amount) as total
      FROM ${DBManager.TABLE_TRANSACTIONS}
      WHERE type = 0
        AND category_id = ?
        AND date >= ?
        AND date <= ?
    `;

    try {
      const resultSet: relationalStore.ResultSet = await this.rdbStore.querySql(sql, [categoryId, startDate, endDate]);
      const total: number = resultSet.goToFirstRow() ? resultSet.getDouble(0) : 0;
      resultSet.close();
      return total;
    } catch (error) {
      console.error('统计月度分类支出失败');
      throw new Error('统计月度分类支出失败');
    }
  }

  /**
   * 按分类统计本月支出占比（用于饼图）
   * @param year 年份
   * @param month 月份 (1-12)
   * @returns 各分类支出占比数据
   */
  public async getMonthlyExpenseRatio(year: number, month: number): Promise<CategoryExpenseRatio[]> {
    const startDate: number = new Date(year, month - 1, 1).getTime();
    const endDate: number = new Date(year, month, 1).getTime() - 1;

    const sql: string = `
      SELECT
        c.id as category_id,
        c.name as category_name,
        c.icon_name as category_icon,
        SUM(t.amount) as amount,
        (SUM(t.amount) * 100.0 / (
          SELECT SUM(amount)
          FROM ${DBManager.TABLE_TRANSACTIONS}
          WHERE type = 0 AND date >= ? AND date <= ?
        )) as percentage
      FROM ${DBManager.TABLE_TRANSACTIONS} t
      LEFT JOIN ${DBManager.TABLE_CATEGORIES} c ON t.category_id = c.id
      WHERE t.type = 0
        AND t.date >= ?
        AND t.date <= ?
      GROUP BY c.id, c.name, c.icon_name
      HAVING amount > 0
      ORDER BY amount DESC
    `;

    try {
      const resultSet: relationalStore.ResultSet = await this.rdbStore.querySql(sql, [startDate, endDate, startDate, endDate]);
      const ratios: CategoryExpenseRatio[] = [];

      while (resultSet.goToNextRow()) {
        const ratio: CategoryExpenseRatio = {
          category_id: resultSet.getLong(0),
          category_name: resultSet.getString(1),
          category_icon: resultSet.getString(2),
          amount: resultSet.getDouble(3),
          percentage: resultSet.getDouble(4)
        };
        ratios.push(ratio);
      }

      resultSet.close();
      return ratios;
    } catch (error) {
      console.error('统计支出占比失败');
      throw new Error('统计支出占比失败');
    }
  }

  /**
   * 获取指定时间范围内的总收入或总支出
   * @param startDate 开始时间戳
   * @param endDate 结束时间戳
   * @param type 交易类型 (0=支出，1=收入)
   * @returns 总金额
   */
  public async getTotalAmount(startDate: number, endDate: number, type: number): Promise<number> {
    const sql: string = `
      SELECT SUM(amount) as total
      FROM ${DBManager.TABLE_TRANSACTIONS}
      WHERE type = ?
        AND date >= ?
        AND date <= ?
    `;

    try {
      const resultSet: relationalStore.ResultSet = await this.rdbStore.querySql(sql, [type, startDate, endDate]);
      const total: number = resultSet.goToFirstRow() ? resultSet.getDouble(0) : 0;
      resultSet.close();
      return total;
    } catch (error) {
      console.error('统计总金额失败');
      throw new Error('统计总金额失败');
    }
  }

  /**
   * 根据ID查询单个交易记录（包含分类信息）
   * @param transactionId 交易ID
   * @returns 交易记录或null
   */
  public async getTransactionById(transactionId: number): Promise<TransactionWithCategory | null> {
    const sql: string = `
      SELECT
        t.id, t.type, t.amount, t.category_id, t.date, t.note,
        c.name as category_name, c.icon_name as category_icon
      FROM ${DBManager.TABLE_TRANSACTIONS} t
      LEFT JOIN ${DBManager.TABLE_CATEGORIES} c ON t.category_id = c.id
      WHERE t.id = ?
    `;

    try {
      const resultSet: relationalStore.ResultSet = await this.rdbStore.querySql(sql, [transactionId]);

      if (resultSet.goToFirstRow()) {
        const transaction: TransactionWithCategory = {
          id: resultSet.getLong(0),
          type: resultSet.getLong(1),
          amount: resultSet.getDouble(2),
          category_id: resultSet.getLong(3),
          date: resultSet.getLong(4),
          note: resultSet.getString(5),
          category_name: resultSet.getString(6),
          category_icon: resultSet.getString(7)
        };
        resultSet.close();
        return transaction;
      }

      resultSet.close();
      return null;
    } catch (error) {
      console.error('查询交易记录失败');
      throw new Error('查询交易记录失败');
    }
  }
}