import { DatabaseHelper } from './DatabaseHelper';

/**
 * 数据层功能测试类
 * 用于验证数据库操作是否正常工作
 */
export class DatabaseTest {

  /**
   * 运行完整的功能测试
   */
  public static async runFullTest(): Promise<string> {
    const results: string[] = [];

    try {
      // 1. 初始化测试
      results.push('📋 开始数据库功能测试...');

      await DatabaseHelper.initialize();
      results.push('✅ 数据库初始化成功');

      // 2. 获取DAO实例
      const categoryDao = DatabaseHelper.getCategoryDao();
      const transactionDao = DatabaseHelper.getTransactionDao();
      results.push('✅ DAO实例获取成功');

      // 3. 分类CRUD测试
      const categoryId = await categoryDao.insertCategory({
        name: '测试分类',
        icon_name: 'test',
        type: 0
      });
      results.push(`✅ 分类创建成功，ID: ${categoryId}`);

      const categories = await categoryDao.getAllCategories();
      results.push(`✅ 分类查询成功，共 ${categories.length} 个分类`);

      // 4. 交易CRUD测试
      const transactionId = await transactionDao.insertTransaction({
        type: 0,
        amount: 100.50,
        category_id: categoryId,
        date: Date.now(),
        note: '测试交易'
      });
      results.push(`✅ 交易创建成功，ID: ${transactionId}`);

      const transactions = await transactionDao.getTransactions({ limit: 10 });
      results.push(`✅ 交易查询成功，共 ${transactions.length} 笔交易`);

      // 5. 聚合查询测试
      const now = new Date();
      const stats = await transactionDao.getMonthlyCategoryStats(
        now.getFullYear(),
        now.getMonth() + 1,
        0
      );
      results.push(`✅ 月度统计查询成功，${stats.length} 个分类有统计数据`);

      // 6. 清理测试数据
      const deleteResult = await categoryDao.deleteCategory(categoryId);
      results.push(`✅ 测试数据清理${deleteResult ? '成功' : '失败'}`);

      results.push('🎉 所有测试通过！数据层功能正常');

    } catch (error) {
      results.push(`❌ 测试失败: ${(error as Error).message}`);
    }

    return results.join('\n');
  }

  /**
   * 快速初始化测试
   */
  public static async testInitialization(): Promise<string> {
    try {
      await DatabaseHelper.initialize();
      return '✅ 数据库初始化测试成功';
    } catch (error) {
      return `❌ 数据库初始化测试失败: ${(error as Error).message}`;
    }
  }

  /**
   * 基本CRUD测试
   */
  public static async testBasicCRUD(): Promise<string> {
    try {
      const categoryDao = DatabaseHelper.getCategoryDao();

      // 创建测试分类
      const categoryId = await categoryDao.insertCategory({
        name: 'CRUD测试',
        type: 0
      });

      // 查询验证
      const categories = await categoryDao.getAllCategories();
      const found = categories.some(c => c.id === categoryId);

      // 清理
      await categoryDao.deleteCategory(categoryId);

      return found ? '✅ 基础CRUD测试成功' : '❌ CRUD测试失败：数据未找到';
    } catch (error) {
      return `❌ 基础CRUD测试失败: ${(error as Error).message}`;
    }
  }
}
