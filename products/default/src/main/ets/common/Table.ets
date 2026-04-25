import { relationalStore } from '@kit.ArkData'
import { util } from '@kit.ArkTS'
import { promptAction } from '@kit.ArkUI'
import { batteryInfo, power } from '@kit.BasicServicesKit'
import { distributedDeviceManager } from '@kit.DistributedServiceKit'
import { rcp } from '@kit.RemoteCommunicationKit'
import { TodoOutItem } from '../pages/DataInOut'
import { encrypt, EncryptData, getKeyAlg } from './Crypto'
import { getTodoList } from './Dataget'
import { write } from './File'
import { getFlushPreference } from './Preference'
import { getWebdavServerInfo } from './Webdavserver'

interface Item {
  deviceId: string,
  deviceName: string,
  deviceType: string,
  networkId: string
}

export async function syncTable(context: Context, networkId: string, syncMode: relationalStore.SyncMode) {
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
    const devices = distributedDeviceManager.createDeviceManager('com.zhangxm.aitodo').getAvailableDeviceListSync()
    const promises = autoSyncDevices.map(async (item) => {
      if (!devices.find(item => item.deviceId === fromDeviceId)) {
        await syncTable(context, item.networkId, relationalStore.SyncMode.SYNC_MODE_PUSH)
      }
    })
    await Promise.all(promises)
  }
}

export async function autoHuaweiCloudSyncTable(context: Context) {
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

export async function backupTable(context: Context) {
  const rdbStore = await relationalStore.getRdbStore(context, {
    name: 'todo',
    securityLevel: relationalStore.SecurityLevel.S1,
    encrypt: true,
    allowRebuild: true
  })
  await rdbStore.backup('todobackup.db')
}

async function getFileBackupString(context: Context, encrypted: boolean): Promise<string> {
  const array = await getTodoList(context)
  if (array.length > 0) {
    const arrayOut = array.filter(item => !item.teamId)
    if (!encrypted) {
      return JSON.stringify({
        encrypted: false,
        data: arrayOut
      })
    }
    if (encrypted) {
      const encryptedArray: EncryptData[] = []
      const promises = arrayOut.map(async (item: TodoOutItem) => {
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
  }
  return 'fail'
}

export async function fileBackupTable(context: Context) {
  const encryptFileBackup = getFlushPreference(context, 'dataSetting', 'encryptFileBackup', true)
  let encrypted = false
  if (encryptFileBackup && getKeyAlg()) {
    encrypted = true
  }
  const datastring = await getFileBackupString(context, encrypted)
  if (datastring !== 'fail') {
    await write(context.filesDir + '/backup/todo.txt', datastring)
  }
}

export async function webdavBackupTable(context: Context) {
  const webdavServerInfo = await getWebdavServerInfo()
  if (!webdavServerInfo.path) {
    return 'fail'
  }
  const encryptWebdavBackup = getFlushPreference(context, 'dataSetting', 'encryptWebdavBackup', true)
  let encrypted = false
  if (encryptWebdavBackup && getKeyAlg()) {
    encrypted = true
  }
  const datastring = await getFileBackupString(context, encrypted)
  if (datastring !== 'fail') {
    const session = rcp.createSession({
      requestConfiguration: {
        security: {
          tlsRange: {
            min: 'TlsV1.2'
          }
        }
      },
      headers: {
        Authorization: 'Basic ' +
          new util.Base64Helper().encodeToStringSync(new util.TextEncoder().encodeInto(webdavServerInfo.username + ':' +
            webdavServerInfo.password))
      }
    })
    try {
      const response = await session.put(webdavServerInfo.path + '/todo.txt', datastring)
      session.close()
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
          message: '请求失败，错误码：' + response.statusCode
        })
        return 'fail'
      }
    } catch (err) {
      session.close()
      await promptAction.openToast({
        message: '发生错误，错误码：' + err.code
      })
      return 'fail'
    }
  }
  return 'success'
}

export async function autoBackupTable(context: Context) {
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
  if (autoFileBackup) {
    await fileBackupTable(context)
  }
  const autoWebdavBackup = getFlushPreference(context, 'dataSetting', 'autoWebdavBackup', true)
  if (autoWebdavBackup) {
    await webdavBackupTable(context)
  }
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