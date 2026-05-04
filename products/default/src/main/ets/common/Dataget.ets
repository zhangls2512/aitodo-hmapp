import { relationalStore } from '@kit.ArkData'
import { promptAction } from '@kit.ArkUI'
import { geoLocationManager } from '@kit.LocationKit'
import { map, mapCommon } from '@kit.MapKit'
import { getPersonalAccountInfo, getTeamName } from './Account'
import { Action, Location } from './Datachange'
import { TodoItem } from './Dataimport'
import { getPermission } from './Permission'
import { getRecentTodoFromFreq } from './Rrule'
import { getTagMap } from './Tag'

export interface CloudBackupTimeItem {
  uid: string,
  time: number
}

export interface Todo {
  id: string,
  teamId: string,
  teamName?: string,
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
  isCompleted?: boolean,
  status?: string,
  updateTime: number,
  cloudBackupTime: CloudBackupTimeItem[],
  isCloudBackup: boolean,
  distance?: number,
  latestStartTime?: number,
  priorityTagScore?: number
}

export async function isTodoCompleted(context: Context, id: string, currentTime: number) {
  const info = await getTodoInfo(context, id)
  if (info !== 'fail') {
    if (!info.recurrenceRule && info.recentCompletedTime !== -1) {
      return true
    }
    if (info.recurrenceRule) {
      const recentTodoStartEndTime =
        getRecentTodoFromFreq(context, info.recurrenceRule, info.startTime, info.endTime, info.excludeTime, currentTime)
      if (info.recentCompletedTime >= recentTodoStartEndTime.startTime) {
        return true
      }
    }
    return false
  }
  return true
}

export async function getTodoInfo(context: Context, id: string) {
  const rdbStore = await relationalStore.getRdbStore(context, {
    name: 'todo',
    securityLevel: relationalStore.SecurityLevel.S1,
    encrypt: true,
    allowRebuild: true
  })
  const predicates = new relationalStore.RdbPredicates('todo')
  predicates.equalTo('id', id)
  const resultSet = await rdbStore.query(predicates)
  const idIndex = resultSet.getColumnIndex('id')
  const teamIdIndex = resultSet.getColumnIndex('teamId')
  const contentIndex = resultSet.getColumnIndex('content')
  const priorityIndex = resultSet.getColumnIndex('priority')
  const startTimeIndex = resultSet.getColumnIndex('startTime')
  const endTimeIndex = resultSet.getColumnIndex('endTime')
  const durationIndex = resultSet.getColumnIndex('duration')
  const recurrenceRuleIndex = resultSet.getColumnIndex('recurrenceRule')
  const excludeTimeIndex = resultSet.getColumnIndex('excludeTime')
  const tagIndex = resultSet.getColumnIndex('tag')
  const dependencyIndex = resultSet.getColumnIndex('dependency')
  const locationIndex = resultSet.getColumnIndex('location')
  const actionIndex = resultSet.getColumnIndex('action')
  const bzIndex = resultSet.getColumnIndex('bz')
  const recentCompletedTimeIndex = resultSet.getColumnIndex('recentCompletedTime')
  const updateTimeIndex = resultSet.getColumnIndex('updateTime')
  const cloudBackupTimeIndex = resultSet.getColumnIndex('cloudBackupTime')
  if (resultSet.goToNextRow()) {
    const info: Todo = {
      id: resultSet.getValue(idIndex) as string,
      teamId: resultSet.getValue(teamIdIndex) as string,
      content: resultSet.getValue(contentIndex) as string,
      priority: resultSet.getValue(priorityIndex) as number,
      startTime: resultSet.getValue(startTimeIndex) as number,
      endTime: resultSet.getValue(endTimeIndex) as number,
      duration: resultSet.getValue(durationIndex) as number,
      recurrenceRule: resultSet.getValue(recurrenceRuleIndex) as string,
      excludeTime: JSON.parse(resultSet.getValue(excludeTimeIndex) as string) as number[],
      tag: JSON.parse(resultSet.getValue(tagIndex) as string) as string[],
      dependency: JSON.parse(resultSet.getValue(dependencyIndex) as string) as string[],
      location: JSON.parse(resultSet.getValue(locationIndex) as string) as Location,
      action: JSON.parse(resultSet.getValue(actionIndex) as string) as Action[],
      bz: resultSet.getValue(bzIndex) as string,
      recentCompletedTime: resultSet.getValue(recentCompletedTimeIndex) as number,
      updateTime: resultSet.getValue(updateTimeIndex) as number,
      cloudBackupTime: JSON.parse(resultSet.getValue(cloudBackupTimeIndex) as string) as CloudBackupTimeItem[],
      isCloudBackup: false
    }
    resultSet.close()
    const accountInfo = await getPersonalAccountInfo()
    const cloudBackupTimeItem = info.cloudBackupTime.find(item => item.uid === accountInfo.uid)
    if (cloudBackupTimeItem) {
      if (cloudBackupTimeItem.time >= info.updateTime) {
        info.isCloudBackup = true
      }
    }
    return info
  }
  resultSet.close()
  return 'fail'
}

