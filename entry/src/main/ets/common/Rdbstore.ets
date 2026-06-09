import { relationalStore } from '@kit.ArkData'

export async function getAllData(context: Context, storeName: string, tableName: string) {
  const rdbStore = await relationalStore.getRdbStore(context, {
    name: storeName,
    securityLevel: relationalStore.SecurityLevel.S1
  })
  const predicates = new relationalStore.RdbPredicates(tableName)
  const resultSet = await rdbStore.query(predicates)
  const columnNames = resultSet.getColumnNames()
  const result: string[][][] = []
  while (resultSet.goToNextRow()) {
    const item: string[][] = []
    for (let i = 0; i < columnNames.length; i++) {
      item.push([columnNames[i], resultSet.getString(i)])
    }
    result.push(item)
  }
  resultSet.close()
  await rdbStore.close()
  return result
}

export async function deleteRdbStoreData(context: Context, storeName: string, tableName: string, columnName: string,
  columnValue: relationalStore.ValueType) {
  const rdbStore = await relationalStore.getRdbStore(context, {
    name: storeName,
    securityLevel: relationalStore.SecurityLevel.S1
  })
  const predicates = new relationalStore.RdbPredicates(tableName)
  predicates.equalTo(columnName, columnValue)
  rdbStore.deleteSync(predicates)
  await rdbStore.close()
}

export async function deleteIndex(context: Context, storeName: string, indexName: string) {
  const rdbStore = await relationalStore.getRdbStore(context, {
    name: storeName,
    securityLevel: relationalStore.SecurityLevel.S1
  })
  await rdbStore.executeSql('DROP INDEX IF EXISTS ' + indexName)
}