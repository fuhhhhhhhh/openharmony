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
   * 检查数据库是否已初始化
   */
  public static isDatabaseInitialized(): boolean {
    return DatabaseHelper.isInitialized;
  }
}