export async function getTodoList(context: Context, currentTime: number) {
  try {
    const rdbStore = await relationalStore.getRdbStore(context, {
      name: 'todo',
      securityLevel: relationalStore.SecurityLevel.S1,
      encrypt: true,
      allowRebuild: true
    })
    const predicates = new relationalStore.RdbPredicates('todo')
    const resultSet = await rdbStore.query(predicates)
    const idIndex = resultSet.getColumnIndex('id')
    const teamIdIndex = resultSet.getColumnIndex('teamId')
    const contentIndex = resultSet.getColumnIndex('content')
    const priorityIndex = resultSet.getColumnIndex('priority')
    const startTimeIndex = resultSet.getColumnIndex('startTime')
    const endTimeIndex = resultSet.getColumnIndex('endTime')
    const durationIndex = resultSet.getColumnIndex('duration')
    const recurrenceRuleIndex = resultSet.getColumnIndex('recurrenceRule')
    const excludeTimeIndex = resultSet.getColumnIndex('excludeTime')
    const tagIndex = resultSet.getColumnIndex('tag')
    const dependencyIndex = resultSet.getColumnIndex('dependency')
    const locationIndex = resultSet.getColumnIndex('location')
    const actionIndex = resultSet.getColumnIndex('action')
    const bzIndex = resultSet.getColumnIndex('bz')
    const recentCompletedTimeIndex = resultSet.getColumnIndex('recentCompletedTime')
    const updateTimeIndex = resultSet.getColumnIndex('updateTime')
    const cloudBackupTimeIndex = resultSet.getColumnIndex('cloudBackupTime')
    const array: Todo[] = []
    while (resultSet.goToNextRow()) {
      const info: Todo = {
        id: resultSet.getValue(idIndex) as string,
        teamId: resultSet.getValue(teamIdIndex) as string,
        content: resultSet.getValue(contentIndex) as string,
        priority: resultSet.getValue(priorityIndex) as number,
        startTime: resultSet.getValue(startTimeIndex) as number,
        endTime: resultSet.getValue(endTimeIndex) as number,
        duration: resultSet.getValue(durationIndex) as number,
        recurrenceRule: resultSet.getValue(recurrenceRuleIndex) as string,
        excludeTime: JSON.parse(resultSet.getValue(excludeTimeIndex) as string) as number[],
        tag: JSON.parse(resultSet.getValue(tagIndex) as string) as string[],
        dependency: JSON.parse(resultSet.getValue(dependencyIndex) as string) as string[],
        location: JSON.parse(resultSet.getValue(locationIndex) as string) as Location,
        action: JSON.parse(resultSet.getValue(actionIndex) as string) as Action[],
        bz: resultSet.getValue(bzIndex) as string,
        recentCompletedTime: resultSet.getValue(recentCompletedTimeIndex) as number,
        isCompleted: await isTodoCompleted(context, resultSet.getValue(idIndex) as string, currentTime),
        updateTime: resultSet.getValue(updateTimeIndex) as number,
        cloudBackupTime: JSON.parse(resultSet.getValue(cloudBackupTimeIndex) as string) as CloudBackupTimeItem[],
        isCloudBackup: false
      }
      info.teamName = await getTeamName(info.teamId)
      const accountInfo = await getPersonalAccountInfo()
      const cloudBackupTimeItem = info.cloudBackupTime.find(item => item.uid === accountInfo.uid)
      if (cloudBackupTimeItem) {
        if (cloudBackupTimeItem.time >= info.updateTime) {
          info.isCloudBackup = true
        }
      }
      array.push(info)
    }
    resultSet.close()
    return array
  } catch (err) {
    await promptAction.openToast({
      message: '发生错误，错误码：' + err.code
    })
    return []
  }
}

