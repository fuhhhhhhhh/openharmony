import relationalStore from '@ohos.data.relationalStore';
import { DBManager } from './DBManager';

/**
 * 分类数据模型接口
 */
interface Category {
  id?: number;
  name: string;
  icon_name?: string;
  type: number; // 0=支出分类，1=收入分类
}

/**
 * 分类数据访问对象
 * 负责 T_Categories 表的 CRUD 操作
 */
export class CategoryDao {
  private rdbStore: relationalStore.RdbStore;

  constructor() {
    this.rdbStore = DBManager.getInstance().getRdbStore();
  }

  /**
   * 新增分类
   * @param category 分类对象
   * @returns 新增分类的ID
   */
  public async insertCategory(category: Category): Promise<number> {
    const valueBucket: relationalStore.ValuesBucket = {
      name: category.name,
      icon_name: category.icon_name || '',
      type: category.type
    };

    try {
      const result: number = await this.rdbStore.insert(DBManager.TABLE_CATEGORIES, valueBucket);
      console.log(`新增分类成功，ID: ${result}`);
      return result;
    } catch (error) {
      console.error('新增分类失败');
      throw new Error('新增分类失败');
    }
  }

  /**
   * 删除分类
   * 删除前需判断是否被交易记录引用
   * @param categoryId 分类ID
   * @returns 是否删除成功
   */
  public async deleteCategory(categoryId: number): Promise<boolean> {
    try {
      // 检查是否有交易记录引用此分类
      const hasTransactions: boolean = await this.hasTransactionsUsingCategory(categoryId);
      if (hasTransactions) {
        console.warn(`分类 ${categoryId} 已被交易记录使用，无法删除`);
        return false;
      }

      const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates(DBManager.TABLE_CATEGORIES);
      predicates.equalTo('id', categoryId);

      const result: number = await this.rdbStore.delete(predicates);
      console.log(`删除分类成功，影响行数: ${result}`);
      return result > 0;
    } catch (error) {
      console.error('删除分类失败');
      throw new Error('删除分类失败');
    }
  }

  /**
   * 检查分类是否被交易记录使用
   * @param categoryId 分类ID
   * @returns 是否被使用
   */
  private async hasTransactionsUsingCategory(categoryId: number): Promise<boolean> {
    const sql: string = `SELECT COUNT(*) as count FROM ${DBManager.TABLE_TRANSACTIONS} WHERE category_id = ?`;
    try {
      const resultSet: relationalStore.ResultSet = await this.rdbStore.querySql(sql, [categoryId]);
      const count: number = resultSet.goToFirstRow() ? resultSet.getLong(0) : 0;
      resultSet.close();
      return count > 0;
    } catch (error) {
      console.error('检查分类使用情况失败');
      throw new Error('检查分类使用情况失败');
    }
  }

  /**
   * 更新分类信息
   * @param categoryId 分类ID
   * @param updates 要更新的字段
   * @returns 是否更新成功
   */
  public async updateCategory(categoryId: number, updates: Category): Promise<boolean> {
    const valueBucket: relationalStore.ValuesBucket = {};

    if (updates.name) {
      valueBucket.name = updates.name;
    }
    if (updates.icon_name) {
      valueBucket.icon_name = updates.icon_name;
    }
    if (updates.type !== undefined) {
      valueBucket.type = updates.type;
    }

    const keys: string[] = Object.getOwnPropertyNames(valueBucket);
    if (keys.length === 0) {
      console.warn('没有要更新的字段');
      return false;
    }

    try {
      const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates(DBManager.TABLE_CATEGORIES);
      predicates.equalTo('id', categoryId);

      const result: number = await this.rdbStore.update(valueBucket, predicates);
      console.log(`更新分类成功，影响行数: ${result}`);
      return result > 0;
    } catch (error) {
      console.error('更新分类失败');
      throw new Error('更新分类失败');
    }
  }

  /**
   * 查询所有分类
   * @returns 分类列表
   */
  public async getAllCategories(): Promise<Category[]> {
    const sql: string = `SELECT id, name, icon_name, type FROM ${DBManager.TABLE_CATEGORIES} ORDER BY id ASC`;
    try {
      const resultSet: relationalStore.ResultSet = await this.rdbStore.querySql(sql);
      const categories: Category[] = [];

      while (resultSet.goToNextRow()) {
        const category: Category = {
          id: resultSet.getLong(0),
          name: resultSet.getString(1),
          icon_name: resultSet.getString(2),
          type: resultSet.getLong(3)
        };
        categories.push(category);
      }

      resultSet.close();
      return categories;
    } catch (error) {
      console.error('查询全部分类失败');
      throw new Error('查询全部分类失败');
    }
  }

  /**
   * 根据类型查询分类列表
   * @param type 分类类型 (0=支出，1=收入)
   * @returns 分类列表
   */
  public async getCategoriesByType(type: number): Promise<Category[]> {
    const sql: string = `SELECT id, name, icon_name, type FROM ${DBManager.TABLE_CATEGORIES} WHERE type = ? ORDER BY id ASC`;
    try {
      const resultSet: relationalStore.ResultSet = await this.rdbStore.querySql(sql, [type]);
      const categories: Category[] = [];

      while (resultSet.goToNextRow()) {
        const category: Category = {
          id: resultSet.getLong(0),
          name: resultSet.getString(1),
          icon_name: resultSet.getString(2),
          type: resultSet.getLong(3)
        };
        categories.push(category);
      }

      resultSet.close();
      return categories;
    } catch (error) {
      console.error(`查询类型 ${type} 分类失败`);
      throw new Error(`查询类型 ${type} 分类失败`);
    }
  }

  /**
   * 根据ID查询单个分类
   * @param categoryId 分类ID
   * @returns 分类对象或null
   */
  public async getCategoryById(categoryId: number): Promise<Category | null> {
    const sql: string = `SELECT id, name, icon_name, type FROM ${DBManager.TABLE_CATEGORIES} WHERE id = ?`;
    try {
      const resultSet: relationalStore.ResultSet = await this.rdbStore.querySql(sql, [categoryId]);

      if (resultSet.goToFirstRow()) {
        const category: Category = {
          id: resultSet.getLong(0),
          name: resultSet.getString(1),
          icon_name: resultSet.getString(2),
          type: resultSet.getLong(3)
        };
        resultSet.close();
        return category;
      }

      resultSet.close();
      return null;
    } catch (error) {
      console.error('查询分类失败');
      throw new Error('查询分类失败');
    }
  }
}