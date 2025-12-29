import { DatabaseHelper } from '../data/DatabaseHelper';
import { DatabaseTest } from '../data/DatabaseTest';

@Entry
@Component
struct Index {
  @State message: string = '记账本 App';
  @State statusMessage: string = '点击按钮测试数据库功能';
  @State transactionIdToDelete: string = '';

  build() {
    Column() {
      Text(this.message)
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 50, bottom: 20 })

      Text(this.statusMessage)
        .fontSize(16)
        .margin({ bottom: 30 })
        .textAlign(TextAlign.Center)

      Button('测试数据库初始化')
        .width(200)
        .height(40)
        .margin({ bottom: 10 })
        .onClick(async () => {
          try {
            await DatabaseHelper.initialize();
            this.statusMessage = '✅ 数据库初始化成功';
          } catch (error) {
            this.statusMessage = `❌ 初始化失败: ${(error as Error).message}`;
          }
        })

      Button('添加测试数据')
        .width(200)
        .height(40)
        .margin({ bottom: 10 })
        .onClick(async () => {
          try {
            const categoryDao = DatabaseHelper.getCategoryDao();
            const transactionDao = DatabaseHelper.getTransactionDao();

            // 添加测试分类
            const categoryId: number = await categoryDao.insertCategory({
              name: '餐饮',
              icon_name: 'food',
              type: 0
            });

            // 添加测试交易
            await transactionDao.insertTransaction({
              type: 0,
              amount: 25.50,
              category_id: categoryId,
              date: Date.now(),
              note: '午餐测试'
            });

            this.statusMessage = '✅ 测试数据添加成功';
          } catch (error) {
            this.statusMessage = `❌ 添加数据失败: ${(error as Error).message}`;
          }
        })

      Button('查询数据')
        .width(200)
        .height(40)
        .margin({ bottom: 10 })
        .onClick(async () => {
          try {
            const categoryDao = DatabaseHelper.getCategoryDao();
            const transactionDao = DatabaseHelper.getTransactionDao();

            const categories = await categoryDao.getAllCategories();
            const transactions = await transactionDao.getTransactions({ limit: 10 });

            this.statusMessage = `✅ 查询成功: ${categories.length}个分类, ${transactions.length}笔交易`;
          } catch (error) {
            this.statusMessage = `❌ 查询失败: ${(error as Error).message}`;
          }
        })

      Button('月度统计测试')
        .width(200)
        .height(40)
        .margin({ bottom: 10 })
        .onClick(async () => {
          try {
            const transactionDao = DatabaseHelper.getTransactionDao();
            const now: Date = new Date();
            const stats = await transactionDao.getMonthlyCategoryStats(now.getFullYear(), now.getMonth() + 1, 0);

            this.statusMessage = `✅ 本月统计: ${stats.length}个分类有支出记录`;
          } catch (error) {
            this.statusMessage = `❌ 统计失败: ${(error as Error).message}`;
          }
        })

      Button('完整功能测试')
        .width(200)
        .height(40)
        .margin({ bottom: 10 })
        .onClick(async () => {
          this.statusMessage = '🔄 正在运行完整测试...';
          try {
            const result: string = await DatabaseTest.runFullTest();
            this.statusMessage = result;
          } catch (error) {
            this.statusMessage = `❌ 测试异常: ${(error as Error).message}`;
          }
        })

      Button('清理数据库')
        .width(200)
        .height(40)
        .margin({ bottom: 10 })
        .onClick(async () => {
          try {
            await DatabaseHelper.clearDatabase();
            this.statusMessage = '✅ 数据库已清理并重新初始化';
          } catch (error) {
            this.statusMessage = `❌ 清理失败: ${(error as Error).message}`;
          }
        })