export async function getPersonalTodoList(context: Context) {
  try {
    const rdbStore = await relationalStore.getRdbStore(context, {
      name: 'todo',
      securityLevel: relationalStore.SecurityLevel.S1,
      encrypt: true,
      allowRebuild: true
    })
    const predicates = new relationalStore.RdbPredicates('todo')
    predicates.equalTo('teamId', '')
    const resultSet = await rdbStore.query(predicates)
    const idIndex = resultSet.getColumnIndex('id')
    const contentIndex = resultSet.getColumnIndex('content')
    const priorityIndex = resultSet.getColumnIndex('priority')
    const startTimeIndex = resultSet.getColumnIndex('startTime')
    const endTimeIndex = resultSet.getColumnIndex('endTime')
    const durationIndex = resultSet.getColumnIndex('duration')
    const recurrenceRuleIndex = resultSet.getColumnIndex('recurrenceRule')
    const excludeTimeIndex = resultSet.getColumnIndex('excludeTime')
    const tagIndex = resultSet.getColumnIndex('tag')
    const dependencyIndex = resultSet.getColumnIndex('dependency')
    const locationIndex = resultSet.getColumnIndex('location')
    const actionIndex = resultSet.getColumnIndex('action')
    const bzIndex = resultSet.getColumnIndex('bz')
    const recentCompletedTimeIndex = resultSet.getColumnIndex('recentCompletedTime')
    const updateTimeIndex = resultSet.getColumnIndex('updateTime')
    const cloudBackupTimeIndex = resultSet.getColumnIndex('cloudBackupTime')
    const array: TodoItem[] = []
    while (resultSet.goToNextRow()) {
      array.push({
        id: resultSet.getValue(idIndex) as string,
        content: resultSet.getValue(contentIndex) as string,
        priority: resultSet.getValue(priorityIndex) as number,
        startTime: resultSet.getValue(startTimeIndex) as number,
        endTime: resultSet.getValue(endTimeIndex) as number,
        duration: resultSet.getValue(durationIndex) as number,
        recurrenceRule: resultSet.getValue(recurrenceRuleIndex) as string,
        excludeTime: JSON.parse(resultSet.getValue(excludeTimeIndex) as string) as number[],
        tag: JSON.parse(resultSet.getValue(tagIndex) as string) as string[],
        dependency: JSON.parse(resultSet.getValue(dependencyIndex) as string) as string[],
        location: JSON.parse(resultSet.getValue(locationIndex) as string) as Location,
        action: JSON.parse(resultSet.getValue(actionIndex) as string) as Action[],
        bz: resultSet.getValue(bzIndex) as string,
        recentCompletedTime: resultSet.getValue(recentCompletedTimeIndex) as number,
        updateTime: resultSet.getValue(updateTimeIndex) as number,
        cloudBackupTime: JSON.parse(resultSet.getValue(cloudBackupTimeIndex) as string) as CloudBackupTimeItem[]
      })
    }
    resultSet.close()
    return array
  } catch (err) {
    await promptAction.openToast({
      message: '发生错误，错误码：' + err.code
    })
    return []
  }
}

