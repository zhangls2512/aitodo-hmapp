import { relationalStore } from '@kit.ArkData'
import { util } from '@kit.ArkTS'
import { promptAction } from '@kit.ArkUI'
import { getPersonalAccountAccessToken, getPersonalAccountInfo } from './Account'
import { encrypt } from './Crypto'
import { CloudBackupTimeItem, getTodoInfo, isTodoCompleted } from './Dataget'
import request from './Request'
import { getRecentTodoFromFreq } from './Rrule'
import { autoBackupTable, autoSyncTable } from './Table'

export interface Location {
  latitude: number,
  longitude: number,
  location: string
}

export interface Action {
  type: string,
  value: string
}

export interface TodoInput {
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
  cloudBackup: boolean
}

interface CloudBackupItem {
  id: string,
  content: string
}

interface Content {
  cloudBackupTime: CloudBackupTimeItem[]
}

export async function newTodo(context: Context, data: TodoInput) {
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
  const id = util.generateRandomUUID()
  const updateTime = Date.now()
  rdbStore.insertSync('todo', {
    id: id,
    teamId: '',
    content: data.content,
    priority: data.priority,
    startTime: data.startTime,
    endTime: data.endTime,
    duration: data.duration,
    recurrenceRule: data.recurrenceRule,
    excludeTime: JSON.stringify(data.excludeTime),
    tag: JSON.stringify(data.tag),
    dependency: JSON.stringify(data.dependency),
    location: JSON.stringify(data.location),
    action: JSON.stringify(data.action),
    bz: data.bz,
    recentCompletedTime: -1,
    updateTime: updateTime,
    cloudBackupTime: JSON.stringify([])
  })
  await promptAction.openToast({
    message: '新增成功'
  })
  huaweiCloudSyncRdbStore.insertSync('todo', {
    id: id,
    content: data.content,
    priority: data.priority,
    startTime: data.startTime,
    endTime: data.endTime,
    duration: data.duration,
    recurrenceRule: data.recurrenceRule,
    excludeTime: JSON.stringify(data.excludeTime),
    tag: JSON.stringify(data.tag),
    dependency: JSON.stringify(data.dependency),
    location: JSON.stringify(data.location),
    action: JSON.stringify(data.action),
    bz: data.bz,
    recentCompletedTime: -1,
    updateTime: updateTime,
    cloudBackupTime: JSON.stringify([])
  })
  await autoSyncTable(context)
  await autoBackupTable(context)
  if (data.cloudBackup) {
    await setCloudBackup(context, {
      id: id,
      content: JSON.stringify({
        content: data.content,
        priority: data.priority,
        startTime: data.startTime,
        endTime: data.endTime,
        duration: data.duration,
        recurrenceRule: data.recurrenceRule,
        excludeTime: data.excludeTime,
        tag: data.tag,
        dependency: data.dependency,
        location: data.location,
        action: data.action,
        bz: data.bz,
        recentCompletedTime: -1,
        updateTime: updateTime,
        cloudBackupTime: []
      })
    })
  }
}

export async function updateTodo(context: Context, id: string, data: TodoInput) {
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
  const predicates = new relationalStore.RdbPredicates('todo')
  predicates.equalTo('id', id)
  const resultSet = await rdbStore.query(predicates)
  let recentCompletedTime = -1
  const updateTime = Date.now()
  let cloudBackupTime: CloudBackupTimeItem[] = []
  if (resultSet.goToNextRow()) {
    recentCompletedTime = resultSet.getValue(resultSet.getColumnIndex('recentCompletedTime')) as number
    cloudBackupTime =
      JSON.parse(resultSet.getValue(resultSet.getColumnIndex('cloudBackupTime')) as string) as CloudBackupTimeItem[]
    resultSet.close()
  }
  rdbStore.updateSync({
    content: data.content,
    priority: data.priority,
    startTime: data.startTime,
    endTime: data.endTime,
    duration: data.duration,
    recurrenceRule: data.recurrenceRule,
    excludeTime: JSON.stringify(data.excludeTime),
    tag: JSON.stringify(data.tag),
    dependency: JSON.stringify(data.dependency),
    location: JSON.stringify(data.location),
    action: JSON.stringify(data.action),
    bz: data.bz,
    updateTime: updateTime
  }, predicates)
  await promptAction.openToast({
    message: '修改成功'
  })
  huaweiCloudSyncRdbStore.updateSync({
    content: data.content,
    priority: data.priority,
    startTime: data.startTime,
    endTime: data.endTime,
    duration: data.duration,
    recurrenceRule: data.recurrenceRule,
    excludeTime: JSON.stringify(data.excludeTime),
    tag: JSON.stringify(data.tag),
    dependency: JSON.stringify(data.dependency),
    location: JSON.stringify(data.location),
    action: JSON.stringify(data.action),
    bz: data.bz,
    updateTime: updateTime
  }, predicates)
  await autoSyncTable(context)
  await autoBackupTable(context)
  if (data.cloudBackup) {
    await setCloudBackup(context, {
      id: id,
      content: JSON.stringify({
        content: data.content,
        priority: data.priority,
        startTime: data.startTime,
        endTime: data.endTime,
        duration: data.duration,
        recurrenceRule: data.recurrenceRule,
        excludeTime: data.excludeTime,
        tag: data.tag,
        dependency: data.dependency,
        location: data.location,
        action: data.action,
        bz: data.bz,
        recentCompletedTime: recentCompletedTime,
        updateTime: updateTime,
        cloudBackupTime: cloudBackupTime
      })
    })
  }
}