      Button('删除支出交易')
        .width(200)
        .height(40)
        .margin({ bottom: 10 })
        .onClick(async () => {
          try {
            const deletedCount = await DatabaseHelper.deleteTransactionsByType(0);
            this.statusMessage = `✅ 已删除 ${deletedCount} 笔支出交易`;
          } catch (error) {
            this.statusMessage = `❌ 删除失败: ${(error as Error).message}`;
          }
        })

      Button('删除收入交易')
        .width(200)
        .height(40)
        .margin({ bottom: 10 })
        .onClick(async () => {
          try {
            const deletedCount = await DatabaseHelper.deleteTransactionsByType(1);
            this.statusMessage = `✅ 已删除 ${deletedCount} 笔收入交易`;
          } catch (error) {
            this.statusMessage = `❌ 删除失败: ${(error as Error).message}`;
          }
        })

      Button('删除小额交易(<10)')
        .width(200)
        .height(40)
        .margin({ bottom: 10 })
        .onClick(async () => {
          try {
            const deletedCount = await DatabaseHelper.deleteTransactionsByAmountRange(0, 10);
            this.statusMessage = `✅ 已删除 ${deletedCount} 笔小额交易`;
          } catch (error) {
            this.statusMessage = `❌ 删除失败: ${(error as Error).message}`;
          }
        })

      Button('删除本月交易')
        .width(200)
        .height(40)
        .margin({ bottom: 10 })
        .onClick(async () => {
          try {
            const now = new Date();
            const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1).getTime();
            const endOfMonth = new Date(now.getFullYear(), now.getMonth() + 1, 0, 23, 59, 59).getTime();

            const deletedCount = await DatabaseHelper.deleteTransactionsByDateRange(startOfMonth, endOfMonth);
            this.statusMessage = `✅ 已删除 ${deletedCount} 笔本月交易`;
          } catch (error) {
            this.statusMessage = `❌ 删除失败: ${(error as Error).message}`;
          }
        })

      Button('删除支出分类')
        .width(200)
        .height(40)
        .margin({ bottom: 10 })
        .onClick(async () => {
          try {
            const deletedCount = await DatabaseHelper.deleteCategoriesByType(0);
            this.statusMessage = `✅ 已删除 ${deletedCount} 个支出分类`;
          } catch (error) {
            this.statusMessage = `❌ 删除失败: ${(error as Error).message}`;
          }
        })

      Button('删除收入分类')
        .width(200)
        .height(40)
        .margin({ bottom: 10 })
        .onClick(async () => {
          try {
            const deletedCount = await DatabaseHelper.deleteCategoriesByType(1);
            this.statusMessage = `✅ 已删除 ${deletedCount} 个收入分类`;
          } catch (error) {
            this.statusMessage = `❌ 删除失败: ${(error as Error).message}`;
          }
        })

      Text('删除单个交易记录')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20, bottom: 10 })

      TextInput({ placeholder: '输入交易记录ID' })
        .width(200)
        .height(40)
        .margin({ bottom: 10 })
        .onChange((value: string) => {
          this.transactionIdToDelete = value;
        })

      Button('删除指定交易')
        .width(200)
        .height(40)
        .margin({ bottom: 10 })
        .onClick(async () => {
          try {
            const transactionId = parseInt(this.transactionIdToDelete.trim());
            if (isNaN(transactionId) || transactionId <= 0) {
              this.statusMessage = '❌ 请输入有效的交易记录ID';
              return;
            }

            const success = await DatabaseHelper.deleteTransaction(transactionId);
            if (success) {
              this.statusMessage = `✅ 已删除交易记录 ID: ${transactionId}`;
              this.transactionIdToDelete = '';
            } else {
              this.statusMessage = `❌ 删除失败: 交易记录 ID ${transactionId} 不存在`;
            }
          } catch (error) {
            this.statusMessage = `❌ 删除失败: ${(error as Error).message}`;
          }
        })
    }
    .width('100%')
    .height('100%')
    .padding(20)
    .alignItems(HorizontalAlign.Center)
  }
}