export async function getCurrentTimePersonalTodoList(context: Context, currentTime: number) {
  try {
    const rdbStore = await relationalStore.getRdbStore(context, {
      name: 'todo',
      securityLevel: relationalStore.SecurityLevel.S1,
      encrypt: true,
      allowRebuild: true
    })
    const predicates = new relationalStore.RdbPredicates('todo')
    predicates.equalTo('teamId', '')
    const resultSet = await rdbStore.query(predicates)
    const idIndex = resultSet.getColumnIndex('id')
    const teamIdIndex = resultSet.getColumnIndex('teamId')
    const contentIndex = resultSet.getColumnIndex('content')
    const priorityIndex = resultSet.getColumnIndex('priority')
    const startTimeIndex = resultSet.getColumnIndex('startTime')
    const endTimeIndex = resultSet.getColumnIndex('endTime')
    const durationIndex = resultSet.getColumnIndex('duration')
    const recurrenceRuleIndex = resultSet.getColumnIndex('recurrenceRule')
    const excludeTimeIndex = resultSet.getColumnIndex('excludeTime')
    const tagIndex = resultSet.getColumnIndex('tag')
    const dependencyIndex = resultSet.getColumnIndex('dependency')
    const locationIndex = resultSet.getColumnIndex('location')
    const actionIndex = resultSet.getColumnIndex('action')
    const bzIndex = resultSet.getColumnIndex('bz')
    const recentCompletedTimeIndex = resultSet.getColumnIndex('recentCompletedTime')
    const updateTimeIndex = resultSet.getColumnIndex('updateTime')
    const cloudBackupTimeIndex = resultSet.getColumnIndex('cloudBackupTime')
    const array: Todo[] = []
    while (resultSet.goToNextRow()) {
      const info: Todo = {
        id: resultSet.getValue(idIndex) as string,
        teamId: resultSet.getValue(teamIdIndex) as string,
        content: resultSet.getValue(contentIndex) as string,
        priority: resultSet.getValue(priorityIndex) as number,
        startTime: resultSet.getValue(startTimeIndex) as number,
        endTime: resultSet.getValue(endTimeIndex) as number,
        duration: resultSet.getValue(durationIndex) as number,
        recurrenceRule: resultSet.getValue(recurrenceRuleIndex) as string,
        excludeTime: JSON.parse(resultSet.getValue(excludeTimeIndex) as string) as number[],
        tag: JSON.parse(resultSet.getValue(tagIndex) as string) as string[],
        dependency: JSON.parse(resultSet.getValue(dependencyIndex) as string) as string[],
        location: JSON.parse(resultSet.getValue(locationIndex) as string) as Location,
        action: JSON.parse(resultSet.getValue(actionIndex) as string) as Action[],
        bz: resultSet.getValue(bzIndex) as string,
        recentCompletedTime: resultSet.getValue(recentCompletedTimeIndex) as number,
        isCompleted: await isTodoCompleted(context, resultSet.getValue(idIndex) as string, currentTime),
        updateTime: resultSet.getValue(updateTimeIndex) as number,
        cloudBackupTime: JSON.parse(resultSet.getValue(cloudBackupTimeIndex) as string) as CloudBackupTimeItem[],
        isCloudBackup: false
      }
      if (info.recurrenceRule) {
        const recentTodoStartEndTime =
          getRecentTodoFromFreq(context, info.recurrenceRule, info.startTime, info.endTime, info.excludeTime,
            currentTime)
        info.startTime = recentTodoStartEndTime.startTime
        info.endTime = recentTodoStartEndTime.endTime
      }
      if (currentTime + 86400000 > info.startTime && (info.endTime === -1 || currentTime <= info.endTime)) {
        const accountInfo = await getPersonalAccountInfo()
        const cloudBackupTimeItem = info.cloudBackupTime.find(item => item.uid === accountInfo.uid)
        if (cloudBackupTimeItem) {
          if (cloudBackupTimeItem.time >= info.updateTime) {
            info.isCloudBackup = true
          }
        }
        array.push(info)
      }
    }
    resultSet.close()
    return array
  } catch (err) {
    await promptAction.openToast({
      message: '发生错误，错误码：' + err.code
    })
    return []
  }
}

