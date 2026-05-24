import { relationalStore } from '@kit.ArkData'
import { util } from '@kit.ArkTS'
import { promptAction } from '@kit.ArkUI'
import { batteryInfo, power } from '@kit.BasicServicesKit'
import { calendarManager } from '@kit.CalendarKit'
import { rcp } from '@kit.RemoteCommunicationKit'
import { caldavBackup, caldavDelete, caldavGet } from './Caldav'
import { encrypt, EncryptData, getKeyAlg } from './Crypto'
import { deleteTodo } from './Datachange'
import { getPersonalTodoList } from './Dataget'
import { importTodoArray, TodoItem } from './Dataimport'
import { write } from './File'
import { getPermission } from './Permission'
import { getFlushPreference } from './Preference'
import { globalDefaultSession } from './Request'
import { parseRRule, stringifyRRule } from './Rrule'
import { getWebdavServerInfo } from './Webdavserver'

interface Item {
  deviceId: string,
  deviceName: string,
  deviceType: string,
  networkId: string
}

export async function autoSyncTable(context: Context, fromDeviceId?: string) {
  const pauseAutoSyncWhenLowBatteryCapacityLevel =
    getFlushPreference(context, 'dataSetting', 'pauseAutoSyncWhenLowBatteryCapacityLevel', false)
  const pauseAutoSyncWhenPowerSave = getFlushPreference(context, 'dataSetting', 'pauseAutoSyncWhenPowerSave', false)
  const lowBatteryCapacityLevel =
    getFlushPreference(context, 'debugSetting', 'lowBatteryCapacityLevel', batteryInfo.BatteryCapacityLevel.LEVEL_LOW)
  if (pauseAutoSyncWhenLowBatteryCapacityLevel && batteryInfo.batteryCapacityLevel >= lowBatteryCapacityLevel) {
    return
  }
  const currentPowerMode = power.getPowerMode()
  if (pauseAutoSyncWhenPowerSave && currentPowerMode !== power.DevicePowerMode.MODE_NORMAL &&
    currentPowerMode !== power.DevicePowerMode.MODE_PERFORMANCE) {
    return
  }
  const autoSync = getFlushPreference(context, 'dataSetting', 'autoSync', false)
  if (autoSync) {
    const autoSyncDevices: Item[] = getFlushPreference(context, 'dataSetting', 'autoSyncDevices', []) as Item[]
    const promises = autoSyncDevices.map(async (item) => {
      if (item.deviceId !== fromDeviceId) {
        await syncTable(context, item.networkId, relationalStore.SyncMode.SYNC_MODE_PUSH)
      }
    })
    await Promise.all(promises)
  }
  await huaweiCloudSyncTable(context)
  const autoSystemCalendarSync = getFlushPreference(context, 'dataSetting', 'autoSystemCalendarSync', false)
  if (autoSystemCalendarSync) {
    await systemCalendarSyncTable(context, 'push')
  }
}

export async function syncTable(context: Context, networkId: string, syncMode: relationalStore.SyncMode) {
  const permission = getPermission('ohos.permission.DISTRIBUTED_DATASYNC')
  if (!permission) {
    await promptAction.openToast({
      message: '同步失败，原因：无权限'
    })
  }
  if (permission) {
    const rdbStore = await relationalStore.getRdbStore(context, {
      name: 'todo',
      securityLevel: relationalStore.SecurityLevel.S1,
      encrypt: true,
      allowRebuild: true
    })
    const predicates = new relationalStore.RdbPredicates('todo')
    predicates.inDevices([networkId])
    try {
      const res = await rdbStore.sync(syncMode, predicates)
      if (res[0][1] !== 0) {
        await promptAction.openToast({
          message: '同步失败，设备 ID：' + res[0][0] + '，错误码：' + res[0][1]
        })
      }
      if (res[0][1] === 0) {
        await promptAction.openToast({
          message: '同步成功，设备 ID：' + res[0][0]
        })
      }
    } catch (err) {
      await promptAction.openToast({
        message: '发生错误，错误码：' + err.code
      })
    }
  }
}

async function huaweiCloudSyncTable(context: Context) {
  const autoHuaweiCloudSync = getFlushPreference(context, 'dataSetting', 'autoHuaweiCloudSync', false)
  if (autoHuaweiCloudSync) {
    const huaweiCloudSyncRdbStore = await relationalStore.getRdbStore(context, {
      name: 'huaweicloudsync',
      securityLevel: relationalStore.SecurityLevel.S1,
      encrypt: true,
      allowRebuild: true
    })
    await huaweiCloudSyncRdbStore.cloudSync(relationalStore.SyncMode.SYNC_MODE_TIME_FIRST, ['todo'], () => {
    })
  }
}

