import { relationalStore } from '@kit.ArkData'
import { promptAction } from '@kit.ArkUI'
import { decrypt, EncryptData, getKeyAlg } from './Crypto'
import { Action, Location } from './Datachange'
import { CloudBackupTimeItem } from './Dataget'
import { autoBackupTable, autoSyncTable } from './Table'

export interface TodoItem {
  id: string,
  content: string,
  priority: number,
  startTime: number,
  endTime: number,
  duration: number,
  recurrenceRule: string,
  excludeTime: number[],
  tag: string[],
  dependency: string[],
  location: Location,
  action: Action[],
  bz: string,
  recentCompletedTime: number,
  updateTime: number,
  cloudBackupTime: CloudBackupTimeItem[]
}

interface FileBackupObject {
  encrypted: boolean,
  data: EncryptData[]
}

async function getImportString(filestring: string) {
  if (filestring.startsWith('[')) {
    return filestring
  } else {
    try {
      const fileBackupObject = JSON.parse(filestring) as FileBackupObject
      if (!fileBackupObject.encrypted) {
        return JSON.stringify(fileBackupObject.data)
      } else {
        if (!getKeyAlg()) {
          await promptAction.openToast({
            message: '未导入密钥，无法解密加密数据'
          })
          return 'unabledecrypt'
        }
        const decryptedArray: object[] = []
        const promises = fileBackupObject.data.map(async (item) => {
          const res = await decrypt(item)
          decryptedArray.push(JSON.parse(res))
        })
        await Promise.all(promises)
        return JSON.stringify(decryptedArray)
      }
    } catch {
      return 'fail'
    }
  }
}

export async function importTodo(context: Context, data: string, conflict: relationalStore.ConflictResolution) {
  const importstring = await getImportString(data)
  if (importstring !== 'fail' && importstring !== 'unabledecrypt') {
    try {
      const array = JSON.parse(importstring) as TodoItem[]
      const rdbStore = await relationalStore.getRdbStore(context, {
        name: 'todo',
        securityLevel: relationalStore.SecurityLevel.S1,
        encrypt: true,
        allowRebuild: true
      })
      const huaweiCloudSyncRdbStore = await relationalStore.getRdbStore(context, {
        name: 'huaweicloudsync',
        securityLevel: relationalStore.SecurityLevel.S1,
        encrypt: true,
        allowRebuild: true
      })
      array.forEach(item => {
        rdbStore.insertSync('todo', {
          id: item.id,
          teamId: '',
          content: item.content,
          priority: item.priority,
          startTime: item.startTime,
          endTime: item.endTime,
          duration: item.duration,
          recurrenceRule: item.recurrenceRule,
          excludeTime: JSON.stringify(item.excludeTime),
          tag: JSON.stringify(item.tag),
          dependency: JSON.stringify(item.dependency),
          location: JSON.stringify(item.location),
          action: JSON.stringify(item.action),
          bz: item.bz,
          recentCompletedTime: item.recentCompletedTime,
          updateTime: item.updateTime,
          cloudBackupTime: JSON.stringify(item.cloudBackupTime)
        }, conflict)
        huaweiCloudSyncRdbStore.insertSync('todo', {
          id: item.id,
          content: item.content,
          priority: item.priority,
          startTime: item.startTime,
          endTime: item.endTime,
          duration: item.duration,
          recurrenceRule: item.recurrenceRule,
          excludeTime: JSON.stringify(item.excludeTime),
          tag: JSON.stringify(item.tag),
          dependency: JSON.stringify(item.dependency),
          location: JSON.stringify(item.location),
          action: JSON.stringify(item.action),
          bz: item.bz,
          recentCompletedTime: item.recentCompletedTime,
          updateTime: item.updateTime,
          cloudBackupTime: JSON.stringify(item.cloudBackupTime)
        }, conflict)
      })
      await autoSyncTable(context)
      await autoBackupTable(context)
      return 'success'
    } catch {
      await promptAction.openToast({
        message: '导入失败'
      })
      return 'fail'
    }
  } else {
    if (importstring === 'fail') {
      await promptAction.openToast({
        message: '导入失败'
      })
    }
    return 'fail'
  }
}