export async function getRecommendTodoList(context: Context) {
  const currentTime = Date.now()
  const list = await getTodoList(context, currentTime)
  const lista = list.filter(item => !item.isCompleted)
  const listb: Todo[] = []
  for (let i = 0; i < lista.length; i++) {
    const item = lista[i]
    let allCompleted = true
    for (let i = 0; i < item.dependency.length; i++) {
      const completed = await isTodoCompleted(context, item.dependency[i], currentTime)
      if (!completed) {
        allCompleted = false
        break
      }
    }
    if (allCompleted) {
      listb.push(item)
    }
  }
  for (let i = 0; i < listb.length; i++) {
    const item = listb[i]
    if (item.recurrenceRule) {
      const recentTodoStartEndTime =
        getRecentTodoFromFreq(context, item.recurrenceRule, item.startTime, item.endTime, item.excludeTime, currentTime)
      item.startTime = recentTodoStartEndTime.startTime
      item.endTime = recentTodoStartEndTime.endTime
    }
  }
  const listc = listb.filter(item => item.startTime <= currentTime && item.endTime > currentTime)
  let latitude = -1
  let longitude = -1
  const location = getPermission('ohos.permission.LOCATION')
  if (location) {
    try {
      const res = await geoLocationManager.getCurrentLocation()
      const gcj02Position = map.convertCoordinateSync(mapCommon.CoordinateType.WGS84, mapCommon.CoordinateType.GCJ02, {
        latitude: res.latitude,
        longitude: res.longitude
      })
      latitude = gcj02Position.latitude
      longitude = gcj02Position.longitude
    } catch {
    }
  }
  listc.forEach(item => {
    if (latitude !== -1 && longitude !== -1 && item.location.latitude !== -1 && item.location.longitude !== -1) {
      item.distance = map.calculateDistance({
        latitude: latitude,
        longitude: longitude
      }, {
        latitude: item.location.latitude,
        longitude: item.location.longitude
      })
    } else {
      item.distance = Infinity
    }
  })
  listc.forEach(item => {
    if (item.endTime !== -1) {
      if (!item.duration) {
        item.latestStartTime = item.startTime
      }
      if (item.duration) {
        const currentTimeDistance = item.endTime - currentTime
        if (currentTimeDistance > 172800000) {
          item.latestStartTime = Infinity
        }
        if (currentTimeDistance <= 172800000) {
          item.latestStartTime = currentTimeDistance
        }
      }
    }
    if (item.endTime === -1) {
      item.latestStartTime = Infinity
    }
  })
  const tagMap = await getTagMap(context)
  listc.forEach(item => {
    let priority = 5
    if (item.priority >= 1 && item.priority <= 9) {
      priority = 10 - item.priority
    }
    let tagScore = 5
    let tagTotalScore = 0
    item.tag.forEach(tagItem => {
      if (!tagMap.has(tagItem)) {
        tagTotalScore += 5
      }
      if (tagMap.has(tagItem)) {
        tagTotalScore += tagMap.get(tagItem) as number
      }
    })
    if (tagTotalScore > 0) {
      tagScore = tagTotalScore / item.tag.length
    }
    item.priorityTagScore = priority * 0.6 + tagScore * 0.4
  })
  return listc.sort((a, b) => {
    if (a.distance !== b.distance) {
      return Number(a.distance) - Number(b.distance)
    }
    if (!a.duration || !b.duration) {
      return -1
    }
    if (a.latestStartTime !== b.latestStartTime) {
      return Number(a.latestStartTime) - Number(b.latestStartTime)
    }
    if (a.priorityTagScore !== b.priorityTagScore) {
      return Number(a.priorityTagScore) - Number(b.priorityTagScore)
    }
    return 0
  })
}