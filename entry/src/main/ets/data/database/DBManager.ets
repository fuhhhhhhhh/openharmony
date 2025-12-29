import relationalStore from '@ohos.data.relationalStore';
import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { common } from '@kit.AbilityKit';

/**
 * 数据库管理类 - 负责 relationalStore 数据库的创建、初始化和管理
 * 采用单例模式，提供统一的数据库访问入口
 */
export class DBManager {
  private static instance: DBManager | null = null;
  private rdbStore: relationalStore.RdbStore | null = null;
  private context: common.BaseContext | null = null;
  private readonly DB_NAME: string = 'accounting_db';
  private readonly DB_VERSION: number = 1;

  // 表名常量
  public static readonly TABLE_TRANSACTIONS: string = 'T_Transactions';
  public static readonly TABLE_CATEGORIES: string = 'T_Categories';

  private constructor() {}

  /**
   * 获取 DBManager 单例实例
   */
  public static getInstance(context?: common.BaseContext): DBManager {
    if (!DBManager.instance) {
      DBManager.instance = new DBManager();
    }
    if (context) {
      DBManager.instance.context = context;
    }
    return DBManager.instance;
  }

  /**
   * 初始化数据库
   * 创建表结构并设置数据库版本
   */
  public async initDB(): Promise<void> {
    if (!this.context) {
      throw new Error('需要先设置context');
    }

    try {
      const config: relationalStore.StoreConfig = {
        name: this.DB_NAME,
        securityLevel: relationalStore.SecurityLevel.S1,
      };

      this.rdbStore = await relationalStore.getRdbStore(this.context, config);
      await this.createTables();
      console.log('数据库初始化成功');
    } catch (error) {
      console.error('数据库初始化失败');
      throw new Error('数据库初始化失败');
    }
  }

  /**
   * 创建数据库表结构
   */
  private async createTables(): Promise<void> {
    if (!this.rdbStore) {
      throw new Error('数据库未初始化');
    }

    // 创建分类表
    const createCategoriesTable: string = `
      CREATE TABLE IF NOT EXISTS ${DBManager.TABLE_CATEGORIES} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        icon_name TEXT,
        type INTEGER NOT NULL CHECK(type IN (0, 1))
      )
    `;

    // 创建交易表
    const createTransactionsTable: string = `
      CREATE TABLE IF NOT EXISTS ${DBManager.TABLE_TRANSACTIONS} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type INTEGER NOT NULL CHECK(type IN (0, 1)),
        amount REAL NOT NULL CHECK(amount > 0),
        category_id INTEGER NOT NULL,
        date INTEGER NOT NULL,
        note TEXT,
        FOREIGN KEY (category_id) REFERENCES ${DBManager.TABLE_CATEGORIES}(id)
      )
    `;

    try {
      await this.rdbStore.executeSql(createCategoriesTable);
      await this.rdbStore.executeSql(createTransactionsTable);
      console.log('数据表创建成功');
    } catch (error) {
      console.error('创建数据表失败');
      throw new Error('创建数据表失败');
    }
  }

  /**
   * 获取 RDBStore 实例
   * 外部类通过此方法获取数据库实例进行操作
   */
  public getRdbStore(): relationalStore.RdbStore {
    if (!this.rdbStore) {
      throw new Error('数据库未初始化，请先调用 initDB()');
    }
    return this.rdbStore;
  }

  /**
   * 关闭数据库连接
   * 应用退出时调用
   */
  public async closeDB(): Promise<void> {
    if (this.rdbStore) {
      try {
        await this.rdbStore.close();
        this.rdbStore = null;
        console.log('数据库连接已关闭');
      } catch (error) {
        console.error('关闭数据库连接失败');
        throw new Error('关闭数据库连接失败');
      }
    }
  }

  /**
   * 删除数据库（开发调试用）
   */
  public async deleteDB(): Promise<void> {
    if (!this.context) {
      throw new Error('需要先设置context');
    }

    try {
      await relationalStore.deleteRdbStore(this.context, this.DB_NAME);
      this.rdbStore = null;
      console.log('数据库已删除');
    } catch (error) {
      console.error('删除数据库失败');
      throw new Error('删除数据库失败');
    }
  }
}

