import { DBManager } from './database/DBManager';
import { CategoryDao } from './database/CategoryDao';
import { TransactionDao } from './database/TransactionDao';
import { common } from '@kit.AbilityKit';

/**
 * 数据库助手类
 * 提供数据层的统一入口和初始化管理
 */
export class DatabaseHelper {
  private static dbManager: DBManager | null = null;
  private static categoryDao: CategoryDao | null = null;
  private static transactionDao: TransactionDao | null = null;
  private static isInitialized: boolean = false;

  /**
   * 初始化数据库和 Dao 层
   * 应在应用启动时调用
   */
  public static async initialize(context?: common.BaseContext): Promise<void> {
    if (DatabaseHelper.isInitialized) {
      console.log('数据库已初始化，跳过');
      return;
    }

    try {
      // 初始化数据库
      DatabaseHelper.dbManager = DBManager.getInstance(context);
      await DatabaseHelper.dbManager.initDB();

      // 创建 Dao 实例
      DatabaseHelper.categoryDao = new CategoryDao();
      DatabaseHelper.transactionDao = new TransactionDao();

      DatabaseHelper.isInitialized = true;
      console.log('数据库助手初始化完成');
    } catch (error) {
      console.error('数据库助手初始化失败');
      throw new Error('数据库助手初始化失败');
    }
  }

  /**
   * 获取分类 Dao 实例
   */
  public static getCategoryDao(): CategoryDao {
    if (!DatabaseHelper.isInitialized || !DatabaseHelper.categoryDao) {
      throw new Error('数据库未初始化，请先调用 DatabaseHelper.initialize()');
    }
    return DatabaseHelper.categoryDao;
  }

  /**
   * 获取交易 Dao 实例
   */
  public static getTransactionDao(): TransactionDao {
    if (!DatabaseHelper.isInitialized || !DatabaseHelper.transactionDao) {
      throw new Error('数据库未初始化，请先调用 DatabaseHelper.initialize()');
    }
    return DatabaseHelper.transactionDao;
  }

  /**
   * 获取数据库管理器实例
   */
  public static getDBManager(): DBManager {
    if (!DatabaseHelper.isInitialized || !DatabaseHelper.dbManager) {
      throw new Error('数据库未初始化，请先调用 DatabaseHelper.initialize()');
    }
    return DatabaseHelper.dbManager;
  }

  /**
   * 关闭数据库连接
   * 应在应用退出时调用
   */
  public static async close(): Promise<void> {
    if (DatabaseHelper.dbManager) {
      await DatabaseHelper.dbManager.closeDB();
      DatabaseHelper.dbManager = null;
      DatabaseHelper.categoryDao = null;
      DatabaseHelper.transactionDao = null;
      DatabaseHelper.isInitialized = false;
      console.log('数据库连接已关闭');
    }
  }

  /**
   * 清空数据库数据
   * 删除数据库文件并重新初始化
   */
  public static async clearDatabase(): Promise<void> {
    try {
      // 如果数据库已初始化，先关闭连接
      if (DatabaseHelper.isInitialized) {
        await DatabaseHelper.close();
      }

      // 删除数据库文件
      if (DatabaseHelper.dbManager) {
        await DatabaseHelper.dbManager.deleteDB();
      } else {
        // 如果没有实例，创建一个临时实例来删除数据库
        const tempManager = DBManager.getInstance();
        await tempManager.deleteDB();
      }

      // 重新初始化
      DatabaseHelper.isInitialized = false;
      await DatabaseHelper.initialize();

      console.log('数据库清理完成');
    } catch (error) {
      console.error('清理数据库失败');
      throw new Error('清理数据库失败');
    }
  }

  /**
   * 删除单个交易记录
   * @param transactionId 交易记录ID
   * @returns 是否删除成功
   */
  public static async deleteTransaction(transactionId: number): Promise<boolean> {
    if (!DatabaseHelper.isInitialized || !DatabaseHelper.transactionDao) {
      throw new Error('数据库未初始化，请先调用 DatabaseHelper.initialize()');
    }
    return await DatabaseHelper.transactionDao.deleteTransaction(transactionId);
  }

  /**
   * 删除某个分类下的所有交易记录
   * @param categoryId 分类ID
   * @returns 删除的记录数量
   */
  public static async deleteTransactionsByCategory(categoryId: number): Promise<number> {
    if (!DatabaseHelper.isInitialized || !DatabaseHelper.transactionDao) {
      throw new Error('数据库未初始化，请先调用 DatabaseHelper.initialize()');
    }
    return await DatabaseHelper.transactionDao.deleteTransactionsByCategory(categoryId);
  }

  /**
   * 删除某个时间范围内的交易记录
   * @param startTime 开始时间戳
   * @param endTime 结束时间戳
   * @returns 删除的记录数量
   */
  public static async deleteTransactionsByDateRange(startTime: number, endTime: number): Promise<number> {
    if (!DatabaseHelper.isInitialized || !DatabaseHelper.transactionDao) {
      throw new Error('数据库未初始化，请先调用 DatabaseHelper.initialize()');
    }
    return await DatabaseHelper.transactionDao.deleteTransactionsByDateRange(startTime, endTime);
  }

  /**
   * 删除某个金额范围内的交易记录
   * @param minAmount 最小金额
   * @param maxAmount 最大金额
   * @param transactionType 交易类型 (0=支出, 1=收入, undefined=全部)
   * @returns 删除的记录数量
   */
  public static async deleteTransactionsByAmountRange(minAmount: number, maxAmount: number, transactionType?: number): Promise<number> {
    if (!DatabaseHelper.isInitialized || !DatabaseHelper.transactionDao) {
      throw new Error('数据库未初始化，请先调用 DatabaseHelper.initialize()');
    }
    return await DatabaseHelper.transactionDao.deleteTransactionsByAmountRange(minAmount, maxAmount, transactionType);
  }

  /**
   * 删除指定类型的交易记录
   * @param transactionType 交易类型 (0=支出, 1=收入)
   * @returns 删除的记录数量
   */
  public static async deleteTransactionsByType(transactionType: number): Promise<number> {
    if (!DatabaseHelper.isInitialized || !DatabaseHelper.transactionDao) {
      throw new Error('数据库未初始化，请先调用 DatabaseHelper.initialize()');
    }
    return await DatabaseHelper.transactionDao.deleteTransactionsByType(transactionType);
  }

  /**
   * 删除指定类型的分类
   * @param categoryType 分类类型 (0=支出分类, 1=收入分类)
   * @returns 删除的分类数量
   */
  public static async deleteCategoriesByType(categoryType: number): Promise<number> {
    if (!DatabaseHelper.isInitialized || !DatabaseHelper.categoryDao) {
      throw new Error('数据库未初始化，请先调用 DatabaseHelper.initialize()');
    }
    return await DatabaseHelper.categoryDao.deleteCategoriesByType(categoryType);
  }

  /**
   * 检查数据库是否已初始化
   */
  public static isDatabaseInitialized(): boolean {
    return DatabaseHelper.isInitialized;
  }
}