export async function systemCalendarSyncTable(context: Context, mode: 'push' | 'pull') {
  if (getPermission('ohos.permission.READ_CALENDAR') && getPermission('ohos.permission.WRITE_CALENDAR')) {
    const systemCalendarManager = calendarManager.getCalendarManager(context)
    const allCalendars = await systemCalendarManager.getAllCalendars()
    const calendars = allCalendars.map(item => item.getAccount())
    if (!calendars.find(item => item.name === 'com.zhangxm.aitodo')) {
      await systemCalendarManager.createCalendar({
        name: 'com.zhangxm.aitodo',
        type: calendarManager.CalendarType.LOCAL,
        displayName: '轩铭智能待办'
      })
    }
    const calendar = await systemCalendarManager.getCalendar({
      name: 'com.zhangxm.aitodo',
      type: calendarManager.CalendarType.LOCAL,
      displayName: '轩铭智能待办'
    })
    const events = await calendar.getEvents()
    const todos = await getPersonalTodoList(context)
    if (mode === 'push') {
      const promisesa = todos.map(async (item) => {
        const eventItem = events.find(eventItem => eventItem.identifier === item.id)
        const event: calendarManager.Event = {
          type: calendarManager.EventType.NORMAL,
          title: item.content,
          location: {
            latitude: item.location.latitude,
            longitude: item.location.longitude,
            location: item.location.location
          },
          startTime: item.startTime,
          endTime: item.endTime,
          description: item.bz,
          identifier: item.id
        }
        if (item.recurrenceRule) {
          event.recurrenceRule = {
            recurrenceFrequency: parseRRule(item.recurrenceRule).recurrenceFrequency,
            expire: parseRRule(item.recurrenceRule).expire,
            count: parseRRule(item.recurrenceRule).count,
            interval: parseRRule(item.recurrenceRule).interval,
            excludedDates: item.excludeTime,
            daysOfWeek: parseRRule(item.recurrenceRule).daysOfWeek,
            daysOfMonth: parseRRule(item.recurrenceRule).daysOfMonth,
            monthsOfYear: parseRRule(item.recurrenceRule).monthsOfYear
          }
        }
        if (!eventItem) {
          try {
            await calendar.addEvent(event)
          } catch {
          }
        } else {
          event.id = eventItem.id
          await calendar.updateEvent(event)
        }
      })
      await Promise.all(promisesa)
      const promisesb = events.map(async (item) => {
        if (!todos.find(todoItem => todoItem.id === item.identifier)) {
          await calendar.deleteEvent(item.id)
        }
      })
      await Promise.all(promisesb)
    }
    if (mode === 'pull') {
      const todoArray: TodoItem[] = []
      for (let i = 0; i < events.length; i++) {
        const item = events[i]
        const event = await calendar.getEvents(calendarManager.EventFilter.filterById([item.id]), ['recurrenceRule'])
        const excludeTime: number[] = []
        if (event[0].recurrenceRule?.excludedDates) {
          event[0].recurrenceRule?.excludedDates.forEach(item => {
            excludeTime.push(item)
          })
        }
        todoArray.push({
          id: String(item.identifier),
          content: String(item.title),
          priority: 0,
          startTime: item.startTime,
          endTime: item.endTime,
          duration: 0,
          recurrenceRule: event[0].recurrenceRule ? stringifyRRule(JSON.stringify(event[0].recurrenceRule)) : '',
          excludeTime: excludeTime,
          tag: [],
          dependency: [],
          location: {
            latitude: item.location?.latitude ? Number(item.location?.latitude) : -1,
            longitude: item.location?.longitude ? Number(item.location?.longitude) : -1,
            location: item.location?.location ? String(item.location?.location) : ''
          },
          action: [],
          bz: String(item.description),
          recentCompletedTime: -1,
          updateTime: Date.now(),
          cloudBackupTime: []
        })
      }
      await importTodoArray(context, todoArray, relationalStore.ConflictResolution.ON_CONFLICT_REPLACE)
      const promisesb = todos.map(async (item) => {
        if (!events.find(eventItem => eventItem.identifier === item.id)) {
          await deleteTodo(context, item.id)
        }
      })
      await Promise.all(promisesb)
    }
    return 'success'
  }
  return 'fail'
}

export async function autoBackupTable(context: Context, caldav = true) {
  const pauseAutoBackupWhenLowBatteryCapacityLevel =
    getFlushPreference(context, 'dataSetting', 'pauseAutoSyncWhenLowBatteryCapacityLevel', false)
  const pauseAutoBackupWhenPowerSave = getFlushPreference(context, 'dataSetting', 'pauseAutoSyncWhenPowerSave', false)
  const lowBatteryCapacityLevel =
    getFlushPreference(context, 'debugSetting', 'lowBatteryCapacityLevel', batteryInfo.BatteryCapacityLevel.LEVEL_LOW)
  if (pauseAutoBackupWhenLowBatteryCapacityLevel && batteryInfo.batteryCapacityLevel >= lowBatteryCapacityLevel) {
    return
  }
  const currentPowerMode = power.getPowerMode()
  if (pauseAutoBackupWhenPowerSave && currentPowerMode !== power.DevicePowerMode.MODE_NORMAL &&
    currentPowerMode !== power.DevicePowerMode.MODE_PERFORMANCE) {
    return
  }
  const autoBackup = getFlushPreference(context, 'dataSetting', 'autoBackup', true)
  if (autoBackup) {
    await backupTable(context)
  }
  const autoFileBackup = getFlushPreference(context, 'dataSetting', 'autoFileBackup', true)
  const autoWebdavBackup = getFlushPreference(context, 'dataSetting', 'autoWebdavBackup', true)
  const autoCaldavBackup = getFlushPreference(context, 'dataSetting', 'autoCaldavBackup', true)
  let array: TodoItem[] = []
  if (autoFileBackup || autoWebdavBackup || (autoCaldavBackup && caldav)) {
    array = await getPersonalTodoList(context)
  }
  if (autoFileBackup) {
    await fileBackupTable(context, array)
  }
  if (autoWebdavBackup) {
    await webdavBackupTable(context, array)
  }
  if (autoCaldavBackup && caldav) {
    await caldavBackupTable(context, array)
  }
}