export async function canCompleteTodo(context: Context, id: string, complete: boolean, completedTime: number,
  prompt = false) {
  let res = true
  const info = await getTodoInfo(context, id)
  if (info !== 'fail') {
    if (!complete) {
      if (info.recentCompletedTime === -1) {
        if (prompt) {
          await promptAction.openToast({
            message: '无需取消完成'
          })
        }
        res = false
      }
      if (info.recurrenceRule) {
        if (prompt) {
          await promptAction.openToast({
            message: '重复待办不支持取消完成'
          })
        }
        res = false
      }
    }
    if (complete) {
      if (!info.recurrenceRule) {
        if (info.recentCompletedTime !== -1) {
          if (prompt) {
            await promptAction.openToast({
              message: '无需重复完成'
            })
          }
          res = false
        }
        if (info.startTime > completedTime) {
          if (prompt) {
            await promptAction.openToast({
              message: '未到开始时间'
            })
          }
          res = false
        }
        if (info.endTime !== -1 && info.endTime < completedTime) {
          if (prompt) {
            await promptAction.openToast({
              message: '已过结束时间'
            })
          }
          res = false
        }
      }
      if (info.recurrenceRule) {
        const recentTodoStartEndTime =
          getRecentTodoFromFreq(context, info.recurrenceRule, info.startTime, info.endTime, info.excludeTime,
            completedTime)
        if (info.recentCompletedTime >= recentTodoStartEndTime.startTime) {
          if (prompt) {
            await promptAction.openToast({
              message: '无需重复完成'
            })
          }
          res = false
        }
        if (recentTodoStartEndTime.startTime > completedTime) {
          if (prompt) {
            await promptAction.openToast({
              message: '未到开始时间'
            })
          }
          res = false
        }
        if (recentTodoStartEndTime.endTime !== -1 && recentTodoStartEndTime.endTime < completedTime) {
          if (prompt) {
            await promptAction.openToast({
              message: '已过结束时间'
            })
          }
          res = false
        }
      }
      for (let i = 0; i < info.dependency.length; i++) {
        const completed = await isTodoCompleted(context, info.dependency[i], completedTime)
        if (!completed) {
          if (prompt) {
            await promptAction.openToast({
              message: '依赖待办未完成'
            })
          }
          res = false
          break
        }
      }
    }
  }
  if (info === 'fail') {
    res = false
  }
  return res
}

export async function completeTodo(context: Context, id: string, complete: boolean) {
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
  const predicates = new relationalStore.RdbPredicates('todo')
  predicates.equalTo('id', id)
  const updateTime = Date.now()
  const canComplete = await canCompleteTodo(context, id, complete, updateTime, true)
  if (canComplete) {
    if (!complete) {
      rdbStore.updateSync({
        recentCompletedTime: -1,
        updateTime: updateTime
      }, predicates)
      huaweiCloudSyncRdbStore.updateSync({
        recentCompletedTime: -1,
        updateTime: updateTime
      }, predicates)
      await promptAction.openToast({
        message: '已取消完成'
      })
    }
    if (complete) {
      rdbStore.updateSync({
        recentCompletedTime: updateTime,
        updateTime: updateTime
      }, predicates)
      huaweiCloudSyncRdbStore.updateSync({
        recentCompletedTime: updateTime,
        updateTime: updateTime
      }, predicates)
      await promptAction.openToast({
        message: '已完成'
      })
    }
    await autoSyncTable(context)
    await autoBackupTable(context)
  }
}

export async function deleteTodo(context: Context, id: string, single = false, excludeTime: number[] = []) {
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
  const predicates = new relationalStore.RdbPredicates('todo')
  predicates.equalTo('id', id)
  if (!single) {
    rdbStore.deleteSync(predicates)
    huaweiCloudSyncRdbStore.deleteSync(predicates)
  }
  if (single) {
    const updateTime = Date.now()
    rdbStore.updateSync({
      excludeTime: JSON.stringify(excludeTime),
      updateTime: updateTime
    }, predicates)
    huaweiCloudSyncRdbStore.updateSync({
      excludeTime: JSON.stringify(excludeTime),
      updateTime: updateTime
    }, predicates)
  }
  await promptAction.openToast({
    message: '删除成功'
  })
  await autoSyncTable(context)
  await autoBackupTable(context)
}

export async function setCloudBackup(context: Context, data: CloudBackupItem) {
  const content = JSON.parse(data.content as string) as Content
  const accountInfo = await getPersonalAccountInfo()
  const cloudBackupTimeItem = content.cloudBackupTime.find(item => item.uid === accountInfo.uid)
  if (cloudBackupTimeItem) {
    cloudBackupTimeItem.time = Date.now()
  }
  if (!cloudBackupTimeItem) {
    content.cloudBackupTime.push({
      uid: accountInfo.uid,
      time: Date.now()
    })
  }
  const encryptres = await encrypt(JSON.stringify(content))
  const accessToken = await getPersonalAccountAccessToken()
  if (accessToken) {
    const res = await request(context, '/todo/setBackup', {
      accessToken: accessToken,
      id: data.id,
      content: encryptres.content,
      iv: encryptres.iv
    })
    if (res !== 'fail') {
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
      const predicates = new relationalStore.RdbPredicates('todo')
      predicates.equalTo('id', data.id)
      rdbStore.updateSync({
        cloudBackupTime: JSON.stringify(content.cloudBackupTime)
      }, predicates)
      huaweiCloudSyncRdbStore.updateSync({
        cloudBackupTime: JSON.stringify(content.cloudBackupTime)
      }, predicates)
      await promptAction.openToast({
        message: '云备份成功'
      })
      await autoSyncTable(context)
      await autoBackupTable(context)
    }
  }
}

export async function deleteCloudBackup(context: Context, id: string) {
  const accessToken = await getPersonalAccountAccessToken()
  const accountInfo = await getPersonalAccountInfo()
  if (accessToken) {
    const res = await request(context, '/todo/deleteBackup', {
      accessToken: accessToken,
      id: id
    })
    if (res !== 'fail') {
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
      const predicates = new relationalStore.RdbPredicates('todo')
      predicates.equalTo('id', id)
      const resultSet = await rdbStore.query(predicates)
      let cloudBackupTime: CloudBackupTimeItem[] = []
      if (resultSet.goToNextRow()) {
        const oldCloudBackupTime = resultSet.getValue(resultSet.getColumnIndex('cloudBackupTime')) as string
        resultSet.close()
        const oldCloudBackupTimeArray = JSON.parse(oldCloudBackupTime) as CloudBackupTimeItem[]
        const oldCloudBackupTimeIndex = oldCloudBackupTimeArray.findIndex(item => item.uid === accountInfo.uid)
        if (oldCloudBackupTimeIndex !== -1) {
          oldCloudBackupTimeArray.splice(oldCloudBackupTimeIndex, 1)
        }
        cloudBackupTime = oldCloudBackupTimeArray
      }
      rdbStore.updateSync({
        cloudBackupTime: JSON.stringify(cloudBackupTime)
      }, predicates)
      huaweiCloudSyncRdbStore.updateSync({
        cloudBackupTime: JSON.stringify(cloudBackupTime)
      }, predicates)
      await promptAction.openToast({
        message: '取消云备份成功'
      })
      await autoSyncTable(context)
      await autoBackupTable(context)
    }
  }
}