export async function backupTable(context: Context) {
  const rdbStore = await relationalStore.getRdbStore(context, {
    name: 'todo',
    securityLevel: relationalStore.SecurityLevel.S1,
    encrypt: true,
    allowRebuild: true
  })
  await rdbStore.backup('todobackup.db')
}

async function getFileBackupString(todoArray: TodoItem[], encrypted: boolean) {
  if (!encrypted) {
    return JSON.stringify({
      encrypted: false,
      data: todoArray
    })
  }
  if (encrypted) {
    const encryptedArray: EncryptData[] = []
    const promises = todoArray.map(async (item) => {
      const res = await encrypt(JSON.stringify(item))
      encryptedArray.push({
        content: res.content,
        iv: res.iv
      })
    })
    await Promise.all(promises)
    return JSON.stringify({
      encrypted: true,
      data: encryptedArray
    })
  }
  return 'fail'
}

export async function fileBackupTable(context: Context, todoArray?: TodoItem[]) {
  const encryptFileBackup = getFlushPreference(context, 'dataSetting', 'encryptFileBackup', true)
  let encrypted = false
  if (encryptFileBackup && getKeyAlg()) {
    encrypted = true
  }
  let array: TodoItem[] = []
  if (!todoArray) {
    array = await getPersonalTodoList(context)
  }
  if (todoArray) {
    array = todoArray
  }
  const datastring = await getFileBackupString(array, encrypted)
  if (datastring !== 'fail') {
    await write(context.filesDir + '/backup/todo.txt', datastring)
  }
}

export async function webdavBackupTable(context: Context, todoArray?: TodoItem[]) {
  const webdavServerInfo = await getWebdavServerInfo()
  if (!webdavServerInfo.path) {
    return 'fail'
  }
  const encryptWebdavBackup = getFlushPreference(context, 'dataSetting', 'encryptWebdavBackup', true)
  let encrypted = false
  if (encryptWebdavBackup && getKeyAlg()) {
    encrypted = true
  }
  let array: TodoItem[] = []
  if (!todoArray) {
    array = await getPersonalTodoList(context)
  }
  if (todoArray) {
    array = todoArray
  }
  const datastring = await getFileBackupString(array, encrypted)
  if (datastring !== 'fail') {
    try {
      const response = await globalDefaultSession.fetch(new rcp.Request(webdavServerInfo.path + '/todo.txt', 'PUT', {
        Authorization: 'Basic ' + new util.Base64Helper().encodeToStringSync(
          new util.TextEncoder().encodeInto(webdavServerInfo.username + ':' + webdavServerInfo.password))
      }, datastring))
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return 'success'
      } else {
        const statusCodeMap: Record<number, string> = {
          401: '账号密码错误',
          405: '目录不存在或无权限'
        }
        const reason = statusCodeMap[response.statusCode]
        if (reason) {
          await promptAction.openToast({
            message: '备份失败，原因：' + reason
          })
          return 'fail'
        }
        await promptAction.openToast({
          message: 'HTTP 请求失败，状态码：' + response.statusCode
        })
        return 'fail'
      }
    } catch (err) {
      await promptAction.openToast({
        message: '发生错误，错误码：' + err.code
      })
      return 'fail'
    }
  }
  return 'fail'
}

export async function caldavBackupTable(context: Context, todoArray?: TodoItem[]) {
  let array: TodoItem[] = []
  if (!todoArray) {
    array = await getPersonalTodoList(context)
  }
  if (todoArray) {
    array = todoArray
  }
  const res = await caldavGet()
  if (res !== 'fail') {
    const todoIdArray = array.map(item => item.id)
    const deleteTodoIdArray = res.map(item => item.id).filter(item => todoIdArray.includes(item))
    const deleteres = await caldavDelete(deleteTodoIdArray)
    if (deleteres !== 'fail') {
      return await caldavBackup(array)
    }
  }
  return 'fail'
}

export async function recoveryTable(context: Context) {
  const rdbStore = await relationalStore.getRdbStore(context, {
    name: 'todo',
    securityLevel: relationalStore.SecurityLevel.S1,
    encrypt: true,
    allowRebuild: true
  })
  await rdbStore.restore('todobackup.db')
}